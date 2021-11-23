/*
 * @date 2021-05-12
 * @group SubAccountRequest
 * @tag SubAccountRequest
 * @domain Core
 * @description Helper for createSubAccountsController component and used for sub account creation
 * @changelog
 * 2021-05-12 - seth.heang@auspost.com.au - Created
 */
public class CreateSubAccountHelper {

    @testVisible static private Map<String, List<SObject>> metadataCoverageRecordsMap = new Map<String, List<SObject>>();

    /**
     * @Description : Creates External Onboarding Request prior to sub account creation and record Id
     *                will be passed as once of the parameter called as transaction Id in request.
     */

    public static externalOnboardingRequestWithConnectionDetails externalOnboardingRequestDetails(SubAccountWithEmptyFields subAccountRecord){
        externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar = new externalOnboardingRequestWithConnectionDetails();
        
        /*
            A new custom Metadata to configure if the org is integration with SAP for billing account creation.
            If yes then actual Integration flow will be executed . If not then a mocking framework will 
            be used to create the event and further billing account record within salesforce.
        */
        try{
            List<SAP_Integration__mdt> sapIntegrationRecord = getSAPIntegrationMetadataRecords('Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'');
            // Live Connection by updating 'connected' to true
            if(sapIntegrationRecord[0].Connected__c =='Yes'){
                String onboardingRequestId = createExternalOnboardingRequest(subAccountRecord);            
                externalOnboardingRequestWithConnectionDetailsVar.connected = true;
                externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
                externalOnboardingRequestWithConnectionDetailsVar.subAccountWithEmptyFieldsVar= subAccountRecord;
                
                List<sObject> updateRelatedRecords = new List<sObject>();
				if(subAccountRecord.subAccountAttributesDetails.sap.customer.childAccount.size()>0){
                    for(BillingAccountWrapper.childAccountDetail obj : subAccountRecord.subAccountAttributesDetails.sap.customer.childAccount){
                       	// Update Sub Account Request status to 'Submitted'
                        APT_Sub_Account__c subAcc = new APT_Sub_Account__c();
                        subAcc.Id = obj.objectId;
                        subAcc.APT_Sub_Account_Request_Status__c = 'Submitted';
                        updateRelatedRecords.add(subAcc); 
                    }
                    ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);  
                }
            }
            // Mock Response
            else{
                String onboardingRequestId = createExternalOnboardingRequest(subAccountRecord);
                // Create a mock response for Billing Account Creation
                Integer len = 8;
                String str = string.valueof(Math.abs(Crypto.getRandomLong()));
                String randomNumber = str.substring(0, len);
    
                List<sObject> updateRelatedRecords = new List<sObject>();
                // Mock Camunda Response by creating mock BillingAccountCreationEvent__e data for sub account requests
                if(subAccountRecord.subAccountAttributesDetails.sap.customer.childAccount.size()>0){
                    for(BillingAccountWrapper.childAccountDetail obj : subAccountRecord.subAccountAttributesDetails.sap.customer.childAccount){
                        Integer len1 = 8;
                        String strn = string.valueof(Math.abs(Crypto.getRandomLong()));
                        String randomNumberSubAccnt = strn.substring(0, len1);
    
                        // Creating BillingAccountCreationEvent__e and populate attributes for Sub-Account Request
                        BillingAccountCreationEvent__e billingEvent1 = new BillingAccountCreationEvent__e() ;
                        billingEvent1.Billing_Account_Name__c = obj.name1;
                        billingEvent1.Billing_Account_Number__c = 'SF-'+randomNumberSubAccnt;
                        billingEvent1.Organisation_Record_Id__c =subAccountRecord.subAccountAttributesDetails.orgRecordId;
                        billingEvent1.Request_Object_Id__c = subAccountRecord.subAccountAttributesDetails.requestObjId;
                        billingEvent1.Status_Description__c = 'Mocking the response';
                        billingEvent1.Transaction_Id__c = onboardingRequestId;
                        billingEvent1.Source_System__c = 'SAP';
                        billingEvent1.Status__c= 'Success';
                        billingEvent1.Parent_Account_Number__c = subAccountRecord.subAccountAttributesDetails.sap.customer.parentBillingAccNo;
                        billingEvent1.Sub_Account_Request_Id__c = obj.objectId;
                        EventBus.publish(billingEvent1);
    
                        // Update Sub Account Request status to 'Submitted'
                        APT_Sub_Account__c subAcc = new APT_Sub_Account__c();
                        subAcc.Id = obj.objectId;
                        subAcc.APT_Sub_Account_Request_Status__c = 'Submitted';
                        updateRelatedRecords.add(subAcc);
                    }
                
                }
                // update 'connected' to false to indicate mock response
                ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);  
                externalOnboardingRequestWithConnectionDetailsVar.connected = false;
                externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
                externalOnboardingRequestWithConnectionDetailsVar.subAccountWithEmptyFieldsVar = subAccountRecord;
            }
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateSubAccountHelper' , 'externalOnboardingRequestDetails', null, LoggingLevel.ERROR);
        }
        
