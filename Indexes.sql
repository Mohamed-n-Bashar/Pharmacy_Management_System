CREATE INDEX idx_employees_branchs ON Employees(branch_id);

CREATE INDEX idx_products_sub_cat ON Products(sub_category_id);
CREATE INDEX idx_products_ings ON Product_Ingredients(ingredient_id, product_id);

CREATE INDEX idx_products_batchs_products ON Product_Batches(product_id);
CREATE INDEX idx_products_batchs_expiry_date ON Product_Batches(expiry_date);

CREATE INDEX idx_stock_availability_branch_batch ON Stock_Availability(branch_id, batch_id);

CREATE INDEX idx_invoices_branch_date ON Invoices(branch_id, create_at);
CREATE INDEX idx_sales_invoices_client ON SalesInvoices(client_id);

CREATE INDEX idx_invoice_items_main ON Invoices_Items(related_invoice_id, batch_id);
CREATE INDEX idx_invoice_items_batch ON Invoices_Items(batch_id);

CREATE INDEX idx_returns_items_parent ON Returns_Items(parent_item_id);

CREATE INDEX idx_trans_branch ON Transactions(branch_id);
CREATE INDEX idx_trans_invoice ON Transactions(related_invoice_id);
CREATE INDEX idx_trans_safe ON Transactions(safe_id);
CREATE INDEX idx_trans_date ON Transactions(created_at);