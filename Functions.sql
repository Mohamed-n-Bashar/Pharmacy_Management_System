-- Returns the total available stock quantity of a specific product across all branches

CREATE FUNCTION fn_GetProductTotalStock(@product_id INT)
RETURNS INT
WITH ENCRYPTION
AS
	BEGIN
		RETURN (
			SELECT COALESCE(SUM(S.quantity), 0)
			FROM Stock_Availability AS S
			INNER JOIN Product_Batches AS B
				ON S.batch_id = B.id
			INNER JOIN Products AS P
				ON B.product_id = P.id AND @product_id = P.id
			)
	END


GO 


-- Formats a numeric value as currency with the appropriate currency symbol

CREATE FUNCTION fn_FormatCurrency(@val DECIMAL(12,2))
RETURNS VARCHAR(50)
WITH ENCRYPTION
AS
	BEGIN
		RETURN (
			FORMAT(@val, 'N2') + ' $'
		)
	END


GO


-- Returns the expiry status of a product batch ('Valid', 'Expiring Soon', or 'Expired') based on the batch ID

CREATE FUNCTION fn_BatchExpiryStatus(@batch_id INT)
RETURNS VARCHAR(100)
WITH ENCRYPTION
AS
	BEGIN
		RETURN (
			SELECT CASE
					WHEN (B.expiry_date <= GETDATE()) THEN 'Expired'
					WHEN (B.expiry_date < DATEADD(DAY, 30, GETDATE())) THEN 'Expiring Soon'
					ELSE 'Valid'
				   END
			FROM Product_Batches B
			WHERE @batch_id = B.id
		)
	END


GO


-- Returns a list of alternative products that share the same active ingredients as the given product

CREATE FUNCTION fn_GetAlternative(@product_id INT)
RETURNS TABLE
WITH ENCRYPTION
AS
	RETURN(
		SELECT DISTINCT name
		FROM Products P
		INNER JOIN Product_Ingredients I
			ON P.id = I.product_id
		WHERE I.ingredient_id IN (SELECT I.ingredient_id FROM Product_Ingredients AS I WHERE I.product_id = @product_id ) AND P.id <> @product_id
	)


GO


-- Returns all items for given invoice

CREATE FUNCTION fn_GetInvoiceItems(@invoice_id INT)
RETURNS TABLE
WITH ENCRYPTION
AS
	RETURN(
		SELECT P.name AS [Product Name],
			   B.batch_number AS [Batch Number],
			   II.quantity AS [Quantity],
			   II.unit_Price AS [Unit Price]
		FROM Invoices AS I
		INNER JOIN Invoices_Items AS II
			ON I.id = II.related_invoice_id
		INNER JOIN Product_Batches AS B
			ON II.batch_id = B.id
		INNER JOIN Products AS P
			ON B.product_id = P.id
		WHERE I.id = @invoice_id
	)


GO