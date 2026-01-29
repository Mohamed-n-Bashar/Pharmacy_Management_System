----------------------------------------------------------------------------------- Manufacturers

CREATE PROCEDURE Add_Manufacturer(
	@Mname NVARCHAR(255),
	@Maddress NVARCHAR(255),
	@Mcontact_info VARCHAR(255)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Manufacturers(name, address, contact_info)
					VALUES (@Mname, @Maddress, @Mcontact_info);
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Manufacturer(
	@Mid INT,
	@Mname NVARCHAR(255) = NULL,
	@Maddress NVARCHAR(255) = NULL,
	@Mcontact_info VARCHAR(255) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Manufacturers
					SET name = COALESCE(@Mname, name),
						address = COALESCE(@Maddress, address),
						contact_info = COALESCE(@Mcontact_info, contact_info)
					WHERE id = @Mid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Manufacturer(
	@Mid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Manufacturers WHERE id = @Mid)
			BEGIN
				RAISERROR('There is no Manufacturer with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Manufacturers
					WHERE id = @Mid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Categories


CREATE PROCEDURE Add_Category(
	@Mname NVARCHAR(255)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Categories(name)
					VALUES (@Mname);
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Category(
	@Cid INT,
	@Cname NVARCHAR(255) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Categories
					SET name = COALESCE(@Cname, name)
					WHERE id = @Cid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Category(
	@Cid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Categories WHERE id = @Cid)
			BEGIN
				RAISERROR('There is no Category with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Categories
					WHERE id = @Cid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Sub_Categories


CREATE PROCEDURE Add_Sub_Category(
	@SCname NVARCHAR(255),
	@category_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Sub_Categories(name, category_id)
					VALUES (@SCname, @category_id);
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Sub_Category(
	@SCid INT,
	@SCname NVARCHAR(255) = NULL,
	@category_id INT = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Sub_Categories
					SET name = COALESCE(@SCname, name),
						category_id = COALESCE(@category_id, category_id)
					WHERE id = @SCid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Sub_Category(
	@SCid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Sub_Categories WHERE id = @SCid)
			BEGIN
				RAISERROR('There is no Sub-Category with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Sub_Categories
					WHERE id = @SCid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Active_Ingredients


CREATE PROCEDURE Add_Active_Ing(
	@AIname NVARCHAR(255)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Active_Ingredients(name)
					VALUES (@AIname);
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Active_Ing(
	@AIid INT,
	@AIname NVARCHAR(255) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Active_Ingredients
					SET name = COALESCE(@AIname, name)
					WHERE id = @AIid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Active_Ing(
	@AIid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Active_Ingredients WHERE id = @AIid)
			BEGIN
				RAISERROR('There is no Active Ingredient with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Active_Ingredients
					WHERE id = @AIid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Dosage_Forms


CREATE PROCEDURE Add_Dosage_Form(
	@DFname NVARCHAR(255)
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Dosage_Forms(name)
					VALUES (@DFname);
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Dosage_Form(
	@DFid INT,
	@DFname NVARCHAR(255) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Dosage_Forms
					SET name = COALESCE(@DFname, name)
					WHERE id = @DFid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Dosage_Form(
	@DFid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Dosage_Forms WHERE id = @DFid)
			BEGIN
				RAISERROR('There is no Dosage Form with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Dosage_Forms
					WHERE id = @DFid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Products & Add (Product_Ingredients)


CREATE PROCEDURE Add_Product(
	@Pname NVARCHAR(255),
	@Pbarcode VARCHAR(255),
	@Pmanufacturer_id INT,
	@Psub_category_id INT,
	@Pdosage_form_id INT,
	@Pingredient_id Ingredients_List READONLY
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @Product_id INT;

		BEGIN TRY
			BEGIN TRANSACTION;
				INSERT INTO Products(name, barcode, manufacturer_id, sub_category_id, dosage_form_id)
					VALUES (@Pname, @Pbarcode, @Pmanufacturer_id, @Psub_category_id, @Pdosage_form_id);
				
				SET @Product_id = SCOPE_IDENTITY();
				
				INSERT INTO Product_Ingredients(product_id, ingredient_id)
					SELECT @Product_id, i FROM @Pingredient_id
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Update_Product(
	@Pid INT,
	@Pname NVARCHAR(255) = NULL,
	@Pbarcode VARCHAR(255) = NULL,
	@Pmanufacturer_id INT = NULL,
	@Psub_category_id INT = NULL,
	@Pdosage_form_id INT = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Products
					SET name = COALESCE(@Pname, name),
						barcode = COALESCE(@Pbarcode, barcode),
						manufacturer_id = COALESCE(@Pmanufacturer_id, manufacturer_id),
						sub_category_id = COALESCE(@Psub_category_id, sub_category_id),
						dosage_form_id = COALESCE(@Pdosage_form_id, dosage_form_id)
					WHERE id = @Pid
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Product(
	@Pid INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Products WHERE id = @Pid)
			BEGIN
				RAISERROR('There is no Product with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Products
					WHERE id = @Pid;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- UPDATE,DELETE (Product_Ingredients)


CREATE PROCEDURE Update_Or_Delete_Product_Ingredients(
	@Pid INT,
	@P_new_ingredient_id INT = NULL,
	@P_old_ingredient_id INT = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				IF @P_new_ingredient_id IS NULL
					DELETE FROM Product_Ingredients
						WHERE product_id = @Pid AND ingredient_id = @P_old_ingredient_id;
				ELSE
					UPDATE Product_Ingredients
						SET ingredient_id = @P_new_ingredient_id
						WHERE product_id = @Pid AND ingredient_id = @P_old_ingredient_id;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END


GO

----------------------------------------------------------------------------------- Product_Batches


CREATE PROCEDURE Add_Product_Batch(
	@B_product_id INT,
	@B_batch_number VARCHAR(255),
	@B_manufacture_date DATETIME,
	@B_expiry_date DATETIME,
	@B_cost_price DECIMAL(12,2),
	@B_public_price DECIMAL(12,2),
	
	@B_new_id INT OUTPUT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @Tran_Started BIT = 0;

		BEGIN TRY
			IF(@@TRANCOUNT = 0)
			BEGIN
				BEGIN TRANSACTION;
			END
				INSERT INTO Product_Batches(product_id,batch_number, manufacture_date, expiry_date, cost_price, public_price)
					VALUES (@B_product_id, @B_batch_number, @B_manufacture_date, @B_expiry_date, @B_cost_price, @B_public_price)
				
				SET @B_new_id = SCOPE_IDENTITY();
			
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


CREATE PROCEDURE Update_Product_Batch(
	@PB_id INT,
	@B_product_id INT = NULL,
	@B_batch_number VARCHAR(255) = NULL,
	@B_manufacture_date DATETIME = NULL,
	@B_expiry_date DATETIME = NULL,
	@B_cost_price DECIMAL(12,2) = NULL,
	@B_public_price DECIMAL(12,2) = NULL
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION;
				UPDATE Product_Batches
					SET product_id = COALESCE(@B_product_id, product_id),
						batch_number = COALESCE(@B_batch_number, batch_number),
						manufacture_date = COALESCE(@B_manufacture_date, manufacture_date),
						expiry_date = COALESCE(@B_expiry_date, expiry_date),
						cost_price = COALESCE(@B_cost_price, cost_price),
						public_price = COALESCE(@B_public_price, public_price)
					WHERE id = @PB_id
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
				THROW;
		END CATCH
	END


GO


CREATE PROCEDURE Delete_Product_Batch(
	@PB_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM Product_Batches WHERE id = @PB_id)
			BEGIN
				RAISERROR('There is no Batch with this id', 16, 1);
				RETURN;
			END

		BEGIN TRY
			BEGIN TRANSACTION;
				DELETE FROM Product_Batches
					WHERE id = @PB_id;
			COMMIT TRANSACTION;
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END

