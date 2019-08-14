//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:2.0.50727.4927
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Microsoft.SqlRap.Client.TestCases.SysConfiguration {
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Xml;
    using System.Xml.Schema;
    using System.Xml.Serialization;
    using System.Runtime.InteropServices;
    using Microsoft.Rapid.Client.Core.Collections;
    
    
    // CodeType: Row
    //     SchemaTypeName: Row
    //     SchemaNamespace: 
    // 
    // <Row />
    [System.Runtime.InteropServices.GuidAttribute("2748818c-5dbc-330c-a331-ec8c48310c70")]
    [System.Xml.Serialization.XmlRootAttribute("Row", Namespace="")]
    public partial class Row : System.ICloneable {
        
        private string m_ruleName;
        
        private string m_serverName;
        
        private string m_instanceName;
        
        private string m_configurationName;
        
        private string m_targetDefaultValue;
        
        private string m_setValue;
        
        private string m_runValue;
        
        [System.Xml.Serialization.XmlAttributeAttribute("RuleName")]
        public string RuleName {
            get {
                return this.m_ruleName;
            }
            set {
                this.m_ruleName = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("ServerName")]
        public string ServerName {
            get {
                return this.m_serverName;
            }
            set {
                this.m_serverName = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("InstanceName")]
        public string InstanceName {
            get {
                return this.m_instanceName;
            }
            set {
                this.m_instanceName = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("ConfigurationName")]
        public string ConfigurationName {
            get {
                return this.m_configurationName;
            }
            set {
                this.m_configurationName = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("TargetDefaultValue")]
        public string TargetDefaultValue {
            get {
                return this.m_targetDefaultValue;
            }
            set {
                this.m_targetDefaultValue = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("SetValue")]
        public string SetValue {
            get {
                return this.m_setValue;
            }
            set {
                this.m_setValue = value;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("RunValue")]
        public string RunValue {
            get {
                return this.m_runValue;
            }
            set {
                this.m_runValue = value;
            }
        }
        
        public Row Clone() {
            Row clone = new Row();
            if ((null != this.m_ruleName)) {
                clone.m_ruleName = ((string)(((System.ICloneable)(this.m_ruleName)).Clone()));
            }
            if ((null != this.m_serverName)) {
                clone.m_serverName = ((string)(((System.ICloneable)(this.m_serverName)).Clone()));
            }
            if ((null != this.m_instanceName)) {
                clone.m_instanceName = ((string)(((System.ICloneable)(this.m_instanceName)).Clone()));
            }
            if ((null != this.m_configurationName)) {
                clone.m_configurationName = ((string)(((System.ICloneable)(this.m_configurationName)).Clone()));
            }
            if ((null != this.m_targetDefaultValue)) {
                clone.m_targetDefaultValue = ((string)(((System.ICloneable)(this.m_targetDefaultValue)).Clone()));
            }
            if ((null != this.m_setValue)) {
                clone.m_setValue = ((string)(((System.ICloneable)(this.m_setValue)).Clone()));
            }
            if ((null != this.m_runValue)) {
                clone.m_runValue = ((string)(((System.ICloneable)(this.m_runValue)).Clone()));
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
        
        public static Row Deserialize(string input) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Row Deserialize(string input, System.Xml.Schema.XmlSchema schema) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, schema);
            return output;
        }
        
        public static Row Deserialize(System.Uri input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Row Deserialize(System.Uri input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, schema);
            return output;
        }
        
        public static Row Deserialize(System.Xml.XmlReader input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Row Deserialize(System.Xml.XmlReader input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Row output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Row>(input, schema);
            return output;
        }
        
        public static string Serialize(Row input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Row));
                serializer.Serialize(xmlWriter, input);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public static void Serialize(Row input, System.Xml.XmlWriter writer) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Row));
            serializer.Serialize(writer, input);
        }
        
        public virtual string Serialize() {
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Row));
                serializer.Serialize(xmlWriter, this);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public virtual void Serialize(System.Xml.XmlWriter writer) {
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Row));
            serializer.Serialize(writer, this);
        }
    }
    
    // CodeType: RowCollection
    //     SchemaTypeName: Row
    //     SchemaNamespace: 
    // 
    // <Row />
    [System.Runtime.InteropServices.GuidAttribute("cc5467b2-a6eb-39c0-b55d-8122e9092862")]
    [System.Runtime.InteropServices.ClassInterfaceAttribute(System.Runtime.InteropServices.ClassInterfaceType.None)]
    [System.Runtime.InteropServices.ComDefaultInterfaceAttribute(typeof(System.Collections.IEnumerable))]
    public class RowCollection : UberCollection<Row>, System.ICloneable {
        
        public RowCollection Clone() {
            RowCollection clone = new RowCollection();
            for (int i = 0; (i < this.Count); i = (i + 1)) {
                clone.Add(this[i].Clone());
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
    }
    
    // CodeType: DataRoot
    //     SchemaTypeName: DataRoot
    //     SchemaNamespace: 
    // 
    // <DataRoot />
    [System.Runtime.InteropServices.GuidAttribute("dff284e8-2ff7-3b2c-b516-cba27e5ad6c6")]
    [System.Xml.Serialization.XmlRootAttribute("DataRoot", Namespace="")]
    public partial class DataRoot : System.ICloneable {
        
        private RowCollection m_rowCollection = new RowCollection();
        
        private string m_target;
        
        [System.Xml.Serialization.XmlElementAttribute(ElementName="Row", Namespace="")]
        public RowCollection RowCollection {
            get {
                return this.m_rowCollection;
            }
        }
        
        [System.Xml.Serialization.XmlAttributeAttribute("Target")]
        public string Target {
            get {
                return this.m_target;
            }
            set {
                this.m_target = value;
            }
        }
        
        public DataRoot Clone() {
            DataRoot clone = new DataRoot();
            if ((null != this.m_rowCollection)) {
                clone.m_rowCollection = ((RowCollection)(((System.ICloneable)(this.m_rowCollection)).Clone()));
            }
            if ((null != this.m_target)) {
                clone.m_target = ((string)(((System.ICloneable)(this.m_target)).Clone()));
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
        
        public static DataRoot Deserialize(string input) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static DataRoot Deserialize(string input, System.Xml.Schema.XmlSchema schema) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, schema);
            return output;
        }
        
        public static DataRoot Deserialize(System.Uri input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static DataRoot Deserialize(System.Uri input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, schema);
            return output;
        }
        
        public static DataRoot Deserialize(System.Xml.XmlReader input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static DataRoot Deserialize(System.Xml.XmlReader input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            DataRoot output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<DataRoot>(input, schema);
            return output;
        }
        
        public static string Serialize(DataRoot input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(DataRoot));
                serializer.Serialize(xmlWriter, input);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public static void Serialize(DataRoot input, System.Xml.XmlWriter writer) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(DataRoot));
            serializer.Serialize(writer, input);
        }
        
        public virtual string Serialize() {
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(DataRoot));
                serializer.Serialize(xmlWriter, this);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public virtual void Serialize(System.Xml.XmlWriter writer) {
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(DataRoot));
            serializer.Serialize(writer, this);
        }
    }
    
    // CodeType: DataRootCollection
    //     SchemaTypeName: DataRoot
    //     SchemaNamespace: 
    // 
    // <DataRoot />
    [System.Runtime.InteropServices.GuidAttribute("bc71df98-2e8b-3c35-bd42-0d270ff6507b")]
    [System.Runtime.InteropServices.ClassInterfaceAttribute(System.Runtime.InteropServices.ClassInterfaceType.None)]
    [System.Runtime.InteropServices.ComDefaultInterfaceAttribute(typeof(System.Collections.IEnumerable))]
    public class DataRootCollection : UberCollection<DataRoot>, System.ICloneable {
        
        public DataRootCollection Clone() {
            DataRootCollection clone = new DataRootCollection();
            for (int i = 0; (i < this.Count); i = (i + 1)) {
                clone.Add(this[i].Clone());
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
    }
    
    // CodeType: Collated
    //     SchemaTypeName: Collated
    //     SchemaNamespace: 
    // 
    // <Collated />
    [System.Runtime.InteropServices.GuidAttribute("84a9a2a0-5094-300e-895d-14774c960afd")]
    [System.Xml.Serialization.XmlRootAttribute("Collated", Namespace="")]
    public partial class Collated : System.ICloneable {
        
        private DataRootCollection m_dataRootCollection = new DataRootCollection();
        
        [System.Xml.Serialization.XmlElementAttribute(ElementName="DataRoot", Namespace="")]
        public DataRootCollection DataRootCollection {
            get {
                return this.m_dataRootCollection;
            }
        }
        
        public Collated Clone() {
            Collated clone = new Collated();
            if ((null != this.m_dataRootCollection)) {
                clone.m_dataRootCollection = ((DataRootCollection)(((System.ICloneable)(this.m_dataRootCollection)).Clone()));
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
        
        public static Collated Deserialize(string input) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Collated Deserialize(string input, System.Xml.Schema.XmlSchema schema) {
            if ((string.IsNullOrEmpty(input) == true)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, schema);
            return output;
        }
        
        public static Collated Deserialize(System.Uri input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Collated Deserialize(System.Uri input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, schema);
            return output;
        }
        
        public static Collated Deserialize(System.Xml.XmlReader input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, "SysConfiguration.xsd");
            return output;
        }
        
        public static Collated Deserialize(System.Xml.XmlReader input, System.Xml.Schema.XmlSchema schema) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((schema == null)) {
                throw new System.ArgumentNullException("schema");
            }
            Collated output = null;
            output = Microsoft.Rapid.Client.Core.SerializerUtil.Deserialize<Collated>(input, schema);
            return output;
        }
        
        public static string Serialize(Collated input) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Collated));
                serializer.Serialize(xmlWriter, input);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public static void Serialize(Collated input, System.Xml.XmlWriter writer) {
            if ((input == null)) {
                throw new System.ArgumentNullException("input");
            }
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Collated));
            serializer.Serialize(writer, input);
        }
        
        public virtual string Serialize() {
            System.Text.StringBuilder stringBuilder = new System.Text.StringBuilder();
            System.Xml.XmlWriter xmlWriter = System.Xml.XmlWriter.Create(stringBuilder, Microsoft.Rapid.Client.Core.RapidClientSchemas.XmlFragmentWriterSettings);
            try {
                System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Collated));
                serializer.Serialize(xmlWriter, this);
                return stringBuilder.ToString();
            }
            finally {
                xmlWriter.Close();
                stringBuilder = null;
                xmlWriter = null;
            }
        }
        
        public virtual void Serialize(System.Xml.XmlWriter writer) {
            if ((writer == null)) {
                throw new System.ArgumentNullException("writer");
            }
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(typeof(Collated));
            serializer.Serialize(writer, this);
        }
    }
    
    // CodeType: CollatedCollection
    //     SchemaTypeName: Collated
    //     SchemaNamespace: 
    // 
    // <Collated />
    [System.Runtime.InteropServices.GuidAttribute("f846be61-788e-382a-b373-36520395f18a")]
    [System.Runtime.InteropServices.ClassInterfaceAttribute(System.Runtime.InteropServices.ClassInterfaceType.None)]
    [System.Runtime.InteropServices.ComDefaultInterfaceAttribute(typeof(System.Collections.IEnumerable))]
    public class CollatedCollection : UberCollection<Collated>, System.ICloneable {
        
        public CollatedCollection Clone() {
            CollatedCollection clone = new CollatedCollection();
            for (int i = 0; (i < this.Count); i = (i + 1)) {
                clone.Add(this[i].Clone());
            }
            return clone;
        }
        
        object System.ICloneable.Clone() {
            return this.Clone();
        }
    }
}