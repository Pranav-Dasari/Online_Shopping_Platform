# app.py
from flask import Flask, render_template, request, redirect, session, g, flash, url_for
import mysql.connector
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import os

app = Flask(__name__)
# production: load from env var
app.secret_key = os.getenv("FLASK_SECRET", "dev-secret-change-me")

# DB credentials: set via environment variables in production
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASS", "Pranav@2005"),
    "database": os.getenv("DB_NAME", "online_shopping"),
    "auth_plugin": "mysql_native_password",
}

# ---------------- DB connection per request ----------------
@app.before_request
def open_db():
    try:
        if "db" not in g:
            g.db = mysql.connector.connect(**DB_CONFIG)
            g.cursor = g.db.cursor(dictionary=True)
    except mysql.connector.Error as err:
        flash(f"Could not connect to database: {err}", "danger")
        g.db = None
        g.cursor = None

@app.teardown_appcontext
def close_db(e=None):
    cur = g.pop("cursor", None)
    if cur:
        cur.close()
    db = g.pop("db", None)
    if db:
        db.close()

# ---------------- Helpers ----------------
def current_user():
    if "user_id" in session and hasattr(g, 'cursor') and g.cursor:
        g.cursor.execute("SELECT user_id, name, email FROM `user` WHERE user_id=%s", (session["user_id"],))
        return g.cursor.fetchone()
    return None

# ---------------- Routes ----------------

@app.route("/")
def index():
    user = current_user()
    products = []
    if hasattr(g, 'cursor') and g.cursor:
        # top 6 products by avg rating then stock
        g.cursor.execute("""
            SELECT p.*, IFNULL(r.avg_rating,0) AS avg_rating
            FROM product p
            LEFT JOIN (
                SELECT product_id, AVG(rating) AS avg_rating
                FROM review
                GROUP BY product_id
            ) r ON p.product_id = r.product_id
            ORDER BY avg_rating DESC, p.stock_quantity DESC
            LIMIT 6
        """)
        products = g.cursor.fetchall()
    return render_template("index.html", user=user, products=products)

# ---------------- Auth ----------------
@app.route("/add_user", methods=["GET", "POST"])
def add_user():
    if not (hasattr(g, 'cursor') and g.cursor):
        return redirect("/")

    if request.method == "POST":
        name = request.form.get("name")
        email = request.form.get("email")
        password = request.form.get("password")
        dob = request.form.get("dob") or None
        phone = request.form.get("phone") or None
        if not (name and email and password):
            flash("Name, email and password required", "danger")
            return render_template("add_user.html")
        
        # Check if password is strong enough (example)
        if len(password) < 6:
            flash("Password must be at least 6 characters long.", "danger")
            return render_template("add_user.html")

        hashed = generate_password_hash(password)
        try:
            g.cursor.execute(
                "INSERT INTO `user` (name,email,password,dob,phone_no) VALUES (%s,%s,%s,%s,%s)",
                (name, email, hashed, dob, phone)
            )
            g.db.commit()
            flash("Account created. Please log in.", "success")
            return redirect("/login")
        except mysql.connector.IntegrityError:
            flash("Email already exists.", "danger")
        except mysql.connector.Error as err:
            flash(f"DB error: {err}", "danger")
    return render_template("add_user.html", user=current_user())

@app.route("/login", methods=["GET", "POST"])
def login():
    if not (hasattr(g, 'cursor') and g.cursor):
        return redirect("/")

    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        g.cursor.execute("SELECT * FROM `user` WHERE email=%s", (email,))
        user = g.cursor.fetchone()
        
        # THIS IS THE CRITICAL FIX: check_password_hash
        if user and check_password_hash(user["password"], password):
            session["user_id"] = user["user_id"]
            flash("Logged in", "success")
            return redirect("/")
        flash("Invalid credentials", "danger")
    return render_template("login.html", user=current_user())

@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out", "info")
    return redirect("/login")

# ---------------- Products ----------------
@app.route("/products")
def products():
    if not current_user():
        return redirect("/login")
    g.cursor.execute("""
        SELECT p.*, IFNULL(r.avg_rating,0) AS avg_rating
        FROM product p
        LEFT JOIN (
            SELECT product_id, AVG(rating) AS avg_rating
            FROM review
            GROUP BY product_id
        ) r ON p.product_id = r.product_id
    """)
    products = g.cursor.fetchall()
    return render_template("products.html", products=products, user=current_user())

