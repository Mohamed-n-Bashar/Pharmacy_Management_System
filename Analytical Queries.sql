-- Current available quantity of each product per branch with the manufacturer name

CREATE VIEW vw_Current_Inventory
WITH ENCRYPTION
AS
	SELECT S.branch_id AS [Branch ID], 
		   P.name AS [Product Name],
		   M.name AS [Manufacturer Name], 
		   SUM(S.quantity) AS [Total Quantity]
	FROM Stock_Availability AS S
	INNER JOIN Product_Batches AS B
		ON S.batch_id = B.id
	INNER JOIN Products AS P
		ON B.product_id = P.id
	INNER JOIN Manufacturers AS M
		ON P.manufacturer_id = M.id
	GROUP BY S.branch_id, P.name, M.name


GO


-- Product batches that are expired or will expire within the next 90 days

CREATE VIEW vw_Expiring_Soon
WITH ENCRYPTION
AS
	SELECT id AS [Batch ID],
		   batch_number AS [Batch Number],
		   CAST(expiry_date AS DATE) AS [Expiry Date]
	FROM Product_Batches
	WHERE DATEDIFF(DAY ,GETDATE(), expiry_date) < 90


GO


-- Products that have not been sold in the past 6 months (slow-moving items)

CREATE VIEW vw_Slow_Moving_Products
WITH ENCRYPTION
AS
	SELECT Pr.name AS [Product Name]
	FROM Products AS Pr
	WHERE NOT EXISTS (SELECT 1 
					  FROM Product_Batches AS B
				   	  INNER JOIN Invoices_Items AS II
				  		  ON B.id = II.batch_id
					  INNER JOIN Invoices AS I
						  ON II.related_invoice_id = I.id 
					  WHERE Pr.id = B.product_id AND DATEDIFF(MONTH, create_at, GETDATE()) < 6)


GO


-- Daily/Monthly sales summary including total sales and net profit

CREATE PROCEDURE pr_Sales_Summary(
	@start_date DATE,
	@end_date DATE
)
WITH ENCRYPTION
AS
	BEGIN
		DECLARE @total_sales DECIMAL(12,2);
		DECLARE @total_discounts DECIMAL(12,2);

		SELECT @total_sales = SUM(net_amount),
			   @total_discounts = SUM(discount_amount)
		FROM Invoices
		WHERE invoice_type = 'S' AND (create_at BETWEEN @start_date AND @end_date)

		SELECT dbo.fn_FormatCurrency(@total_sales) AS [Total Sales],
			   dbo.fn_FormatCurrency(SUM(II.quantity * (B.public_price - B.cost_price))-@total_discounts) AS [Net Profit]
		FROM Invoices AS I
		INNER JOIN Invoices_Items AS II
			ON I.id = II.related_invoice_id
		INNER JOIN Product_Batches AS B
			ON II.batch_id = B.id
		WHERE I.invoice_type = 'S' AND (I.create_at BETWEEN @start_date AND @end_date)
	END


GO


-- Lists the top 10 best-selling products by sales quantity/value for a specific branch

CREATE PROCEDURE Top_Selling_Products(
	@branch_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SELECT TOP(10) P.name AS [Product Name],
			   dbo.fn_FormatCurrency(SUM(II.quantity*II.unit_Price)) AS [Total Sales]
		FROM Invoices AS I
		INNER JOIN Invoices_Items AS II
			ON I.id = II.related_invoice_id
		INNER JOIN Product_Batches AS B
			ON II.batch_id = B.id
		INNER JOIN Products AS P
			ON B.product_id = P.id
		WHERE I.invoice_type = 'S' AND I.branch_id = @branch_id
		GROUP BY P.name
		ORDER BY [Total Sales] DESC
	END


GO


-- The percentage of sales returns compared to total sales

CREATE PROCEDURE Returns_Percentage(
	@start_date DATE,
	@end_date DATE
)
WITH ENCRYPTION
AS
	BEGIN
		DECLARE @returns_amount DECIMAL(12,2);
	
		SELECT @returns_amount = SUM(net_amount)
		FROM Invoices
		WHERE invoice_type = 'R' AND (create_at BETWEEN @start_date AND @end_date)

		SELECT CAST(COALESCE(@returns_amount, 0)/IIF(SUM(net_amount) = 0, 1, SUM(net_amount)) * 100 AS DECIMAL(12,2)) AS [Returns Percentage %]
		FROM Invoices
		WHERE invoice_type = 'S' AND (create_at BETWEEN @start_date AND @end_date)
	END


GO


-- Purchase orders that have not yet been received and have exceeded their expected delivery date

CREATE VIEW vw_Pending_Purchase_Orders
WITH ENCRYPTION
AS
	SELECT id AS [Order ID],
		   branch_id AS [Branch ID],
		   CAST(order_date AS DATE) AS [Order Date],
		   CAST(expected_delivery_date AS DATE) AS [Expected Delivery Date],
		   DATEDIFF(DAY, expected_delivery_date, GETDATE()) AS [Days Delayed]
	FROM Purchase_Orders
	WHERE status = 'Ordered' AND expected_delivery_date < GETDATE()


GO


-- Display detailed cash inflow and outflow for a specific safe during the last 24 hours

CREATE PROCEDURE Cash_Flow_Report(
	@safe_id INT
)
WITH ENCRYPTION
AS
	BEGIN
		SELECT dbo.fn_FormatCurrency(CASE WHEN trans_type IN ('Sale', 'Collection') THEN amount ELSE -amount END) AS [Amount],
			   CAST(created_at AS DATE) AS [Date],
			   FORMAT(created_at, 'hh:mm tt') AS [TIME],
			   trans_type AS [Type]
		FROM Transactions
		WHERE safe_id = @safe_id AND payment_method = 'Cash' AND created_at >= DATEADD(HOUR, -24, GETDATE())
	END


GO


-- Lists clients with outstanding debts and shows the total amount owed by each client

CREATE VIEW vw_Client_Debts
WITH ENCRYPTION
AS
	SELECT id AS [Client ID],
		   CONCAT(Fname, ' ', Lname) AS [Client Name],
		   phone AS [Phone Number],
		   dbo.fn_FormatCurrency(SUM(balance)) AS [Client Balance]
	FROM Clients
	GROUP BY id, CONCAT(Fname, ' ', Lname), phone
	HAVING SUM(balance) > 0


GO





------------------- To Be Continued...

