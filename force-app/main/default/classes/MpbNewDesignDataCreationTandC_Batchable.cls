/**
  * @author       : disha.kariya@auspost.com.au
  * @date         : 28/05/2017   
  * @description  : REQ1136642 - This batch class is to Create TandC Assets and Delete Duplicate MPBIZ Assets 
  */
/*******************************  History ************************************************
28/05/2017          disha.kariya@auspost.com.au   Created
17/07/2017          disha.kariya@auspost.com.au   Updated - Exclude MPBSN Asset to follow MPBIZ design
    
    
*******************************  History ************************************************/
global without sharing class MpbNewDesignDataCreationTandC_Batchable implements Database.Batchable<SObject> {
    
    /* Private Variables */
    private String query;
    private String orgRecType = 'Organisation'; 
    private Id tandcRecTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('TandC').getRecordTypeId();
    
    
    /** 
      * @name: MpbNewDesignDataMirationTandC_Batchable()
      * @desciption: Constructor
      * @param: NA
      * @return: NA
      *
      */
    global MpbNewDesignDataCreationTandC_Batchable() {
             
        
        /* Query all records from the Assets table which are to be processed. This will pick up only those records that have the flag 'To be Processed' as TRUE*/
        query =     'Select Id, AccountId, name, Status,  Product2.Id, recordtype.name, ParentId, contact.name, '
                +   'Org_Id_for_Non_Child_Asset__c, account.recordtype.name, InstallDate, contact.id, createdDate from Asset '
                +   'where account.recordtype.name = :orgRecType AND name = \'MPBIZ\' '
                +   'AND account.IsPersonAccount=FALSE AND contactId !=NULL ORDER BY accountId, createdDate';
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
        Map<Id, List<Asset>> mapAccountToAssets = new Map<Id, List<Asset>>();
        Map<Id, List<Asset>> mapMPBSNAccountToAssets = new Map<Id, List<Asset>>();
        Map<Id, Set<Id>> mapAccountToContact = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> mapMPBSNAccountToContact = new Map<Id, Set<Id>>();
        List<Asset> tandcAssetTOInsert = new List<Asset>();
        List<Asset> parentAssetTODelete = new List<Asset>();
        // List<Asset> parentAssetTOUpdate = new List<Asset>();
        try { 
            Product2 tandcProduct = [SELECT id from Product2 where name='TandC' limit 1];
            for(Asset AssetsRec : (List<Asset>) mpbizAssets)
            {
                //if(AssetsRec.name == 'MPBIZ' && AssetsRec.contactId !=NULL)
                //{
                    System.debug('Parent Asset---->'+AssetsRec.name);
                    if(!mapAccountToAssets.containskey(AssetsRec.accountid))
                    {
                        System.debug('First Asset---->'+AssetsRec.id+' Contact.name--->'+AssetsRec.contact.name);
                        Set<id> firstContactIds = new Set<id>();
                        mapAccountToAssets.put(AssetsRec.accountid, new List<Asset>{AssetsRec});
                        Asset tandcAsset = new Asset(name = 'MYPSTTandC', 
                                                        Product2id = tandcProduct.id,
                                                        contactId = AssetsRec.contactId,
                                                        recordtypeId = tandcRecTypeId,
                                                        parentID = AssetsRec.id,
                                                        Status = 'Agreed',
                                                        Quantity = 1.0,
                                                        AccountId = AssetsRec.accountId);
                        if(AssetsRec.installDate == null)
                        {
                            DateTime create = AssetsRec.createdDate;
                            tandcAsset.installDate = date.newinstance(create.year(), create.month(), create.day());
                        }
                        else
                        {
                            tandcAsset.installDate = AssetsRec.installDate;
                        }
                        tandcAssetTOInsert.add(tandcAsset);
                        firstContactIds.add(AssetsRec.contactId);
                        mapAccountToContact.put(AssetsRec.accountId, firstContactIds);
                        // AssetsRec.contactId = NULL;
                        // if(AssetsRec.status == 'Agreed' && AssetsRec.name == 'MPBSN'){
                            // AssetsRec.status='Registered';
                        // }
                        //parentAssetTOUpdate.add(AssetsRec);
                    }
                    else
                    {
                        List<Asset> secondAsset = new List<Asset>();
                        Set<Id> secondContactIds = new Set<Id>();
                        Set<Id> secondMPBSNContactIds = new Set<Id>();
                        secondAsset.addAll(mapAccountToAssets.get(AssetsRec.accountid));
                        secondContactIds = mapAccountToContact.get(AssetsRec.accountId);
                        System.debug('Second Asset---->'+AssetsRec.id+' Contact.name--->'+AssetsRec.contact.name);
                        system.debug('secondAsset---->'+secondAsset);
                        system.debug('AssetsRec.contactId--->'+AssetsRec.contactId);
                        system.debug('mapAccountToContact.get(AssetsRec.accountId)--->'+mapAccountToContact.get(AssetsRec.accountId));
                        system.debug('mapMPBSNAccountToContact.get(AssetsRec.accountId)--->'+mapMPBSNAccountToContact.get(AssetsRec.accountId));
                        System.debug('secondContactIds---->'+secondContactIds);
                        System.debug('secondMPBSNContactIds---->'+secondMPBSNContactIds);
                        if(!secondContactIds.contains(AssetsRec.contactId))
                        {
                            system.debug('AssetsRec.contactId--->'+AssetsRec.contactId);
                            system.debug('AssetsRec.installDate--->'+AssetsRec.installDate);
                            Asset tandcAsset = new Asset(name = 'MYPSTTandC', 
                                                            Product2id = tandcProduct.id,
                                                            installDate = AssetsRec.installDate,
                                                            contactId = AssetsRec.contactId,
                                                            recordtypeId = tandcRecTypeId,
                                                            parentID = secondAsset[0].id,
                                                            Status = 'Agreed',
                                                            Quantity = 1.0,
                                                            AccountId = AssetsRec.accountId);
                            if(AssetsRec.installDate == null)
                            {
                                DateTime create = AssetsRec.createdDate;
                                tandcAsset.installDate = date.newinstance(create.year(), create.month(), create.day());
                            }
                            else
                            {
                                tandcAsset.installDate = AssetsRec.installDate;
                            }
                            tandcAssetTOInsert.add(tandcAsset);
                            
                                secondContactIds.add(AssetsRec.contactId);
                                mapAccountToContact.put(AssetsRec.accountId, secondContactIds);
                        }
                        parentAssetTODelete.add(AssetsRec);
                    }
                //}
                // else if(AssetsRec.recordtype.name != 'TandC' && AssetsRec.Org_Id_for_Non_Child_Asset__c == NULL && AssetsRec.ParentId == NULL){
                    // System.debug('Non MPBIZ Asset---->'+AssetsRec.name);
                    // parentAssetTOUpdate.add(AssetsRec);
                // }
            }
            
            if(tandcAssetTOInsert.size()>0){
                system.debug('tandcAssetTOInsert.size()---->'+tandcAssetTOInsert.size());
                system.debug('tandcAssetTOInsert---->'+tandcAssetTOInsert);
                database.insert(tandcAssetTOInsert);
            }
            // if(parentAssetTOUpdate.size()>0){
                // system.debug('parentAssetTOUpdate.size()---->'+parentAssetTOUpdate.size());
                // system.debug('parentAssetTOUpdate---->'+parentAssetTOUpdate);
                // database.update(parentAssetTOUpdate);
            // }
            if(parentAssetTODelete.size()>0){
                system.debug('parentAssetTODelete.size()---->'+parentAssetTODelete.size());
                system.debug('parentAssetTODelete---->'+parentAssetTODelete);
                database.delete(parentAssetTODelete);
            }
        } 
        catch(Exception exp) {
             
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'MPB Data Migration TandC', 
                                                    'MpbNewDesignDataMirationTandC_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        }
    }
}