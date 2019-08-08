use AdventureWorks2008
go


--See the entire hierarchy
SELECT 
	OrganizationNode.ToString(), *
FROM HumanResources.Employee
ORDER BY OrganizationNode
GO



--Find all ancestors?
--v1: Use GetAncestor for every level above C
SELECT 
	p.*
FROM HumanResources.Employee AS P
JOIN HumanResources.Employee AS C ON 
	C.OrganizationNode = 0x5AC0
    AND P.OrganizationNode = 
		C.OrganizationNode.GetAncestor
		(
			C.OrganizationLevel - P.OrganizationLevel
		)
	AND P.OrganizationLevel < C.OrganizationLevel
GO


--v2: Use IsDescendantOf
SELECT 
	p.*
FROM HumanResources.Employee AS P
JOIN HumanResources.Employee AS C ON 
	C.OrganizationNode = 0x5AC0
	AND 1 = 
		C.OrganizationNode.IsDescendantOf
		(
			P.OrganizationNode
		)
	AND C.OrganizationNode <> P.OrganizationNode
GO



--Find all descendants?
--opposite of v2
SELECT 
	c.*
FROM HumanResources.Employee AS P
JOIN HumanResources.Employee AS C ON 
	P.OrganizationNode = 0x5AC0
	AND 1 = 
		C.OrganizationNode.IsDescendantOf
		(
			P.OrganizationNode
		)
	AND C.OrganizationNode <> P.OrganizationNode
GO


--Find all immediate subordinates
SELECT 
	c.*
FROM HumanResources.Employee AS P
JOIN HumanResources.Employee AS C ON 
	P.OrganizationNode = 0x5AC0
	AND 1 = 
		C.OrganizationNode.IsDescendantOf
		(
			P.OrganizationNode
		)
	AND C.OrganizationLevel = P.OrganizationLevel + 1
GO


--Reparenting
SELECT 
	c.OrganizationNode.ToString(),
	C.OrganizationNode.GetReparentedValue('/1/1/', '/1/2/').ToString()
FROM HumanResources.Employee AS P
JOIN HumanResources.Employee AS C ON 
	P.OrganizationNode = 0x5AC0
	AND 1 = 
		C.OrganizationNode.IsDescendantOf
		(
			P.OrganizationNode
		)
	AND C.OrganizationLevel = P.OrganizationLevel + 1
GO
