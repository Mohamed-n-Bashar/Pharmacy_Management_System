CREATE DATABASE PharmaDB
GO


USE PharmaDB
GO



----------------------------------------------------------------------------------- Organization Module

CREATE TABLE Branches(
	id INT IDENTITY(1,1) PRIMARY KEY,
	tax_num VARCHAR(255) NOT NULL UNIQUE,
	address NVARCHAR(255)
);


CREATE TABLE Employees(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(100) NOT NULL,
	role VARCHAR(20) NOT NULL,
	phone VARCHAR(50) NOT NULL UNIQUE,
	branch_id INT NULL,
	work_shift VARCHAR(10) NOT NULL,

	CONSTRAINT FK_employee_branch FOREIGN KEY (branch_id) REFERENCES Branches(id) ON DELETE SET NULL,
	CONSTRAINT check_emp_type CHECK (work_shift IN ('Morning','Evening','Night')),
	CONSTRAINT check_role CHECK (role IN ('Pharmacist','Cashier','Manager','Delivery'))
);


CREATE TABLE Safes(
	id INT IDENTITY(1,1) PRIMARY KEY,
	branch_id INT,
	type VARCHAR(10),
	balance DECIMAL(12,2) DEFAULT 0,

	CONSTRAINT FK_safe_branch FOREIGN KEY (branch_id) REFERENCES Branches(id) ON DELETE NO ACTION,
	CONSTRAINT check_safe_type CHECK (type IN ('Main','Till'))
);



----------------------------------------------------------------------------------- Advanced Product Module

CREATE TABLE Manufacturers(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255) NOT NULL, 
	address NVARCHAR(255),
	contact_info VARCHAR(255) NOT NULL
);


CREATE TABLE Categories(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255) NOT NULL UNIQUE
);


CREATE TABLE Sub_Categories(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255) NOT NULL,
	category_id INT NOT NULL,

	CONSTRAINT FK_category FOREIGN KEY (category_id) REFERENCES Categories(id) ON DELETE CASCADE,
	CONSTRAINT UQ_cat_name UNIQUE (name, category_id)
);


CREATE TABLE Active_Ingredients(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255) NOT NULL UNIQUE
);


CREATE TABLE Dosage_Forms(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255) NOT NULL UNIQUE
);


CREATE TABLE Products(
	id INT IDENTITY(1,1) PRIMARY KEY,
	name NVARCHAR(255),
	barcode VARCHAR(255) UNIQUE,
	manufacturer_id INT,
	sub_category_id INT,
	dosage_form_id INT,

	CONSTRAINT FK_product_manufact FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(id) ON DELETE NO ACTION,
	CONSTRAINT FK_product_sub_cat FOREIGN KEY (sub_category_id) REFERENCES Sub_Categories(id) ON DELETE NO ACTION,
	CONSTRAINT FK_product_dosage_form FOREIGN KEY (dosage_form_id) REFERENCES Dosage_Forms(id) ON DELETE NO ACTION
);


CREATE TABLE Product_Ingredients(
	product_id INT NOT NULL,
	ingredient_id INT NOT NULL,

	CONSTRAINT PK_Product_Ingredients PRIMARY KEY (product_id, ingredient_id),
	CONSTRAINT FK_product FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
	CONSTRAINT FK_ingredient FOREIGN KEY (ingredient_id) REFERENCES Active_Ingredients(id) ON DELETE NO ACTION
);



----------------------------------------------------------------------------------- Inventory & Batches

CREATE TABLE Product_Batches(
	id INT IDENTITY(1,1) PRIMARY KEY,
	product_id INT NOT NULL,
	batch_number VARCHAR(255) NOT NULL,
	manufacture_date DATETIME DEFAULT GETDATE(),
	expiry_date DATETIME NOT NULL,
	cost_price DECIMAL(12,2) DEFAULT 0,				-- purchase price
	public_price DECIMAL(12,2) DEFAULT 0,			-- sale price

	CONSTRAINT FK_batch_product FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE NO ACTION,
);


CREATE TABLE Stock_Availability(
	id INT IDENTITY(1,1) PRIMARY KEY,
	branch_id INT NOT NULL,
	batch_id INT NOT NULL,
	quantity INT DEFAULT 0 CHECK (quantity >= 0),

	CONSTRAINT FK_stock_branch FOREIGN KEY (branch_id) REFERENCES Branches(id),
	CONSTRAINT FK_stock_batch FOREIGN KEY (batch_id) REFERENCES Product_Batches(id),
	CONSTRAINT UQ_stock_uniqueness UNIQUE (branch_id, batch_id)
);


