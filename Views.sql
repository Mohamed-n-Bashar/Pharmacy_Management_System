-- Displays full product details

CREATE VIEW vw_ProductFullDetails
WITH ENCRYPTION
AS
	SELECT P.name AS [Product Name],
		   P.barcode AS [Barcode],
		   D.name AS [Dosage Name],
		   M.name AS [Manufacturer Name],
		   C.name AS [Category Name],
		   SC.name AS [Sub-Cat Name]
	FROM Products AS P
	INNER JOIN Dosage_Forms AS D
		ON P.dosage_form_id = D.id
	INNER JOIN Manufacturers AS M
		ON P.manufacturer_id = M.id
	INNER JOIN Sub_Categories AS SC
		ON P.sub_category_id = SC.id
	INNER JOIN Categories AS C
		ON SC.category_id = C.id


GO


-- Displays current stock levels with details

CREATE VIEW vw_DetailedStock
WITH ENCRYPTION
AS
	SELECT P.name AS [Product Name],
		   Br.address AS [Branch],
		   B.batch_number AS [Batch Number],
		   CAST(B.expiry_date AS DATE) AS [Expiry Date],
		   S.quantity AS [Quantity]
	FROM Stock_Availability AS S
	INNER JOIN Branches AS Br
		ON S.branch_id = Br.id
	INNER JOIN Product_Batches AS B
		ON S.batch_id = B.id
	INNER JOIN Products AS P
		ON B.product_id = P.id


GO


-- Displays sales invoice details

CREATE VIEW vw_SalesDetails
WITH ENCRYPTION
AS
	SELECT I.id AS [Invoice ID],
		   Br.address AS [Branch],
		   (C.Fname + ' ' + C.Fname) AS [Client Name],
		   E.name AS [Employee Name],
		   dbo.fn_FormatCurrency(I.total_amount) AS [Total Amount],
		   dbo.fn_FormatCurrency(I.discount_amount) AS [Discount Amount],
		   dbo.fn_FormatCurrency(I.net_amount) AS [Net Amount],
		   FORMAT(I.create_at, 'dd-MM-yyy') AS [Creation Date],
		   FORMAT(I.create_at, 'hh:mm tt') AS [Creation Time]
	FROM Invoices AS I
	INNER JOIN Branches AS Br
		ON I.branch_id = Br.id
	INNER JOIN Employees AS E
		ON I.employee_id = E.id
	INNER JOIN SalesInvoices AS SI
		ON I.id = SI.sales_id
	INNER JOIN Clients AS C
		ON SI.client_id = C.id


GO


-- Displays purchase invoices details

CREATE VIEW vw_PurchaseSummary
WITH ENCRYPTION
AS
	SELECT I.id AS [Invoice ID],
		   Br.address AS [Branch],
		   S.supplier_name AS [Supplier Name],
		   E.name AS [Employee Name],
		   dbo.fn_FormatCurrency(I.total_amount) AS [Total Amount],
		   dbo.fn_FormatCurrency(I.discount_amount) AS [Discount Amount],
		   dbo.fn_FormatCurrency(I.net_amount) AS [Net Amount],
		   FORMAT(I.create_at, 'dd-MM-yyy') AS [Creation Date],
		   FORMAT(I.create_at, 'hh:mm tt') AS [Creation Time]
	FROM Invoices AS I
	INNER JOIN Branches AS Br
		ON I.branch_id = Br.id
	INNER JOIN Employees AS E
		ON I.employee_id = E.id
	INNER JOIN Purchase_Invoices AS P
		ON I.id = P.purchase_id
	INNER JOIN Suppliers AS S
		ON P.supplier_id = S.id

GO


-- Displays safes transactions

CREATE VIEW vw_SafeTransactions
WITH ENCRYPTION
AS
	SELECT S.id AS [Safe ID],
		   dbo.fn_FormatCurrency(S.balance) AS [Safe Current Balance],
		   B.address AS [Branch],
		   E.name AS [Employee Name],
		   T.trans_type AS [Transaction Type],
		   dbo.fn_FormatCurrency(T.amount) AS [Amount],
		   FORMAT(T.created_at, 'dd-MM-yyy') AS [Transaction Date],
		   FORMAT(T.created_at, 'hh:mm tt') AS [Transaction Time]
	FROM Transactions AS T
	INNER JOIN Safes AS S
		ON T.safe_id = S.id
	INNER JOIN Branches AS B
		ON T.branch_id = B.id
	INNER JOIN Employees AS E
		ON T.employee_id = E.id
	WHERE T.payment_method = 'Cash'


