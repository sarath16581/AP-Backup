/**
  * @author       : disha.kariya@auspost.com.au
  * @date         : 28/05/2017   
  * @description  : REQ1136642 - This batch class is to Create TandC Assets and Delete Duplicate MPBIZ Assets 
  */
/*******************************  History ************************************************
28/05/2017          disha.kariya@auspost.com.au   Created
17/07/2017          disha.kariya@auspost.com.au   Updated - Exclude MPBSN Asset to follow MPBIZ design
    
    
*******************************  History ************************************************/
global without sharing class MPBUpdateMPBIZforContactId_Batchable implements Database.Batchable<SObject> {
    
    /* Private Variables */
    private String query;
    private String orgRecType = 'Organisation'; 
    //private Id tandcRecTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('TandC').getRecordTypeId();
    
    
    /** 
      * @name: MpbNewDesignDataMirationTandC_Batchable()
      * @desciption: Constructor
      * @param: NA
      * @return: NA
      *
      */
    global MPBUpdateMPBIZforContactId_Batchable() {
             
        
        /* Query all records from the Assets table which are to be processed. This will pick up only those records that have the flag 'To be Processed' as TRUE*/
        query =     'Select Id, AccountId, name, Status,  Product2.Id, recordtype.name, ParentId, contact.name, '
                +   'Org_Id_for_Non_Child_Asset__c, account.recordtype.name, InstallDate, contact.id, createdDate from Asset '
                +   'where account.recordtype.name = :orgRecType AND name = \'MPBIZ\' '
                +   'AND account.IsPersonAccount=FALSE AND contactId !=NULL ';
              //  +   'AND AccountId in (\'001N000001GFHaH\') ORDER BY accountId, createdDate';
                
    }
    
     /** 
      * @name: start()
      * @desciption: start method to run the query and get the results
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: START - query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    
    /** 
      * @name: finish()
      * @desciption: method to perform tasks once the batch is complete
      * @param: NA
      * @return: NA
      *
      */
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }   
    
    /** 
      * @name: execute()
      * @desciption: To insert, update and Delete MPBIZ Assets depending on different conditions.
      * @param: Database.BatchableContext BC, List<SObject> bsoAssets
      * @return: NA
      *
      */
    global void execute(Database.BatchableContext BC, List<SObject> mpbizAssets) {
        List<Asset> parentAssetTOUpdate = new List<Asset>();
        try { 
            for(Asset AssetsRec : (List<Asset>) mpbizAssets){
                AssetsRec.contactId = NULL;
                parentAssetTOUpdate.add(AssetsRec);
            }
            
            if(parentAssetTOUpdate.size()>0){
                system.debug('parentAssetTOUpdate.size()---->'+parentAssetTOUpdate.size());
                system.debug('parentAssetTOUpdate---->'+parentAssetTOUpdate);
                database.update(parentAssetTOUpdate);
            }
       }catch(Exception exp){
           handleException(exp, UserInfo.getOrganizationId());
       }
    }
    
    public  void handleException(Exception excp, String orgID){

        UTIL_LoggingService.logHandledException(excp, orgID, 'MPB Data Migration MPBIZ', 
                                                    'MPBUpdateMPBIZforContactId_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        
    }
}