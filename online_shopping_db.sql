-- ======================================
-- SCHEMA CREATION
-- ======================================

-- USER
CREATE TABLE user (
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  dob DATE,
  phone_no VARCHAR(20),
  age INT,
  refer_id INT NULL,
  FOREIGN KEY (refer_id) REFERENCES user(user_id) ON DELETE SET NULL
);

-- Multivalued phones for users
CREATE TABLE UserPhones (
  user_id INT,
  phone VARCHAR(20),
  PRIMARY KEY (user_id, phone),
  FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

-- USERPROFILE
CREATE TABLE userprofile (
  profile_id INT PRIMARY KEY AUTO_INCREMENT,
  photo VARCHAR(255),
  preference VARCHAR(255),
  user_id INT UNIQUE,
  FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

-- CART
CREATE TABLE cart (
  cart_id INT PRIMARY KEY AUTO_INCREMENT,
  status VARCHAR(50),
  price DECIMAL(10,2),
  user_id INT,
  FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

-- CATEGORY
CREATE TABLE category (
  cat_id INT PRIMARY KEY AUTO_INCREMENT,
  cat_name VARCHAR(100),
  cat_description TEXT,
  parent_id INT NULL,
  FOREIGN KEY (parent_id) REFERENCES category(cat_id) ON DELETE SET NULL
);

-- VENDOR
CREATE TABLE vendor (
  vendor_id INT PRIMARY KEY AUTO_INCREMENT,
  fname VARCHAR(50),
  mname VARCHAR(50),
  lname VARCHAR(50)
);

-- PRODUCT
CREATE TABLE product (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  product_name VARCHAR(150) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INT DEFAULT 0,
  cat_id INT,
  vendor_id INT,
  FOREIGN KEY (cat_id) REFERENCES category(cat_id) ON DELETE CASCADE,
  FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) ON DELETE CASCADE
);

-- ORDERTABLE
CREATE TABLE ordertable (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  status VARCHAR(50),
  order_total DECIMAL(10,2),
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  user_id INT,
  FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE SET NULL
);

-- ORDERITEM
CREATE TABLE orderitem (
  order_id INT,
  product_id INT,
  unit_price DECIMAL(10,2),
  quantity INT,
  line_total DECIMAL(10,2),
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id) REFERENCES ordertable(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- PAYMENT
CREATE TABLE payment (
  payment_id INT PRIMARY KEY AUTO_INCREMENT,
  method VARCHAR(50),
  amount DECIMAL(10,2),
  pay_status VARCHAR(50),
  paid_at TIMESTAMP NULL,
  order_id INT UNIQUE,
  FOREIGN KEY (order_id) REFERENCES ordertable(order_id) ON DELETE CASCADE
);

-- DELIVERY
CREATE TABLE delivery (
  delivery_id INT PRIMARY KEY AUTO_INCREMENT,
  carrier VARCHAR(100),
  track_no VARCHAR(100),
  shipped_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  del_status VARCHAR(50),
  payment_id INT,
  FOREIGN KEY (payment_id) REFERENCES payment(payment_id) ON DELETE CASCADE
);

-- REVIEW
CREATE TABLE review (
  product_id INT,
  user_id INT,
  order_id INT,
  rating INT,
  comment TEXT,
  PRIMARY KEY (product_id, user_id, order_id),
  FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES ordertable(order_id) ON DELETE CASCADE
);

-- CARTITEM
CREATE TABLE cartitem (
  cart_id INT,
  product_id INT,
  quantity INT,
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (cart_id, product_id),
  FOREIGN KEY (cart_id) REFERENCES cart(cart_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- SELLS 
CREATE TABLE sells (
  vendor_id INT,
  product_id INT,
  warehouseno VARCHAR(50),
  PRIMARY KEY (vendor_id, product_id),
  FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- ======================================
-- INSERT SAMPLE DATA
-- ======================================

-- USERS (Passwords are now HASHED using werkzeug.security)
-- The password for all users is their plain text counterpart (pass123, pass234, etc.)
INSERT INTO user (user_id, name, email, password, dob, phone_no, age, refer_id) VALUES
(1,'Alice Johnson','alice.johnson@email.com','scrypt:32768:8:1$pGq8N9yTfK1bXqGq$4659b9f05928d3bf73379201a4e1a06733de3f136e05086d8f2b7b0521e42845', '1990-05-12', '9876543210', 33, NULL),
(2,'Bob Smith','bob.smith@email.com','scrypt:32768:8:1$aD9jL8kYfP6tQzWw$7f7c8d9e6f3b5c4a1e9d2b2a1c8d4f9e1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d', '1988-11-22', '9876543211', 35, 1),
(3,'Carol Davis','carol.davis@email.com','scrypt:32768:8:1$hG5tK2jPqW9rD6zX$f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3', '1995-07-08', '9876543212', 28, 1),
(4,'David Brown','david.brown@email.com','scrypt:32768:8:1$zX8vY7wUoP4iR1eV$1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b', '1992-03-30', '9876543213', 31, 2),
(5,'Eve Wilson','eve.wilson@email.com','scrypt:32768:8:1$mN6bV5cWqT2yL9uE$c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5', '1985-09-14', '9876543214', 38, NULL),
(6,'Frank Miller','frank.miller@email.com','scrypt:32768:8:1$jK9lO8pRqW4tY7uI$a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9', '1998-01-21', '9876543215', 25, 3),
(7,'Grace Lee','grace.lee@email.com','scrypt:32768:8:1$qP3oI4uYfD7sR1gZ$e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7', '1991-06-11', '9876543216', 32, 4),
(8,'Hank Martin','hank.martin@email.com','scrypt:32768:8:1$vC5xZ4eWqY8tH3kL$9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d', '1989-12-05', '9876543217', 34, 5),
(9,'Ivy Clark','ivy.clark@email.com','scrypt:32768:8:1$uI1oO2pEaG6sK9jW$b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9', '1993-04-17', '9876543218', 30, 6),
(10,'Jack Lewis','jack.lewis@email.com','scrypt:32768:8:1$rE4tY5uIqW7oP9zA$d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1', '1996-08-29', '9876543219', 27, 7);

-- USERPROFILE
INSERT INTO userprofile (profile_id, photo, preference, user_id) VALUES
(1,'alice.jpg','Electronics',1),
(2,'bob.jpg','Books',2),
(3,'carol.jpg','Clothing',3),
(4,'david.jpg','Sports',4),
(5,'eve.jpg','Beauty',5),
(6,'frank.jpg','Gaming',6),
(7,'grace.jpg','Home',7),
(8,'hank.jpg','Electronics',8),
(9,'ivy.jpg','Books',9),
(10,'jack.jpg','Clothing',10);

-- CART
INSERT INTO cart (cart_id, status, price, user_id) VALUES
(1,'Active',1200.00,1),
(2,'Active',450.50,2),
(3,'Inactive',0,3),
(4,'Active',320.00,4),
(5,'Inactive',0,5),
(6,'Active',700.75,6),
(7,'Active',1599.99,7),
(8,'Inactive',0,8),
(9,'Active',250.00,9),
(10,'Active',890.00,10);

-- CATEGORY
INSERT INTO category (cat_id, cat_name, cat_description, parent_id) VALUES
(1,'Electronics','Devices and gadgets',NULL),
(2,'Books','All kinds of books',NULL),
(3,'Clothing','Apparel for men and women',NULL),
(4,'Sports','Sports equipment',NULL),
(5,'Beauty','Cosmetics and skincare',NULL),
(6,'Gaming','Gaming consoles and accessories',NULL),
(7,'Home','Home and kitchen',NULL),
(8,'Mobiles','Smartphones',1),
(9,'Laptops','All laptops',1),
(10,'Fiction','Novels and stories',2);

-- VENDOR
INSERT INTO vendor (vendor_id, fname, mname, lname) VALUES
(1,'John','A','Doe'),
(2,'Mary','B','Smith'),
(3,'Robert','C','Johnson'),
(4,'Linda','D','Williams'),
(5,'Michael','E','Brown'),
(6,'Susan','F','Jones'),
(7,'William','G','Garcia'),
(8,'Patricia','H','Miller'),
(9,'James','I','Davis'),
(10,'Barbara','J','Martinez');

-- PRODUCT
INSERT INTO product (product_id, product_name, description, price, stock_quantity, cat_id, vendor_id) VALUES
(1, 'iPhone 14', 'The latest smartphone with advanced camera features.', 799.99, 50, 8, 1),
(2, 'MacBook Pro', 'A powerful and sleek laptop for professionals.', 1299.99, 30, 9, 2),
(3, 'Gaming Chair', 'Ergonomic chair designed for long gaming sessions.', 199.99, 75, 6, 3),
(4, 'Football', 'Official size 5, all-weather football.', 29.99, 200, 4, 4),
(5, 'Lipstick', 'Long-lasting matte finish lipstick in vibrant red.', 15.99, 150, 5, 5),
(6, 'Cookbook', 'A collection of over 100 international recipes.', 25.50, 120, 2, 6),
(7, 'T-shirt', '100% premium cotton crew neck t-shirt.', 19.99, 300, 3, 7),
(8, 'Headphones', 'Noise-cancelling over-ear headphones with Bluetooth.', 99.99, 90, 1, 8),
(9, 'Smartwatch', 'Fitness tracker and smartwatch with GPS and heart rate monitor.', 199.99, 110, 1, 9),
(10, 'Novel: The Alchemist', 'A classic and inspiring novel by Paulo Coelho.', 12.99, 250, 10, 10);

-- SELLS
INSERT INTO sells (vendor_id, product_id, warehouseno) VALUES
(1,1,'WH101'),(1,2,'WH101'),(2,2,'WH102'),(2,3,'WH102'),(3,3,'WH103'),(3,4,'WH103'),(4,4,'WH104'),
(5,5,'WH105'),(5,6,'WH105'),(6,6,'WH106'),(6,7,'WH106'),(7,7,'WH107'),(8,8,'WH108'),(9,9,'WH109'),(10,10,'WH110');

-- ORDERTABLE
INSERT INTO ordertable (order_id, status, order_total, order_date, user_id) VALUES
(1,'Delivered',799.99,'2025-09-01 10:00:00',1),
(2,'Shipped',1299.99,'2025-09-05 12:30:00',2),
(3,'Cancelled',0.00,'2025-09-07 14:20:00',3),
(4,'Delivered',29.99,'2025-09-08 16:45:00',4),
(5,'Pending',15.99,'2025-09-10 11:15:00',5),
(6,'Delivered',25.50,'2025-09-11 09:10:00',6),
(7,'Shipped',19.99,'2025-09-12 13:40:00',7),
(8,'Pending',99.99,'2025-09-13 17:55:00',8),
(9,'Delivered',199.99,'2025-09-14 15:25:00',9),
(10,'Shipped',12.99,'2025-09-15 18:30:00',10);

-- ORDERITEM
INSERT INTO orderitem (order_id, product_id, unit_price, quantity, line_total) VALUES
(1,1,799.99,1,799.99), (2,2,1299.99,1,1299.99), (3,3,199.99,1,199.99), (4,4,29.99,1,29.99), (5,5,15.99,1,15.99),
(6,6,25.50,1,25.50), (7,7,19.99,1,19.99), (8,8,99.99,1,99.99), (9,9,199.99,1,199.99), (10,10,12.99,1,12.99);

-- PAYMENT
INSERT INTO payment (payment_id, method, amount, pay_status, paid_at, order_id) VALUES
(1,'Credit Card',799.99,'Paid','2025-09-01 10:05:00',1),
(2,'Debit Card',1299.99,'Paid','2025-09-05 12:35:00',2),
(3,'UPI',0.00,'Failed','2025-09-07 14:25:00',3),
(4,'Cash','29.99','Paid','2025-09-08 16:50:00',4),
(5,'Credit Card',15.99,'Pending','2025-09-10 11:20:00',5),
(6,'UPI',25.50,'Paid','2025-09-11 09:15:00',6),
(7,'Debit Card',19.99,'Paid','2025-09-12 13:45:00',7),
(8,'Credit Card',99.99,'Pending','2025-09-13 18:00:00',8),
(9,'UPI',199.99,'Paid','2025-09-14 15:30:00',9),
(10,'Cash',12.99,'Paid','2025-09-15 18:35:00',10);

-- DELIVERY
INSERT INTO delivery (delivery_id, carrier, track_no, shipped_at, delivered_at, del_status, payment_id) VALUES
(1,'DHL','DHL101','2025-09-01 12:00:00','2025-09-03 10:00:00','Delivered',1),
(2,'FedEx','FDX102','2025-09-05 14:00:00',NULL,'Shipped',2),
(3,'DHL','DHL103',NULL,NULL,'Cancelled',3),
(4,'UPS','UPS104','2025-09-08 18:00:00','2025-09-10 11:00:00','Delivered',4),
(5,'FedEx','FDX105',NULL,NULL,'Pending',5),
(6,'UPS','UPS106','2025-09-11 11:00:00','2025-09-12 10:00:00','Delivered',6),
(7,'DHL','DHL107','2025-09-12 15:00:00',NULL,'Shipped',7),
(8,'FedEx','FDX108',NULL,NULL,'Pending',8),
(9,'UPS','UPS109','2025-09-14 17:00:00','2025-09-15 12:00:00','Delivered',9),
(10,'DHL','DHL110','2025-09-15 20:00:00',NULL,'Shipped',10);

-- REVIEW
INSERT INTO review (product_id, user_id, order_id, rating, comment) VALUES
(1,1,1,5,'Excellent product!'),
(2,2,2,4,'Very good, satisfied.'),
(3,3,3,3,'Average quality.'),
(4,4,4,5,'Perfect for sports.'),
(5,5,5,4,'Nice color.'),
(6,6,6,5,'Highly recommended!'),
(7,7,7,3,'It is okay.'),
(8,8,8,4,'Good headphones.'),
(9,9,9,5,'Worth the price.'),
(10,10,10,4,'Interesting read.');

-- CARTITEM
INSERT INTO cartitem (cart_id, product_id, quantity, added_at) VALUES
(1,1,1,'2025-09-01 09:00:00'),
(2,2,1,'2025-09-05 11:00:00'),
(3,3,2,'2025-09-07 13:00:00'),
(4,4,1,'2025-09-08 15:00:00'),
(5,5,1,'2025-09-10 10:00:00'),
(6,6,1,'2025-09-11 08:00:00'),
(7,7,1,'2025-09-12 12:00:00'),
(8,8,1,'2025-09-13 16:00:00'),
(9,9,1,'2025-09-14 14:00:00'),
(10,10,1,'2025-09-15 17:00:00');

-- ======================================
-- TRIGGERS & FUNCTIONS & PROCEDURES 
-- ======================================
DELIMITER //

-- 1️. Trigger: Update cart total after inserting into cartitem
CREATE TRIGGER trg_cartitem_insert
AFTER INSERT ON cartitem
FOR EACH ROW
BEGIN
  UPDATE cart
  SET price = (
    SELECT IFNULL(SUM(ci.quantity * p.price), 0)
    FROM cartitem ci
    JOIN product p ON ci.product_id = p.product_id
    WHERE ci.cart_id = NEW.cart_id
  )
  WHERE cart_id = NEW.cart_id;
END;
//

-- 2️. Trigger: Update cart total after deleting from cartitem
CREATE TRIGGER trg_cartitem_delete
AFTER DELETE ON cartitem
FOR EACH ROW
BEGIN
  UPDATE cart
  SET price = (
    SELECT IFNULL(SUM(ci.quantity * p.loc_price), 0)
    FROM cartitem ci
    JOIN (SELECT product_id, price as loc_price FROM product) p ON ci.product_id = p.product_id
    WHERE ci.cart_id = OLD.cart_id
  )
  WHERE cart_id = OLD.cart_id;
END;
//

-- 3️. Trigger: Update delivery status after payment becomes Paid
CREATE TRIGGER trg_payment_paid
AFTER UPDATE ON payment
FOR EACH ROW
BEGIN
  IF NEW.pay_status = 'Paid' AND OLD.pay_status != 'Paid' THEN
    
    -- Create a delivery record if one doesn't exist
    IF NOT EXISTS (SELECT 1 FROM delivery WHERE payment_id = NEW.payment_id) THEN
        INSERT INTO delivery (carrier, del_status, payment_id, shipped_at, track_no)
        VALUES ('CarrierPending', 'Shipped', NEW.payment_id, NOW(), 'TBD');
    ELSE
        -- Update existing delivery record
        UPDATE delivery
        SET del_status = 'Shipped',
            shipped_at = NOW()
        WHERE payment_id = NEW.payment_id AND del_status = 'Pending';
    END IF;
    
    -- !! REVISED: Update the main order table status as well !!
    UPDATE ordertable
    SET status = 'Shipped'
    WHERE order_id = NEW.order_id;
    
  END IF;
END;
//

-- 1️. Function: Total amount spent by a user
CREATE FUNCTION fn_total_spent(uid INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE total DECIMAL(10,2);
  SELECT IFNULL(SUM(p.amount), 0)
  INTO total
  FROM payment p
  JOIN ordertable o ON p.order_id = o.order_id
  WHERE o.user_id = uid AND p.pay_status = 'Paid';
  RETURN total;
END;
//

-- 2️. Function: Average product rating
CREATE FUNCTION fn_avg_product_rating(pid INT)
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
  DECLARE avg_rate DECIMAL(3,2);
  SELECT IFNULL(AVG(rating), 0)
  INTO avg_rate
  FROM review
  WHERE product_id = pid;
  RETURN avg_rate;
END;
//


-- 1. Procedure: Process delivery only if payment completed
CREATE PROCEDURE sp_process_delivery(IN p_payment_id INT)
BEGIN
  DECLARE pay_stat VARCHAR(50);
  DECLARE del_stat VARCHAR(50);

  SELECT pay_status INTO pay_stat FROM payment WHERE payment_id = p_payment_id;
  SELECT del_status INTO del_stat FROM delivery WHERE payment_id = p_payment_id;

  IF pay_stat = 'Paid' THEN
    IF del_stat = 'Shipped' THEN
        UPDATE delivery
        SET del_status = 'Delivered',
            delivered_at = NOW()
        WHERE payment_id = p_payment_id;
        
        -- !! Update the main order table status as well !!
        UPDATE ordertable o
        JOIN payment p ON o.order_id = p.order_id
        SET o.status = 'Delivered'
        WHERE p.payment_id = p_payment_id;
            
    ELSEIF del_stat = 'Delivered' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery is already complete.';
    ELSE
        SIGNAL SQLSTATE '4L500'
        SET MESSAGE_TEXT = 'Delivery is not yet shipped.';
    END IF;
  ELSE
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Delivery cannot be processed: Payment not completed.';
  END IF;
END;
//

-- 2. Procedure: Show delivery report
CREATE PROCEDURE sp_delivery_report()
BEGIN
  SELECT d.delivery_id, d.carrier, d.track_no, d.shipped_at, d.delivered_at,
         d.del_status, p.pay_status, o.user_id, o.order_total
  FROM delivery d
  JOIN payment p ON d.payment_id = p.payment_id
  JOIN ordertable o ON p.order_id = o.order_id
  ORDER BY d.delivery_id;
END;
//
DELIMITER ;