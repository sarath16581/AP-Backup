/*
 * @date 2021-03-15
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Controller for createSTBillingAccount component and used for billing account creation
 * @changelog
 * 2020-11-18 - Shashwat.Nath@auspost.com.au - Created
 * 2021-06-08 - seth.heang@auspost.com.au - STP-5386 map sender name field from opportunity and to same field on DSR's New Billing Account Request Modal Popup 
 * 2022-08-04 - Seth Heang - Updated parseResponse param due to changes in method signature
 */
public with sharing class CreateBillingAccountControllerForTeams {
    @TestVisible private static final String DSR_OBJECT = 'Deal_Support_Request__c';
    @TestVisible private static stateInfo stateInfoVar;
    /**
    * @Description:  Checks and validation all the required attributes for Billing Account creation and provide
    *                a message to user in case of any one attribute is missing and prevents the billign account
    *                creation till the time all requried attribute is populated.
    *                1. Will generate the Billing account request record using generateBillingAccountCreationRequestFromDSR method
    *                2. Will validatite the attribute details using CreateBillingAccountHelper.BillingAccountValidations method
    */
    @AuraEnabled
    public static CreateTeamsBillingAccountHelper.billingAccountWithEmptyfields billingAccountCreationPreCheck(String recordId){
        CreateTeamsBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar ;
        try {
                String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
                if(ObjectName == DSR_OBJECT){
                    billingAccountWithEmptyfieldsVar = generateBillingAccountCreationRequestFromDSR(recordId, null);
                }
                return billingAccountWithEmptyfieldsVar;
        }
        catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @Descciption  : Generated the External onboading request record prior to actual billing account creation is triggered.
    *                 Uses  CreateTeamsBillingAccountHelper.ExternalOnboardingRequestDetails() for creation.
    * */
    @AuraEnabled
    public static CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails generateExternalOnboardingRecord(String recordId, String billingAccountName){
        CreateTeamsBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar;
        CreateTeamsBillingAccountHelper.ExternalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsVar;
        try {
                String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
                if(ObjectName == DSR_OBJECT){
                    billingAccountWithEmptyfieldsVar = generateBillingAccountCreationRequestFromDSR(recordId, billingAccountName);
                }
                externalOnboardingRequestWithConnectionDetailsVar = CreateTeamsBillingAccountHelper.ExternalOnboardingRequestDetails(billingAccountWithEmptyfieldsVar);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return externalOnboardingRequestWithConnectionDetailsVar;
    }
    /**
   * @Description: Creates the Billing Account Creation Request For Teams using DSR as a base record which has details from multiple objects such as
   *                related organisation, Primary Contact, Credit Assessment.
   *
   */
    public static CreateTeamsBillingAccountHelper.billingAccountWithEmptyfields generateBillingAccountCreationRequestFromDSR(String recordId, String billingAccountName){
        BillingAccountWrapperForTeams billingAccountRequestVar = new BillingAccountWrapperForTeams();
        CreateTeamsBillingAccountHelper.BillingAccountWithEmptyfields billingAccountWithEmptyfieldsVar ;
        CreateTeamsBillingAccountHelper.BillingAccountWithOtherValidations billingAccountOtherValidation = new CreateTeamsBillingAccountHelper.billingAccountWithOtherValidations();
        String tradingName;
        String legalEntityName;
        String contractId;
        String contractTerm;
        String senderNameFromOpportunity;
        Deal_Support_Request__c dealSupportRequest = DealSupportRequestsSelector.newInstance().selectById(new set<Id>{recordId}, new set<object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY}).values()[0];
        String integrationStatus = dealSupportRequest.Integration_Status__c ;
        billingAccountOtherValidation.loggedInUserProfile = ProfilesSelector.newInstance().selectById(new set<id>{userinfo.getProfileId()}).values()[0].name;
        if(dealSupportRequest.APT_Contract__c != null){
            Apttus__APTS_Agreement__c contractRecord = ApttusContractsSelector.newInstance().selectById(new set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY}).values()[0];
            if(contractRecord != null){
                contractId = contractRecord.id;
                contractTerm = contractRecord.Term__c;
                if(contractRecord.Apttus__Account__c != null){
                    Set<String> serviceCodeSet = New Set<String>();
                    List<Apttus_Config2__ProductConfiguration__c> productConfigForServiceCodes = new List<Apttus_Config2__ProductConfiguration__c>();
                    List<String> listServiceCode = new List<String>();
                    List<Credit_Officers_Mapping_For_Teams__mdt> creditOfficersMapping = new List<Credit_Officers_Mapping_For_Teams__mdt>();
                    // Querying the organisation record
                    Account accountRecord =  AccountsSelector.newInstance().selectById(new set<id>{contractRecord.Apttus__Account__c} , new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES}).values()[0];
                    // Checking for Multiple Customer Roles
                    if(accountRecord?.Organisation_Roles__r.size()>1){
                        billingAccountOtherValidation.hasMultipleRoles = true;
                    }
                    else{
                        billingAccountOtherValidation.hasMultipleRoles = false;
                    }
                    if('Customer'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c) || 'Prospect'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c)
                    || 'Known'.equalsIgnoreCase(accountRecord?.Role_Type_Roll_Up__c)){

                        billingAccountOtherValidation.isValidRole = true;
                    }
                    else{
                        billingAccountOtherValidation.isValidRole = false;
                    }
                    // Setting up details for the validations to be displayed to the users on click of Billing account Creation Button
                    billingAccountOtherValidation.chargeAccountRequestId = contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Credit_Assessment__r?.APT_Charge_Account__c;
                    billingAccountOtherValidation.newAccountType = contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Method_of_Payment__c;
                    billingAccountOtherValidation.dsrWorkType = dealSupportRequest.Work_Type__c;
                    billingAccountOtherValidation.physicalStreet = contractRecord.Apttus__Account__r.ShippingStreet;
                    billingAccountOtherValidation.physicalCity = contractRecord.Apttus__Account__r.ShippingCity;
                    billingAccountOtherValidation.physicalState = contractRecord.Apttus__Account__r.ShippingState;
                    billingAccountOtherValidation.physicalPostCode = contractRecord.Apttus__Account__r.ShippingPostalCode;

                    // Setting up the Mailing address from the primary Pickup Location Record associated to the opportunity via csq
                    if(contractRecord.Apttus__Related_Opportunity__c != null){
                        List<Pick_Up_Location__c> primaryPickUpLocationRecord  = new List<Pick_Up_Location__c>();
                        primaryPickUpLocationRecord = PickUpLocationSelector.newInstance().selectById(new Set<ID>{contractRecord.Apttus__Related_Opportunity__r.Primary_Pick_Up_Location__c}).values();
                        if(!primaryPickUpLocationRecord.isEmpty()){
                            billingAccountRequestVar.team.organisations.mailingAddress.addressLine1 = primaryPickUpLocationRecord[0].Address__c;
                            billingAccountRequestVar.team.organisations.mailingAddress.suburb = primaryPickUpLocationRecord[0].Suburb__c;
                            if(primaryPickUpLocationRecord[0].Postcode__c !=null){
                                billingAccountRequestVar.team.organisations.mailingAddress.postcode = Integer.ValueOf(primaryPickUpLocationRecord[0].Postcode__c);
                            }

                        }
                    }

                    //Setting up the Credit Assessment Details
                    billingAccountOtherValidation.creditAssessmentStatus = contractRecord.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.APT_Credit_Assessment_Status__c ;
                    billingAccountRequestVar.team.creditDetails.creditAssessNo = contractRecord.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.name ;
                    billingAccountRequestVar.team.creditDetails.creditLimit = Integer.valueOf(contractRecord.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.StarTrack_Proposed_for_New_Account__c);
                    billingAccountRequestVar.team.creditDetails.estimatedMonthlyRevenue =Integer.valueOf(contractRecord.Apttus_QPComply__RelatedProposalId__r?.APT_Minimum_Monthly_Spend__c);
                    if('Open Ended'.equalsIgnoreCase(contractRecord.Term__c)) {
                        date myDate = date.newInstance( Date.Today().Year(), 08, 01);
                        if(contractRecord.Apttus__Contract_Start_Date__c <= myDate){
                            billingAccountRequestVar.team.creditDetails.nextRevenueDueDate = date.newInstance( Date.Today().Year(), 11, 01);
                        }
                        else{
                            billingAccountRequestVar.team.creditDetails.nextRevenueDueDate = date.newInstance( Date.Today().Year() + 1, 11, 01);
                        }
                    }
                    else if('Fixed Term'.equalsIgnoreCase(contractRecord.Term__c)){
                        billingAccountRequestVar.team.creditDetails.nextRevenueDueDate = contractRecord.Apttus__Contract_End_Date__c;
                    }
                    billingAccountRequestVar.team.creditDetails.authoriser = dealSupportRequest.Name;
                    System.debug('**** Legal Entity Name ***' +legalEntityName);
                    legalEntityName = contractRecord.Apttus__Account__r.Name;
                    if(!String.isBlank(legalEntityName)){
                        System.debug('**** Credit Officer Code ***'+legalEntityName.subString(0,1));
                        creditOfficersMapping = [Select id , Code__c from Credit_Officers_Mapping_For_Teams__mdt where MasterLabel =:legalEntityName.subString(0,1) LIMIT 1];
                    }
                    if(!creditOfficersMapping.isEmpty()) {
                        billingAccountRequestVar.team.creditDetails.creditOfficer = creditOfficersMapping[0].Code__c;
                    }
                    else{
                        billingAccountRequestVar.team.creditDetails.creditOfficer = 'P11';
                    }
                    // Setting up the Primary Contact Details
                    billingAccountRequestVar.team.organisations.primaryContact.email = contractRecord.Apttus__Primary_Contact__r.Email;
                    billingAccountRequestVar.team.organisations.primaryContact.firstName = contractRecord.Apttus__Primary_Contact__r.FirstName;
                    billingAccountRequestVar.team.organisations.primaryContact.lastName = contractRecord.Apttus__Primary_Contact__r.LastName;
                    billingAccountRequestVar.team.organisations.primaryContact.salutation = contractRecord.Apttus__Primary_Contact__r.Salutation;
                    billingAccountRequestVar.team.organisations.primaryContact.jobTitle = contractRecord.Apttus__Primary_Contact__r.Title;
                    if(contractRecord.Apttus__Primary_Contact__r.phone !=null){
                        billingAccountRequestVar.team.organisations.primaryContact.phone = contractRecord.Apttus__Primary_Contact__r.phone;
                    }
                    else{
                        billingAccountRequestVar.team.organisations.primaryContact.phone = contractRecord.Apttus__Primary_Contact__r.MobilePhone;
                    }
                    // Setting up the Secondary Contact Details
                    billingAccountRequestVar.team.organisations.secondaryContact.email = contractRecord.Apttus__Primary_Contact__r.Email;
                    billingAccountRequestVar.team.organisations.secondaryContact.firstName = 'Accounts';
                    billingAccountRequestVar.team.organisations.secondaryContact.lastName = 'Payable';
                    billingAccountRequestVar.team.organisations.secondaryContact.salutation = contractRecord.Apttus__Primary_Contact__r.Salutation;
                    billingAccountRequestVar.team.organisations.secondaryContact.jobTitle = 'Accounts Payable';
                    if(contractRecord.Apttus__Primary_Contact__r.phone !=null){
                        billingAccountRequestVar.team.organisations.secondaryContact.phone = contractRecord.Apttus__Primary_Contact__r.phone;
                    }
                    else{
                        billingAccountRequestVar.team.organisations.secondaryContact.phone = contractRecord.Apttus__Primary_Contact__r.MobilePhone;
                    }

                    //Setting up the Org Details
                    String accountNameVar;
                    String accountName2Var;

                    tradingName = contractRecord.Apttus__Account__r.Organisation_Trading_Name__c;
                    
                    if(contractRecord.Apttus__Account__r.Organisation_Trading_Name__c != null){
                        accountNameVar = billingAccountName;
                        accountName2Var = contractRecord.Apttus__Account__r.Name;
                    }else{
                        accountNameVar = billingAccountName;
                        accountName2Var = '';
                    }
                    // Map the Sender_name_to_appear_on_parcel_label__c field from opportunity and populate the same field on DSR's New Billing Account Request Modal Popup 
                    senderNameFromOpportunity = dealSupportRequest?.Opportunity__r?.Sender_name_to_appear_on_parcel_label__c;

                    billingAccountRequestVar.team.organisations.accountName1 = accountNameVar;
                    billingAccountRequestVar.team.organisations.accountName2 = accountName2Var;
                    billingAccountRequestVar.team.organisations.billingAddress.suburb = contractRecord.Apttus__Account__r.BillingCity;
                    //populating org email with contract primary contact email as TEAM does not expect org email
                    billingAccountRequestVar.team.organisations.primaryContact.email = contractRecord.Apttus__Primary_Contact__r.Email;
                    if(contractRecord.Apttus__Account__r.BillingPostalCode !=null) {
                        billingAccountRequestVar.team.organisations.billingAddress.postcode = Integer.valueOf(contractRecord.Apttus__Account__r.BillingPostalCode);
                    }
                    //Code to Populate address line 1 and line 2
                    if(contractRecord.Apttus__Account__r.BillingStreet != null && contractRecord.Apttus__Account__r.BillingStreet.length() > 25){
                        billingAccountRequestVar.team.organisations.billingAddress.addressLine1 = contractRecord.Apttus__Account__r.BillingStreet.substring(0,25);
                        String addrLine2 = contractRecord.Apttus__Account__r.BillingStreet.substringAfter(contractRecord.Apttus__Account__r.BillingStreet.substring(0,25));
                        billingAccountRequestVar.team.organisations.billingAddress.addressLine2=addrLine2;
                    }else{
                        billingAccountRequestVar.team.organisations.billingAddress.addressLine1 = contractRecord.Apttus__Account__r.BillingStreet;
                    }
                    if(contractRecord.Apttus__Primary_Contact__r.Phone != null){
                        billingAccountRequestVar.team.organisations.phone = contractRecord.Apttus__Primary_Contact__r.Phone;
                    }else{
                        billingAccountRequestVar.team.organisations.phone = contractRecord.Apttus__Primary_Contact__r.MobilePhone;
                    }
                    //Org Control  Details
                    billingAccountRequestVar.team.organisations.abn = contractRecord.Apttus__Account__r.ABN__c;
                    if(contractRecord.Apttus__Account__r.ACN__c !=null){
                        billingAccountRequestVar.team.organisations.acn = contractRecord.Apttus__Account__r.ACN__c;
                    }
                    else{
                        billingAccountRequestVar.team.organisations.acn = '000000000';
                    }
                    // Setting Service Codes
                    productConfigForServiceCodes = ProductConfigurationSelector.newInstance().selectById(new Set<ID>{contractRecord.Apttus_QPComply__RelatedProposalId__c} , new Set<object>{ProductConfigurationSelector.Options.WITH_LINE_ITEMS}).values();
                    if(!productConfigForServiceCodes.isEmpty()){
                        for(Apttus_Config2__LineItem__c lineItem : productConfigForServiceCodes[0].Apttus_Config2__LineItems__r ){
                            serviceCodeSet.add(lineItem.Apttus_Config2__AttributeValueId__r.APT_StarTrack_Service_Type__c);
                            if(!String.IsBlank(lineItem.Apttus_Config2__AttributeValueId__r.Service_Code_Startrack__c)){
                                serviceCodeSet.add(lineItem.Apttus_Config2__AttributeValueId__r.Service_Code_Startrack__c);
                            }
                        }
                    }
                    listServiceCode.addAll(serviceCodeSet);
                    billingAccountRequestVar.team.service = listServiceCode;

                    //Requested record Id
                    billingAccountRequestVar.requestObjId = Id.valueOf(recordId);
                    billingAccountRequestVar.orgRecordId = contractRecord.Apttus__Account__c;
                    billingAccountRequestVar.processType='Assisted Onboarding';
                    billingAccountRequestVar.targetSystem = 'TEAM';

                }
            }
        }
        billingAccountWithEmptyfieldsVar = CreateTeamsBillingAccountHelper.billingAccountValidations(billingAccountRequestVar, integrationStatus , billingAccountOtherValidation,
                tradingName, legalEntityName, contractId, contractTerm, senderNameFromOpportunity);

        return billingAccountWithEmptyfieldsVar;
    }

    /**
    * @Description : Triggers the actual Billing account creation and uses CreateTeamsBillingAccountHelper.createBillingAccountCallOut() for call out
    */

    @AuraEnabled(continuation=true)
    public static Object billingAccountCreationRequest(String externalOnboardingRequestWithConnectionDetailsVar){
        Boolean callOutSuccessful = false;
        String sourceSystem = 'salesforce';
        CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails externalOnboardingRequestWithConnectionDetailsRecord = (CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails)System.JSON.deserialize(externalOnboardingRequestWithConnectionDetailsVar, CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails.class);
        try {
            BillingAccountWrapperForTeams billingAccount = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails;
            billingAccount.transactionId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;
            String billingAccountJson = System.JSON.serialize(billingAccount);
            String requestObjId = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails.requestObjId;
            String chargeAccountRequestId = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountValidations.chargeAccountRequestId;
            String onboardingRequestId = externalOnboardingRequestWithConnectionDetailsRecord.onboardingRequestId;

            contractDetail conDetails = new contractDetail();
            conDetails.contractId = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.contractId;
            conDetails.contractTerm = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.contractTerm;
            conDetails.contractEndDate = externalOnboardingRequestWithConnectionDetailsRecord.billingAccountWithEmptyfieldsVar.billingAccountAttributesDetails.team.creditDetails.nextRevenueDueDate;

            stateInfoVar = new stateInfo();
            stateInfoVar.requestObjId = requestObjId;
            stateInfoVar.chargeAccountRequestId = chargeAccountRequestId;
            stateInfoVar.onboardingRequestId = onboardingRequestId;
            stateInfoVar.contractdetails = conDetails;
            System.debug('I5 BRP billingAccountJson 2 : ' + billingAccountJson);  
            BillingAccountService service = BillingAccountService.getInstance();
            Continuation con = service.getContinuation(billingAccountJson, onboardingRequestId, sourceSystem);
            con.state = stateInfoVar;
            con.continuationMethod = 'processResponse';
           
            return con;
        }
        catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean processResponse(List<String> labels,
    Object state) {
        StateInfo stateinformation = (StateInfo)state;
        HttpResponse response = Continuation.getResponse(labels[0]);
        System.debug('response>>>>'+response);
        BillingAccountService service = BillingAccountService.getInstance();
        Boolean callOutSuccess = service.parseResponse(response, stateinformation.requestObjId, stateinformation.chargeAccountRequestId, stateinformation.onboardingRequestId, stateinformation.contractdetails, null); // added null param due to changes in method signature
        return callOutSuccess;
     }
    public class stateInfo{
        @AuraEnabled
        public string requestObjId;
        @AuraEnabled
        public string chargeAccountRequestId;
        @AuraEnabled
        public string onboardingRequestId;
        @AuraEnabled
        public contractDetail contractdetails;

    }
    public class contractDetail{
        @AuraEnabled
        public string contractId;
        @AuraEnabled
        public string contractTerm;
        @AuraEnabled
        public date contractEndDate;

    }
}