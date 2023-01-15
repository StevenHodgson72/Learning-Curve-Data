
--Steven Hodgson
--Script to take unprocessed data from UnProcessedOrders table, populate the Products table, populate the Customers table, and finally populate the Orders table

--Stage 1 - Insert Products

--Reseed Products table to reset ID AutoInc Primary Key to 0
  DBCC CHECKIDENT ( 'Products', RESEED, 0)

--Temporarily remove Foreign Key from Orders table to allow Truncation of Products table
ALTER TABLE Orders
DROP CONSTRAINT FK_Orders_Products

--Truncate Products table to clear data and retain strucutre of table
  TRUNCATE TABLE Products

--Insert into Products table
--Use nested select to order by ProductID, but only select ProductName
--Use OFFSET 0 ROWS to order by ProductId and ensure that ProductName to be inserted into Products table is ordered
  INSERT INTO Products(Name)
  SELECT pro.ProductName
  FROM(
  SELECT DISTINCT ProductID, ProductName
  FROM UnProcessedOrders
  ORDER BY ProductID ASC
  OFFSET 0 ROWS
  ) as pro

--Reinstate Foreign Key Constraint on Orders table
  ALTER TABLE [Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Products] FOREIGN KEY([Product_FK])
REFERENCES Products ([ID])



--Stage 2 Populate Customers

--Reseed Customers table to reset ID AutoInc Primary Key to 0
  DBCC CHECKIDENT ( 'Customers', RESEED, 0)

--Temporarily remove Foreign Key  from Orders table to allow Truncation of Customers table
ALTER TABLE Orders
DROP CONSTRAINT FK_Orders_Customers

--Truncate Customers table to clear data and retain structure of table
  TRUNCATE TABLE Customers

--Insert into Customers table
--CustomerName field is made up of CustomerFirstName and CustomerLastName
--Use nested select to order by CustomerID, but only select CustomerName and CustomerEmailAddress
--Use OFFSET 0 ROWS to order by CustomerId and ensure that CustomerName and CustomerEmailAddress to be inserted into Customers table are ordered
  INSERT INTO Customers(CustomerName, CustomerEmailAddress)
  SELECT cus.CustomerFirstName + ' ' + cus.CustomerLastName as CustomerName,  cus.CustomerEmailAddress
  FROM
  (
   SELECT DISTINCT CustomerID, CustomerFirstName, CustomerLastName, CustomerEmailAddress
  FROM UnprocessedOrders
  ORDER BY CustomerID ASC
  OFFSET 0 ROWS
  ) as cus

--Reinstate Foreign Key Constraint on Orders table
  ALTER TABLE [Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Customers] FOREIGN KEY([Customer_FK])
REFERENCES Customers ([ID])




--Stage 3 - Insert into Orders table
TRUNCATE TABLE Orders

--Reseed Orders table to reset ID AutoInc Primary Key to 0
DBCC CHECKIDENT ( 'Orders', RESEED, 1)

--Insert into Orders table
--Link tables so that UnProcessedOrders table is joined to Products and Customers tables
--Use nested select to order by UnProcessedOrders.OrderID, but only select Customer.ID as Customer_FK Foreign Key, Products.ProductID as Product_FK Foreign Key and UnProcessedOrders.OrderDescription as OrderDescription
--Use OFFSET 0 ROWS to order by UnProcessedOrders.OrderID and ensure that CustomerID as Foreign Key and ProductID as Foreign Key to be inserted into Orders table are ordered
INSERT INTO Orders
(Customer_FK, Product_FK, OrderDescription)
SELECT
ord.CustomerID,
ord.ProductID,
ord.OrderDescription
FROM
(
SELECT DISTINCT 
cus.ID as CustomerID,
pro.ID as ProductID,
upo.OrderDescription,
upo.OrderID
FROM UnProcessedOrders as upo
LEFT JOIN Products as pro
ON upo.ProductID = pro.ID
LEFT JOIN Customers as cus
ON upo.CustomerID = cus.ID
  ORDER BY upo.OrderID ASC
  OFFSET 0 ROWS
) as ord