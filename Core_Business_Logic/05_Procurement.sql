----------------------------------------------------------------------------------- Suppliers

CREATE PROCEDURE Add_supplier(
	@S_name NVARCHAR(100),
	@S_contact_info NVARCHAR(100),
	@S_tax_number VARCHAR(255)
)
WITH ENCRYPTION
AS
	BEGIN 
		SET NOCOUNT ON;
		DECLARE @Tran_Started BIT = 0;

		BEGIN TRY
			
			IF (@@TRANCOUNT = 0)
			BEGIN
		        BEGIN TRANSACTION;
	            SET @Tran_Started = 1;
			END
				INSERT INTO Suppliers(supplier_name, contact_info, tax_number)
					VALUES(@S_name, @S_contact_info, @S_tax_number)

			IF (@Tran_Started = 1)
				COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF (@Tran_Started = 1 AND @@TRANCOUNT > 0)
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Orders & Purchases


CREATE PROCEDURE Add_Order_Items(
	@order_id INT,
    @o_items Order_Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		BEGIN TRY
			INSERT INTO Purchase_Order_Items(order_id, product_id, quantity)
			SELECT @order_id, product_id, quantity FROM @o_items
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Add_Order(
	@supplier_id INT,
	@branch_id INT,
	@expected_delivery_date DATETIME,

	@o_items Order_Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN 
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @order_id INT;
				INSERT INTO Purchase_Orders(supplier_id, branch_id, expected_delivery_date, status)
					VALUES(@supplier_id, @branch_id, @expected_delivery_date, 'Ordered')
				SET @order_id = SCOPE_IDENTITY();
				EXEC Add_Order_Items @order_id ,@o_items;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Cancel_Order(
	@order_id INT
)
WITH ENCRYPTION
AS
	BEGIN 
		SET NOCOUNT ON;

	    BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Purchase_Orders
					SET status = 'Canceled'
					WHERE id = @order_id
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRANSACTION;
		    THROW;
		END CATCH
	END


GO 


CREATE PROCEDURE Receive_Order(
	@order_id INT,
	@branch_id INT,
	@employee_id INT,
	@safe_id INT,
	@total_amount DECIMAL(12, 2),
	@discount_amount DECIMAL(12, 2),
	@paid_amount DECIMAL(12, 2),
	@payment_method VARCHAR(10),
	@supplier_id INT,

	@registered_items_data Received_Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @invoice_id INT;
				DECLARE @row_product_id INT, 
						@row_qty INT,
						@row_batch_number VARCHAR(255),
						@row_manufacture_date DATETIME,
						@row_expiry_date DATETIME,
						@row_cost_price DECIMAL(12,2),
						@row_public_price DECIMAL(12,2);
				
				-- Add received order to Invoices Table
				INSERT INTO Invoices(invoice_type, branch_id, employee_id, total_amount, discount_amount, paid_amount)
					VALUES ('P',
							@branch_id,
							@employee_id,
							@total_amount,
							@discount_amount,
							@paid_amount)
				SET @invoice_id = SCOPE_IDENTITY();
				
				INSERT INTO Purchase_Invoices(purchase_id, order_id, supplier_id)
					VALUES (@invoice_id, @order_id, @supplier_id)

				-- Add items to Invoices Items Table & Add items to them Batches Table
				DECLARE item_cursor CURSOR LOCAL FAST_FORWARD 
					FOR SELECT product_id, quantity, batch_number, manufacture_date, expiry_date, cost_price, public_price
						FROM @registered_items_data
				OPEN item_cursor;
				FETCH NEXT FROM item_cursor INTO @row_product_id, 
												 @row_qty,
												 @row_batch_number,
												 @row_manufacture_date,
												 @row_expiry_date,
 												 @row_cost_price,
						 						 @row_public_price;
				DECLARE @batch_id INT;
				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					SET @batch_id = NULL
					SELECT TOP(1) @batch_id = id FROM Product_Batches WHERE product_id = @row_product_id 
																			AND batch_number = @row_batch_number 
		   							    								    AND cost_price = @row_cost_price
					IF (@batch_id IS NULL)
						BEGIN
							EXEC Add_Product_Batch @row_product_id, @row_batch_number, 
												   @row_manufacture_date, @row_expiry_date, 
												   @row_cost_price, @row_public_price,
												   @B_new_id = @batch_id OUTPUT;
						END
					
					INSERT INTO Invoices_Items (related_invoice_id, batch_id, quantity, unit_Price)
						VALUES(@invoice_id, @batch_id, @row_qty, @row_cost_price)

					EXEC Add_To_Stock @branch_id, @batch_id, @row_qty, @invoice_id, NULL, @employee_id;

					FETCH NEXT FROM item_cursor INTO @row_product_id, 
													 @row_qty,
													 @row_batch_number,
													 @row_manufacture_date,
													 @row_expiry_date,
 													 @row_cost_price,
							 						 @row_public_price;
				END
				CLOSE item_cursor;
				DEALLOCATE item_cursor;

				-- Update order status
				UPDATE Purchase_Orders
					SET status = 'Received'
					WHERE id = @order_id

				EXEC Record_Transaction 'Purchase', 
										@branch_id, 
										@invoice_id, 
										@safe_id, 
										@paid_amount, 
										@payment_method,
										@employee_id,
										'record Purchase transaction';

				IF (@payment_method = 'Cash')
					EXEC Withdraw_balance_from_Safe @Sid = @safe_id, @Sbalance = @paid_amount;

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF CURSOR_STATUS('local', 'item_cursor') >= 0
			BEGIN
				CLOSE item_cursor;
				DEALLOCATE item_cursor;
			END
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRANSACTION;
		    THROW;
		END CATCH
	END

