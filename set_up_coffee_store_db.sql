-- Create database ===============================
CREATE DATABASE CoffeeStore;

-- Create tables =================================

-- Customer table -----------------------------
CREATE TABLE Customers (
	customer_id SERIAL PRIMARY KEY,
	home_store SMALLINT NOT NULL,
	name VARCHAR(225) NOT NULL,
 	email VARCHAR(255) NOT NULL,
	customer_since DATE,
	loyalty_card_number VARCHAR(100),
	birth_date DATE,
	gender VARCHAR(7),
	birth_year INTEGER
);

COPY Customers (
	customer_id, 
	home_store,
	name, 
	email, 
	customer_since, 
	loyalty_card_number, 
	birth_date,
	gender,
	birth_year
)
FROM 'C:\Temp\coffee-db\customer.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY Customers FROM 'C:\Temp\coffee-db\customer.csv' WITH (FORMAT CSV, HEADER);

-- (Optional check)
SELECT * FROM Customers;



-- Inventory table ---------------------------------
CREATE TABLE Inventory (
	outlet_id INTEGER NOT NULL,
	transaction_date DATE NOT NULL,
	product_id INTEGER NOT NULL,
	start_of_day INTEGER NOT NULL,
	quantity_sold INTEGER NOT NULL,
	waste INTEGER,
	percentage_waste FLOAT
);

COPY Inventory (
	outlet_id, 
	transaction_date,
	product_id, 
	start_of_day, 
	quantity_sold, 
	waste, 
	percentage_waste
)
FROM 'C:\Temp\coffee-db\inventory.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY Inventory FROM 'C:\Temp\coffee-db\inventory.csv' WITH (FORMAT CSV, HEADER);

-- (Optional check)
SELECT * FROM Inventory;



-- Product table -------------------------------------
CREATE TABLE Products (
	product_id SERIAL PRIMARY KEY,
	product_group VARCHAR(50) NOT NULL,
	product_category VARCHAR(50) NOT NULL,
	product_type VARCHAR(50) NOT NULL,
	product VARCHAR(100) NOT NULL,
	description TEXT,
	unit_of_measure VARCHAR(10),
	current_wholesale_price FLOAT,
	current_retail_price FLOAT,
	tax_exemption VARCHAR(5),
	promotion VARCHAR(5),
	new_product VARCHAR(5)
);

COPY Products (
	product_id,
	product_group,
	product_category,
	product_type,
	product,
	description,
	unit_of_measure,
	current_wholesale_price,
	current_retail_price,
	tax_exemption,
	promotion,
	new_product
)
FROM 'C:\Temp\coffee-db\product.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY Products FROM 'C:\Temp\coffee-db\product.csv' WITH (FORMAT CSV, HEADER);

-- (Optional check)
SELECT * FROM Products;



-- Outlet table ------------------------------------------
CREATE TABLE Outlets (
	outlet_id INTEGER NOT NULL PRIMARY KEY,
	outlet_type VARCHAR(20) NOT NULL,
	store_square_feet INTEGER,
	address VARCHAR(255),
	city VARCHAR(100),
	state_province VARCHAR(5),
	telephone VARCHAR(15),
	postal_code INTEGER,
	longitude FLOAT,
	latitude FLOAT,
	manager SMALLINT,
	neighborhood VARCHAR(100)
);

COPY Outlets (
	outlet_id,
	outlet_type,
	store_square_feet,
	address,
	city,
	state_province,
	telephone,
	postal_code,
	longitude,
	latitude,
	manager,
	neighborhood
)
FROM 'C:\Temp\coffee-db\sales_outlet.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY Outlets FROM 'C:\Temp\coffee-db\sales_outlet.csv' WITH (FORMAT CSV, HEADER);


-- (Optional check)
SELECT * FROM Outlets;



-- Staff table -------------------------------------------
CREATE TABLE Staffs (
	staff_id SERIAL PRIMARY KEY,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100) NOT NULL,
	position VARCHAR(50) NOT NULL,
	start_date DATE,
	location VARCHAR(5)
);

COPY Staffs (
	staff_id, 
	first_name,
	last_name, 
	staff_position, 
	start_date, 
	staff_location
)
FROM 'C:\Temp\coffee-db\staff.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY Staffs FROM 'C:\Temp\coffee-db\staff.csv' WITH (FORMAT CSV, HEADER);

-- (Optional check)
SELECT * FROM Staffs;



-- Sales Receipt table --------------------------------------------
CREATE TABLE SalesReceipt (
	transaction_id SERIAL PRIMARY KEY,
	customer_transaction_id INTEGER NOT NULL,
	transaction_date DATE NOT NULL,
	transaction_time TIME NOT NULL,
	outlet_id INTEGER NOT NULL,
	staff_id INTEGER NOT NULL,
	customer_id INTEGER NOT NULL,
	product_instore VARCHAR(5),
	product_order SMALLINT,
	line_item_id INTEGER NOT NULL,
	product_id INTEGER NOT NULL,
	quantity SMALLINT,
	line_item_amount FLOAT,
	unit_price FLOAT,
	item_promotion VARCHAR(5),
	FOREIGN KEY (outlet_id) REFERENCES Outlets(outlet_id),
	FOREIGN KEY (staff_id) REFERENCES Staffs(staff_id),
	FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
	FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


COPY SalesReceipt (
	transaction_id,
	customer_transaction_id,
	transaction_date,
	transaction_time,
	outlet_id,
	staff_id,
	customer_id,
	product_instore,
	product_order,
	line_item_id,
	product_id,
	quantity,
	line_item_amount,
	unit_price,
	item_promotion
)
FROM 'C:\Temp\coffee-db\sales_receipts.csv'
DELIMITER ','
CSV HEADER;

-- PSQL shell ----------------
-- \COPY SalesReceipt FROM 'C:\Temp\coffee-db\sales_receipts.csv' WITH (FORMAT CSV, HEADER);

-- (Optional check)
SELECT * FROM SalesReceipt LIMIT 10;