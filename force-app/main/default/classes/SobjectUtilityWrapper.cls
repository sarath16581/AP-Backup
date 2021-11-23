/*@File Name		: SobjectUtilityWrapper
@Description 		: Wrapper class to hold record information grouped by
@Author				: Ramtej Juloori
@Created			: 08/08/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/ 
public with sharing class SobjectUtilityWrapper {
	public class sObjectWrapper{
        public List<ObjectClass> ObjectClassList {get; set;}
    }
    
    public class ObjectClass{
        @AuraEnabled public string objectLabel {get; set;}
        @AuraEnabled public string objectAPIName {get; set;}
        //hold list of field labels and API names
        @AuraEnabled public List<fieldClass> fieldClassList {get; set;}
        //hold set of field labels
        @AuraEnabled public set<string> fieldLabelSet {get; set;}
        //hold of list of records which includes field label, API name and value
        @AuraEnabled public List<record> record {get; set;}
    }
    
    //Hold field level info
    public class fieldClass{
        @AuraEnabled public string fieldLabel {get; set;}
        @AuraEnabled public string fieldAPIName {get; set;}
        @AuraEnabled public object fieldValue {get; set;}
        @AuraEnabled public Id fieldValueId {get; set;}
        @AuraEnabled public string fieldValueName {get; set;}
    }
     
    public class record{
        @AuraEnabled public List<fieldClass> recordMap {get; set;}
    }
}