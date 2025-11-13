# 🛍️ ShopSmart: Full-Stack E-Commerce Platform

ShopSmart is a complete online shopping web application built with Flask and MySQL. It demonstrates a fully integrated system where the Python backend, user interface, and a relational database work together.

The project's key feature is its deep integration with advanced database features, including **Triggers** (for automated cart calculations), **Stored Procedures** (for processing deliveries), and **Functions** (for calculating user spending).

---

## 🚀 Core Features
- **User Authentication:** Secure user registration and login with password hashing (Werkzeug)
- **Product Catalog:** Browse all products or view detailed pages for individual items
- **Product Reviews:** Users can add and view product ratings and comments
- **Shopping Cart:** Full cart functionality (add, remove, update quantities)
- **Checkout & Orders:** Multi-step checkout with order, payment, and delivery management
- **Order Management:** Track status (Pending, Shipped, Delivered)
- **Payment & Delivery:** Mock payment system triggers automated status updates

---

## 🗄️ Database & Backend Features
This project showcases advanced MySQL database logic integrated with Flask.

### 🔹 Triggers
- **trg_cartitem_insert:** Recalculates cart total when an item is added  
- **trg_cartitem_delete:** Recalculates cart total when an item is removed  
- **trg_payment_paid:** Updates order status to *'Shipped'* and creates a delivery record after payment

### 🔹 Stored Procedures
- **sp_process_delivery:** Updates order and delivery status to *'Delivered'* when called
- **sp_delivery_report:** Shows delivery report

### 🔹 Functions
- **fn_total_spent:** Calculates a user’s total lifetime spending on the platform
- **fn_avg_product_rating:** Calculates average product rating

---

## 🛠️ Tech Stack
- **Backend:** Flask (Python)
- **Database:** MySQL
- **Frontend:** HTML, CSS, Bootstrap 5
- **Libraries:** mysql-connector-python, Werkzeug

---

## 📦 Setup & Run Instructions

Follow these steps to set up and run the project locally:

1️⃣ **Set up the Database**

- Ensure MySQL server is running.  
- Execute the SQL file to create all tables, triggers, functions, and sample data:

  ```bash
  mysql -u root -p < online_shopping_db.sql

2️⃣ **Set up the Python Environment**

- Create and activate a virtual environment:
  ```bash
  python -m venv venv
  venv\Scripts\activate    # on Windows
  # or
  source venv/bin/activate # on macOS/Linux

- Install required dependencies:
  ```bash
  pip install flask mysql-connector-python werkzeug

3️⃣ Configure Database Credentials

- Set your database credentials as environment variables:
  ```bash
  # macOS/Linux
  export DB_USER=root
  export DB_PASS=your_password
  export DB_NAME=online_shopping

  # Windows (PowerShell)
  set DB_USER=root
  set DB_PASS=your_password
  set DB_NAME=online_shopping

4️⃣ Run the Application

- Start the Flask server:
  ```bash
  python app.py

Then open your browser and visit:
👉 http://127.0.0.1:5000/
