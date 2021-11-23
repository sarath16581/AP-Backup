/**
    Description: This controller will export all Accounts of 'Charge Account','Sub Account' and 'Cash Account'.
    Created By: Sagar Jogi
    Created Date: 14th July, 2016
    Last Modified By:
    Last Modified Date:
**/
public class APT_exportAccountDetailCtrl {

    public List<APT_Cash_Account__c> cashAccList { get; set; }
    public List<APT_Sub_Account__c> subAccList { get; set; }
    public List<APT_Charge_Account__c> chargeAccList { get; set; }
    public List<APT_Agreement_Lodgement_Point__c> agreementLPList {get;set;}
    
    public List<Schema.FieldSetMember> cashAccFieldList { get; set; }
    public List<Schema.FieldSetMember> subAccFieldList { get; set; }
    public List<Schema.FieldSetMember> chargeAccFieldList { get; set; }

    public List<Schema.FieldSetMember> cashAccLPFieldList { get; set; }
    public List<Schema.FieldSetMember> subAccLPFieldList { get; set; }
    public List<Schema.FieldSetMember> chargeAccLPFieldList { get; set; }
    
    public List<Schema.FieldSetMember> allLPFieldList { get; set; }
    
    public string accid {get; set;}

    public string Filetype{get;set;}
    public boolean isExcel {get;set;}
    public boolean isCsv {get;set;}
    
    public Set<Id> cashAccIdSet {get; set;}
    public Set<Id> subAccIdSet {get; set;}
    public Set<Id> chargeAccIdSet {get; set;}
    public Set<Id> allIdSet {get; set;}
   
    public Map<Id,APT_Cash_Account__c> cashAccountMap {get; set;}
    public Map<Id,APT_Sub_Account__c> subAccountMap {get; set;}
    public Map<Id,APT_Charge_Account__c> chargeAccountMap {get; set;}
    
    public Map<String, List<APT_Agreement_Lodgement_Point__c>> agreementLodgmentPointMap {get; set;}
    /**
        This method is for xlx file's header
    **/
    public String xlsHeader{get{return APT_constants.strHeader;} }
     

    
    /**
        Constructor
    **/ 
    public APT_exportAccountDetailCtrl(){
            Filetype = APT_Constants.EMPTY_STRING;
 
            cashAccIdSet = new Set<Id> ();
            subAccIdSet = new Set<Id> ();
            chargeAccIdSet = new Set<Id> ();
            allIdSet  = new Set<Id> ();

            agreementLPList = new List<APT_Agreement_Lodgement_Point__c> ();
            
            cashAccFieldList = new List<Schema.FieldSetMember> ();
            subAccFieldList = new List<Schema.FieldSetMember> ();
            chargeAccFieldList = new List<Schema.FieldSetMember> ();
        
            cashAccLPFieldList = new List<Schema.FieldSetMember> ();
            subAccLPFieldList = new List<Schema.FieldSetMember> ();
            chargeAccLPFieldList = new List<Schema.FieldSetMember> ();
                        
            allLPFieldList =  new List<Schema.FieldSetMember> ();
           
            cashAccountMap = new Map<Id,APT_Cash_Account__c> ();
            subAccountMap = new Map<Id,APT_Sub_Account__c> ();
            chargeAccountMap = new Map<Id,APT_Charge_Account__c> ();
            
            agreementLodgmentPointMap  = new Map<String, List<APT_Agreement_Lodgement_Point__c>> ();
              
            cashAccFieldList = getFieldsFromFieldSet (APT_Constants.SOQL_CASHACCOUNT_OBJECT,APT_Constants.FIELDSETNAME_EXPORT);
            subAccFieldList = getFieldsFromFieldSet (APT_Constants.SOQL_SUBACCOUNT_OBJECT,APT_Constants.FIELDSETNAME_EXPORT);
            chargeAccFieldList = getFieldsFromFieldSet(APT_Constants.SOQL_CHARGEACCOUNT_OBJECT,APT_Constants.FIELDSETNAME_EXPORT);
            
            cashAccLPFieldList  = getFieldsFromFieldSet (APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT,APT_Constants.FIELDSETNAME_CASHACCOUNT_LP);
            subAccLPFieldList  = getFieldsFromFieldSet (APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT,APT_Constants.FIELDSETNAME_SUBACCOUNT_LP);
            chargeAccLPFieldList  = getFieldsFromFieldSet (APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT,APT_Constants.FIELDSETNAME_CHARGEACCOUNT_LP);
            
            allLPFieldList.addAll(cashAccLPFieldList);
            allLPFieldList.addAll(subAccLPFieldList);
            allLPFieldList.addAll(chargeAccLPFieldList);
            
            accid = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);
            
            cashAccList = Database.query(getQuery(cashAccFieldList,APT_Constants.SOQL_CASHACCOUNT_OBJECT,false));
            subAccList = Database.query(getQuery(subAccFieldList,APT_Constants.SOQL_SUBACCOUNT_OBJECT,false));
            chargeAccList = Database.query(getQuery(chargeAccFieldList,APT_Constants.SOQL_CHARGEACCOUNT_OBJECT,false));
             
