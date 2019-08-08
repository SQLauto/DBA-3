'<!-- ****************************************************************** -->
'<!-- **  Active Directory Snapshot Tool                              ** -->
'<!-- **  Copyright 2006 Microsoft Corporation, All rights reserved.  ** -->
'<!-- **  Version 4.1.0.35                                            ** -->
'<!-- **  Signature="759781F374368947"                                ** -->
'<!-- ****************************************************************** -->


Class MyADHC
	Private privbErrorsFound, privbDEBUG 'As Boolean
	Private privstrForest, privstrRootNode, privstrFilename, privstrDomain, privstrNetBIOSDomain, privstrServer, privstrCluster 'Standard variables
	Private privXMLDoc, privXMLRootNode, privXMLForestNode, privXMLDomainNode, privXMLServerNode	'Standard XML Elements for defined XML Schema
	Private PrivXMLADConvergence, privXMLDC, privstrScope, privstrDomainList, privstrDCList, privstrQuick, privstrOutputDir, privstrShowDetail
	Private privstrNumberOfLines, privstrNumberOfDays, privstrCollatedFilename,privstrForce2000Style,privstrCollectZones
	Private strTmpDCList

	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Defining public properties that can be gotten
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Property Get bErrorsFound
		bErrorsFound = privbErrorsFound
	End Property
	Public Property Get bDEBUG
		bDEBUG = privbDEBUG
	End Property
	
	Public Property Get OutputFile
		Set OutputFile = objFSO.CreateTextFile(WORKING_DIR & OUTPUT_FILENAME,true)
	End Property

	Public Property Get strForest
		strForest = privstrForest
	End Property
	
	
	Public Property Get strRootNode
	    strRootNode = privstrRootNode
	end Property
	
	Public Property Get strFilename
	   strFilename = privstrFilename
	end Property   
	
	Public Property Get strNumberOfLines
	   strNumberOfLines = privstrNumberOfLines
	end Property   

	Public Property Get strNumberOfDays
	   strNumberOfDays = privstrNumberOfDays
	end Property   

	Public Property Get strCollatedFilename
	   strCollatedFilename = privstrCollatedFilename
	end Property   

	Public Property Get strForce2000Style
	   strForce2000Style = privstrForce2000Style
	end Property   

	Public Property Get strCollectZones
	   strCollectZones = privstrCollectZones
	end Property   
	
	
	Public Property Get strScope
	   strScope = privstrScope
	end Property   
	
	Public Property Get strDomainList
	   strDomainList = privstrDomainList
	end Property   
	
	Public Property Get strDCList
	   strDCList = privstrDCList
	end Property   
	    
	Public Property Get strQuick
	   strQuick = privstrQuick
	end Property   
	
	Public Property Get strOutputDir
	   strOutputDir = privstrOutputDir
	end Property   

	Public Property Get strShowDetail
	   strShowDetail = privstrShowDetail
	end Property   
	    
	    
	Public Property Get strDomain
		strDomain = privstrDomain
	End Property
	Public Property Get strNetBIOSDomain
		strNetBIOSDomain = privstrNetBIOSDomain
	End Property
	Public Property Get strServer
		strServer = privstrServer
	End Property
		Public Property Get strCluster
		strCluster = privstrCluster
	End Property
	Public Property Get NearestServer
		On Error Resume Next
		Set rootDSE = GetObject("LDAP://rootDSE")
		If Err.number<>0 Then
			Err.Description = "Unable to bind to AD:  " & Err.Description
			NearestServer =  empty
			Exit Property
		End If
		
		Err.Clear
		sznearestServer = rootDSE.Get("dnsHostName")
		If Err.number<>0 Then
			Err.Description = "Unable to get target server name:  " & Err.Description
			NearestServer = empty
			Exit Property
		End If
		NearestServer = sznearestServer
	End Property

	Public Property Get xmlForestNode
		Set xmlForestNode = privXMLForestNode
	End Property
	Public Property Get xmlDomainNode
		Set xmlDomainNode = privXMLDomainNode
	End Property
	Public Property Get xmlServerNode
		Set xmlServerNode = privXMLServerNode
	End Property
	
	Public Property Get xmlADConvergence
		Set xmlADConvergence = privXMLADConvergence
	End Property
	
	Public Property Get xmlDC
	    set xmlDC = privXMLAD
	End Property    
	
	Public Property Get xmlRootNode
	   Set xmlRootNode = privXMLRootNode
	end property
	   
	
	
	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Defining public properties that can be set
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Property Let bErrorsFound(value)
		privbErrorsFound = value
	End Property


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Initialze global variables
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Function InitializeScriptState
		'Initialize Global State
		ExecuteGlobal strglobalInitializations

		'Set Debugging mode
		If ReadADHCRegValue("DEBUG") = 1 Then 
			privbDEBUG = true
		Else
			privbDEBUG = false
		End If
		privbErrorsFound = false
        'msgbox "privbDEBUG=" & privbDEBUG
		internalParseCommandLine
	End Function

	'This function is designed to be called by ExecuteGlobal.
	'	Thus, when making calls to procedures within this class
	'	it must use the object declared in the actual script.  I.e. ADHC.ReadADHCRegValue
	Private Function strglobalInitializations
		szTemp = szAddExecuteGlobalStatement(szTemp, "On Error Resume Next")
		
		'Declare standard global variables
		szTemp = szAddExecuteGlobalStatement(szTemp, "Dim objFSO, WshShell")
		szTemp = szAddExecuteGlobalStatement(szTemp, "Dim OUTPUT_FILENAME, OUTPUT_FILEEXT, WORKING_DIR, WORKING_ADDENDUM, MAIN_PAGE_TITLE, HISTORY_PAGE_TITLE")

		'Declare standard global objects
		szTemp = szAddExecuteGlobalStatement(szTemp, "Set WshShell = Wscript.CreateObject(""Wscript.Shell"")")
		szTemp = szAddExecuteGlobalStatement(szTemp, "Set objFSO = CreateObject(""Scripting.FileSystemObject"")")
	
		'Declare well known constants
		szTemp = szAddExecuteGlobalStatement(szTemp, "const ForReading = 1, ForWriting = 2, ForAppending = 8")

		'Get well known variables.
		'	These must be declared as resources in the WSH file
		szTemp = szAddExecuteGlobalStatement(szTemp, "OUTPUT_FILENAME = getResource(""OUTPUT_FILENAME"")")
		szTemp = szAddExecuteGlobalStatement(szTemp, "OUTPUT_FILEEXT = getResource(""OUTPUT_FILEEXT"")")
		'szTemp = szAddExecuteGlobalStatement(szTemp, "HISTORY_PAGE_TITLE = getResource(""HISTORY_PAGE_TITLE"")")
		szTemp = szAddExecuteGlobalStatement(szTemp, "WORKING_ADDENDUM = getResource(""WORKING_ADDENDUM"")")
		szTemp = szAddExecuteGlobalStatement(szTemp, "HISTORY_PAGE_TITLE = getResource(""HISTORY_PAGE_TITLE"")")
		
		szTemp = szAddExecuteGlobalStatement(szTemp, "MAIN_PAGE_TITLE = getResource(""MAIN_PAGE_TITLE"")")
		
		
		szTemp = szAddExecuteGlobalStatement(szTemp, "Flags = getResource(""Flags"")")
		
		
		'Get working directory
		'	This is where all files are created and put.  They are
		'	instantiated by FinishScript.vbs
		szTemp = szAddExecuteGlobalStatement(szTemp, "WORKING_DIR = ADHC.ReadADHCRegValue(""Working_Dir"") & ""\""")
		szTemp = szAddExecuteGlobalStatement(szTemp, "OUTPUT_DIR = ADHC.ReadADHCRegValue(""Output_Dir"") & ""\""")
			
		szTemp = szAddExecuteGlobalStatement(szTemp, "On Error Goto 0")
			
		strglobalInitializations = szTemp
	End Function
	Private Function szAddExecuteGlobalStatement(szCurrentStatement, szStatementToAdd)
		szAddExecuteGlobalStatement = szCurrentStatement & szStatementToAdd & vbCrLf
	End function


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Internal routine to parse the command line for well known variables
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Private Sub internalParseCommandLine
		If Wscript.Arguments.Named.Exists("Forest") Then privstrForest = WScript.Arguments.Named.Item("Forest")
		If Wscript.Arguments.Named.Exists("Domain") Then privstrDomain = WScript.Arguments.Named.Item("Domain")
		If Wscript.Arguments.Named.Exists("NetBIOSDomain") Then privstrNetBIOSDomain = WScript.Arguments.Named.Item("NetBIOSDomain")
		If Wscript.Arguments.Named.Exists("Server") Then privstrServer = WScript.Arguments.Named.Item("Server")
		If Wscript.Arguments.Named.Exists("Cluster") Then privstrCluster = WScript.Arguments.Named.Item("Cluster")
		if Wscript.Arguments.Named.Exists("RootNode") then privstrRootNode = Wscript.Arguments.Named.Item("RootNode")
		if Wscript.Arguments.Named.Exists("Filename") then privstrFilename = Wscript.Arguments.Named.Item("Filename")
		if Wscript.Arguments.Named.Exists("Scope") then privstrScope = Wscript.Arguments.Named.Item("Scope")
		if Wscript.Arguments.Named.Exists("DomainList") then privstrDomainList = Wscript.Arguments.Named.Item("DomainList")
		if Wscript.Arguments.Named.Exists("DCList") then privstrDCList = Wscript.Arguments.Named.Item("DCList")
		if Wscript.Arguments.Named.Exists("Quick") then privstrQuick = Wscript.Arguments.Named.Item("Quick")
		if Wscript.Arguments.Named.Exists("OutputDir") then privstrOutputDir = Wscript.Arguments.Named.Item("OutputDir")
		if Wscript.Arguments.Named.Exists("ShowDetail") then privstrShowDetail = Wscript.Arguments.Named.Item("ShowDetail")
		if Wscript.Arguments.Named.Exists("NumberOfLines") then privstrNumberOfLines = Wscript.Arguments.Named.Item("NumberOfLines")
		if Wscript.Arguments.Named.Exists("NumberOfDays") then privstrNumberOfDays = Wscript.Arguments.Named.Item("NumberOfDays")
		if Wscript.Arguments.Named.Exists("CollatedFilename") then privstrCollatedFilename = Wscript.Arguments.Named.Item("CollatedFilename")
		if Wscript.Arguments.Named.Exists("Force2000Style") then privstrForce2000Style = Wscript.Arguments.Named.Item("Force2000Style")
		if Wscript.Arguments.Named.Exists("CollectZones") then privstrCollectZones = Wscript.Arguments.Named.Item("CollectZones")
	End Sub


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Setup Basic XML structure
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Sub PrepareXML(strRootNode)
		Set privXMLDoc = CreateObject("MSXML2.DOMDocument")
		Set privXMLRootNode = AddXMLElement(privXMLDoc, strRootNode)
	End Sub
	
	Public Sub CreateXMLDomainNode(szDomainName)
		Set privXMLForestNode = privXMLDoc.selectSingleNode("//Forest")
		Set privXMLDomainNode = AddXMLUniqueElement(privXMLForestNode, "Domain", lcase(szDomainName))
	End Sub
	Public Sub CreateXMLServerNode(szServerName, szDomainName)
		Set privXMLDomainNode = privXMLDoc.selectSingleNode("//Domain[@id = '" & lcase(szDomainName) & "']")
		Set privXMLServerNode = AddXMLUniqueElement(privXMLDomainNode, "Server", lcase(szServerName))
	End Sub


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Add an attribute to an element
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Sub AddXMLAttr(xmlElement, szAttribute, varValue)
            Set XMLAttrib = privXMLDoc.createAttribute(szAttribute)
			On Error Resume Next
			xmlAttrib.Text = varValue
			
			If Err.number<>0 Then 
				Exit Sub
			end if	
			On Error Goto 0

			xmlElement.setAttributeNode(xmlAttrib)
	End Sub


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Add XML Element that will contain child elements
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Function AddXMLUniqueElement(xmlParentElement, szChildElement, varVariable)
		Set xmlChild = AddXMLElement(xmlParentElement, szChildElement)
		AddXMLAttr xmlChild, "id", varVariable
		Set AddXMLUniqueElement = xmlChild
	End Function


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Add XML Element that will contain child elements
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Function AddXMLElement(xmlParentElement, szChildElement)
			Dim xmlChild
			Set xmlChild = privXMLDoc.createElement(szChildElement)
			xmlParentElement.appendChild xmlChild
			Set AddXMLElement = xmlChild
	End Function


	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Add XML Element that will contain ONLY text or Attributes.
	'	In otherwords, don't plan on adding any child nodes.
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Public Function AddXMLTextOnlyElement(xmlParentElement, szChildElement, varVariable)
			Dim xmlChild

			Set xmlChild = AddXMLElement(xmlParentElement, szChildElement)

			On Error Resume Next
			xmlChild.Text = varVariable
			If Err.number<>0 Then xmlChild.Text = Null
			On Error Goto 0
		
			Set AddXMLTextOnlyElement = xmlChild
	End Function
	
	Public Sub SaveXML(szFileName)
		privxmlDoc.save(szFileName)
	End Sub





	'''''''''''''''''''''''''''''''''''''''''''''''''
	'Gracefully handle errors
	'''''''''''''''''''''''''''''''''''''''''''''''''
	Public Sub OutputError(szErrorString)
		If bDEBUG Then Wscript.Echo szErrorString & vbCrLf & vbTab & "(" & Err.number & ") " & Err.Description
		fsOutFile.WriteLine "<p><A><font color='red'><b>" & szErrorString & "</b></font></p>"
		fsOutFile.WriteLine "<p><A><font color='red'><b>&nbsp;&nbsp;&nbsp;" & Err.number & " - " & Err.Description & "</b></font></p>"
		bErrorsFound = true
	End Sub


	Public Function ReadADHCRegValue(szValueName)
		const ADHC_REGISTRY_KEY = "HKLM\SOFTWARE\Microsoft\ADHCWeb\"
		On Error Resume Next
		ReadADHCRegValue = WshShell.RegRead(ADHC_REGISTRY_KEY & szValueName)
		If Err.number<>0 Then
			ReadADHCRegValue = null
			Exit Function
		End If
	End Function
	
	
	''''''''''''''''''''''''''''''''''''''''''''''''''
	'Query Remote Registry Value via WMI
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Function QueryRemoteRegistryForString(strTargetComputer, szHKLMKey, szValue, szReturnValue)
		on error resume next
		const HKEY_LOCAL_MACHINE = &H80000002
		Set objRegService = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strTargetComputer & "\root\default:StdRegProv")
		QueryRemoteRegistryForString = objRegService.GetStringValue(HKEY_LOCAL_MACHINE, szHKLMKey, szValue, szReturnValue)
	End Function
	
	Function QueryRemoteRegistryForDWORD(strTargetComputer, szHKLMKey, szValue, dwReturnValue)
		on error resume next
		const HKEY_LOCAL_MACHINE = &H80000002
		Set objRegService = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strTargetComputer & "\root\default:StdRegProv")
		QueryRemoteRegistryForDWORD = objRegService.GetDWORDValue(HKEY_LOCAL_MACHINE, szHKLMKey, szValue, dwReturnValue)
	End Function
	
	
	'''''''''''''''''''''''''''''''''''''''''''''''''
	'Get FQDN of Forest Root PDC
	''''''''''''''''''''''''''''''''''''''''''''''''''
	Function szGetForestRootPDC
		szGetForestRootPDC = ""
		On Error Resume Next
		
		'Do a serverless bind to rootDSE
		Set rootDSE = GetObject("LDAP://rootDSE")
		If Err.number<>0 Then
			OutputError "Unable to locate forest Root DC.  Failed to bind to AD:"
			Exit Function
		End If

		'Get the forest root domain from rootDSE and bind to it
		Err.Clear
		Set objForestRoot = GetObject("LDAP://" & rootDSE.Get("rootDomainNamingContext"))
		If Err.number<>0 Then
			OutputError "Unable to locate forest Root DC.  Failed to bind to Root domain Partition:"
			Exit Function
		End If
		
		'Find the PDC FSMO Role owner for the forest root and bind to the NTDS object representing that DC
		Err.Clear
		Set objForestRootPDCNTDS = GetObject("LDAP://" & objForestRoot.Get("fSMORoleOwner"))
		If Err.number<>0 Then
			OutputError "Unable to locate forest Root DC.  Failed to get bind to PDC NTDS object:"
			Exit Function
		End If
		
		'Bind to the NTDS object's parent so that we can resolve the friendly names
		Err.Clear
		Set objForestRootPDCNTDSParent = GetObject(objForestRootPDCNTDS.Parent)
		If Err.number<>0 Then
			OutputError "Unable to locate forest Root DC.  Failed to get bind to PDC NTDS object's parent:"
			Exit Function
		End If

		'Finally we get the FQDN for the PDC for the forest root.
		szGetForestRootPDC = objForestRootPDCNTDSParent.Get("dNSHostName")
	End Function
	
	'**********************
	'*** Get Closest DC ***
	'**********************
	Function szGetClosestDC
	   on error resume next
	   szGetClosestDC=""
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   if err.number<>0 then
	       wscript.echo "Error getting RootDSE"
	       exit function
	   end if    
	   set objIadsTools = CreateObject("IADsTools.DCFunctions")
	   if err.number<>0 then
	      wscript.echo "error getting IADsTools"
	      exit function
	   end if 
	   ConfigNC=objRootDSE.Get("ConfigurationNamingContext")
	   RootDomain=replace(lcase(ConfigNC),"cn=configuration,","")  
