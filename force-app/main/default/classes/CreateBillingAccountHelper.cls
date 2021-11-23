/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createBillingAccount component and used for billing account creation
 * @changelog
 * 2020-11-18 - arjun.singh@auspost.com.au - Created
 * 2021-05-12 - seth.heang@auspost.com.au - updated fields mapping due to changes to wrapper class attribute
 * 2021-05-14 - avula.jansirani@auspost.com.au - updated (for BCA billing account creation)
 * 2021-06-15 - Seth.Heang@auspost.com.au - STP-5386 Add senderNameFromOpportunity attribute in the wrapper and pass this value to LWC
 */
public with sharing class CreateBillingAccountHelper {
    private static final String DSR_OBJECT = 'Deal_Support_Request__c';
    private static final String CA_OBJECT = 'APT_Credit_Assessment__c';
    @testVisible static private Map<String, List<SObject>> metadataCoverageRecordsMap = new Map<String, List<SObject>>();
    /**
     * @Description : Checks and validation all the required attributes for Billing Account creation and provide
     *                a message to user in case of any one attribute is missing and prevents the billign account 
     *                creation till the time all requried attribute is populated.
     * 				  Seth Heang 12/05/21 - Add hasSubAccount and subAccountCount as parameters to be sent fir UI processing at LWC component
     */
    public static billingAccountWithEmptyfields billingAccountValidations(BillingAccountWrapper billingAccountRecord, String integrationStatus , 
                                            billingAccountWithOtherValidations otherValidationCheck, String tradingName, String legalEntityName, boolean hasSubAccount, Integer subAccountCount, String senderNameFromOpportunity){
        //Validation
        List<String> fieldList = new List<String>();
        if(otherValidationCheck.loggedInUserProfile !='Enterprise Onboarding' && otherValidationCheck.loggedInUserProfile !='System Administrator'){
            fieldList.add('Only Customer On Boarding users can access Billing Account Request');    
        }
        if('Sub Account'.equalsIgnoreCase(otherValidationCheck.newAccountType)){ 
            fieldList.add('Billing Account Creation is not allowed for Sub Account');    
        }
        
        if(!'New Account'.equalsIgnoreCase(otherValidationCheck.dsrWorkType)){ 
            fieldList.add('Billing Account Creation is only allowed for New Account Work Type');    
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.street)){
            fieldList.add('Billing Street is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.city)){
            fieldList.add('Billing City/Suburb is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.state)){
            fieldList.add('Billing State is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.addressInfo.postcode)){
            fieldList.add('Billing Postal Code is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalStreet)){
            fieldList.add('Physical Street is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalCity)){
            fieldList.add('Physical City/Suburb is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalState)){
            fieldList.add('Physical State is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalPostCode)){
            fieldList.add('Physical Postal Code is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.abn) && String.isEmpty(billingAccountRecord.sap.customer.acn)){
            fieldList.add('ABN or ACN is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].firstName)){
            fieldList.add('First Name is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].lastName)){
            fieldList.add('Last Name is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.contactPersons[0].communicationInfo.email)){
            fieldList.add('Primary Contact Email is required');
        }
        if(String.isEmpty(otherValidationCheck.chargeAccountRequestId)){
            fieldList.add('Charge Account Request Id is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.creditControls.creditAssessNo)){
            fieldList.add('Credit Assessment Number is required');
        }
        if(String.isEmpty(billingAccountRecord.sap.customer.creditControls.creditLimit)){
            fieldList.add('Credit Limit is required');
        }
        if(billingAccountRecord.sap.customer.creditControls.creditLimit != null
                && Integer.ValueOf(billingAccountRecord.sap.customer.creditControls.creditLimit) <= 10){
            fieldList.add('Proposed Credit Limit is less than $10, unable to proceed with Account Creation');
        }
        if(hasSubAccount == true && subAccountCount == 0){
            fieldList.add('You need to "finalize" sub-account requests prior to submission. You can finalize sub-account requests in the sub-account request form for the related proposal');
        }
        /* Shashwat.Nath@auspost.com has added below lines of code */ 
        
        if(otherValidationCheck.hasMultipleRoles != null && otherValidationCheck.hasMultipleRoles){
            fieldList.add('Organisation has multiple roles . Please resolve');
        }
        if(otherValidationCheck.isValidRole !=null && !otherValidationCheck.isValidRole){
            fieldList.add('Organisation role must be Prospect, Known or Customer');
        }
        
        /* Shashwat.Nath@auspost.com code ends */

        billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar = new billingAccountWithEmptyfields();
        billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails = billingAccountRecord;
        billingAccountWithEmptyfieldsVar.emptyAttributesList = fieldList;
        billingAccountWithEmptyfieldsVar.integrationStatus = integrationStatus;
        billingAccountWithEmptyfieldsVar.billingAccountValidations = otherValidationCheck;
        billingAccountWithEmptyfieldsVar.tradingName = tradingName;
        billingAccountWithEmptyfieldsVar.legalEntityName = legalEntityName;
        billingAccountWithEmptyfieldsVar.senderNameFromOpportunity = senderNameFromOpportunity;
        billingAccountWithEmptyfieldsVar.hasSubAccount = hasSubAccount;
        billingAccountWithEmptyfieldsVar.subAccountCount = subAccountCount;
        return billingAccountWithEmptyfieldsVar;
    }
    /**
     * @Descrtipion : An object which holds informations as below:
     *                1. billingAccountAttributesDetails: Attributes for billing account creation
     *                2. emptyAttributesList: Attribites which has missing values and related message
     *                3. integrationStatus : Integration status which holds current status of request for billing account creation
     *                                       It has different values such as Requested, Completed, Error
     *                4. billingAccountValidations : Addtitional validation details which are required prior to billing account creation
     *                5. tradingName : Related organisation trading name
     *                6. senderNameFromOpportunity : Query value from Opportunity.Sender_name_to_appear_on_parcel_label__c
     *                                               Used to pre-populate the "What sender name should be displayed on parcel labels" input field on DSR's New Billing Account Modal Popup
     *                7. legalEntityName : Related organisation legal Entity name
     *                8. hasSubAccount : flag to determine if this is Charge Account Only or Charge + Sub Account Scenario
     *                9. subAccountCount : count of the sub-account requests
     */
    public class BillingAccountWithEmptyfields{
        @AuraEnabled
        public BillingAccountWrapper billingAccountAttributesDetails;
        @AuraEnabled
        public List<String> emptyAttributesList;
        @AuraEnabled
        public String integrationStatus;
        @AuraEnabled
        public billingAccountWithOtherValidations billingAccountValidations;
        @AuraEnabled
        public String tradingName;
        @AuraEnabled
        public String senderNameFromOpportunity;
        @AuraEnabled
        public String legalEntityName;
        @AuraEnabled
        public boolean hasSubAccount;
        @AuraEnabled
        public Integer subAccountCount;
    }
    /**
     * @ Description: Object which has details of additionl validation required prior to billing account creation
     */
    public class BillingAccountWithOtherValidations{
        @AuraEnabled
        public Boolean hasMultipleRoles;
        @AuraEnabled
        public Boolean isValidRole;
        @AuraEnabled
        public String chargeAccountRequestId;
        @AuraEnabled
        public String loggedInUserProfile;
        @AuraEnabled
        public String newAccountType;
        @AuraEnabled
        public String dsrWorkType;        
        @AuraEnabled
        public String physicalStreet;
        @AuraEnabled
        public String physicalCity;
        @AuraEnabled
        public String physicalState;
        @AuraEnabled
        public String physicalPostCode;
        
    }
    /**
     * @Description : Creates External Onboarding Request prior to billing account creation and record Id
     *                will be passed as once of the parameter called as transaction Id in request.
     */

    public static externalOnboardingRequestWithConnectionDetails externalOnboardingRequestDetails(billingAccountWithEmptyfields billingAccountRecord, String onboardingRequestId){
        /*
            A new custom Metadata to configure if the org is integration with SAP for billing account creation.
            If yes then actual Integration flow will be executed . If not then a mocking framework will 
            be used to create the event and further billing account record within salesforce.
        */
        externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar = new externalOnboardingRequestWithConnectionDetails();
        
        try{
            List<SAP_Integration__mdt> sapIntegrationRecord = getSAPIntegrationMetadataRecords('Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'');

            System.debug('sapIntegrationRecord>>>>'+sapIntegrationRecord[0]);
            if(sapIntegrationRecord[0].Connected__c =='Yes'){
                externalOnboardingRequestWithConnectionDetailsVar.connected = true;
                externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
                externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;
            }else{
                // Create a mock response for Billing Account Creation
                Integer len = 8;
                String str = string.valueof(Math.abs(Crypto.getRandomLong()));
                String randomNumber = str.substring(0, len);
                // common for DSR and BCA
                BillingAccountCreationEvent__e billingEvent = new BillingAccountCreationEvent__e() ;
                billingEvent.Billing_Account_Number__c =  'SF-'+randomNumber;
                billingEvent.Billing_Account_Name__c =   billingAccountRecord.billingAccountAttributesDetails.sap.customer.name1;
                billingEvent.Customer_Id__c = billingAccountRecord.billingAccountAttributesDetails.sap.customer.customerId;
                billingEvent.Organisation_Record_Id__c = billingAccountRecord.billingAccountAttributesDetails.orgRecordId;
                billingEvent.Request_Object_Id__c = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
                billingEvent.Status_Description__c = 'Mocking the response';
                billingEvent.Source_System__c = 'SAP';
                billingEvent.Transaction_Id__c = onboardingRequestId;
                billingEvent.Status__c= 'Success';
                String objectName = String.valueOf(id.valueOf(billingAccountRecord.billingAccountAttributesDetails.requestObjId)?.getsobjecttype());
                
                //-- for BCA flow, the source as 'SAP'
                if(CA_OBJECT.equalsIgnoreCase(objectName)){
                    billingEvent.Source_System__c = 'SAP';
                    billingEvent.Type__c = 'CUST';
                    billingEvent.Credit_Person__c='	xxxx - SMB VIC/TAS';
                    billingEvent.Credit_Group__c='Credit Mgt - VIC';
                    billingEvent.Credit_Person_Code__c='3N';
                }

                System.debug('billingEvent platform event='+billingEvent);
                Database.SaveResult sr = EventBus.publish(billingEvent);

                if(billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount!=null &&
                    billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount.size()>0){
                    Integer count = 0;
                    for(BillingAccountWrapper.childAccountDetail obj : billingAccountRecord.billingAccountAttributesDetails.sap.customer.childAccount){
                        Integer len1 = 8;
                        String strn = string.valueof(Math.abs(Crypto.getRandomLong()));
                        String randomNumberSubAccnt = strn.substring(0, len1);
                        
                        BillingAccountCreationEvent__e billingEvent1 = new BillingAccountCreationEvent__e() ;
                        billingEvent1.Billing_Account_Name__c = obj.name1;
                        billingEvent1.Billing_Account_Number__c = 'SF-'+randomNumberSubAccnt;
                        billingEvent1.Organisation_Record_Id__c =billingAccountRecord.billingAccountAttributesDetails.orgRecordId;
                        billingEvent1.Request_Object_Id__c = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
                        billingEvent1.Status_Description__c = 'Mocking the response';
                        billingEvent1.Transaction_Id__c = onboardingRequestId;
                        billingEvent1.Source_System__c = 'SAP';
                        billingEvent1.Status__c= 'Success'; 
                        billingEvent1.Parent_Account_Number__c = billingEvent.Billing_Account_Number__c;
                        billingEvent1.Sub_Account_Request_Id__c = obj.objectId;
                        billingEvent1.MLID__c = '555000';
                        count++;
                        EventBus.publish(billingEvent1);
                    }
                }


                       
                /* shashwat.nath@auspost.com updated the below code to set the interim status of the charge account request to "New" when
                the request is submitted */

                List<sObject> updateRelatedRecords = new List<sObject>();
                
                if(objectName == DSR_OBJECT){
                    Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
                    dealSupportRequest.Id = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
                    dealSupportRequest.Integration_Status__c= 'Requested';
                    updateRelatedRecords.add(dealSupportRequest);
                }else if(objectName == CA_OBJECT){
                    APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
                    ca.Id = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
                    ca.Integration_Status__c= 'Requested';
                    updateRelatedRecords.add(ca);
                }

                if(objectName != CA_OBJECT){ 
                    APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
                    chargeAccntReq.id = billingAccountRecord.billingAccountValidations.chargeAccountRequestId;
                    chargeAccntReq.Status__c = 'New';
                    updateRelatedRecords.add(chargeAccntReq);
                }
                 
                updateSobjectRecords(updateRelatedRecords);
                externalOnboardingRequestWithConnectionDetailsVar.connected = false;
                externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
                externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;
            }
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'externalOnboardingRequestDetails', null, LoggingLevel.ERROR);
        }
        
        return externalOnboardingRequestWithConnectionDetailsVar;
    }
    /**
     * @Description : External Onboarding Request creation method. The created record is used as transaction Id
     *                for request.
     */
    public static String createExternalOnboardingRequest(BillingAccountWrapper billingAccountWrapperVar){
        List<Database.SaveResult> sResult;
        try{
            String requestObjId = billingAccountWrapperVar.requestObjId;
            String objectName = String.valueOf(id.valueOf(requestObjId).getsobjecttype());

            // populate external onboarding request object for logging purposes
            BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();        
            bamExternalOnboardingRequest.Request_Object_Name__c = objectName;
            bamExternalOnboardingRequest.Request_Object_Id__c = requestObjId;
            bamExternalOnboardingRequest.Request_Date__c = System.now();
            bamExternalOnboardingRequest.RecordTypeId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('Billing_Account_Creation').getRecordTypeId();
            
            sResult= ApplicationDatabase.getInstance().dmlInsert(new List<BAMExternalOnboardingRequest__c>{bamExternalOnboardingRequest});
            // save external onboarding request id to the transactionId of the request payload
            billingAccountWrapperVar.transactionId = String.valueOf(sResult[0].getId());
            
            BAMExternalOnboardingRequest__c updateBamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
            updateBamExternalOnboardingRequest.Id= String.valueOf(sResult[0].getId());
            // remove null attribute/object off the payload
            //We need to make Bank account details null for not storing in External On boarding request.
            BillingAccountWrapper billingAccountTempWrapper = billingAccountWrapperVar;
            billingAccountTempWrapper.sap.customer.bankAccounts = null;
            // remove null attribute/object off the payload
            updateBamExternalOnboardingRequest.Request_Payload__c = JSON.serialize(billingAccountTempWrapper, true);
            List<Database.SaveResult> sResultForUpdate= ApplicationDatabase.getInstance().dmlUpdate(new List<BAMExternalOnboardingRequest__c>{updateBamExternalOnboardingRequest});
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'createExternalOnboardingRequest', null, LoggingLevel.ERROR);
        }
        
        return String.valueOf(sResult[0].getId());
    }   
        
    /**
     * @Description: Updates the related DSR and Charge Account and external onborading request based on the initial
     *               response received from camunda
     */
    public static void updateDSRAndChargeAccount(String requestObjId, String chargeAccountRequestId, String onboardingRequestId, String status, String responseMsg){
        try{
            List<sObject> updateRelatedRecords = new List<sObject>();
        	if(DSR_OBJECT.equalsIgnoreCase(String.valueOf(id.valueOf(requestObjId)?.getsobjecttype()))){
                Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
                dealSupportRequest.Id = requestObjId;
                dealSupportRequest.Integration_Status__c= status;
                dealSupportRequest.Integration_Status_Description__c =responseMsg;
                dealSupportRequest.Integration_Transaction_Id__c = onboardingRequestId;
                updateRelatedRecords.add(dealSupportRequest);
            }
              
            if(status == 'Requested' && (chargeAccountRequestId != null || !String.isBlank(chargeAccountRequestId))){
                APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
                chargeAccntReq.id = chargeAccountRequestId;
                chargeAccntReq.Status__c = 'New';
                updateRelatedRecords.add(chargeAccntReq);
            }
            BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
            bamExternalOnboardingRequest.Id = onboardingRequestId;
            bamExternalOnboardingRequest.Response_Payload__c = responseMsg;
            if(status =='Error'){
                bamExternalOnboardingRequest.Status__c = status;
            }
            updateRelatedRecords.add(bamExternalOnboardingRequest);
            //ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);
            updateSobjectRecords(updateRelatedRecords);
        }catch(Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'B&G Sales', 'CreateBillingAccountHelper' , 'updateDSRAndChargeAccount', null, LoggingLevel.ERROR);
        }
    }
    
    /**
     * @Description: Updates the CA and external onborading request based on the initial
     *               response received from camunda
     * avula.jansirani@auspost.com.au
     */
    public static void updateCaAndOnboardingObj(String requestObjId, String onboardingRequestId, String status, String responseMsg){
        List<sObject> updateRelatedRecords = new List<sObject>();
        
        APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
        ca.Id = requestObjId;
        ca.Integration_Status__c= status;
        ca.Integration_Status_Description__c = responseMsg;
        ca.Integration_Transaction_Id__c = onboardingRequestId;
        updateRelatedRecords.add(ca);
        
        BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
        bamExternalOnboardingRequest.Id = onboardingRequestId;
        bamExternalOnboardingRequest.Response_Payload__c = responseMsg;
        if(status =='Error'){
            bamExternalOnboardingRequest.Status__c = status;      
        }
        updateRelatedRecords.add(bamExternalOnboardingRequest);   
        updateSobjectRecords(updateRelatedRecords);
    }
    
     /**
     * @Description: Updates the sobjects
     * avula.jansirani@auspost.com.au - created
     */
    public static void updateSobjectRecords(List<sObject> recordsList){
        ApplicationDatabase.getInstance().dmlUpdate(recordsList);
    }
    
    public class ExternalOnboardingRequestWithConnectionDetails{
        @AuraEnabled
        public Boolean connected;
        @AuraEnabled
        public String onboardingRequestId;
        @AuraEnabled
        public billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
    }
    public static List<SObject> getSAPIntegrationMetadataRecords(String query){
        if(!metadataCoverageRecordsMap.containsKey(query)){
            metadataCoverageRecordsMap.put(query, Database.query(query));
        }
        return metadataCoverageRecordsMap.get(query);
    }    
}