            for(APT_Cash_Account__c cashAcc :cashAccList ) {
                cashAccIdSet.add(String.valueof(cashAcc.Id).substring(0,15));
            } 
            for(APT_Sub_Account__c subAcc :subAccList ) {
                subAccIdSet.add(String.valueof(subAcc.Id).substring(0,15));
            } 
            for(APT_Charge_Account__c chargeAcc :chargeAccList ) {
                chargeAccIdSet.add(String.valueof(chargeAcc.Id).substring(0,15));
            } 
            
            allIdSet.addAll(cashAccIdSet);
            allIdSet.addAll(subAccIdSet);
            allIdSet.addAll(chargeAccIdSet);
            
            
            agreementLPList = Database.query(getQuery(allLPFieldList,APT_Constants.SOQL_AGREEMENT_LODGEMENT_POINT_OBJECT,true));
        
            
            for(APT_Agreement_Lodgement_Point__c agmtLP : agreementLPList) {
                 List<APT_Agreement_Lodgement_Point__c >  agmtList;
                 if(agmtLp.APT_Charge_Account__c != null) {
                     agmtList = new List<APT_Agreement_Lodgement_Point__c >();
                     if(agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Charge_Account__c).substring(0,15)) != null) {
                         agmtList = agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Charge_Account__c).substring(0,15));
                     }
                     agmtList.add(agmtLP);
                     agreementLodgmentPointMap.put(String.valueOf(agmtLp.APT_Charge_Account__c).substring(0,15),agmtList);
                 }
                 if(agmtLp.APT_Cash_Account__c != null) {
                     agmtList = new List<APT_Agreement_Lodgement_Point__c >();
                     if(agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Cash_Account__c).substring(0,15)) != null) {
                         agmtList = agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Cash_Account__c).substring(0,15));
                     }
                     agmtList.add(agmtLP);
                     agreementLodgmentPointMap.put(String.valueOf(agmtLp.APT_Cash_Account__c).substring(0,15),agmtList);
                 }
                 if(agmtLp.APT_Sub_Account__c!= null) {
                     agmtList = new List<APT_Agreement_Lodgement_Point__c >();
                     if(agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Sub_Account__c).substring(0,15)) != null) {
                         agmtList = agreementLodgmentPointMap.get(String.valueOf(agmtLp.APT_Sub_Account__c).substring(0,15));
                     }
                     agmtList.add(agmtLP);
                     agreementLodgmentPointMap.put(String.valueOf(agmtLp.APT_Sub_Account__c).substring(0,15),agmtList);
                     
                 }
            }
            for(Id accId : allIdSet) {
                if(agreementLodgmentPointMap.get(String.valueOf(accId).substring(0,15)) == null) {
                    agreementLodgmentPointMap.put(String.valueOf(accId).substring(0,15),new List<APT_Agreement_Lodgement_Point__c >());
                }
            }
            cashAccountMap = new Map<Id,APT_Cash_Account__c>(cashAccList);
            subAccountMap = new Map<Id,APT_Sub_Account__c>(subAccList);
            chargeAccountMap = new Map<Id,APT_Charge_Account__c>(chargeAccList);
            
            redirect ();                 
    }
    
    /**
        This method will redirect you to previous page.
    **/
    public pagereference redirect () {
        Pagereference pageref = new pagereference(APT_Constants.GettAccoundDetail_URL+accId);
        pageref.setredirect(true);
        return pageref;
    }
    
    /**
        This method will return fieldset Member's list
    **/
    private List<Schema.FieldSetMember> getFieldsFromFieldSet (String accountName, String fieldSetName) {
        Map<String, Schema.SObjectType> allObjects= Schema.getGlobalDescribe();
        Schema.SObjectType objType = allObjects.get(accountName);
        Schema.DescribeSObjectResult d = objType.getDescribe();
        List<Schema.FieldSetMember> FsMap =  d.fieldSets.getMap().get(fieldSetName).getFields(); 
        
        return FsMap;
    }

    /**
        This method will return dynamic SOQL query using fieldset
    **/    
    private String getQuery (List<Schema.FieldSetMember> fieldSetMember, String AccountName, Boolean agreementLP) {
       
        String query = APT_Constants.SOQL_SELECT;
        if(agreementLP) {
            query += 'APT_Charge_Account__c,APT_Cash_Account__c,APT_Sub_Account__c,' ;
        }
        for(Schema.FieldSetMember f : fieldSetMember) {
            system.debug('####'+f.getFieldPath());
            if(query.indexOf(f.getFieldPath()) == -1) {
                query += f.getFieldPath() + APT_Constants.SEPARATOR_COMMA_SPACE;
            }
        }
        query = query.subString(0,query.Length()-2);
        query += APT_Constants.SOQL_FROM +AccountName;
        if(agreementLP) {
            query += APT_Constants.WHERECLAUSE_AGMTLP;
        }
        else {
            query +=APT_Constants.QUERYSTRING_SELECTEDACCOUNTS;
        }
        return query;
    }
   
 
}