@app.route("/product/<int:product_id>")
def product_details(product_id):
    if not (hasattr(g, 'cursor') and g.cursor):
        return redirect("/")

    g.cursor.execute("""
        SELECT p.*, IFNULL(r.avg_rating,0) AS avg_rating
        FROM product p
        LEFT JOIN (
            SELECT product_id, AVG(rating) AS avg_rating
            FROM review
            GROUP BY product_id
        ) r ON p.product_id = r.product_id
        WHERE p.product_id=%s
    """, (product_id,))
    product = g.cursor.fetchone()
    if not product:
        flash("Product not found", "warning")
        return redirect("/products")
    g.cursor.execute("""
        SELECT rv.*, u.name FROM review rv
        JOIN `user` u ON rv.user_id = u.user_id
        WHERE rv.product_id=%s
        ORDER BY rv.rating DESC, rv.user_id
    """, (product_id,))
    reviews = g.cursor.fetchall()
    return render_template("product_details.html", product=product, reviews=reviews, user=current_user())

@app.route("/add_review", methods=["POST"])
def add_review():
    if "user_id" not in session:
        return redirect("/login")
    product_id = int(request.form.get("product_id"))
    rating = int(request.form.get("rating"))
    comment = request.form.get("comment") or ""
    user_id = session["user_id"]

    # Basic validation: only allow review if user has an order that contains this product
    g.cursor.execute("""
        SELECT COUNT(*) AS cnt
        FROM orderitem oi JOIN ordertable o ON oi.order_id=o.order_id
        WHERE o.user_id=%s AND oi.product_id=%s AND o.status IN ('Delivered','Shipped')
    """, (user_id, product_id))
    allowed = g.cursor.fetchone()["cnt"] > 0
    if not allowed:
        flash("You can only review products you purchased (and shipped/delivered).", "warning")
        return redirect(url_for("product_details", product_id=product_id))

    # pick a related order id (required by composite PK in review)
    g.cursor.execute("""
        SELECT o.order_id
        FROM orderitem oi JOIN ordertable o ON oi.order_id=o.order_id
        WHERE o.user_id=%s AND oi.product_id=%s
        LIMIT 1
    """, (user_id, product_id))
    orow = g.cursor.fetchone()
    order_id = orow["order_id"] if orow else None
    if order_id is None:
        flash("Related order not found to attach review.", "danger")
        return redirect(url_for("product_details", product_id=product_id))

    try:
        # Use ON DUPLICATE KEY UPDATE to allow users to change their review
        g.cursor.execute("""
            INSERT INTO review (product_id, user_id, order_id, rating, comment)
            VALUES (%s,%s,%s,%s,%s)
            ON DUPLICATE KEY UPDATE rating = %s, comment = %s
        """, (product_id, user_id, order_id, rating, comment, rating, comment))
        g.db.commit()
        flash("Thank you for your review!", "success")
    except mysql.connector.Error as err:
        flash(f"Error saving review: {err}", "danger")
    return redirect(url_for("product_details", product_id=product_id))

# ---------------- Cart ----------------
@app.route("/add_to_cart", methods=["POST"])
def add_to_cart():
    if "user_id" not in session:
        return redirect("/login")
    try:
        user_id = session["user_id"]
        product_id = int(request.form.get("product_id"))
        qty = int(request.form.get("quantity", 1))
        
        # Ensure product exists and has stock
        g.cursor.execute("SELECT stock_quantity FROM product WHERE product_id=%s", (product_id,))
        product_stock = g.cursor.fetchone()
        if not product_stock:
             flash("Product not found.", "danger")
             return redirect(request.referrer or "/products")
        if product_stock['stock_quantity'] < qty:
             flash(f"Not enough stock. Only {product_stock['stock_quantity']} left.", "warning")
             return redirect(request.referrer or "/products")

        g.cursor.execute("SELECT cart_id FROM cart WHERE user_id=%s AND status='Active'", (user_id,))
        cart = g.cursor.fetchone()
        if not cart:
            g.cursor.execute("INSERT INTO cart (status, price, user_id) VALUES ('Active',0,%s)", (user_id,))
            g.db.commit()
            cart_id = g.cursor.lastrowid
        else:
            cart_id = cart["cart_id"]

        g.cursor.execute("""
            INSERT INTO cartitem (cart_id, product_id, quantity)
            VALUES (%s,%s,%s)
            ON DUPLICATE KEY UPDATE quantity = quantity + %s
        """, (cart_id, product_id, qty, qty))
        g.db.commit()
        # cart triggers will update cart.price automatically (if triggers exist in DB)
        flash("Added to cart", "success")
    except mysql.connector.Error as err:
        flash(f"DB error adding to cart: {err}", "danger")
    return redirect(request.referrer or "/products")

