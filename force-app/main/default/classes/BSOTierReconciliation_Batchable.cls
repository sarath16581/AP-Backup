/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 03/01/2017     
  * @description  : This class is to read the BSO records daily and activate the customer tier based on business logic
  */
/*******************************  History ************************************************
*06/02/2017          snigdha.sahu@auspost.com.au   Created
*26/04/2017          disha.kariya@auspost.com.au   Modified for populating Data into "Active Band History" object.
*24/04/2020          disha.kariya@auspost.com.au   Modified to mark assets as Processed and not to send it to COM when band has not changed.
    
*******************************  History ************************************************/
global without sharing class BSOTierReconciliation_Batchable implements Database.Batchable<SObject> {
    
    /* Private Variables */
    private String query;
    private String bsoRecType = 'PSR';     // Changed from BSO to PSR for Terminology change - Disha on 22March2017 
    List<Active_Band_History__c> activeBandToInsert = new List<Active_Band_History__c>();
    List<Asset>assetRecsToUpdate = new List<Asset>();
    List<Asset>assetSendToCOM = new List<Asset>();
    //To access ActiveBand History while adding assets to list
    Map<Id, List<Active_Band_History__c>> mapAccountToActiveBand = new Map<Id, List<Active_Band_History__c>>();
    @TestVisible private final String ASSIGNED = 'Assigned';
    @TestVisible private final String TRANSACTIONAL = 'Transactional';
    @TestVisible private final String ACTIVE = 'Active';
    @TestVisible private final String INACTIVE = 'Inactive';
    /** 
      * @name: BSOTierReconciliation_Batchable()
      * @desciption: Constructor
      * @param: NA
      * @return: NA
      *
      */
    global BSOTierReconciliation_Batchable() {
             
        
        /* Query all records from the Assets table which are to be processed. This will pick up only those records that have the flag 'To be Processed' as TRUE*/
        query =     'SELECT Id, AccountId, Name, Account_Legacy_Id__c, Product_Hierarchy_Value__c, Product_Name__c, Tier_Calculated_Date__c, Tier_Type__c, '
                +   'Freeze_Period_Start_Date__c, Freeze_Period_End_Date__c, Status, To_Be_Processed__c, Product2Id FROM Asset '
                +   'WHERE To_Be_Processed__c = TRUE AND RecordType.DeveloperName = :bsoRecType AND AccountId != NULL order by accountId ';
        
    }
    
    /** 
      * @name: start()
      * @desciption: start method to run the query and get the results
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global Database.QueryLocator start(Database.BatchableContext currentScope) {
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
    global void finish(Database.BatchableContext currentScope) {
        System.debug('*** FINISH:');
    }   
    
    /** 
      * @name: execute()
      * @desciption: To determine which BSO asset should be active based on business rules for Product Tier
      * @param: Database.BatchableContext currentScope, List<SObject> bsoAssets
      * @return: NA
      *
      */
    global void execute(Database.BatchableContext currentScope, List<SObject> bsoAssets) {
        //Map for AccountIds and related Assets
        Map<Id, List<Asset>> mapAccountToAssets = new Map<Id, List<Asset>>();
//        Map<Id, List<Active_Band_History__c>> mapAccountToActiveBand = new Map<Id, List<Active_Band_History__c>>();
        try {   
                
            //List<Active_Band_History__c> activeBandToUpdate = new List<Active_Band_History__c>();
            Set<Id> accountIdSet = new Set<Id>();
                
            
            //Create Map of AccountIds and related Assets
            for  (Asset bsoAssetsRec : (List<Asset>) bsoAssets) {  
                if ( !mapAccountToAssets.containsKey(bsoAssetsRec.AccountId)) {
                    mapAccountToAssets.put(bsoAssetsRec.AccountId , new List<Asset>());
                    accountIdSet.add(bsoAssetsRec.AccountId);
                }
                mapAccountToAssets.get(bsoAssetsRec.AccountId).add(bsoAssetsRec);
                System.debug('Before 2nd Asset mapAccountToAssets---->'+mapAccountToAssets.get(bsoAssetsRec.accountId));
            }
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows()); // Get Query Row Limit
            //Fetch the other BSO Asset record for the relevant accounts, since the first query fetches only records that have the 'To be processed' to be True
            for (Asset bsoAssets1 : MyPostBusinessAssetsSelector.newInstance(rowLimit).selectPSRUnprocessedByAccounts(accountIdSet).values())
            {
                mapAccountToAssets.get(bsoAssets1.AccountId).add(bsoAssets1);
            }
            Integer rowLimitNew = (Limits.getLimitQueryRows() - Limits.getQueryRows()); // Get Query Row Limit
            //Fetch all Active bands for Organisation in descending order of change date
            for (Active_Band_History__c activeBands : ActiveBandHistoriesSelector.newInstance(rowLimitNew).selectActiveBandHistoriesByAccountIds(accountIdSet).values()){
                System.debug('activeBands---->'+activeBands);
                if ( !mapAccountToActiveBand.containsKey(activeBands.Organisation__c)) {
                    mapAccountToActiveBand.put(activeBands.Organisation__c , new List<Active_Band_History__c>());
                }
                mapAccountToActiveBand.get(activeBands.Organisation__c).add(activeBands);
            } 
                
            //loop through 
            for (Id accountId : mapAccountToAssets.keySet()) {
                System.debug('BSOTierReconciliation_Batchable : accountId ' + accountId );
                List<Asset>assetRecs = mapAccountToAssets.get(accountId);
                System.debug('BSOTierReconciliation_Batchable : For loop for AssetRecords');
                Integer i = 0;
                System.debug('assetRecs.size() ' + assetRecs.size());
                //system.debug('assetRecs.get(i)---->' + assetRecs.get(i).name);
                if (assetRecs.size() > 1 && assetRecs.size() <=2 ) {
                    System.debug('BSOTierReconciliation_Batchable : Inside IF condition');
                    Asset assignedAsset = ASSIGNED.equals(assetRecs.get(i).Tier_Type__c)?assetRecs.get(i): assetRecs.get(i+1);
                    Asset transactionalAsset = TRANSACTIONAL.equals(assetRecs.get(i).Tier_Type__c)?assetRecs.get(i): assetRecs.get(i+1);
                    //When Assigned is Inactive but has higher Hierarchy value and today is in Freeze period
                    if (currentFreezePriod(assignedAsset) && (assignedAsset.Product_Hierarchy_Value__c >= transactionalAsset.Product_Hierarchy_Value__c) &&  INACTIVE.equals(assignedAsset.Status) ) {
                        System.debug('If Assigned >= Transactional');
                        updateAssets(assignedAsset, transactionalAsset, true,(mapAccountToActiveBand.containsKey(accountId)?true:false),true); //Assigned gets active
                    }
                    else if ((assignedAsset.Product_Hierarchy_Value__c < transactionalAsset.Product_Hierarchy_Value__c) && INACTIVE.equals(transactionalAsset.Status)){
                        //When Transactional is Inactive but has higher Hierarchy value
                        System.debug('If Freeze is current but Assigned < Transactional');
                        updateAssets(transactionalAsset, assignedAsset, true, (mapAccountToActiveBand.containsKey(accountId)?true:false),true);   //Transactional gets active
                    }
                    else if(currentFreezePriod(assignedAsset) && ACTIVE.equals(assignedAsset.Status) && mapAccountToActiveBand.containsKey(accountId) && assignedAsset.Product_Hierarchy_Value__c!=mapAccountToActiveBand.get(accountId)[0].Product_Hierarchy__c ){
                        //When Band is changed but the Active tier type (Assigned) remains the same
                        updateAssets(assignedAsset, transactionalAsset, false, true, true);
                    }
                    else if(ACTIVE.equals(transactionalAsset.Status) && mapAccountToActiveBand.containsKey(accountId) && transactionalAsset.Product_Hierarchy_Value__c!=mapAccountToActiveBand.get(accountId)[0].Product_Hierarchy__c ){
                        //When Band is changed but the Active tier (Transactional) type remains the same
                        updateAssets(transactionalAsset, assignedAsset, false, true, true);
                    }
                    else if(currentFreezePriod(assignedAsset) && ACTIVE.equals(assignedAsset.Status) && mapAccountToActiveBand.containsKey(accountId) && assignedAsset.Freeze_Period_End_Date__c != mapAccountToActiveBand.get(accountId)[0].Freeze_End_Date__c) {
                        //When Freeze end date has changed on active Assigned assets then update Freeze Period End Date on ABH
                        mapAccountToActiveBand.get(accountId)[0].Freeze_End_Date__c = assignedAsset.Freeze_Period_End_Date__c;
                        activeBandToInsert.add(mapAccountToActiveBand.get(accountId)[0]);
                        //Update records as processed no need to update status
                        updateAssets(assignedAsset, transactionalAsset, false, false, false);
                    }
                    else if ( !currentFreezePriod(assignedAsset) && ACTIVE.equals(assignedAsset.Status)) {
                        //When freeze period ends and Transactional gets active
                        System.debug('If Freeze period is NOT Current');
                        updateAssets(transactionalAsset, assignedAsset, true, (mapAccountToActiveBand.containsKey(accountId)?true:false), true);
                    }
                    else {
                        //Update records as processed no need to update status, create ABH and send to COM
                        updateAssets(assignedAsset, transactionalAsset, false, false, false);
                    }
                }  
            }
            System.debug('<<<<Database.insert assetRecsToUpdate>>>>'+assetRecsToUpdate.size());
            if ( assetRecsToUpdate != null) 
            {
                System.debug('Database Upsert');
                Database.upsert(assetRecsToUpdate);
            }
            System.debug('<<<<Database.insert>>>>'+activeBandToInsert.size());
            if(activeBandToInsert.size()>0)
            {
                System.debug('<<<<Database.insert>>>>'+activeBandToInsert.size());
                Database.upsert(activeBandToInsert);
            }
            System.debug('assetSendToCOM---->'+assetSendToCOM);
            //Webservice Callout
            if(assetSendToCOM.size()>0){
                System.debug('<<<<DassetSendToCOM>>>>'+assetSendToCOM.size());
                System.enqueueJob(new sendProductDetailstoCOM(assetSendToCOM));
            }
        }
        catch(Exception exp) {
            // Error Logged to Exception object for analysis
            System.debug('Esception--->'+exp);
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'PSR', 
                                                    'BSOTierReconciliation_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        }
    }
    /** 
      * @name: updateAssets()
      * @desciption: Update Assets with new status
      * @param: Asset activeAsset, Asset inactiveAsset
      * @return: NA
      *
      */
    private void updateAssets(Asset activeAsset, Asset inactiveAsset, Boolean updateStatus, Boolean createABH, Boolean sendToCOM)
    {
        //Update the status
        if(updateStatus) {
            activeAsset.Status = ACTIVE;
            inactiveAsset.Status = INACTIVE;
        }

        //Create Active Band History
        if(createABH){
            createABH(activeAsset,mapAccountToActiveBand.get(activeAsset.AccountId)[0]);
        }

        //Send change of Band to COM
        if(sendToCOM){
            //Exclude from sending it to COM if last and current bands are same but create ABH and set status update
            if(mapAccountToActiveBand.containsKey(activeAsset.AccountId) && mapAccountToActiveBand.get(activeAsset.AccountId)[0].Product_Hierarchy__c != activeAsset.Product_Hierarchy_Value__c) {
                assetSendToCOM.add(activeAsset);
            }
        }

        //mark records as processed exclude assigned assets with future start date
        if((activeAsset.Tier_Type__c.equalsIgnoreCase(ASSIGNED) && activeAsset.Freeze_Period_Start_Date__c <= Date.today()) || activeAsset.Tier_Type__c.equalsIgnoreCase(TRANSACTIONAL)){
            activeAsset.To_Be_Processed__c = false;
        }
        if((inactiveAsset.Tier_Type__c.equalsIgnoreCase(ASSIGNED) && inactiveAsset.Freeze_Period_Start_Date__c <= Date.today()) || inactiveAsset.Tier_Type__c.equalsIgnoreCase(TRANSACTIONAL)) {
            inactiveAsset.To_Be_Processed__c = false;
        }
        assetRecsToUpdate.add(activeAsset);
        assetRecsToUpdate.add(inactiveAsset);
    }
    /** 
      * @name: createABH()
      * @desciption: Create Active Band History table records
      * @param: Asset asset, Active_Band_History__c previousABH
      * @return: NA
      *
     **/
    private void createABH(Asset asset, Active_Band_History__c previousABH)
    {
        Active_Band_History__c firstActive = new Active_Band_History__c(Organisation__c = asset.AccountId,
                                        Band_Value__c = asset.Product2Id,
                                        Band_Type__c = asset.Tier_Type__c,
                                        //Previous_Band_Value__c = previousABH.Band_Value__c,
                                        Offer_type__c = 'PSR', Change_Date__c = System.today(),
                                        Previous_ABH__c = previousABH.Id);
        if(ASSIGNED.equals(asset.Tier_Type__c)) {
            firstActive.Freeze_End_Date__c = asset.Freeze_Period_End_Date__c;
        }
        activeBandToInsert.add(firstActive);
    }

    /**
     * @name: currentFreezePriod()
     * @desciption: Check today is in current Freeze period.
     * @param: Asset assignedAsset
     * @return: NA
     *
    **/
    private Boolean currentFreezePriod(Asset assignedAsset) {
        if(assignedAsset.Freeze_Period_Start_Date__c <= Date.today() && assignedAsset.Freeze_Period_End_Date__c  >= Date.today()){
            return true;
        }
        return false;
    }
}