        return externalOnboardingRequestWithConnectionDetailsVar;
    }

    /**
     * @Description : External Onboarding Request creation method. The created record is used as transaction Id
     *                for request.
     * @return        Id of BAMExternalOnboardingRequest__c
     */
    private static String createExternalOnboardingRequest(SubAccountWithEmptyFields subAccountRecords){
        List<Database.SaveResult> sResult;
        try{
            BillingAccountWrapper subAccountWrapperVar = subAccountRecords.subAccountAttributesDetails;
        
            String requestObjId = subAccountWrapperVar.requestObjId;
            String objectName = String.valueOf(id.valueOf(requestObjId).getsobjecttype());
    
            // Create External Onboarding Request Object and populate attributes
            BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();        
            bamExternalOnboardingRequest.Request_Object_Name__c = objectName;
            bamExternalOnboardingRequest.Request_Object_Id__c = requestObjId;
            bamExternalOnboardingRequest.Request_Date__c = System.now();
            bamExternalOnboardingRequest.RecordTypeId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('Billing_Account_Creation').getRecordTypeId();
            
            // Save External Onboarding Request object and get its Id
            sResult= ApplicationDatabase.getInstance().dmlInsert(new List<BAMExternalOnboardingRequest__c>{bamExternalOnboardingRequest});
            // Update Transaction Id from External Onboarding Request Id
            subAccountWrapperVar.transactionId = String.valueOf(sResult[0].getId());
            
            BAMExternalOnboardingRequest__c updateBamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
            updateBamExternalOnboardingRequest.Id= String.valueOf(sResult[0].getId());
            // Update the payload from the Sub Account Wrapper object and remove null attribute/object
            updateBamExternalOnboardingRequest.Request_Payload__c = JSON.serialize(subAccountWrapperVar, true); 
            List<Database.SaveResult> sResultForUpdate= ApplicationDatabase.getInstance().dmlUpdate(new List<BAMExternalOnboardingRequest__c>{updateBamExternalOnboardingRequest});
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateSubAccountHelper' , 'createExternalOnboardingRequest', null, LoggingLevel.ERROR);
        }
        return String.valueOf(sResult[0].getId());
    } 

    /**
     * @Descrtipion : An object which holds informations as below:
     *                1. subAccountAttributesDetails: Attributes for sub account creation
     *                2. emptyAttributesList: Attribites which has missing values and related message
     *                3. integrationStatus : Integration status which holds current status of request for billing account creation
     *                                       It has different values such as Requested, Success, Partial Success, Error
     */
    public class SubAccountWithEmptyFields{
        @AuraEnabled
        public BillingAccountWrapper subAccountAttributesDetails;
        @AuraEnabled
        public List<String> emptyAttributesList;
        @AuraEnabled
        public String integrationStatus;
    }
    /**
     * @Descrtipion : An object which holds informations as below:
     *                1. connected: flag to switch between actual connection or mock response
     *                2. onboardingRequestId: Id to store the External Onboarding Request Id and used to populate the Transaction Id 
     *                3. subAccountWithEmptyFieldsVar : Sub Account Wrapper class to store the payload
     */
    public class ExternalOnboardingRequestWithConnectionDetails{
        @AuraEnabled
        public Boolean connected;
        @AuraEnabled
        public String onboardingRequestId;
        @AuraEnabled
        public SubAccountWithEmptyFields subAccountWithEmptyFieldsVar;
    }
    /**
     * @Descrtipion : Method Query the Sap Integration Metadata Records
     * @return      : List<SAP_Integration__mdt>
     */
    public static List<SObject> getSAPIntegrationMetadataRecords(String query){
        if(!metadataCoverageRecordsMap.containsKey(query)){
            metadataCoverageRecordsMap.put(query, Database.query(query));
        }
        return metadataCoverageRecordsMap.get(query);
    } 
}