@app.route("/remove_from_cart", methods=["POST"])
def remove_from_cart():
    if "user_id" not in session:
        return redirect("/login")
    product_id = int(request.form.get("product_id"))
    user_id = session["user_id"]
    g.cursor.execute("SELECT cart_id FROM cart WHERE user_id=%s AND status='Active'", (user_id,))
    cart = g.cursor.fetchone()
    if cart:
        try:
            g.cursor.execute("DELETE FROM cartitem WHERE cart_id=%s AND product_id=%s", (cart["cart_id"], product_id))
            g.db.commit()
            # trigger will recalc cart.price
            flash("Removed from cart", "info")
        except mysql.connector.Error as err:
            flash(f"DB error removing item: {err}", "danger")
    return redirect("/cart")

@app.route("/cart")
def view_cart():
    if "user_id" not in session:
        return redirect("/login")
    user_id = session["user_id"]
    g.cursor.execute("""
        SELECT p.product_id, p.product_name, p.price, ci.quantity, (p.price * ci.quantity) AS total, p.stock_quantity
        FROM cartitem ci
        JOIN cart c ON ci.cart_id = c.cart_id
        JOIN product p ON ci.product_id = p.product_id
        WHERE c.user_id=%s AND c.status='Active'
    """, (user_id,))
    items = g.cursor.fetchall()
    
    # Check cart item quantities against stock
    stock_warning = False
    for item in items:
        if item['quantity'] > item['stock_quantity']:
            stock_warning = True
            flash(f"Warning: Quantity for {item['product_name']} ({item['quantity']}) exceeds stock ({item['stock_quantity']}).", "warning")

    g.cursor.execute("SELECT price FROM cart WHERE user_id=%s AND status='Active'", (user_id,))
    cart_total_row = g.cursor.fetchone()
    cart_total = cart_total_row["price"] if cart_total_row else 0.0

    g.cursor.execute("SELECT fn_total_spent(%s) AS total_spent", (user_id,))
    total_spent_row = g.cursor.fetchone()
    total_spent = total_spent_row['total_spent'] if total_spent_row else 0.0
    
    return render_template("cart.html", items=items, cart_total=cart_total, total_spent=total_spent, item_count=len(items), user=current_user(), stock_warning=stock_warning)

