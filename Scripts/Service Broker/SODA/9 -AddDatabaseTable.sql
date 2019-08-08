
:CONNECT localhost\SQLDEV01
GO

-- These need to be on the initiator

USE TestDB
GO

SET NOCOUNT ON

-- drop constraints and tables
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_invrequest_form_order_form]') AND parent_object_id = OBJECT_ID(N'[dbo].[invrequest_form]'))
ALTER TABLE [dbo].[invrequest_form] DROP CONSTRAINT [FK_invrequest_form_order_form]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_order_form_orders]') AND parent_object_id = OBJECT_ID(N'[dbo].[order_form]'))
ALTER TABLE [dbo].[order_form] DROP CONSTRAINT [FK_order_form_orders]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_order_line_item_orders]') AND parent_object_id = OBJECT_ID(N'[dbo].[order_line_item]'))
ALTER TABLE [dbo].[order_line_item] DROP CONSTRAINT [FK_order_line_item_orders]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_order_line_item_product]') AND parent_object_id = OBJECT_ID(N'[dbo].[order_line_item]'))
ALTER TABLE [dbo].[order_line_item] DROP CONSTRAINT [FK_order_line_item_product]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_orders_customer]') AND parent_object_id = OBJECT_ID(N'[dbo].[orders]'))
ALTER TABLE [dbo].[orders] DROP CONSTRAINT [FK_orders_customer]
GO
USE [TestDB]
GO
/****** Object:  Table [dbo].[customer]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[customer]') AND type in (N'U'))
DROP TABLE [dbo].[customer]
GO
/****** Object:  Table [dbo].[invrequest_form]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[invrequest_form]') AND type in (N'U'))
DROP TABLE [dbo].[invrequest_form]
GO
/****** Object:  Table [dbo].[order_form]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[order_form]') AND type in (N'U'))
DROP TABLE [dbo].[order_form]
GO
/****** Object:  Table [dbo].[order_line_item]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[order_line_item]') AND type in (N'U'))
DROP TABLE [dbo].[order_line_item]
GO
/****** Object:  Table [dbo].[orders]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[orders]') AND type in (N'U'))
DROP TABLE [dbo].[orders]
GO
/****** Object:  Table [dbo].[product]    Script Date: 08/25/2006 15:35:17 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[product]') AND type in (N'U'))
DROP TABLE [dbo].[product]
GO

-- Replicated or shared scalable database copy of product table
-- Only needed to enforce referential integrity in inventory system

CREATE TABLE dbo.product (
 product_id INT PRIMARY KEY,
 description NVARCHAR(100)
)
GO

CREATE TABLE customer (
 customer_id BIGINT PRIMARY KEY,
 customer_name NVARCHAR(100)
)

CREATE TABLE orders (
 order_id BIGINT IDENTITY PRIMARY KEY,
 customer_id BIGINT,
 order_date DATETIME
)

ALTER TABLE [dbo].[orders]  
	WITH CHECK ADD  CONSTRAINT [FK_orders_customer] 
	FOREIGN KEY([customer_id])
	REFERENCES [dbo].[customer] ([customer_id])
GO

CREATE TABLE order_line_item (
 order_id BIGINT PRIMARY KEY,
 product_id INT,
 quantity INT,
 unit_price DECIMAL(7,2),
 in_stock BIT
)

ALTER TABLE [dbo].[order_line_item]  
	WITH CHECK ADD  CONSTRAINT [FK_order_line_item_orders] 
	FOREIGN KEY([order_id])
	REFERENCES [dbo].[orders] ([order_id])
GO

ALTER TABLE [dbo].[order_line_item]  
	WITH CHECK ADD  CONSTRAINT [FK_order_line_item_product] 
	FOREIGN KEY([product_id])
	REFERENCES [dbo].[product] ([product_id])
GO

-- store replica of order form
CREATE TABLE order_form (
 order_id BIGINT PRIMARY KEY,
 order_form_xml XML
)

ALTER TABLE [dbo].[order_form]  
	WITH CHECK ADD  CONSTRAINT [FK_order_form_orders] 
	FOREIGN KEY([order_id])
	REFERENCES [dbo].[orders] ([order_id])
GO

CREATE TABLE invrequest_form (
 inv_req_number UNIQUEIDENTIFIER PRIMARY KEY,
 order_id BIGINT,
 inventory_req XML
)

ALTER TABLE [dbo].[invrequest_form]  
	WITH CHECK ADD  CONSTRAINT [FK_invrequest_form_order_form] 
	FOREIGN KEY([order_id])
	REFERENCES [dbo].[order_form] ([order_id])
GO

INSERT product VALUES(134,  'Cola')
INSERT product VALUES(285,  'Drinking Straw')
INSERT product VALUES(1040, 'Sofa')
INSERT product VALUES(1500, 'Comfy Chair')
INSERT product VALUES(1580, 'Desk Chair')
INSERT product VALUES(2100, 'Desk Lamp')
INSERT product VALUES(2250, 'File Cabinet')
INSERT product VALUES(2253, 'Bookcase')
GO

INSERT customer VALUES(347, 'Acme Company')
INSERT customer VALUES(358, 'Bob''s Books')
INSERT customer VALUES(429, 'John Smith')
INSERT customer VALUES(445, 'Kevin Woo')
INSERT customer VALUES(501, 'Jane Smith')
GO

:CONNECT localhost\SQLDEV02
GO

-- These need to be on the target

USE TestDB
GO

SET NOCOUNT ON

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_inventory_product]') AND parent_object_id = OBJECT_ID(N'[dbo].[inventory]'))
ALTER TABLE [dbo].[inventory] DROP CONSTRAINT [FK_inventory_product]
GO
USE [TestDB]
GO
/****** Object:  Table [dbo].[inventory]    Script Date: 08/25/2006 15:37:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[inventory]') AND type in (N'U'))
DROP TABLE [dbo].[inventory]
GO
/****** Object:  Table [dbo].[product]    Script Date: 08/25/2006 15:37:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[product]') AND type in (N'U'))
DROP TABLE [dbo].[product]
GO

CREATE TABLE product (
 product_id INT PRIMARY KEY,
 description NVARCHAR(100)
)
GO

CREATE TABLE [dbo].[inventory] (
 product_id INT PRIMARY KEY,
 units_in_stock INT
)

ALTER TABLE [dbo].[inventory]  
	WITH CHECK ADD  CONSTRAINT [FK_inventory_product] 
	FOREIGN KEY([product_id])
	REFERENCES [dbo].[product] ([product_id])

INSERT product VALUES(134,  'Cola')
INSERT product VALUES(285,  'Drinking Straw')
INSERT product VALUES(1040, 'Sofa')
INSERT product VALUES(1500, 'Comfy Chair')
INSERT product VALUES(1580, 'Desk Chair')
INSERT product VALUES(2100, 'Desk Lamp')
INSERT product VALUES(2250, 'File Cabinet')
INSERT product VALUES(2253, 'Bookcase')
GO

INSERT inventory VALUES(134, 10000)
INSERT inventory VALUES(285, 20000)
INSERT inventory VALUES(1040, 1000)
INSERT inventory VALUES(1500, 2000)
INSERT inventory VALUES(1580, 2500)
INSERT inventory VALUES(2100, 1000)
INSERT inventory VALUES(2250, 750)
INSERT inventory VALUES(2253, 3000)
GO