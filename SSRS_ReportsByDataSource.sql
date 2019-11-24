SELECT
    DS.Name AS DatasourceName,
    C.Name AS DependentItemName, 
    C.Path AS DependentItemPath
FROM
    ReportServer.dbo.Catalog AS C 
        INNER JOIN
    ReportServer.dbo.Users AS CU
        ON C.CreatedByID = CU.UserID
        INNER JOIN
    ReportServer.dbo.Users AS MU
        ON C.ModifiedByID = MU.UserID
        LEFT OUTER JOIN
    ReportServer.dbo.SecData AS SD
        ON C.PolicyID = SD.PolicyID AND SD.AuthType = 1
        INNER JOIN
    ReportServer.dbo.DataSource AS DS
        ON C.ItemID = DS.ItemID
WHERE
    DS.Name IS NOT NULL
	AND DS.Name in ('dsAFO', 'dsDipData', 'dsMVS_Control', 'dsZIntegrationControl')
ORDER BY
    DS.Name;