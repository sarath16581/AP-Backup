/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createSTBillingAccount component and used for billing account creation
 * @changelog
 * 2020-13-10 - shashwat.nath@auspost.com.au - Created
 * 2020-06-03 - Dheeraj.Mandavilli@auspost.com.au - Removed Validations on Organisation Phone and Primary Contact Phone as part of STP-5981.
 * 2020-06-08 - Dheeraj.Mandavilli@auspost.com.au - Updated the error messages for Physical and Mailing Address fields based upon UAT Feedback.
 * 2021-06-15 - Seth.Heang@auspost.com.au - STP-5386 Add senderNameFromOpportunity attribute in the wrapper and pass this value to LWC
 */
public with sharing class CreateTeamsBillingAccountHelper {
     private static final String DSR_OBJECT = 'Deal_Support_Request__c';
    @testVisible static private Map<String, List<SObject>> metadataCoverageRecordsMap = new Map<String, List<SObject>>();
    /**
     * @Description : Checks and validation all the required attributes for Billing Account creation and provide
     *                a message to user in case of any one attribute is missing and prevents the billign account 
     *                creation till the time all requried attribute is populated.
     *               
     */
    public static billingAccountWithEmptyfields billingAccountValidations(BillingAccountWrapperForTeams billingAccountRecord, String integrationStatus , billingAccountWithOtherValidations otherValidationCheck,
                                                                            String tradingName, String legalEntityName, String contractId , String contractTerm, String senderNameFromOpportunity){
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
        if(String.isEmpty(billingAccountRecord.team.organisations.billingAddress.addressLine1)){
            fieldList.add('Billing Address Line 1 is required');
        }
       if(String.isEmpty(billingAccountRecord.team.organisations.billingAddress.suburb)){
            fieldList.add('Billing City/Suburb is required'); 
        }
        if(billingAccountRecord.team.organisations.billingAddress.postcode == null){
            fieldList.add('Billing Postal Code is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.mailingAddress.addressLine1)){
            fieldList.add('Pickup Address Line 1 is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.mailingAddress.suburb)){
            fieldList.add('Pickup City/Suburb is required');
        }
        if(billingAccountRecord.team.organisations.mailingAddress.postcode == null){
            fieldList.add('Pickup Postal Code is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.abn)){
            fieldList.add('ABN  is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.primaryContact.firstName)){
            fieldList.add('First Name is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.primaryContact.lastName)){
            fieldList.add('Last Name is required');
        }
        if(String.isEmpty(billingAccountRecord.team.organisations.primaryContact.email)){
            fieldList.add('Primary Contact Email is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalStreet)){
            fieldList.add('Shipping Street is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalCity)){
            fieldList.add('Shipping City/Suburb is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalState)){
            fieldList.add('Shipping State is required');
        }
        if(String.isEmpty(otherValidationCheck.physicalPostCode)){
            fieldList.add('Contract Postal Code is required');
        }
        if(String.isEmpty(otherValidationCheck.chargeAccountRequestId)){
            fieldList.add('Charge Account Request Id is required');
        }
        if(billingAccountRecord.team.creditDetails.creditLimit == null){
            fieldList.add('Credit Limit is required');
        }
        if(billingAccountRecord.team.creditDetails.creditLimit != null
                && Integer.ValueOf(billingAccountRecord.team.creditDetails.creditLimit) <= 10){
            fieldList.add('Credit Amount must be greater than 10$');
        }
        if(billingAccountRecord.team.creditDetails.estimatedMonthlyRevenue == null){
            fieldList.add('Estimated Monthly Revenue is required');
        }
        if((billingAccountRecord.team.creditDetails.nextRevenueDueDate == null)){
            fieldList.add('Next Revenue Date is required');
        }
        if(otherValidationCheck.hasMultipleRoles != null && otherValidationCheck.hasMultipleRoles){
            fieldList.add('Organisation has multiple roles . Please resolve');
        }
        if(otherValidationCheck.isValidRole !=null && !otherValidationCheck.isValidRole){
            fieldList.add('Organisation role must be Prospect, Known or Customer');
        }
        if(otherValidationCheck.creditAssessmentStatus != 'Approved' && otherValidationCheck.creditAssessmentStatus != 'Auto-Approved'){
            fieldList.add('Credit Assessment must be Approved');
        }
        billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar = new billingAccountWithEmptyfields();
        billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails = billingAccountRecord;
        billingAccountWithEmptyfieldsVar.emptyAttributesList = fieldList;
        billingAccountWithEmptyfieldsVar.integrationStatus = integrationStatus;
        billingAccountWithEmptyfieldsVar.billingAccountValidations = otherValidationCheck;
        billingAccountWithEmptyfieldsVar.tradingName = tradingName;
        billingAccountWithEmptyfieldsVar.legalEntityName = legalEntityName;
        billingAccountWithEmptyfieldsVar.contractId = contractId;
        billingAccountWithEmptyfieldsVar.contractTerm = contractTerm;
        billingAccountWithEmptyfieldsVar.senderNameFromOpportunity = senderNameFromOpportunity;
        return billingAccountWithEmptyfieldsVar;
    }
    /**
     * @Descrtipion : An object which holds informations as below:
     *                1. billingAccountAttributesDetails: Attributes for billing account creation in TEAM
     *                2. emptyAttributesList: Attribites which has missing values and related message
     *                3. integrationStatus : Integration status which holds current status of request for billing account creation
     *                                       It has different values such as Requested, Completed, Error
     *                4. billingAccountValidations : Addtitional validation details which are required prior to billing account creation
     *                5.  tradingName : Related organisation trading name
     *                6. legalEntityName : Related organisation legal Entity name
     *                7. senderNameFromOpportunity : Query value from Opportunity.Sender_name_to_appear_on_parcel_label__c
     *                                               Used to pre-populate the "What sender name should be displayed on parcel labels" input field on DSR's New Billing Account Modal Popup
     */
    public class BillingAccountWithEmptyfields{
        @AuraEnabled
        public BillingAccountWrapperForTeams billingAccountAttributesDetails;
        @AuraEnabled
        public List<String> emptyAttributesList;
        @AuraEnabled
        public String integrationStatus;
        @AuraEnabled
        public billingAccountWithOtherValidations billingAccountValidations;
        @AuraEnabled
        public String tradingName;
        @AuraEnabled
        public String legalEntityName;
        @AuraEnabled
        public String contractId;
        @AuraEnabled
        public String contractTerm;
        @AuraEnabled
        public String senderNameFromOpportunity;

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
        @AuraEnabled
        public String creditAssessmentStatus;
        
    }

    /**
    * @Description : Creates External Onboarding Request prior to billing account creation and record Id
    *                will be passed as once of the parameter called as transaction Id in request.
    */

    public static externalOnboardingRequestWithConnectionDetails externalOnboardingRequestDetails(BillingAccountWithEmptyfields billingAccountRecord){
        /*
            A new custom Metadata to configure if the org is integration with SAP for billing account creation.
            If yes then actual Integration flow will be executed . If not then a mocking framework will
            be used to create the event and further billing account record within salesforce.
        */
        externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar = new externalOnboardingRequestWithConnectionDetails();
        List<SAP_Integration__mdt> teamIntegrationRecord = getTeamIntegrationMetadataRecords('Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'Team_Integration\'');
        System.debug('sapIntegrationRecord>>>>'+teamIntegrationRecord[0]);
        if(teamIntegrationRecord[0].Connected__c =='Yes'){
            String onboardingRequestId = createExternalOnboardingRequest(billingAccountRecord.billingAccountAttributesDetails);
            externalOnboardingRequestWithConnectionDetailsVar.connected = true;
            externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
            externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;

        }else{
            String onboardingRequestId = createExternalOnboardingRequest(billingAccountRecord.billingAccountAttributesDetails);
            // Create a mock response for Billing Account Creation
            Integer len = 8;
            String str = string.valueof(Math.abs(Crypto.getRandomLong()));
            String randomNumber = str.substring(0, len);

            BillingAccountCreationEvent__e billingEvent = new BillingAccountCreationEvent__e() ;
            billingEvent.Billing_Account_Name__c =   billingAccountRecord.billingAccountAttributesDetails.team.organisations.accountName1;
            billingEvent.Billing_Account_Number__c =  'T-'+randomNumber;
            billingEvent.Organisation_Record_Id__c = billingAccountRecord.billingAccountAttributesDetails.orgRecordId ;
            billingEvent.Request_Object_Id__c = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
            billingEvent.Status_Description__c = 'Mocking the response';
            billingEvent.Transaction_Id__c = onboardingRequestId;
            billingEvent.Source_System__c = 'TEAM';
            billingEvent.Status__c= 'Success';

            Database.SaveResult sr = EventBus.publish(billingEvent);

            /* shashwat.nath@auspost.com updated the below code to set the interim status of the charge account request to "New" when
              the request is submitted */

            List<sObject> updateRelatedRecords = new List<sObject>();
            Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
            dealSupportRequest.Id = billingAccountRecord.billingAccountAttributesDetails.requestObjId;
            dealSupportRequest.Integration_Status__c= 'Requested';
            updateRelatedRecords.add(dealSupportRequest);

            APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
            chargeAccntReq.id = billingAccountRecord.billingAccountValidations.chargeAccountRequestId;
            chargeAccntReq.Status__c = 'New';
            updateRelatedRecords.add(chargeAccntReq);
            //update updateRelatedRecords;
            ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);
            externalOnboardingRequestWithConnectionDetailsVar.connected = false;
            externalOnboardingRequestWithConnectionDetailsVar.onboardingRequestId = onboardingRequestId;
            externalOnboardingRequestWithConnectionDetailsVar.billingAccountWithEmptyfieldsVar = billingAccountRecord;
        }
        return externalOnboardingRequestWithConnectionDetailsVar;
    }
    /**
     * @Description : External Onboarding Request creation method. The created record is used as transaction Id
     *                for request.
     */
    private static String createExternalOnboardingRequest(BillingAccountWrapperForTeams billingAccountWrapperVar){
        String requestObjId = billingAccountWrapperVar.requestObjId;
        String objectName = String.valueOf(id.valueOf(requestObjId).getsobjecttype());

        BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
        bamExternalOnboardingRequest.Request_Object_Name__c = objectName;
        bamExternalOnboardingRequest.Request_Object_Id__c = requestObjId;
        bamExternalOnboardingRequest.Request_Date__c = System.now();
        bamExternalOnboardingRequest.RecordTypeId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('Billing_Account_Creation').getRecordTypeId();
        bamExternalOnboardingRequest.Target_System__c = 'TEAM';
        List<Database.SaveResult> sResult= ApplicationDatabase.getInstance().dmlInsert(new List<BAMExternalOnboardingRequest__c>{bamExternalOnboardingRequest});
        billingAccountWrapperVar.transactionId = String.valueOf(sResult[0].getId());

        BAMExternalOnboardingRequest__c updateBamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
        updateBamExternalOnboardingRequest.Id= String.valueOf(sResult[0].getId());
        updateBamExternalOnboardingRequest.Request_Payload__c = JSON.serialize(billingAccountWrapperVar);
        List<Database.SaveResult> sResultForUpdate= ApplicationDatabase.getInstance().dmlUpdate(new List<BAMExternalOnboardingRequest__c>{updateBamExternalOnboardingRequest});

        return String.valueOf(sResult[0].getId());
    }

    /**
     * @Description: Updates the related DSR and Charge Account and external onborading request based on the initial
     *               response received from camunda
     */
    public static void updateDSRAndChargeAccountAndContract(String requestObjId, String chargeAccountRequestId, String onboardingRequestId,
                                                            String status, String responseMsg, CreateBillingAccountControllerForTeams.contractDetail contractDetails){

        List<sObject> updateRelatedRecords = new List<sObject>();
        Deal_Support_Request__c dealSupportRequest = new Deal_Support_Request__c();
        dealSupportRequest.Id = requestObjId;
        dealSupportRequest.Integration_Status__c= status;
        dealSupportRequest.Integration_Status_Description__c =responseMsg;
        dealSupportRequest.Integration_Transaction_Id__c = onboardingRequestId;
        updateRelatedRecords.add(dealSupportRequest);

        if(status == 'Requested'){
            APT_Charge_Account__c chargeAccntReq = new APT_Charge_Account__c();
            chargeAccntReq.id = chargeAccountRequestId;
            chargeAccntReq.Status__c = 'New';
            updateRelatedRecords.add(chargeAccntReq);

            /*if('Open Ended'.equalsIgnoreCase(contractDetails.contractTerm)){
                Apttus__APTS_Agreement__c apttusContract = new Apttus__APTS_Agreement__c();
                apttusContract.id = contractDetails.contractId;
                apttusContract.Apttus__Contract_End_Date__c = contractDetails.contractEndDate;
                updateRelatedRecords.add(apttusContract);
            }*/

        }
        BAMExternalOnboardingRequest__c bamExternalOnboardingRequest = new BAMExternalOnboardingRequest__c();
        bamExternalOnboardingRequest.Id = onboardingRequestId;
        bamExternalOnboardingRequest.Response_Payload__c = responseMsg;
        if(status =='Error'){
            bamExternalOnboardingRequest.Status__c = status;
        }
        //update bamExternalOnboardingRequest;
        updateRelatedRecords.add(bamExternalOnboardingRequest);
        ApplicationDatabase.getInstance().dmlUpdate(updateRelatedRecords);
    }
    public class ExternalOnboardingRequestWithConnectionDetails{
        @AuraEnabled
        public Boolean connected;
        @AuraEnabled
        public String onboardingRequestId;
        @AuraEnabled
        public billingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
    }
    public static List<SObject> getTeamIntegrationMetadataRecords(String query){
        if(!metadataCoverageRecordsMap.containsKey(query)){
            metadataCoverageRecordsMap.put(query, Database.query(query));
        }
        return metadataCoverageRecordsMap.get(query);
    }
}