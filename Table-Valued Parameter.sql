---------------------------------------------- Add Ingredients To Products
CREATE TYPE Ingredients_List AS TABLE(
	i INT
);


---------------------------------------------- Sale Items
CREATE TYPE Items_Table AS TABLE(
	stock_id INT NOT NULL,
	quantity INT NOT NULL CHECK(quantity > 0)
);


---------------------------------------------- Return Items
CREATE TYPE Returned_Items_Table AS TABLE(
	original_item_id INT NOT NULL,					-- sale invoice item id
	quantity INT NOT NULL CHECK(quantity > 0)		-- returned quantity
);


---------------------------------------------- Order Items (Create order)
CREATE TYPE Order_Items_Table AS TABLE(
	product_id INT NOT NULL,
	quantity INT NOT NULL CHECK(quantity > 0)
);


---------------------------------------------- Register Items (Receive order)
CREATE TYPE Received_Items_Table AS TABLE(
	product_id INT NOT NULL,
	quantity INT NOT NULL CHECK(quantity > 0),
	batch_number VARCHAR(255) NOT NULL,
	manufacture_date DATETIME DEFAULT GETDATE(),
	expiry_date DATETIME NOT NULL,
	cost_price DECIMAL(12,2) DEFAULT 0,
	public_price DECIMAL(12,2) DEFAULT 0
);