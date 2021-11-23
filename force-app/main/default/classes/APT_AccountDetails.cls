/**
    Description: It will used to fetch detail about Cash Account, Sub Account and Charge Account 
    Created By: Sagar Jogi
    Created Date: 14th July, 2016
    Last Modified By:
    Last Modified Date:
**/
public class APT_AccountDetails {

    public List<APT_Cash_Account__c> cashAccList { get; set; }
    public List<APT_Sub_Account__c> subAccList { get; set; }
    public List<APT_Charge_Account__c> chargeAccList { get; set; }
    
    public List<Schema.FieldSetMember> cashAccFieldList { get; set; }
    public List<Schema.FieldSetMember> subAccFieldList { get; set; }
    public List<Schema.FieldSetMember> chargeAccFieldList { get; set; }
    
    public String accId {get; set;}
    
    /**
        Constructor
    **/    
    public APT_AccountDetails(ApexPages.StandardController controller) {
        cashAccList = new List<APT_Cash_Account__c>();
        subAccList = new List<APT_Sub_Account__c> ();
        chargeAccList = new List<APT_Charge_Account__c> ();
        
        cashAccFieldList = new List<Schema.FieldSetMember> ();
        subAccFieldList = new List<Schema.FieldSetMember> ();
        chargeAccFieldList = new List<Schema.FieldSetMember> ();
        
        accId = Apexpages.Currentpage().getparameters().get(APT_Constants.PARAM_ID);
        cashAccFieldList = getFieldsFromFieldSet (APT_Constants.SOQL_CASHACCOUNT_OBJECT, APT_Constants.FIELDSETNAME);
        subAccFieldList = getFieldsFromFieldSet (APT_Constants.SOQL_SUBACCOUNT_OBJECT , APT_Constants.FIELDSETNAME);
        chargeAccFieldList = getFieldsFromFieldSet(APT_Constants.SOQL_CHARGEACCOUNT_OBJECT ,APT_Constants.FIELDSETNAME);
        
        cashAccList = Database.query(getQuery(cashAccFieldList,APT_Constants.SOQL_CASHACCOUNT_OBJECT));
        subAccList = Database.query(getQuery(subAccFieldList,APT_Constants.SOQL_SUBACCOUNT_OBJECT));
        chargeAccList = Database.query(getQuery(chargeAccFieldList, APT_Constants.SOQL_CHARGEACCOUNT_OBJECT));
    }

    /**
        This method will return fieldset Member's list
    **/
    private List<Schema.FieldSetMember> getFieldsFromFieldSet (String accountName, String fieldSetName) {
        Map<String, Schema.SObjectType> allObjects= Schema.getGlobalDescribe();
        Schema.SObjectType objType = allObjects.get(accountName);
        Schema.DescribeSObjectResult dfield = objType.getDescribe();
        List<Schema.FieldSetMember> FsMap =  dfield.fieldSets.getMap().get(fieldSetName).getFields(); 
        return FsMap;
    }
    
    /**
        This method will return dynamic SOQL query using fieldset
    **/
    private String getQuery (List<Schema.FieldSetMember> fieldSetMember, String AccountName) {
       
        String query = APT_Constants.SOQL_SELECT;
        for(Schema.FieldSetMember f : fieldSetMember) {
            query += f.getFieldPath() + APT_Constants.SEPERATOR_COMMA_SPACE;
        }
        query += APT_Constants.QUERYSTRING_ACCOUNT +AccountName+ APT_Constants.WHERECLAUSE_ACCOUNT+' ORDER BY LastModifiedDate DESC';
        return query;
    }
    
    /**
        Cancel Method
    **/
    public pagereference cancel () {
       Pagereference pageref = new pagereference(APT_Constants.SEPERATOR_BACKWARD_SLASH+accId);
        pageref.setredirect(true);
        return pageref;
    }

    /**
        Save Method
    **/    
    public void save () {
        if(cashAccList != null) {
            update cashAccList;
        } else {
        
        }
        if(subAccList != null) {
            update subAccList;
        } else {
        
        }
        if(chargeAccList != null) {
            update chargeAccList;
        } else {
        
        }
    }
    
    /**
        Method to export all data.
    **/     
    public pagereference export () {
        save();
        Pagereference pageref = new pagereference(APT_Constants.EXPORTACCOUNT_URL+accId);
        return pageref;
    }
    
}