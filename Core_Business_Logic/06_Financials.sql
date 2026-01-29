----------------------------------------------------------------------------------- Transactions


CREATE PROCEDURE Record_Transaction(
	@T_trans_type VARCHAR(20),
	@T_branch_id INT,
	@T_invoice_id INT = NULL,
	@T_safe_id INT,
	@T_paid_amount DECIMAL(12,2) = NULL,
	@T_payment_method VARCHAR(10) = NULL,
	@T_employee_id INT,
	@T_note NVARCHAR(MAX)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;
		
		IF (@T_paid_amount < 0)
		BEGIN
			RAISERROR('Cannot make transaction with negative amount', 16, 1);
			RETURN;
		END
		
		IF (@T_paid_amount = 0)
			RETURN;

		BEGIN TRY
			INSERT INTO Transactions(trans_type, branch_id, related_invoice_id, safe_id, amount, payment_method, employee_id, note)
				VALUES (@T_trans_type, @T_branch_id, @T_invoice_id, @T_safe_id, @T_paid_amount, @T_payment_method, @T_employee_id, @T_note)
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END