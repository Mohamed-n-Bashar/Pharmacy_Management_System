----------------------------------------------------------------------------------- Clients

CREATE PROCEDURE Add_Client(
	@c_Fname NVARCHAR(50),
	@c_Lname NVARCHAR(50),
	@c_phone VARCHAR(50),
	@c_balance DECIMAL(12, 2) = NULL,
	@c_new_id INT OUTPUT
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
				INSERT INTO Clients(Fname, Lname, phone, balance)
					VALUES(@c_Fname, @c_Lname, @c_phone, COALESCE(@c_balance, 0))

				SET @c_new_id = SCOPE_IDENTITY();
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


CREATE PROCEDURE Collect_Client_Due(
	@c_id INT,
	@branch_id INT,
	@related_invoice_id INT = NULL,
	@safe_id INT,
	@paid_amount DECIMAL(12, 2),
	@payment_method VARCHAR(10) = NULL,
	@employee_id INT
)
WITH ENCRYPTION
AS
	BEGIN 
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @note VARCHAR(100);
				DECLARE @due_amount DECIMAL(12, 2);
				SELECT @due_amount = balance FROM Clients WHERE id = @c_id

				IF (@paid_amount > @due_amount)
					BEGIN
						RAISERROR('Its more than the due amount', 16, 1);
						ROLLBACK TRANSACTION;
						RETURN;
					END

				UPDATE Clients
					SET balance -= @paid_amount
					WHERE id = @c_id

				EXEC Add_balance_to_Safe @Sid = @safe_id, @Sbalance = @paid_amount;

				SET @note = CONCAT('received collection from client with id: #', @c_id);
				EXEC Record_Transaction 'Collection', 
										@branch_id, 
										@related_invoice_id, 
										@safe_id, 
										@paid_amount, 
										@payment_method,
										@employee_id,
										@note;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


----------------------------------------------------------------------------------- Sale Invoices
-- Handled With UI
----------------------------------------------

CREATE PROCEDURE Add_Sale_Invoice_Items(
	@branch_id INT,
	@invoice_id INT,
	@employee_id INT,
	@i_items Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY

			INSERT INTO Invoices_Items (related_invoice_id, batch_id, quantity, unit_Price)
			SELECT @invoice_id,
				   S.batch_id,
				   T.quantity,
				   B.public_price
			FROM @i_items AS T
			INNER JOIN Stock_Availability AS S
				ON T.stock_id = S.id
			INNER JOIN Product_Batches AS B
				ON S.batch_id = B.id

			DECLARE @row_stock_id INT, @row_qty INT;

			DECLARE item_cursor CURSOR LOCAL FAST_FORWARD 
				FOR SELECT stock_id, quantity FROM @i_items
			OPEN item_cursor;
			FETCH NEXT FROM item_cursor INTO @row_stock_id, @row_qty;
			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				EXEC Deduct_From_stock @row_stock_id,
	 								   @row_qty,
									   @invoice_id,
									   NULL,
									   @employee_id;
				FETCH NEXT FROM item_cursor INTO @row_stock_id, @row_qty;
			END
			CLOSE item_cursor;
			DEALLOCATE item_cursor;

		END TRY
		BEGIN CATCH
			IF CURSOR_STATUS('local', 'item_cursor') >= 0
			BEGIN
				CLOSE item_cursor;
				DEALLOCATE item_cursor;
			END;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Add_Sale_Invoice(
	@i_branch_id INT,
	@i_safe_id INT,
	@i_employee_id INT,
	@i_discount_amount DECIMAL(12,2) = NULL,
	@i_paid_amount DECIMAL(12,2) = NULL,
	@i_payment_method VARCHAR(10) = NULL,

	@i_client_id INT = NULL,
	@i_Fname NVARCHAR(50) = NULL,
	@i_Lname NVARCHAR(50) = NULL,
	@i_phone VARCHAR(50) = NULL,

	@i_items Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @i_total_amount DECIMAL(12, 2);
				SELECT @i_total_amount = COALESCE(SUM(I.quantity * P.public_price), 0)
				FROM @i_items AS I
				INNER JOIN Stock_Availability AS S
					ON S.id = I.stock_id
				INNER JOIN Product_Batches AS P
					ON S.batch_id = P.id
				IF (@i_total_amount < @i_paid_amount)
					BEGIN
						RAISERROR('The Paid amount is greater than the invoice amount', 16, 1);
						ROLLBACK TRANSACTION;
						RETURN;
					END

				IF (@i_total_amount <= 0)
					BEGIN
						RAISERROR('Total invoice amount must be more than 0', 16, 1);
						ROLLBACK TRANSACTION;
						RETURN;
					END
				DECLARE @invoice_id INT;
				DECLARE @i_client_balance DECIMAL(12, 2) = (@i_total_amount - @i_discount_amount - @i_paid_amount);
				DECLARE @status VARCHAR(10) = 'Paid';
				DECLARE @note NVARCHAR(MAX) = ('Full payment sale Invoice');

	            IF (@i_paid_amount = 0) SET @status = 'Unpaid';
		        ELSE IF (@i_paid_amount < (@i_total_amount - @i_discount_amount))
					BEGIN 
						SET @status = 'Partial';
						SET @note = 'Partial payment sale Invoice';
					END

				IF (@i_client_id IS NULL)
					BEGIN
						EXEC Add_Client @i_Fname, @i_Lname, @i_phone, @i_client_balance, @c_new_id = @i_client_id OUTPUT;
					END
				ELSE
					BEGIN
						UPDATE Clients
							SET balance += @i_client_balance
							WHERE id = @i_client_id
					END

				INSERT INTO Invoices(invoice_type, branch_id, employee_id, total_amount, discount_amount, paid_amount, invoice_status)
					VALUES ('S',
							@i_branch_id,
							@i_employee_id,
							COALESCE(@i_total_amount, 0),
							COALESCE(@i_discount_amount, 0),
							@i_paid_amount,
							@status)

				SET @invoice_id = SCOPE_IDENTITY();
				INSERT INTO SalesInvoices(sales_id, client_id)
					VALUES (@invoice_id, @i_client_id)

				IF (@status <> 'Unpaid')
					BEGIN
						EXEC Record_Transaction 'Sale', 
												@i_branch_id, 
												@invoice_id, 
												@i_safe_id, 
												@i_paid_amount, 
												@i_payment_method,
												@i_employee_id,
												@note;

						IF (@i_payment_method = 'Cash')
							EXEC Add_balance_to_Safe @Sid = @i_safe_id, @Sbalance = @i_paid_amount;
					END
				
				EXEC Add_Sale_Invoice_Items @i_branch_id,
											@invoice_id,
											@i_employee_id,
											@i_items

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Add_Prescription(
	@P_invoice_id INT,
	@P_doctor_name NVARCHAR(100),
	@P_patient_name NVARCHAR(100),
	@P_note NVARCHAR(MAX)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Prescriptions(invoice_id, doctor_name, patient_name, note)
					VALUES(@P_invoice_id, @P_doctor_name, @P_patient_name, @P_note)
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Return


CREATE PROCEDURE Return_items(
	@branch_id INT,
	@employee_id INT,
	@client_id INT,
	@safe_id INT,
	@payment_method VARCHAR(10),

	@returned_items Returned_Items_Table READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF EXISTS (SELECT 1 
				   FROM @returned_items AS R 
				   JOIN Invoices_Items AS I 
					   ON R.original_item_id = I.id
	 		       WHERE R.quantity > I.quantity)
		BEGIN
			RAISERROR('Returned quantity cannot be more than sold quantity', 16, 1);
		    RETURN;
		END

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @row_item_id INT, @row_qty INT;
				DECLARE @batch_id INT, @original_unit_Price DECIMAL(12,2);
				DECLARE @total_returned_value DECIMAL(12,2) = 0;

				SELECT @total_returned_value = COALESCE(SUM(R.quantity * I.unit_Price), 0)
				FROM @returned_items AS R
				JOIN Invoices_Items AS I 
					ON R.original_item_id = I.id;
				
				----------
				DECLARE @client_balance DECIMAL(12,2);
				DECLARE @paid_amount DECIMAL(12,2);
				SELECT @client_balance = balance FROM Clients WHERE id = @client_id
				IF (@total_returned_value >= @client_balance)
					BEGIN
						UPDATE Clients
							SET balance = 0
							WHERE id = @client_id
						SET @paid_amount = (@total_returned_value - @client_balance);
					END
				ELSE
					BEGIN
						UPDATE Clients
							SET balance -= @total_returned_value
							WHERE id = @client_id
						SET @paid_amount = 0;
					END

				DECLARE @invoice_id INT;
				INSERT INTO Invoices(invoice_type, branch_id, employee_id, total_amount, discount_amount, paid_amount, invoice_status)
					VALUES ('R', @branch_id, @employee_id, @total_returned_value, 0, @paid_amount, 'Paid')
				SET @invoice_id = SCOPE_IDENTITY();

				----------
				DECLARE item_cursor CURSOR LOCAL FAST_FORWARD 
					FOR SELECT original_item_id, quantity FROM @returned_items
				OPEN item_cursor;
				FETCH NEXT FROM item_cursor INTO @row_item_id, @row_qty;
				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					SELECT @batch_id = NULL, @original_unit_Price = NULL;
					SELECT @batch_id = batch_id,
						   @original_unit_Price = unit_Price
					FROM Invoices_Items WHERE id = @row_item_id

					DECLARE @item_id INT;
					INSERT INTO Invoices_Items(related_invoice_id, batch_id, quantity, unit_Price)
						VALUES(@invoice_id, @batch_id, @row_qty, @original_unit_Price)
					SET @item_id = SCOPE_IDENTITY();

					INSERT INTO Returns_Items(item_id, parent_item_id)
						VALUES(@item_id, @row_item_id)

					EXEC Add_To_Stock @branch_id,
									  @batch_id,
									  @row_qty,
							     	  @invoice_id,
									  NULL,
									  @employee_id;
					FETCH NEXT FROM item_cursor INTO @row_item_id, @row_qty;
				END
				CLOSE item_cursor;
				DEALLOCATE item_cursor;

				----------
				EXEC Record_Transaction 'Return', 
										@branch_id, 
										@invoice_id, 
										@safe_id, 
										@paid_amount, 
										@payment_method,
										@employee_id,
										'record return transaction';

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
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END
