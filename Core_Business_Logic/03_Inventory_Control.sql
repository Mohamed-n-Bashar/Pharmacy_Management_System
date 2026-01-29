----------------------------------------------------------------------------------- Stock_Availability

CREATE PROCEDURE Record_stock_movement(
	@Rstock_id INT,
    @Rquantity_before INT,
    @Rquantity_after INT,
    @Rrelated_invoice_id INT = NULL,
	@Rinternal_trans_id INT = NULL,
    @Remployee_id INT,
	@Rnote VARCHAR(MAX)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT INTO Stock_Movements(stock_id, quantity_before, quantity_after, related_invoice_id, internal_trans_id, employee_id, note)
			VALUES(@Rstock_id, 
				   @Rquantity_before, 
          	       @Rquantity_after, 
	               @Rrelated_invoice_id, 
           		   @Rinternal_trans_id, 
		           @Remployee_id,
				   @Rnote);
	END


GO


CREATE PROCEDURE Add_To_Stock(		-- Add new or update exist value (Purchase_invoice - Return)
	@Sbranch_id INT = NULL,
	@Sbatch_id INT = NULL,
	@Squantity INT,
	@Rrelated_invoice_id INT = NULL,
	@Rinternal_trans_id INT = NULL,
    @Remployee_id INT
)
WITH ENCRYPTION
AS 
	BEGIN 
		SET NOCOUNT ON;
		DECLARE @Tran_Started BIT = 0;
		DECLARE @Sid INT;

		SELECT @Sid = id 
		FROM Stock_Availability
		WHERE branch_id = @Sbranch_id AND
			  batch_id = @Sbatch_id

		BEGIN TRY
			IF (@@TRANCOUNT = 0)
	        BEGIN
		        BEGIN TRANSACTION;
			    SET @Tran_Started = 1;
			END
				IF @Sid IS NULL
					BEGIN
						DECLARE @new_stock_id INT;
						INSERT INTO Stock_Availability(branch_id, batch_id, quantity)
							VALUES (@Sbranch_id, @Sbatch_id, @Squantity);
						SET @new_stock_id = SCOPE_IDENTITY();
						EXEC Record_stock_movement @new_stock_id, 
												   0, 
												   @Squantity, 
												   @Rrelated_invoice_id, 
												   @Rinternal_trans_id, 
												   @Remployee_id, 
												   'Created a new stock batch' ;
					END
				ELSE 
					BEGIN
						DECLARE @old_qty INT;
						DECLARE @new_qty INT;

						SELECT @old_qty = quantity FROM Stock_Availability WITH (UPDLOCK) WHERE id = @Sid;
						SET @new_qty = @old_qty + COALESCE(@Squantity, 0);

						UPDATE Stock_Availability
							SET	quantity += COALESCE(@Squantity, 0)
							WHERE id = @Sid
						EXEC Record_stock_movement @Sid, 
												   @old_qty, 
												   @new_qty, 
												   @Rrelated_invoice_id, 
												   @Rinternal_trans_id, 
												   @Remployee_id, 
												   'Added quantity to an existing stock batch';
				END
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


CREATE PROCEDURE Deduct_From_stock(			-- (Sale_invoice - Internal_Trans)
	@Sid INT,
	@quantity INT,
	@Rrelated_invoice_id INT = NULL,
	@Rinternal_trans_id INT = NULL,
    @Remployee_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			DECLARE @old_qty INT;
			DECLARE @new_qty INT;
			SELECT @old_qty = quantity FROM Stock_Availability WITH (UPDLOCK) WHERE id = @Sid;
			SET @new_qty = (@old_qty - COALESCE(@quantity, 0))
			IF (@old_qty < COALESCE(@quantity, 0))
				BEGIN
					RAISERROR('Requested quantity is more than available stock', 16, 1);
					RETURN;
				END
			ELSE
				BEGIN
					UPDATE Stock_Availability
						SET	quantity -= COALESCE(@quantity, 0)
						WHERE id = @Sid
					EXEC Record_stock_movement @Sid, 
											   @old_qty, 
											   @new_qty, 
											   @Rrelated_invoice_id, 
											   @Rinternal_trans_id, 
											   @Remployee_id, 
											   'Deducted quantity from a stock items';
				END
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END


GO


----------------------------------------------------------------------------------- Internal_Transfers


CREATE PROCEDURE Add_Internal_Transfer(
	@ITfrom_branch_id INT,
	@ITto_branch_id INT,
	@ITbatch_id INT,
	@ITquantity INT,
	@ITtransfer_date DATETIME = NULL,
	@ITemployee_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @note VARCHAR(100);
				DECLARE @current_qty INT;
				DECLARE @new_qty INT;
				DECLARE @stock_id INT;
				DECLARE @internal_trans_id INT;

				SELECT @current_qty = quantity, @stock_id = id FROM Stock_Availability WITH (UPDLOCK) 
					WHERE batch_id = @ITbatch_id AND branch_id = @ITfrom_branch_id
				SET @new_qty = (@current_qty - COALESCE(@ITquantity, 0));

				IF (@current_qty < COALESCE(@ITquantity, 0))
					BEGIN
						RAISERROR('Requested quantity is more than available stock', 16, 1);
						IF @@TRANCOUNT > 0
							ROLLBACK TRANSACTION;
						RETURN;
					END
				ELSE
					BEGIN
						INSERT INTO Internal_Transfers(from_branch_id, to_branch_id, batch_id, quantity, transfer_date, status)
							VALUES (@ITfrom_branch_id, @ITto_branch_id, @ITbatch_id, COALESCE(@ITquantity, 0), @ITtransfer_date, 'Dispatched');
						SET @internal_trans_id = SCOPE_IDENTITY();
						UPDATE Stock_Availability
							SET	quantity -= COALESCE(@ITquantity, 0)
							WHERE id = @stock_id
						SET @note = CONCAT('Internal transfer: Deducted stock from Branch: #', @ITfrom_branch_id , ' to Branch: ', @ITto_branch_id);
						EXEC Record_stock_movement @stock_id, 
												   @current_qty, 
												   @new_qty, 
												   NULL, 
												   @internal_trans_id, 
												   @ITemployee_id, 
												   @note;
					END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Cancel_Internal_Transfer(
	@IT_id INT,
	@ITemployee_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY 
			BEGIN TRANSACTION;
				DECLARE @note VARCHAR(100);
				DECLARE @IT_status VARCHAR(20);
				DECLARE @stock_id INT;
				DECLARE @stock_qty INT;
				DECLARE @new_qty INT;
				DECLARE @IT_qty INT;
				DECLARE @IT_batch INT;
				DECLARE @IT_branch INT;
				
				SELECT @IT_qty = quantity,
					   @IT_batch = batch_id,
					   @IT_branch = from_branch_id,
					   @IT_status = status
					   FROM Internal_Transfers WITH(UPDLOCK) WHERE id = @IT_id

				IF @IT_status <> 'Dispatched'
					BEGIN
						RAISERROR('Only dispatched transfers can be canceled', 16, 1);
						ROLLBACK TRANSACTION;
						RETURN;
					END

				SELECT @stock_id = id,
					   @stock_qty = quantity
					   FROM Stock_Availability WITH(UPDLOCK) WHERE batch_id = @IT_batch AND branch_id = @IT_branch
				
				UPDATE Stock_Availability
					SET quantity += @IT_qty
					WHERE batch_id = @IT_batch AND branch_id = @IT_branch

				UPDATE Internal_Transfers
					SET status = 'Canceled'
					WHERE id = @IT_id

				SET @new_qty = (@stock_qty + COALESCE(@IT_qty, 0));
				SET @note = CONCAT('Cancel Internal transfer with id: #', @IT_id);
				EXEC Record_stock_movement @stock_id, 
										   @stock_qty, 
										   @new_qty, 
										   NULL, 
										   @IT_id, 
										   @ITemployee_id, 
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


CREATE PROCEDURE Receive_Internal_Transfer(
	@IT_id INT,
	@ITemployee_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY 
			BEGIN TRANSACTION;
				DECLARE @note VARCHAR(100);
				DECLARE @old_qty INT;
				DECLARE @new_qty INT;
				DECLARE @stock_id INT;
				DECLARE @IT_status VARCHAR(20);
				DECLARE @destination_branch INT;
				DECLARE @transferred_batch_id INT;
				DECLARE @transferred_qty INT;
				DECLARE @stock_qty INT;
				
				SELECT @IT_status = status,
					   @destination_branch = to_branch_id,
					   @transferred_batch_id = batch_id,
					   @transferred_qty = quantity
					   FROM Internal_Transfers WITH(UPDLOCK) WHERE id = @IT_id

				SELECT @stock_id = id,
					   @stock_qty = quantity
				FROM Stock_Availability WITH(UPDLOCK)
				WHERE branch_id = @destination_branch AND batch_id = @transferred_batch_id

				IF @IT_status <> 'Dispatched'
					BEGIN
						RAISERROR('Only dispatched transfers can be received', 16, 1);
						ROLLBACK TRANSACTION;
						RETURN;
					END

				UPDATE Internal_Transfers
					SET status = 'Received'
					WHERE id = @IT_id
				
				IF (@stock_id IS NULL)
					BEGIN
						INSERT INTO Stock_Availability(branch_id, batch_id, quantity)
							VALUES (@destination_branch, @transferred_batch_id, @transferred_qty)
						SET @stock_id = SCOPE_IDENTITY();
						SET @stock_qty = 0;
					END
				ELSE
					BEGIN
						UPDATE Stock_Availability
							SET quantity += @transferred_qty
							WHERE id = @stock_id
					END

				SET @old_qty = COALESCE(@stock_qty, 0);
				SET @new_qty = (COALESCE(@stock_qty, 0) + @transferred_qty);
				SET @note = CONCAT('Received Internal transfer with id: #', @IT_id);
				EXEC Record_stock_movement @stock_id, 
										   @old_qty, 
										   @new_qty, 
										   NULL, 
										   @IT_id, 
										   @ITemployee_id, 
										   @note;

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END