# ---------------- Checkout -> make order + payment (pending) ----------------
@app.route("/checkout", methods=["POST"])
def checkout():
    if "user_id" not in session:
        return redirect("/login")
    user_id = session["user_id"]
    # fetch active cart id
    g.cursor.execute("SELECT cart_id FROM cart WHERE user_id=%s AND status='Active'", (user_id,))
    cart = g.cursor.fetchone()
    if not cart:
        flash("No active cart", "warning")
        return redirect("/cart")
    cart_id = cart["cart_id"]
    
    # Check stock one more time
    g.cursor.execute("""
        SELECT ci.product_id, ci.quantity, p.price, p.stock_quantity, p.product_name
        FROM cartitem ci JOIN product p ON ci.product_id=p.product_id 
        WHERE ci.cart_id=%s
    """, (cart_id,))
    items = g.cursor.fetchall()
    if not items:
        flash("Cart is empty", "warning")
        return redirect("/cart")

    total = 0
    for row in items:
        if row["quantity"] > row["stock_quantity"]:
            flash(f"Checkout failed: Not enough stock for {row['product_name']}. Only {row['stock_quantity']} available.", "danger")
            return redirect("/cart")
        total += row["quantity"] * float(row["price"])

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        # Start transaction
        # g.db.start_transaction()  <--- THIS LINE IS REMOVED
        
        g.cursor.execute("INSERT INTO ordertable (status, order_total, order_date, user_id) VALUES (%s,%s,%s,%s)", ('Pending', total, now, user_id))
        order_id = g.cursor.lastrowid
        
        for row in items:
            g.cursor.execute("INSERT INTO orderitem (order_id, product_id, unit_price, quantity, line_total) VALUES (%s,%s,%s,%s,%s)",
                             (order_id, row["product_id"], row["price"], row["quantity"], row["quantity"] * float(row["price"])))
            # Update stock
            g.cursor.execute("UPDATE product SET stock_quantity = stock_quantity - %s WHERE product_id = %s", (row['quantity'], row['product_id']))

        # create payment record (Pending)
        g.cursor.execute("INSERT INTO payment (method, amount, pay_status, paid_at, order_id) VALUES (%s,%s,%s,%s,%s)", ('Online', total, 'Pending', None, order_id))
        
        # mark cart inactive (or delete items)
        g.cursor.execute("DELETE FROM cartitem WHERE cart_id=%s", (cart_id,))
        g.cursor.execute("UPDATE cart SET status='Inactive', price=0 WHERE cart_id=%s", (cart_id,))
        
        g.db.commit()
        flash("Order created. Go to Payments to complete.", "success")
        return redirect(url_for("payments"))

    except mysql.connector.Error as err:
        g.db.rollback()
        flash(f"Checkout failed: {err}", "danger")
        return redirect("/cart")

# ---------------- Orders ----------------
@app.route("/orders")
def orders():
    if "user_id" not in session:
        return redirect("/login")
    user_id = session["user_id"]
    g.cursor.execute("SELECT * FROM ordertable WHERE user_id=%s ORDER BY order_date DESC", (user_id,))
    orders = g.cursor.fetchall()
    return render_template("orders.html", orders=orders, user=current_user())

# ---------------- Payments ----------------
@app.route("/payments")
def payments():
    if "user_id" not in session:
        return redirect("/login")
    user_id = session["user_id"]
    g.cursor.execute("""
        SELECT p.*, o.order_total 
        FROM payment p 
        JOIN ordertable o ON p.order_id=o.order_id 
        WHERE o.user_id=%s 
        ORDER BY p.paid_at DESC, p.payment_id DESC
    """, (user_id,))
    payments = g.cursor.fetchall()
    return render_template("payments.html", payments=payments, user=current_user())

@app.route("/confirm_payment", methods=["POST"])
def confirm_payment():
    if "user_id" not in session:
        return redirect("/login")
    payment_id = int(request.form.get("payment_id"))
    try:
        # mark payment paid; this will invoke your 'trg_payment_paid' trigger
        g.cursor.execute("UPDATE payment SET pay_status='Paid', paid_at=%s WHERE payment_id=%s", (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), payment_id))
        g.db.commit()

        flash("Payment marked 'Paid'. Delivery status is being updated by the database.", "success")
    except mysql.connector.Error as err:
        flash(f"Error updating payment: {err}", "danger")
    return redirect("/payments")

# ---------------- Delivery ----------------
@app.route("/delivery")
def delivery():
    if "user_id" not in session:
        return redirect("/login")
    user_id = session["user_id"]
    g.cursor.execute("""
        SELECT d.*, p.pay_status, o.order_id
        FROM delivery d
        JOIN payment p ON d.payment_id = p.payment_id
        JOIN ordertable o ON p.order_id = o.order_id
        WHERE o.user_id=%s
        ORDER BY d.delivery_id DESC
    """, (user_id,))
    deliveries = g.cursor.fetchall()
    return render_template("delivery.html", deliveries=deliveries, user=current_user())

@app.route("/process_delivery", methods=["POST"])
def process_delivery():
    if "user_id" not in session:
        return redirect("/login")
    payment_id = int(request.form.get("payment_id"))
    try:
        # Call stored procedure which checks payment status
        g.cursor.callproc("sp_process_delivery", [payment_id])
        g.db.commit()
        flash("Marked as 'Delivered'.", "success")
    except mysql.connector.Error as err:
        # This will catch the SIGNAL '45000' from the procedure
        flash(f"Could not process delivery: {err.msg}", "danger")
    return redirect("/delivery")

# ---------------- Run ----------------
if __name__ == "__main__":
    app.run(debug=True)