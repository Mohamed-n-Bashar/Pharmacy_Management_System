----------------------------------------------------------------------------------- Branches
CREATE PROCEDURE Add_Branch (@tax_num VARCHAR(255), @address VARCHAR(255))
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Branches(tax_num, address) VALUES (@tax_num, @address);
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO



CREATE PROCEDURE Update_Branch (
	@Bid INT,
	@Btax_num NVARCHAR(255) = NULL,
	@Baddress NVARCHAR(255) = NULL)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Branches
					SET 
						tax_num = COALESCE(@Btax_num, tax_num),
						address = COALESCE(@Baddress, address)
					WHERE id = @Bid;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Employees


CREATE PROCEDURE Add_Employee (
	@Ename NVARCHAR(100), 
	@Erole NVARCHAR(20), 
	@Ephone NVARCHAR(50), 
	@Ebranch_id INT,
	@Ework_shift VARCHAR(10))
WITH ENCRYPTION
AS 
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Employees(name ,role ,phone ,branch_id ,work_shift)
					VALUES (@Ename ,@Erole ,@Ephone ,@Ebranch_id ,@Ework_shift);
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Employee (
	@Eid INT,
	@Ename NVARCHAR(100) = NULL,
	@Erole NVARCHAR(20) = NULL,
	@Ephone NVARCHAR(50) = NULL,
	@Ebranch_id INT = NULL,
	@Ework_shift VARCHAR(10) = NULL)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Employees
					SET 
						name = COALESCE(@Ename, name),
						role = COALESCE(@Erole, role),
						phone = COALESCE(@Ephone, phone),
						branch_id = COALESCE(@Ebranch_id, branch_id),
						work_shift = COALESCE(@Ework_shift, work_shift)
					WHERE id = @Eid;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Employee (@Eid INT)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Employees WHERE id = @Eid)
			BEGIN
				RAISERROR('There is no employee with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Employees
					WHERE id = @Eid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Safes


CREATE PROCEDURE Add_Safe (
	@Sbranch_id INT,
	@Stype VARCHAR(10),
	@Sbalance DECIMAL(12,2) = 0
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Safes(branch_id, type, balance) 
					VALUES(@Sbranch_id, @Stype, @Sbalance);
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Safe (
	@Sid INT,
	@Sbranch_id INT = NULL,
	@Stype VARCHAR(10) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Safes
					SET branch_id = COALESCE(@Sbranch_id ,branch_id),
						type = COALESCE(@Stype ,type)
					WHERE id = @Sid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
			
		END CATCH
	END


GO


CREATE PROCEDURE Add_balance_to_Safe (
	@Sid INT,
	@Sbalance DECIMAL(12,2) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			UPDATE Safes
				SET balance += COALESCE(@Sbalance ,0)
				WHERE id = @Sid
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Withdraw_balance_from_Safe (
	@Sid INT,
	@Sbalance DECIMAL(12,2) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			IF EXISTS (SELECT 1 FROM Safes WHERE id = @Sid AND balance < @Sbalance)
				BEGIN
					RAISERROR('there are not enough balance to withdraw', 16, 1);
					RETURN;
				END
			UPDATE Safes
				SET balance -= COALESCE(@Sbalance ,0)
				WHERE id = @Sid
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Safe (
	@Sid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Safes WHERE id = @Sid)
			BEGIN
				RAISERROR('There is no safe with this id', 16, 1);
				RETURN;
			END

		IF EXISTS (SELECT 1 FROM Safes WHERE id = @Sid AND balance > 0)
			BEGIN
				RAISERROR('Cannot delete safe with balance', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Safes
					WHERE id = @Sid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END