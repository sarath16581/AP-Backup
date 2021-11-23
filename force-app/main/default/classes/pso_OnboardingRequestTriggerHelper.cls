/**************************************************
Description:  Onboarding request trigger Helper class

History:
--------------------------------------------------
2019-05-19  hasantha.liyanage@auspost.com.au Created
2019-08-19  hasantha.liyanage@auspost.com.au modified to use a future method for delete lock on contact
2019-09-06  shashwat.a.nath@accenture.com created a new method for asset creation
**************************************************/

public without sharing class pso_OnboardingRequestTriggerHelper {


    /**
     * Prepare and handover the delete lock required parameters in this method.
     *
     * @param requests
     */

    public static void toggleDeleteLockContact(List<BAMExternalOnboardingRequest__c> requests) {
        Map<String,String> idToStatus = new Map<String,String>();
        // prepare contact id to status map
        for (BAMExternalOnboardingRequest__c request : requests) {
            // concider Parcel Send Recordtype only
            if(request.recordTypeId != Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('PS').getRecordTypeId()){
                continue;
            }
            idToStatus.put(request.Contact__c, request.Status__c);
        }
        // call the future method with prepared map
        toggleDeleteLockContact(idToStatus);

    }


    /**
     * Lock/ unlock contact record and prevent user deleting a contact record where a pending external onboarding requests exists
     *
     * @param idToStatus
     */
    @future
    public static void toggleDeleteLockContact(Map<String,String> idToStatus) {
        try {
            List<Contact> contacts = new List<Contact>();
            for(String id : idToStatus.keySet()) {
                Contact contact = new Contact(Id = id);
                String status = idToStatus.get(id);
                // if the external onboarding requst is a pending, prevent user from deleting the contact.
                if(status.equalsIgnoreCase('Pending')) {
                    contact.Delete_Locked__c = true;
                    contact.Delete_Locked_Reason__c = 'Pending Parcel Send External Onboarding request exists';
                } else if(status.equalsIgnoreCase('Success')) {
                    // change the locked reason when on a succeeded provisioning
                    contact.Delete_Locked_Reason__c = 'Parcel Send, provisioned customer';
                } else if(status.equalsIgnoreCase('Error')) {
                    // release on Error, there is a trigger method to clear out the reason field wwhen delete lock is released
                    contact.Delete_Locked__c = false;
                }
                contacts.add(contact);
            }

            update contacts;

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'External Onboarding Requests',
                    CaseTriggerHelper.class.getName(), 'createExternalOnboardingRequests',
                    'pso_OnboardingRequestTrigger trigger', LoggingLevel.ERROR);
        }
    }
    
     /**
     * Create Parcel Send Asset record against the each account for the every Parcel Send Onboarding Request
     *
     * @param onboardingRequests
     */
    public static void createParcelSendAsset(List<BAMExternalOnboardingRequest__c> onboardingRequests) {
        Set<Id> requestAccountIdSet = new Set<Id>();
        Set<Id> contactIdSet= new Set<Id>();
        List<Asset> assetListToBeUpdated = new List<Asset>();
        List<Account> accountList = new List<Account>();
        List<BAMApplication__c> parcelSendApplication = new List<BAMApplication__c>();
        try{
            // Iterating over the Request Records for parcel send
            for(BAMExternalOnboardingRequest__c request : onboardingRequests) {
                // Filtering out only the parcel send requests
                if(request.recordtypeId==Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('PS').getRecordTypeId()){
                    contactIdSet.add(request.Contact__c);    
                }
            }
            // Iterating over the contacts to get Account Id's
            for(Contact contactRecord : [Select id , AccountId from contact where id IN:contactIdSet]){
                requestAccountIdSet.add(contactRecord.AccountId);
            }
            
            if(!requestAccountIdSet.isEmpty()){
                    // getting product from BAM Application Record
                    parcelSendApplication = [SELECT Id, Product__c from BAMApplication__c Where AppKey__c ='PS' LIMIT 1];
                    // querying account and related Assets if Asset product is Parcel Send
                    if(!parcelSendApplication.isEmpty()) {
                        accountList = [SELECT id , (Select id, Status from Assets where Product2Id =: parcelSendApplication[0].Product__c LIMIT 1) FROM ACCOUNT Where ID IN:requestAccountIdSet];
                    }
                }
                 // Iterating over List of Accounts
            for(Account accountRecord : accountList){
                // Checking if account has an Parcel Send Asset and it's Status is Inactive then updating it to Active
                if(accountRecord.Assets.size()>0 && !'Active'.equalsIgnoreCase(accountRecord.Assets[0].Status)){
                    accountRecord.Assets[0].Status = 'Active';
                    //Adding to the List of Assets to be updated 
                    assetListToBeUpdated.add(accountRecord.Assets[0]); 
                } else if(accountRecord.Assets.size()==0){
                    // creating an instance of Asset Record
                    Asset newAssetToBeCreated = new Asset();
                    // Assigning the recordtype as General
                    newAssetToBeCreated.recordtypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('General').getRecordTypeId();
                    // Setting the asset name
                    newAssetToBeCreated.name = 'Parcel Send';
                    // setting the Account Id
                    newAssetToBeCreated.AccountId = accountRecord.id;
                    // setting the Product Id
                    newAssetToBeCreated.Product2Id = parcelSendApplication[0].Product__c;
                    // setting the status to Active
                    newAssetToBeCreated.Status = 'Active';
                    // Adding to the list to be upserted
                    assetListToBeUpdated.add(newAssetToBeCreated);  
                       
                }
            }
        
            if(!assetListToBeUpdated.isEmpty()){
                // Upserting the asset
                database.upsert(assetListToBeUpdated);
            }

        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'External Onboarding Requests',
                    CaseTriggerHelper.class.getName(), 'createExternalOnboardingRequests',
                    'pso_OnboardingRequestTrigger trigger', LoggingLevel.ERROR);
        }   
    }
}