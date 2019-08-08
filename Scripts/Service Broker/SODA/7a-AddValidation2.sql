
:CONNECT localhost\SQLDEV02

USE TestDB
GO

-- Literal schema
CREATE XML SCHEMA COLLECTION dbo.InventoryReq_xsd
AS
'<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://www.company.com/inventoryRequest">
  <xs:element name="InventoryReq">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="order" type="xs:integer" />
        <xs:element name="product" type="xs:integer" />
        <xs:element name="units" type="xs:integer" />
        <xs:element name="status" type="xs:string" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>'
GO


IF EXISTS 
  (SELECT * FROM sys.service_contracts WHERE name = 'InvContract')
    DROP CONTRACT InvContract;
GO

IF EXISTS 
  (SELECT * FROM sys.service_message_types WHERE name = 'InvRequestMsg')
    DROP MESSAGE TYPE InvRequestMsg;
GO

IF EXISTS 
  (SELECT * FROM sys.service_message_types WHERE name = 'InvResponseMsg')
    DROP MESSAGE TYPE InvResponseMsg;
GO

-- 
-- CREATE the MESSAGE TYPES and CONTRACT for this program
-- CREATE the QUEUES and SERVICES for this program
--

-- define two message types with XML validation
CREATE MESSAGE TYPE InvRequestMsg 
VALIDATION = VALID_XML WITH SCHEMA COLLECTION dbo.InventoryReq_xsd
GO

CREATE MESSAGE TYPE InvResponseMsg
VALIDATION = WELL_FORMED_XML
GO

-- define a contract between the two sides
CREATE CONTRACT InvContract
 (InvRequestMsg SENT BY INITIATOR,
  InvResponseMsg SENT BY TARGET)
GO

-- Now change the service

ALTER SERVICE TestTarget
  (ADD CONTRACT InvContract, 
   DROP CONTRACT [DEFAULT]
  )
GO

-- To turn off the validation
/*
ALTER SERVICE TestTarget
  (ADD CONTRACT [DEFAULT], 
   DROP CONTRACT InvContract
  )
GO
*/