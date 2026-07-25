DELETE FROM dbo.tbl_Products WHERE Sku LIKE 'PHARM-%';
DELETE FROM dbo.tbl_CustomerOrderProducts WHERE Sku LIKE 'PHARM-%';
DELETE FROM dbo.tbl_CompanyProducts WHERE ProductCode LIKE 'PHARM-%';