'wscript.echo "RootDomain1: " & RootDomain	   
	   RootDomain=replace(RootDomain,",dc=",".")
'wscript.echo "RootDomain2: " & RootDomain	   	   
	   RootDomain=replace(RootDomain,"dc=","")
'wscript.echo "RootDomain3: " & RootDomain	   	   
	   objIadsTools.DsGetDcName(RootDomain)
	   DCName=objIadsTools.DCName
'wscript.echo "DCName: " & DCName	   
	   szGetClosestDC=objIadsTools.DCName
	end function

	'********************
	'*** Convert Date ***
	'********************	
	Function ConvertDate(DateIn)
		ConvertDate = ""
		
		if DateIn="" then
		   exit function
		end if      
		strDay=DatePart("d",DateIn)
		if len(strDay)=1 then strDay="0" & strDay
		strMonth=DatePart("m",DateIn)
		if len(strMonth)=1 then strMonth="0" & strMonth
		strYear=DatePart("yyyy",DateIn)
		strHour=DatePart("h",DateIn)
		if len(strHour)=1 then strHour="0" & strHour
		strMin=DatePart("n",DateIn)
		if len(strMin)=1 then strMin="0" & strMin
		strSec=DatePart("s",DateIn)
		if len(strSec)=1 then strSec="0" & strSec
		   
		ConvertDate = strYear & "-" & strMonth & "-" & strDay & "T" & strHour & ":" & strMin & ":" & strSec


	end function

	Function szGetTombstoneLifetime

		wscript.echo "Determining Tombstone Lifetime"

		set objRootDSE = GetObject("LDAP://RootDSE")
		set objDSCont = GetObject("LDAP://cn=Directory Service,cn=Windows NT," & _
				"cn=Services," & objRootDSE.Get("configurationNamingContext") )
		err.clear
		on error resume next
		TombStone = objDSCont.Get("TombstoneLifetime")
		if TombStone="" then
			TSL = 60
		else
			TSL = TombStone 
		end if
		szGetTombstoneLifetime=TSL

		set objRootDSE=Nothing
		set objDSCont=Nothing

	end Function


	'********************************************
	'*** Get Forest NCs Replication Intervals ***
	'********************************************
	Sub szGetForestNCsReplicationIntervals(szNCsOut,szFirstDelayOut,szSecondDelayOut)
		on error resume next
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   strADsPath = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;" 

	   strFilter = "(&(objectcategory=Crossref));"
	       
	   strAttrs = "NCName,msDS-Replication-Notify-First-DSA-Delay,msDS-Replication-Notify-Subsequent-DSA-Delay;"
	   strScope2 = "SubTree"
	   
	   set objConn = CreateObject("ADODB.Connection")
	   objConn.Provider = "ADsDSOObject"
	   objConn.Open "Active Directory Provider"
	   set objRS = objConn.Execute(strADsPath & strFilter & strAttrs & strScope2)
	   objRS.MoveFirst
	   
	   szNCsOut=""
	   szFirstDelayOut=""
	   szSecondDelayOut=""
	   
	   while not objRS.EOF
	      NC = objRS.Fields(0).Value
	      FirstDelay = objRS.Fields(1).Value
	      SecondDelay = objRS.Fields(2).Value
	      
		  if (instr(ucase(NC),"FORESTDNSZONES")) or (instr(ucase(NC),"DOMAINDNSZONES")) then
	 
		  else

			if szNCsOut="" then
				szNCsOut=NC
				szFirstDelayOut=FirstDelay
				szSecondDelayOut=SecondDelay
			else
				szNCsOut=szNCsOut & ";" & NC
				szFirstDelayOut=szFirstDelayOut & ";" & FirstDelay
				szSecondDelayOut=szSecondDelayOut & ";" & SecondDelay
			end if      
	      
	      end if
	      
	      objRS.MoveNext
	   wend   
	
	   
	End Sub


	Function szGetForestNCs
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   strADsPath = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;" 

	   'strFilter = "(&(objectcategory=Crossref)(netBIOSName=*));"
	   strFilter = "(&(objectcategory=Crossref));"
	       
	   strAttrs = "NCName;"
	   strScope2 = "SubTree"
	   
	   set objConn = CreateObject("ADODB.Connection")
	   objConn.Provider = "ADsDSOObject"
	   objConn.Open "Active Directory Provider"
	   set objRS = objConn.Execute(strADsPath & strFilter & strAttrs & strScope2)
	   objRS.MoveFirst
	   szDomainsOut=""
	   while not objRS.EOF
	      NC = objRS.Fields(0).Value
	
		  if (instr(ucase(NC),"FORESTDNSZONES")) or (instr(ucase(NC),"DOMAINDNSZONES")) then
	 
		  else

			if szNCsOut="" then
				szNCsOut=NC
			else
				szNCsOut=szNCsOut & ";" & NC
			end if      
	      
	      end if
	      
	      objRS.MoveNext
	   wend   
	
	   szGetForestNCs=szNCsOut
	End Function

	Function szGetAllForestNCs
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   strADsPath = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;" 

	   'strFilter = "(&(objectcategory=Crossref)(netBIOSName=*));"
	   strFilter = "(&(objectcategory=Crossref));"
	       
	   strAttrs = "NCName;"
	   strScope2 = "SubTree"
	   
	   set objConn = CreateObject("ADODB.Connection")
	   objConn.Provider = "ADsDSOObject"
	   objConn.Open "Active Directory Provider"
	   set objRS = objConn.Execute(strADsPath & strFilter & strAttrs & strScope2)
	   objRS.MoveFirst
	   szDomainsOut=""
	   while not objRS.EOF
		    NC = objRS.Fields(0).Value
	
			if szNCsOut="" then
				szNCsOut=NC
			else
				szNCsOut=szNCsOut & ";" & NC
			end if      
	      
    
			objRS.MoveNext
	   wend   
	
	   szGetAllForestNCs=szNCsOut
	End Function




	Function szFindAllConflicts(strServer,strNC)
		on error resume next
		set objRootDSE = GetObject("LDAP://RootDSE")

		tmpFilename=lcase(strNC)
		tmpFilename=Replace(tmpFilename,",dc=","-")
		tmpFilename=Replace(tmpFilename,",cn=","-")
		
		tmpFilename=Replace(tmpFilename,"\","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"<","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,">","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"/","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"&","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"%","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"@","") ' remove restricted chars that a filename would choke on.
		tmpFilename=Replace(tmpFilename,"cn=","-")
		tmpFilename=Replace(tmpFilename,"dc=","")
		tmpFilename="ADConflicts-" & tmpFilename & ".TXT"
		tmpFilename=strOutputDir & "\" & tmpFilename
		
		Set FileConflicts = objFSO.CreateTextFile(tmpFilename,true)
		strADsPath = "LDAP://" & strServer & "/" & strNC
		strFilter = "cn='*\0ACNF:*'"
		strCommand="Select distinguishedName from '" & strADsPath & "' where " & strFilter
		wscript.echo "Command: " & strCommand
		
		Set objConnection = CreateObject("ADODB.Connection")
		Set objCommand = CreateObject("ADODB.Command")
		objConnection.Provider = "ADsDSOObject"
		objConnection.Open "Active Directory Provider"
		Set objCOmmand.ActiveConnection = objConnection

		objCommand.CommandText = strCommand
		
		'"' where objectClass='nTDSDSA'" 
		objCommand.Properties("Page Size") = 1000
		objCommand.Properties("Searchscope") = 2

		Set objRecordSet = objCommand.Execute
		'objRecordSet.MoveFirst
		if err.number<>0 then
			ObjCount=-1	
		else
			objCount=0
			Do Until objRecordSet.EOF
				objCount=objCount+1
				DN=objRecordSet.Fields("distinguishedName").Value
				'wscript.echo "----------------->DN: " & DN
				FileConflicts.Writeline DN
				objRecordSet.MoveNext
			loop	
		end if
		'wscript.echo "objCount: " & objCount
	
		set objCommand=nothing
		set objConnection=nothing
		set FileConflicts = Nothing
				
		szFindAllConflicts = ObjCount
		
	End Function


	Function CountLostAndFound(strServerIn,NC)
		on error resume next
		wscript.echo "--->NC: " & NC

		strBase = "LDAP://" & strServerIn & "/cn=LostAndFound," & NC
		if instr(lcase(trim(NC)),"cn=configuration") then
			strBase = "LDAP://" & strServerIn & "/cn=LostAndFoundConfig," & NC
		end if
		if instr(lcase(trim(NC)),"cn=schema,") then
			'strBase = "LDAP://" & strServerIn & "/cn=LostAndFound," & NC
			'Schema NC does have a Lost and Found folder, exit routine
			CountLostAndFound=0
			exit function
		end if	
		
		strCommand="Select distinguishedName from '" & strBase & "' where objectClass='*'" 		
		wscript.echo "Command: " & strCommand
		
		Set objConnection = CreateObject("ADODB.Connection")
		Set objCommand = CreateObject("ADODB.Command")
		objConnection.Provider = "ADsDSOObject"
		objConnection.Open "Active Directory Provider"
		Set objCOmmand.ActiveConnection = objConnection
 
		objCommand.CommandText = strCommand
		
		objCommand.Properties("Page Size") = 1000
		objCommand.Properties("Searchscope") = 2

		Set objRecordSet = objCommand.Execute
		if err.number<>0 then
			objCount=-1		
		else
			objRecordSet.MoveFirst
			objCount=-1
			Do Until objRecordSet.EOF
				objCount=objCount+1
				DN=objRecordSet.Fields("distinguishedName").Value
				
				objRecordSet.MoveNext
			loop	
		end if
		wscript.echo "objCount: " & objCount
	
		set objCommand=nothing
		set objConnection=nothing
		
		'if objCount=-1 then objCount=0
		
		CountLostAndFound = ObjCount
	
	
	End Function
	
	Function szGetReplicaLocations(AppNC)
	
		strAppPart=AppNC
		set objRootDSE = GetObject("LDAP://RootDSE")
		strBase = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;"
		strFilter = "(&(objectcategory=crossRef)(dnsRoot=" & strAppPart & "));"
		strAttrs = "msDS-NC-Replica-Locations;"
		strScope2 = "onelevel"
		set objConn = CreateObject("ADODB.Connection")
		objConn.Provider = "ADsDSOObject"
		objConn.Open "Active Directory Provider"
		set objRS = objConn.Execute(strBase & strFilter & strAttrs & strScope2)
		ServersOut=""
		if objRS.RecordCount <> 1 then
			wscript.echo "Did not find Application Partition: " & strAppPart
		else
			objRS.Movelast
			if objRS.Fields("msDS-NC-Replica-Locations").Properties.Count > 0 then
				wscript.echo "There are no replica servers for app partition: " & strAppPart
			else
				for each strNTDS in objRS.Fields("msDS-NC-Replica-Locations").Value
					'wscript.echo "-->" & strNTDS
					arrServerParts=split(strNTDS,",")
					CurServer=lcase(arrServerParts(1))
					CurServer=Replace(CurServer,"cn=","")
					If ServersOut = "" then
						ServersOut = CurServer
					else
						ServersOut = ServersOut & ";" & CurServer
					end if	
				next	
			end if	   
		end if
		set objRS=Nothing
		set objConn=Nothing

		szGetReplicaLocations = ServersOut
		
	End Function

	
	Function szGetDomainsInForest
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   strADsPath = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;" 

	   strFilter = "(&(objectcategory=Crossref)(netBIOSName=*));"
	       
	   strAttrs = "NCName;"
	   strScope2 = "SubTree"
	   
	   set objConn = CreateObject("ADODB.Connection")
	   objConn.Provider = "ADsDSOObject"
	   objConn.Open "Active Directory Provider"
	   set objRS = objConn.Execute(strADsPath & strFilter & strAttrs & strScope2)
	   objRS.MoveFirst
	   szDomainsOut=""
	   while not objRS.EOF
	      LDAPDomain = objRS.Fields(0).Value

	      DNSDomain = Replace(lcase(LDAPDomain),",dc=",".")
	      DNSDomain = Replace(lcase(DNSDomain),"dc=","")
	      
	      if szDomainsOut="" then
	         szDomainsOut=DNSDomain
	      else
	         szDomainsOut=szDomainsOut & ";" & DNSDomain
	      end if      
	      objRS.MoveNext
	   wend   
	
	   szGetDomainsInForest=szDomainsOut
	End Function

	Function szGetNETBIOSDomainsInForest
	   set objRootDSE = GetObject("LDAP://RootDSE")
	   strADsPath = "<LDAP://cn=Partitions," & objRootDSE.Get("ConfigurationNamingContext") & ">;" 

	   strFilter = "(&(objectcategory=Crossref)(netBIOSName=*));"
	       
	   strAttrs = "netBIOSName,NCName;"
	   strScope2 = "SubTree"
	   
	   set objConn = CreateObject("ADODB.Connection")
	   objConn.Provider = "ADsDSOObject"
	   objConn.Open "Active Directory Provider"
	   set objRS = objConn.Execute(strADsPath & strFilter & strAttrs & strScope2)
	   objRS.MoveFirst
	   szNetbiosOut=""
	   szDNSOut=""
	   while not objRS.EOF
	      NETBIOSDomain = objRS.Fields(0).Value
		  DNSDomain = objRS.Fields(1).Value
		  
  	      DNSDomain = Replace(lcase(DNSDomain),",dc=",".")
	      DNSDomain = Replace(lcase(DNSDomain),"dc=","")

 	      if szNetbiosOut="" then
	         szNetbiosOut=NetBIOSDomain
	         szDNSOut=DNSDomain
	      else
	         szNetbiosOut=szNetbiosOut & "," & NetBIOSDomain
	         szDNSOut=szDNSOut & "," & DNSDomain
	      end if      
	      objRS.MoveNext
	   wend   
	
	   szGetNETBIOSDomainsInForest=szNetbiosOut & ";" & szDNSOut
	End Function

	
	Function szConvertDNStoLDAP(CurDomain)
	   szConvertDNStoLDAP = "dc=" & replace(CurDomain,".",",dc=")
	end Function
	
	Function szConvertDNtoDomain(CurDN)
		szConvertDNtoDomain=""
		CurDN=lcase(CurDN)
		nAt=instr(CurDN,",dc=")
		szConvertDNtoDomain=right(CurDN,len(CurDN) - (nAt+3))
		szConvertDNtoDomain=replace(szConvertDNtoDomain,"dc=","")
		szConvertDNtoDomain=replace(szConvertDNtoDomain,",",".")
	end Function
	
Function szGetDCDomain(strDCName)
	'wscript.echo "-->In szGetDCDomain..." & strDCName
	on error resume next
	DomainFile = ADHC.strOutputDir 
	'wscript.echo "-->strOutputDir: " & ADHC.strOutputDir	
	if Right(DomainFile,1) <> "\" then
		DomainFile = DomainFile & "\"
	end if
	DomainFile = DomainFile & "ActiveDirectoryContext.ctx"
	err.Clear
	nAt = Instr(strDCName,".")
	if nAt > 1 then
		TargetServer = lcase(left(strDCName,nAt-1))
	else
		TargetServer = lcase(strDCName)
	end if	

	Set xmlDocIn = CreateObject("MSXML2.DOMDocument")
	xmlDocIn.async = false
	xmlDocIn.load DomainFile

	set xmlDomainData = xmlDocIn.SelectSingleNode("/DomainData")
	set xmlDomainDataDCs = xmlDomainData.selectNodes("DC")
	j=0
	strFQDN=""
	for j = 0 to xmlDomainDataDCs.Length - 1
		CurDC = lcase(xmlDomainDataDCs.item(j).GetAttribute("Name"))
		
		if CurDC=TargetServer then
			strFQDN = lcase(xmlDomainDataDCs.item(j).GetAttribute("FQDN"))
			nAt=Instr(strFQDN,".")
			if nAt>1 then
				strFQDN=right(strFQDN,len(strFQDN))
			end if
		end if
	next
	'wscript.echo "strFQDN: " & strFQDN
	
	szGetDCDomain=strFQDN

end function
	
Function szGetDCSite2(strDCName)

	szGetDCSite2=""
	on error resume next
	DomainFile = ADHC.strOutputDir 
	if Right(DomainFile,1) <> "\" then
		DomainFile = DomainFile & "\"
	end if
	DomainFile = DomainFile & "ActiveDirectoryContext.ctx"
	err.Clear
	nAt = Instr(strDCName,".")
	if nAt > 1 then
		TargetServer = lcase(left(strDCName,nAt-1))
	else
		TargetServer = lcase(strDCName)
	end if	

	Set xmlDocIn = CreateObject("MSXML2.DOMDocument")
	xmlDocIn.async = false
	xmlDocIn.load DomainFile

	set xmlDomainData = xmlDocIn.SelectSingleNode("/DomainData")
	set xmlDomainDataDCs = xmlDomainData.selectNodes("DC")
	j=0
	TargetSite=""
	for j = 0 to xmlDomainDataDCs.Length - 1
		CurDC = lcase(xmlDomainDataDCs.item(j).GetAttribute("Name"))
		
		if CurDC=TargetServer then
			TargetSite = lcase(xmlDomainDataDCs.item(j).GetAttribute("SiteName"))
			IsGC = lcase(xmlDomainDataDCs.item(j).GetAttribute("IsGC"))
			
			arrTemp=Split(TargetSite,",")
			if ubound(arrTemp) > 0 then
				TargetSite=arrTemp(0)
				TargetSite=Replace(TargetSite,"cn=","")
			end if
		end if
	next
	szGetDCSite2=TargetSite

end Function    

   
	Function szGetServersInSite(strSiteName)
		on error resume next
		Set objRootDSE = GetObject("LDAP://RootDSE")
		strConfigurationNC = objRootDSE.Get("configurationNamingContext")
		strServersPath = "cn=Servers," & strSiteName & ",cn=Sites," & strConfigurationNC
		Set objServersContainer = GetObject("LDAP://" & strServersPath)
		if err.number<>0 then
			szGetServersInSite=""
		end if 
		For Each objServer In objServersContainer

			'See if there is an NTDS Setting object under server to filter out non-DCs
			on error resume next
			TargetObject="LDAP://" & "cn=ntds settings," & objServer.Name & "," & strServersPath

			set objNTDS = GetObject(TargetObject)
			if err.number<>0 then
				'This server is not a DC.
			else   
			    ServerName = replace(lcase(objServer.Name),"cn=","")
			    if szGetServersInSite <> "" then
	                szGetServersInSite = szGetServersInSite & ";" & ServerName
	            else
					szGetServersInSite = szGetServersInSite & ServerName    
				end if	

			end if 'Is a DC
		Next

		set objRootDSE = Nothing
		set objServersContainer = Nothing
   

	end Function
   
	
	Function szGetForestFunctionalLevel
		on error resume next
		Set RootDSE = GetObject("LDAP://RootDSE")
		TargetObject = "LDAP://CN=partitions," & RootDSE.Get("configurationNamingContext")
		set objBehavior = GetObject(TargetObject)
		objBehavior.GetInfo
		FFL = objBehavior.Get("msDS-Behavior-Version")
		if err.number<>0 then
		   FFLOut = "Windows 2000"
		else	
		
			select case FFL
				case 0
					FFLOut = "Windows 2000"
				case 1
					FFLOut = "Windows 2003 Interim"
				case 2   
					FFLOut = "Windows 2003 Native"
			end select
		end if	
		szGetForestFunctionalLevel = FFLOut
		set objBehavior = nothing
		set RootDSE = nothing
	End Function
	
	Function ConvertRepadminDateToLocal(strDateTime)
		'wscript.echo "RepadminDate: " & strDateTime
		ConvertRepadminDateToLocal=""
		if strDateTime="" or strDateTime="n/a" then
			exit function
		end if
		   
			'2006-06-21 15:54:57
			'wscript.echo "strDateTime=" & strDateTime
		   
		arrDateTime=split(strDateTime," ")
		arrDate=Split(arrDateTime(0),"-")
		arrTime=Split(arrDateTime(1),":")
		   
		strYear=arrDate(0)
		strMonth=arrDate(1)
		strDate=arrDate(2)
		strHour=arrTime(0)
		strMinute=arrTime(1)
		strSecond=arrTime(2)
		   
		ConvertRepadminDateToLocal=DateSerial(strYear,strMonth,strDate) & " " & TimeSerial(strHour,strMinute,strSecond)

	end function
	
	Function szGetDomainPDC(DomainIn)
	
		'Set WSHNetwork = CreateObject("WScript.Network")
		
		Set ADOconnObj = CreateObject("ADODB.Connection")
		ADOconnObj.Provider = "ADSDSOObject"
		ADOconnObj.Open "ADs Provider"

		'PDC FSMO
		bstrADOQueryString = "<LDAP://" & DomainIn & ">;(&(objectClass=domainDNS)(fSMORoleOwner=*));adspath;subtree"
		Set RootDom = GetObject("LDAP://RootDSE")
		on error resume next
		Set RSObj = ADOconnObj.Execute(bstrADOQueryString)
		if err.number<>0 then
		   szGetDomainPDC=""
		   wscript.echo "ERROR: Couldn't contact PDC for " & DomainIn & "  Error: " & err.number
		   exit function
		end if

		Set FSMOobj = GetObject(RSObj.Fields(0).Value)
		Set CompNTDS = GetObject("LDAP://" & FSMOobj.fSMORoleOwner)
		Set Computer = GetObject(CompNTDS.Parent)
		szGetDomainPDC=Computer.dnsHostName & ";" & Computer.ServerReference

	End Function

	Function GetDCList(DomainList)

		Set objRootDSE = GetObject("LDAP://RootDSE")
		strConfigurationNC = objRootDSE.Get("configurationNamingContext")

		Const ADS_SCOPE_SUBTREE = 2

		Set objConnection = CreateObject("ADODB.Connection")
		Set objCommand = CreateObject("ADODB.Command")
		objConnection.Provider = "ADsDSOObject"
		objConnection.Open "Active Directory Provider"
		Set objCOmmand.ActiveConnection = objConnection

		LDAPRootDomain = replace(lcase(strConfigurationNC),"cn=configuration,","")
 
		objCommand.CommandText = "Select distinguishedName from 'LDAP://cn=Sites," & strConfigurationNC & "' where objectClass='nTDSDSA'" 
		objCommand.Properties("Page Size") = 1000
		objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 

		Set objRecordSet = objCommand.Execute
		objRecordSet.MoveFirst
        strTmpDCList=""

		Do Until objRecordSet.EOF
			DCSiteObject=objRecordSet.Fields("distinguishedName").Value
		    'Wscript.Echo "DC Site Object: " & DCSiteObject
        
			Set DcRefObj = GetObject("LDAP://" & replace(lcase(DCSiteObject),"cn=ntds settings,",""))
		
			DomainControllerDN = DcRefObj.Get("ServerReference")
			
			on error resume next
			if err.number<>0 then
			   'Server Reference is blank; ran into this issue with bad replication for a new DC - DNS issues caused it.
				wscript.echo "ERROR: ServerReference attribute is blank. for "
				wscript.quit
			end if

		    
			DCDNSHostname = DcRefObj.Get("DnsHostName")
            nAt=Instr(lcase(DomainControllerDN),",dc=")
            tmpLDAP=right(DomainControllerDN,len(DomainControllerDN)-(nAt+3))
            tmpLDAP=replace(lcase(tmpLDAP),",dc=",".")
            'wscript.echo "tmp=" & tmpLDAP

			FirstDot = Instr(DCDNSHostname,".")
			DomainName = right(DCDNSHostname,len(DCDNSHostname)-FirstDot)
            
            if lcase(tmpLDAP)=lcase(DomainList) then
				if strTmpDCList="" then
				   strTmpDCList = strTmpDCList & DCDNSHostname
				else
				   strTmpDCList = strTmpDCList & ";" & DCDNSHostname
				end if   
			end if
    
			objRecordSet.MoveNext
		Loop
		GetDCList=strTmpDCList
		

	end function
	
	Function szGetForestRootDomain()
		Set objRootDSE = GetObject("LDAP://RootDSE")
		strConfigurationNC = objRootDSE.Get("configurationNamingContext")
		szGetForestRootDomain = replace(lcase(strConfigurationNC),"cn=configuration,","")
	end function	

	Function GetForestDCs()
	    
		Set objRootDSE = GetObject("LDAP://RootDSE")
		strConfigurationNC = objRootDSE.Get("configurationNamingContext")
        
		Const ADS_SCOPE_SUBTREE = 2

		Set objConnection = CreateObject("ADODB.Connection")
		Set objCommand = CreateObject("ADODB.Command")
		objConnection.Provider = "ADsDSOObject"
		objConnection.Open "Active Directory Provider"
		Set objCOmmand.ActiveConnection = objConnection

		LDAPRootDomain = replace(lcase(strConfigurationNC),"cn=configuration,","")
 
		objCommand.CommandText = "Select distinguishedName from 'LDAP://cn=Sites," & strConfigurationNC & "' where objectClass='nTDSDSA'" 
		objCommand.Properties("Page Size") = 1000
		objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 

		Set objRecordSet = objCommand.Execute
		objRecordSet.MoveFirst
        strTmpDCList=""
		on error resume next

		Do Until objRecordSet.EOF
			DCSiteObject=objRecordSet.Fields("distinguishedName").Value
		    
            err.Clear
			Set DcRefObj = GetObject("LDAP://" & replace(lcase(DCSiteObject),"cn=ntds settings,",""))
			if err.number<>0 then
			   wscript.echo "  DCRefObj Err.Description=" & Err.Description   
			end if
			
			err.Clear
			DomainControllerDN = DcRefObj.Get("ServerReference")
			if err.number<>0 then
			   wscript.echo "  DomainControllerDN Err.Description=" & Err.Description   
			end if
			
			err.Clear
			DCDNSHostname = DcRefObj.Get("DnsHostName")
			if err.number<>0 then
			   wscript.echo "  DCDNSHostname Err.Description=" & Err.Description   
			end if
			
			if strTmpDCList="" then
			   strTmpDCList = strTmpDCList & DCDNSHostname
			else
			   strTmpDCList = strTmpDCList & ";" & DCDNSHostname
			end if   
			FirstDot = Instr(DCDNSHostname,".")
			DomainName = right(DCDNSHostname,len(DCDNSHostname)-FirstDot)
			objRecordSet.MoveNext
		Loop
		GetForestDCs=strTmpDCList
	   
	end function
	
	Function IsGC(strDCName)
		IsGC=False
       
		On Error resume next
		
		'Get GC Status 
		Const NTDSDSA_OPT_IS_GC = 1
 
		Set objRootDSE = GetObject("LDAP://" & strDCName & "/rootDSE")
		strDsServiceDN = objRootDSE.Get("dsServiceName")

		Set objDsRoot  = GetObject("LDAP://" & strDCName & "/" & strDsServiceDN)
		intOptions = objDsRoot.Get("options")
 
		If intOptions And NTDSDSA_OPT_IS_GC Then
			IsGC=true
		Else
			IsGC=false
		End If

	end Function

	Function GetDomainNC(strDCName)

		On Error resume next

		nAt=instr(strDCName,".")
		SiteName = szGetDCSite2(strDCName)
		
		'Get GC Status 
		Set objRootDSE = GetObject("LDAP://rootDSE")
		ConfigNC=objRootDSE.Get("ConfigurationNamingContext")
        Target = "LDAP://CN=ntds settings,CN=" & strDCName & ",CN=Servers,CN=" & SiteName & ",CN=Sites," & ConfigNC
		Set objDsRoot  = GetObject(Target)
		if err.number<>0 then
			wscript.echo "Target: " & Target
		    wscript.echo "Error: " & err.Description
		end if
		
		for each prop in objDsRoot.GetEx("hasMasterNCs")
			if left(lcase(prop),3) = "dc=" then
			    'wscript.echo "Prop: " & prop
			    GetDomainNC = prop
			end if    
		next

	end Function	


	Function GetMasterNCs(strDCName)

		On Error resume next

		nAt=instr(strDCName,".")
		SiteName = szGetDCSite2(strDCName)
		
		
		Set objRootDSE = GetObject("LDAP://rootDSE")
		ConfigNC=objRootDSE.Get("ConfigurationNamingContext")
        Target = "LDAP://CN=ntds settings,CN=" & strDCName & ",CN=Servers,CN=" & SiteName & ",CN=Sites," & ConfigNC
		Set objDsRoot  = GetObject(Target)
		if err.number<>0 then
			wscript.echo "Target: " & Target
		    wscript.echo "Error: " & err.Description
		end if
		
		strMasterNCs=""		
		for each prop in objDsRoot.GetEx("msDS-hasMasterNCs")
			if strMasterNCs="" then
				strMasterNCs=prop
			else
				strMasterNCs=strMasterNCs & ";" & prop
			end if	
		next
		
		if strMasterNCs="" then
			'Windows 2000 DC
			for each prop in objDsRoot.GetEx("hasMasterNCs")
				if strMasterNCs="" then
					strMasterNCs=prop
				else
					strMasterNCs=strMasterNCs & ";" & prop
				end if	
			next
		end if
		GetMasterNCs = strMasterNCs
		
	end Function	



Function IsGC2(strDCName)
'wscript.echo "strDCName: " & strDCName
	on error resume next
	DomainFile = ADHC.strOutputDir 
	if Right(DomainFile,1) <> "\" then
		DomainFile = DomainFile & "\"
	end if
	DomainFile = DomainFile & "ActiveDirectoryContext.ctx"
	err.Clear
	nAt = Instr(strDCName,".")
	if nAt > 1 then
		TargetServer = lcase(left(strDCName,nAt-1))
	else
		TargetServer = lcase(strDCName)
	end if	
'wscript.echo "DomainFile: " & DomainFile
	
	Set xmlDocIn = CreateObject("MSXML2.DOMDocument")
	xmlDocIn.async = false
	xmlDocIn.load DomainFile

	set xmlDomainData = xmlDocIn.SelectSingleNode("/DomainData")
	set xmlDomainDataDCs = xmlDomainData.selectNodes("DC")
	j=0
	IsGC2=""
	for j = 0 to xmlDomainDataDCs.Length - 1
		CurDC = lcase(xmlDomainDataDCs.item(j).GetAttribute("Name"))
'wscript.echo "CurDC: " & CurDC		
		if CurDC=TargetServer then
			strIsGC = lcase(xmlDomainDataDCs.item(j).GetAttribute("IsGC"))
			if lcase(strIsGC) = "true" then
				IsGC2=true
			end if
			if lcase(strIsGC) = "false" then
				IsGC2=false
			end if	
		end if
	next
	
end Function	
	
'**************************
'*** Get OS Description ***
'**************************
Function GetOSDescription(strComputer)
	wscript.echo "Getting OS Description for " & strComputer
	GetOSDescription="n/a"
	err.Clear
	on error resume next
	Set objWMIService2 = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer & "\root\cimv2")
	if Err.number<>0 then
		'Do Nothing
	else
		Set colOperatingSystems = objWMIService2.ExecQuery("Select Name from Win32_OperatingSystem","WQL",48)
		For Each objOperatingSystem In colOperatingSystems

			arrNames=Split(objOperatingSystem.Name,"|")
			if ubound(arrNames) > 0 then
				OSNameOut=arrNames(0)
			else
				OSNameOut="n/a"
			end if
		Next
	End If 'Err<>0

			
	set objWMIService2 = Nothing
	set colItems = Nothing
	GetOSDescription=OSNameOut
end Function

'************************
'*** Get System Drive ***
'************************
Function GetSystemDir(strComputer)
	GetSystemDir=""
	err.Clear
    on error resume next  
    Set objWMIService2 = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer & "\root\cimv2")
    if Err.number <> 0 then
		wscript.echo "WMI Error reading System Drive: " & err.Description
	else	
		Set colOperatingSystems = objWMIService2.ExecQuery("Select SystemDirectory from Win32_OperatingSystem","WQL",48)
		For Each objOperatingSystem In colOperatingSystems
			'Get SystemDrive
			SystemDir = objOperatingSystem.SystemDirectory
		Next
	end if	
	GetSystemDir=SystemDir
	set objWMIService2 = Nothing
end Function

	
End Class
