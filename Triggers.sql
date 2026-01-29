CREATE TRIGGER BranchesTrigger 
ON Branches
INSTEAD OF DELETE
AS 
	BEGIN
		SET NOCOUNT ON;
		RAISERROR('Not allowed to delete branches', 16, 1);
		RETURN;
	END


GO

CREATE TRIGGER InvoicesTrigger
ON Invoices
INSTEAD OF DELETE, UPDATE
AS
	BEGIN
		SET NOCOUNT ON;
		RAISERROR('Not allowed to delete or update Invoices', 16, 1);
		RETURN;
	END


GO


CREATE TRIGGER TransactionTrigger
ON Transactions
INSTEAD OF DELETE, UPDATE
AS
	BEGIN
		SET NOCOUNT ON;
		RAISERROR('Not allowed to delete or update Transactions', 16, 1);
		RETURN;
	END


GO


CREATE TRIGGER SafeTrigger
ON Safes
AFTER DELETE
AS
	BEGIN
		SET NOCOUNT ON;
		IF EXISTS (SELECT 1 FROM DELETED WHERE balance <> 0)
		BEGIN
			RAISERROR('Not allowed to delete a safe that has a balance', 16, 1);
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			RETURN;
		END
	END


GO



CREATE TRIGGER StockTrigger
ON Stock_Availability
INSTEAD OF DELETE
AS
	BEGIN
		SET NOCOUNT ON;
		RAISERROR('Not allowed to delete from stock', 16, 1);
		RETURN;
	END


GO