GO


-- Displays employee full details

CREATE VIEW vw_EmployeeActivity
WITH ENCRYPTION
AS
	SELECT E.name AS [Employee Name],
		   B.address AS [Branch],
		   SUM(CASE WHEN I.invoice_type = 'S' THEN 1 ELSE 0 END) AS [Sale Invoices],
		   SUM(CASE WHEN I.invoice_type = 'P' THEN 1 ELSE 0 END) AS [Purchase Invoices],
		   SUM(CASE WHEN I.invoice_type = 'R' THEN 1 ELSE 0 END) AS [Return Invoices],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN I.invoice_type = 'S' THEN I.net_amount ELSE 0 END)) AS [Total Amount In],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN I.invoice_type = 'R' OR I.invoice_type = 'P' THEN I.net_amount ELSE 0 END)) AS [Total Amount Out]
	FROM Employees AS E
	INNER JOIN Branches AS B
		ON E.branch_id = B.id
	INNER JOIN Invoices AS I
		ON I.employee_id = E.id
	GROUP BY E.name, B.address


GO


-- Displays a financial summary per branch

CREATE VIEW vw_BranchFinancialSummary
WITH ENCRYPTION
AS
	SELECT B.id AS [Branch ID],
		   B.address AS [Branch],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN T.trans_type = 'Sale' THEN T.amount ELSE 0 END)) AS [Total Sales],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN T.trans_type = 'Purchase' THEN T.amount ELSE 0 END)) AS [Total Purchases],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN T.trans_type = 'Expense' THEN T.amount ELSE 0 END)) AS [Total Expenses],
		   dbo.fn_FormatCurrency(SUM(CASE WHEN T.trans_type = 'Return' THEN T.amount ELSE 0 END)) AS [Total Returns]
	FROM Transactions AS T
	INNER JOIN Branches AS B
		ON T.branch_id = B.id
	GROUP BY B.id, B.address


GO


-- Displays details of internal transfers between branches

CREATE VIEW vw_InternalTransferLogs
WITH ENCRYPTION
AS
	SELECT FB.address AS [Source Branch],
		   TB.address AS [Destination Branch],
		   IT.quantity AS [Transfered Quantity],
		   IT.status AS [Transfers Status],
		   B.batch_number AS [Transfers Batch],
		   P.name AS [Transfers Product],
		   FORMAT(IT.transfer_date, 'dd-MM-yyy') AS [Transfer Date],
		   FORMAT(IT.transfer_date, 'hh:mm tt') AS [Transfer Time]
	FROM Internal_Transfers AS IT
	INNER JOIN Branches AS FB
		ON IT.from_branch_id = FB.id
	INNER JOIN Branches AS TB
		ON IT.to_branch_id = TB.id
	INNER JOIN Product_Batches AS B
		ON IT.batch_id = B.id
	INNER JOIN Products AS P
		ON B.product_id = P.id


GO


-- Displays stock movements with details

CREATE VIEW vw_StockAuditTrail
WITH ENCRYPTION
AS
	SELECT P.name AS [Product Name],
		   B.batch_number AS [Batch Number],
		   E.name AS [Employee Name],
		   SM.quantity_before AS [Quantity Before],
		   SM.quantity_after AS [Quantity After],
		   COALESCE(CAST(SM.related_invoice_id AS VARCHAR(100)), '-') AS [Related Invoice],
		   COALESCE(CAST(SM.internal_trans_id AS VARCHAR(100)), '-') AS [Related Intenal-Tran],
		   FORMAT(SM.created_at, 'dd-MM-yyy') AS [Movement Date],
		   FORMAT(SM.created_at, 'hh:mm tt') AS [Movement Time],
		   SM.note AS [Note]
	FROM Stock_Movements AS SM
	INNER JOIN Employees AS E
		ON SM.employee_id = E.id
	INNER JOIN Stock_Availability AS S
		ON SM.stock_id = S.id
	INNER JOIN Product_Batches AS B
		ON S.batch_id = B.id
	INNER JOIN Products AS P
		ON B.product_id = P.id