CREATE TABLE Internal_Transfers(
	id INT IDENTITY(1,1) PRIMARY KEY,
	from_branch_id INT NOT NULL,
	to_branch_id INT NOT NULL,
	batch_id INT NOT NULL,
	quantity INT NOT NULL,
	transfer_date DATETIME DEFAULT GETDATE(),
	status VARCHAR(20),

	CONSTRAINT FK_int_trans_from_branch_id FOREIGN KEY (from_branch_id) REFERENCES Branches(id) ON DELETE NO ACTION,
	CONSTRAINT FK_int_trans_to_branch_id FOREIGN KEY (to_branch_id) REFERENCES Branches(id) ON DELETE NO ACTION,
	CONSTRAINT FK_int_trans_batch_id FOREIGN KEY (batch_id) REFERENCES Product_Batches(id) ON DELETE NO ACTION,
	CONSTRAINT check_trans_status CHECK (status IN ('Dispatched','Received', 'Canceled'))
);



----------------------------------------------------------------------------------- Parents for EERD

CREATE TABLE Invoices(
	id INT IDENTITY(1,1) PRIMARY KEY,
	invoice_type VARCHAR(1) NOT NULL,			-- Discriminator (sale, purchase, return)
	branch_id INT NOT NULL,
	employee_id INT NOT NULL,
	total_amount DECIMAL(12,2) DEFAULT 0,
	discount_amount DECIMAL(12,2) DEFAULT 0,
	net_amount AS CAST((total_Amount - discount_Amount) AS DECIMAL(12,2)) PERSISTED,
	paid_amount DECIMAL(12,2) DEFAULT 0,
	remaining_amount AS (CAST((total_amount - discount_amount - paid_amount) AS DECIMAL(12,2))),
	create_at DATETIME DEFAULT GETDATE(),
	invoice_status VARCHAR(10) DEFAULT 'Paid',

	CONSTRAINT FK_invoice_branch FOREIGN KEY (branch_id) REFERENCES Branches(id) ON DELETE NO ACTION,
	CONSTRAINT FK_invoice_emp FOREIGN KEY (employee_id) REFERENCES Employees(id) ON DELETE NO ACTION,
	CONSTRAINT check_invoice_type CHECK (invoice_type IN ('S','P','R')),
	CONSTRAINT check_invoice_status CHECK (invoice_status IN ('Paid','Partial','Unpaid'))
);


CREATE TABLE Invoices_Items(
	id INT IDENTITY(1,1) PRIMARY KEY,
	related_invoice_id INT NOT NULL,
	batch_id INT NOT NULL,
	quantity INT NOT NULL CHECK(quantity > 0),
	unit_Price DECIMAL(12,2) DEFAULT 0,

	CONSTRAINT FK_item_invoice FOREIGN KEY (related_invoice_id) REFERENCES Invoices(id) ON DELETE CASCADE,
	CONSTRAINT FK_item_batch FOREIGN KEY (batch_id) REFERENCES Product_Batches(id) ON DELETE NO ACTION,
	CONSTRAINT UQ_invoice_batch UNIQUE (related_invoice_id, batch_id)
);


CREATE TABLE Stock_Movements (
    id INT IDENTITY(1,1) PRIMARY KEY,
    stock_id INT NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    related_invoice_id INT,
	internal_trans_id INT SPARSE NULL,
    employee_id INT,
    created_at DATETIME DEFAULT GETDATE(),
	note VARCHAR(MAX),

    CONSTRAINT FK_movement_stock FOREIGN KEY (stock_id) REFERENCES Stock_Availability(id),
	CONSTRAINT FK_stock_movement_related_internal_trans FOREIGN KEY (internal_trans_id) REFERENCES Internal_Transfers(id) ON DELETE NO ACTION,
	CONSTRAINT FK_stock_movement_related_invoice FOREIGN KEY (related_invoice_id) REFERENCES Invoices(id) ON DELETE NO ACTION,
	CONSTRAINT FK_stock_movement_related_employee FOREIGN KEY (employee_id) REFERENCES Employees(id) ON DELETE NO ACTION
);

----------------------------------------------------------------------------------- Sales & Insurance

CREATE TABLE Clients(
	id INT IDENTITY(1,1) PRIMARY KEY,
	Fname NVARCHAR(50),
	Lname NVARCHAR(50),
	phone VARCHAR(50),
	balance DECIMAL(12, 2) DEFAULT 0
);


CREATE TABLE SalesInvoices(
	sales_id INT PRIMARY KEY,
	client_id INT,

	CONSTRAINT FK_sales_invoice FOREIGN KEY (sales_id) REFERENCES Invoices(id) ON DELETE CASCADE,
	CONSTRAINT FK_invoice_client FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE,
);



