-- Signature="94E6BD3A328BC6B1"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    drop SQL Census objects from the instance														 ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.26										                                 ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
SET NOCOUNT ON

USE tempdb
GO

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- dropping SQL Census infrastructure' AS [Status]

IF OBJECT_ID('fnSQLRAP_SQLCensus_Presentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_Presentation

IF OBJECT_ID('fnSQLRAP_SQLCensus_PresentationForJobs') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_PresentationForJobs

IF OBJECT_ID('fnSQLRAP_SQLCensus_ObjectTypePresentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentation

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentationForJobs') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentationForJobs

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert

IF OBJECT_ID('fnSQLRAP_SQLCensus_NearKeywordsPresentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation

IF OBJECT_ID('fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs

IF OBJECT_ID('fnSQLRAP_SQLCensus_ExclusionMessageCheck') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck

IF OBJECT_ID('fnSQLRAP_SQLCensus_ExclusionMessagePresentation') IS NOT NULL
	DROP FUNCTION dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation

IF OBJECT_ID('SQLRAP_SQLCensus_Summary') IS NOT NULL
	DROP VIEW dbo.SQLRAP_SQLCensus_Summary

IF OBJECT_ID('vwSQLRAP_SQLCensus_TestCaseIssue') IS NOT NULL
	DROP VIEW  dbo.vwSQLRAP_SQLCensus_TestCaseIssue

IF OBJECT_ID('spSQLRAP_SQLCensus_ExcludedDatabases') IS NOT NULL
	DROP PROCEDURE dbo.spSQLRAP_SQLCensus_ExcludedDatabases

IF OBJECT_ID('SQLRAP_SQLCensus_ExcludedDatabases') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_ExcludedDatabases

IF OBJECT_ID('SQLRAP_SQLCensus_TimeAndSpace') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_TimeAndSpace

IF OBJECT_ID('SQLRAP_SQLCensus_Timings') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_Timings

IF OBJECT_ID('SQLRAP_SQLCensus_Numbers') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_Numbers

IF OBJECT_ID('SQLRAP_SQLCensus_Keywords') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_Keywords

IF OBJECT_ID('SQLRAP_SQLCensus_Objects') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_Objects

IF OBJECT_ID('SQLRAP_SQLCensus_RunTimeEstimates') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates

IF OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysis') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysis

IF OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysisForJobs') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs

IF OBJECT_ID('SQLRAP_SQLCensus_Issue') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_Issue

IF OBJECT_ID('SQLRAP_SQLCensus_TestCase') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_TestCase

IF OBJECT_ID('SQLRAP_SQLCensus_ReservedWords') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_ReservedWords

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- dropped SQL Census infrastructure' AS [Status]