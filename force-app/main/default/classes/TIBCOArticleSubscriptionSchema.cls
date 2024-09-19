/***
 * @author Nathan Franklin
 * @date 2024-05-16
 * @changelog
 */
public class TIBCOArticleSubscriptionSchema {
	private static final String s_ns0 = 'urn:sobject.enterprise.soap.sforce.com';

	//Extends urn:sobject.enterprise.soap.sforce.com:sObject
	//Warning: '<xsd:any>' element type has been changed to dataType List<DOM.XmlNode> called anyElement
	public class AggregateResult {
		public String[] fieldsToNull;
		public String Id;
		private transient String[] fieldsToNull_type_info = new String[]{'fieldsToNull',s_ns0,'string','0','-1','true'};
		private transient String[] Id_type_info = new String[]{'Id',s_ns0,'ID','1','1','true'};
		public List<DOM.XmlNode> anyElement;
		private transient String[] anyElement_type_info = new String[]{'anyElement','urn:sobject.enterprise.soap.sforce.com','List<DOM.XmlNode>','0','1','true'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'fieldsToNull','Id','anyElement'};
	}

	public class Case_x {
		public String[] fieldsToNull;
		public String Id;
		private transient String[] fieldsToNull_type_info = new String[]{'fieldsToNull',s_ns0,'string','0','-1','true'};
		private transient String[] Id_type_info = new String[]{'Id',s_ns0,'ID','1','1','true'};
		public String ArticleCount_xc;
		public String CaseNumber;
		public String EventCode_xc;
		public String FacilityOrOutletWCC_xc;
		public DateTime LastModifiedDate;
		public String OwnerUserName_xc;
		public String ReferenceID_xc;
		public String Subject;
		public String Type_x;
		private transient String[] ArticleCount_xc_type_info = new String[]{'ArticleCount__c',s_ns0,'string','0','1','true'};
		private transient String[] CaseNumber_type_info = new String[]{'CaseNumber',s_ns0,'string','0','1','true'};
		private transient String[] EventCode_xc_type_info = new String[]{'EventCode__c',s_ns0,'string','0','1','true'};
		private transient String[] FacilityOrOutletWCC_xc_type_info = new String[]{'FacilityOrOutletWCC__c',s_ns0,'string','0','1','true'};
		private transient String[] LastModifiedDate_type_info = new String[]{'LastModifiedDate',s_ns0,'dateTime','0','1','true'};
		private transient String[] OwnerUserName_xc_type_info = new String[]{'OwnerUserName__c',s_ns0,'string','0','1','true'};
		private transient String[] ReferenceID_xc_type_info = new String[]{'ReferenceID__c',s_ns0,'string','0','1','true'};
		private transient String[] Subject_type_info = new String[]{'Subject',s_ns0,'string','0','1','true'};
		private transient String[] Type_x_type_info = new String[]{'Type',s_ns0,'string','0','1','true'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'fieldsToNull','Id','ArticleCount_xc','CaseNumber','EventCode_xc','FacilityOrOutletWCC_xc','LastModifiedDate','OwnerUserName_xc','ReferenceID_xc','Subject','Type_x'};
	}

	public class sObject_x {
		public String[] fieldsToNull;
		public String Id;
		private transient String[] fieldsToNull_type_info = new String[]{'fieldsToNull',s_ns0,'string','0','-1','true'};
		private transient String[] Id_type_info = new String[]{'Id',s_ns0,'ID','1','1','true'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'fieldsToNull','Id'};
	}
}