CREATE TABLE Prescriptions(
	id INT IDENTITY(1,1) PRIMARY KEY,
	invoice_id INT NOT NULL,
	doctor_name NVARCHAR(100) NOT NULL,
	patient_name NVARCHAR(100) NOT NULL,
	note NVARCHAR(MAX),

	CONSTRAINT FK_prescription_invoice FOREIGN KEY (invoice_id) REFERENCES SalesInvoices(sales_id) ON DELETE CASCADE
);



CREATE TABLE Returns_Items(
	item_id INT PRIMARY KEY,		-- returned item id
	parent_item_id INT NOT NULL,	-- Oreginal sold item id before return

	CONSTRAINT FK_return_item_base FOREIGN KEY (item_id) REFERENCES Invoices_Items(id) ON DELETE CASCADE,
	CONSTRAINT FK_return_parent_item FOREIGN KEY (parent_item_id) REFERENCES Invoices_Items(id)
);



----------------------------------------------------------------------------------- Procurement (Purchase)

CREATE TABLE Suppliers(
	id INT IDENTITY(1,1) PRIMARY KEY,
	supplier_name NVARCHAR(100) NOT NULL,
	contact_info NVARCHAR(100) NOT NULL,
	tax_number VARCHAR(255) NOT NULL UNIQUE
);


CREATE TABLE Purchase_Orders(
	id INT IDENTITY(1,1) PRIMARY KEY,
	supplier_id INT NOT NULL,
	branch_id INT NOT NULL,
	order_date DATETIME DEFAULT GETDATE(),
	expected_delivery_date DATETIME,
	status VARCHAR(20) NOT NULL DEFAULT 'Ordered',

	CONSTRAINT FK_purchase_order_supplier FOREIGN KEY (supplier_id) REFERENCES Suppliers(id) ON DELETE NO ACTION,
	CONSTRAINT FK_purchase_order_branch FOREIGN KEY (branch_id) REFERENCES Branches(id) ON DELETE CASCADE,
	CONSTRAINT check_purchase_order_status CHECK(status IN ('Ordered','Received','Canceled'))
);


CREATE TABLE Purchase_Order_Items(
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),

    CONSTRAINT FK_PO_item_order FOREIGN KEY (order_id) REFERENCES Purchase_Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_PO_item_product FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE NO ACTION,
    CONSTRAINT UQ_PO_item_unique UNIQUE (order_id, product_id)
);


CREATE TABLE Purchase_Invoices(
	purchase_id INT PRIMARY KEY,
	order_id INT NOT NULL,
	supplier_id INT NOT NULL,

	CONSTRAINT FK_purchase_invoice FOREIGN KEY (purchase_id) REFERENCES Invoices(id) ON DELETE CASCADE,
	CONSTRAINT FK_purchase_invoice_order FOREIGN KEY (order_id) REFERENCES Purchase_Orders(id) ON DELETE NO ACTION,
	CONSTRAINT FK_purchase_invoice_supplier FOREIGN KEY (supplier_id) REFERENCES Suppliers(id) ON DELETE NO ACTION
);



----------------------------------------------------------------------------------- Finance

CREATE TABLE Transactions(
	id INT IDENTITY(1,1) PRIMARY KEY,
	trans_type VARCHAR(20),
	branch_id INT,
	related_invoice_id INT NULL,
	employee_id INT NOT NULL,
	safe_id INT NOT NULL,
	amount DECIMAL(12,2),
	payment_method VARCHAR(10) DEFAULT 'Cash',
	created_at DATETIME DEFAULT GETDATE(),
	note NVARCHAR(MAX),

	CONSTRAINT FK_trans_branch FOREIGN KEY (branch_id) REFERENCES Branches(id) ON DELETE NO ACTION,
	CONSTRAINT FK_trans_related_invoice FOREIGN KEY (related_invoice_id) REFERENCES Invoices(id) ON DELETE NO ACTION,
	CONSTRAINT FK_trans_related_safe FOREIGN KEY (safe_id) REFERENCES Safes(id) ON DELETE NO ACTION,
	CONSTRAINT FK_trans_related_emp FOREIGN KEY (employee_id) REFERENCES Employees(id) ON DELETE NO ACTION,
	CONSTRAINT check_trans_type CHECK (trans_type IN ('Sale', 'Purchase', 'Expense', 'Return', 'Collection')),
	CONSTRAINT check_trans_payment_method CHECK (payment_method IN ('Cash','Card','Wallet'))
);
