/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 06/11/2015
  * @description  : Opportunity Utility Class for Case Triggers
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    06/11/2015          nandan.narasappa@auspost.com.au             Created
    2017-09-28          nathan.franklin@auspost.com.au             Change recordTypeMap to use Utility method which caches.
    
*******************************  History ************************************************/
public with sharing class CaseOpportunityUtility{
    
    // variables
    public static Map<String,Id> recordTypeMap = new Map<String,Id>();    //stores case record type details
    private static Id validRecordType;  // stores valid record type for business requirement
    
    static{
        try{
            // fetch all case record types
            recordTypeMap = Utility.getsObjectRecordTypes(SSSWConstants.CASE_OBJ);

            // get the Sales Manger review record type          
            validRecordType = recordTypeMap.get(SSSWConstants.RECTYPE_CASE_SALES_MANAGER);
        }
        catch(Exception exp){
            System.debug('** StackTrack ==>'+ exp.getStackTraceString());
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CaseOpportunityUtility.class.getName(), SSSWConstants.STATIC_BLOCK, 
                                                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
      * @description       This method is invoked in after insert event, sets under review by sales manager for product
                           classification to true for Sales Manager Cases
      * @param             caseList - List<Case> 
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */
    public void updateOPCUnderReviewBySalesManagerFlag(List<Case> caseList){
        try{
            Set<Id> oppProdClassIds = new Set<Id>();
            for(Case csRec : caseList){
                // check if case is valid & got Opportunity product
                if(validRecordType == csRec.RecordTypeId && csRec.Originating_OPC__c != null){
                    oppProdClassIds.add(csRec.Originating_OPC__c);
                }
            }
            
            if(!oppProdClassIds.isEmpty()){ // check if oppProdClassIds got values
                List<Opp_Product_Classification__c> oppProdClassList = new List<Opp_Product_Classification__c>();
                // opportunity product classification records to be updated
                for(Id opcId : oppProdClassIds){
                    Opp_Product_Classification__c prodClass = new Opp_Product_Classification__c(Id = opcId);
                    prodClass.Under_Review_by_Sales_Manager__c = true;  // set under reveiw to true
                    oppProdClassList.add(prodClass);                    
                }
                                
                if(!oppProdClassList.isEmpty()){    // check if oppProdClassList got values before DML
                    Database.update(oppProdClassList,false);
                }
            }
        }
        catch(Exception exp){
            System.debug('** StackTrack ==>'+ exp.getStackTraceString());
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CaseOpportunityUtility.class.getName(), SSSWConstants.METH_UPDATE_OPC, 
                                                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
      * @description       This method is invoked in before insert event, sets Opportunity driver for 
                           sales manager review cases
      * @param             caseList - List<Case> 
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */
    public void updateOpportunityDriver(List<Case> caseList){
        try{
            Set<Id> oppIds = new Set<Id>();
            List<Case> casesToBeUpdated = new List<Case>();
            for(Case csRec : caseList){
                // check if case is valid & got Opportunity 
                if(validRecordType == csRec.RecordTypeId && csRec.Opportunity__c != null){
                    oppIds.add(csRec.Opportunity__c);
                    casesToBeUpdated.add(csRec);
                }
            }
            
            if(!oppIds.isEmpty()){  // check if oppIds got values
                Map<Id,Id> oppOwnerMap = new Map<Id,Id>();
                Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
                // fetch opportunity owner & store in a map
                for(Opportunity opp : [SELECT OwnerId FROM Opportunity WHERE Id IN: oppIds LIMIT : rowLimit]){
                    oppOwnerMap.put(opp.Id,opp.OwnerId);
                }
                
                if(!oppOwnerMap.isEmpty()){ // check if oppOwnerMap got values
                    // Set Opportunity driver for case to Opportunity owner
                    for(Case csRec : casesToBeUpdated){
                        csRec.Opportunity_Driver1__c = oppOwnerMap.containsKey(csRec.Opportunity__c) ? 
                                                        oppOwnerMap.get(csRec.Opportunity__c) : csRec.Opportunity_Driver1__c;
                    }
                }
            }
        }
        catch(Exception exp){
            System.debug('** StackTrack ==>'+ exp.getStackTraceString());
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CaseOpportunityUtility.class.getName(), SSSWConstants.METH_UPDATE_OPPDriver, 
                                                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
}