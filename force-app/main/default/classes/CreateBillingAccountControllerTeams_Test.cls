/**
 * Created by shashwat.a.nath on 25/03/2021.
 */

@IsTest
private class CreateBillingAccountControllerTeams_Test {
    @TestSetup
    private static void setup() {
        AusPostSettings__c setting = new AusPostSettings__c(Name = 'CreateBillingAccountCredentials', ApplicationName__c = 'Camunda', URL2__c = 'callout:LAYER7_CERT/csp/customer/v1/billingaccounts');
        insert setting;


    }
    public static void setMetadata(String query, List<SObject> records){
        CreateTeamsBillingAccountHelper.MetadataCoverageRecordsMap.put(query, records);
    }
    @IsTest
    private static void BillingAccountCreationPreCheckTest() {
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockDsrMap);

        Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
        MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockApttusContractMap);

        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        CreateTeamsBillingAccountHelper.billingAccountWithEmptyfields bAccount = CreateBillingAccountControllerForTeams.BillingAccountCreationPreCheck(dealSupportRequest.Id);
        System.assert(!bAccount.emptyAttributesList.isEmpty()) ;
        Test.stopTest();
    }

    @IsTest
    private static void generateExternalOnboardingRecordTest() {
        setMetadata(
                'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'Team_Integration\'',
                (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockDsrMap);

        Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
        MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockApttusContractMap);
        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
        // MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountControllerForTeams.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        Test.stopTest();
    }
    @IsTest
    private static void generateExternalOnboardingRecordTestWithDummyConnection() {
        setMetadata(
                'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'Team_Integration\'',
                (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"No"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockDsrMap);

        Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
        MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockApttusContractMap);
        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountControllerForTeams.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        Test.stopTest();
    }
    @IsTest
    private static void billingAccountCreationRequestTest() {
        setMetadata(
                'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
                (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockDsrMap);

        Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
        MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockApttusContractMap);
        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
        // MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();
        String requestLabel;
        Test.startTest();
        CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountControllerForTeams.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
        String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
        Continuation con = (Continuation)CreateBillingAccountControllerForTeams.billingAccountCreationRequest(onboardingRecordJson);
        requestLabel = new List<String>(con.getRequests().keySet())[0];
        Test.stopTest();
        String mockResponseBody = 'TestBodyResponse';
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(202);
        response.setBody(mockResponseBody);
        Test.setContinuationResponse(requestLabel, response);

        List<String> labels = new List<String>{requestLabel};
        Boolean result = CreateBillingAccountControllerForTeams.processResponse(labels, CreateBillingAccountControllerForTeams.stateInfoVar);
        System.assertEquals(true, result);
    }
    @IsTest
    private static void billingAccountCreationRequestErrorScenarioTest() {
        setMetadata(
                'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
                (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        Account chargeAccount = accountList[1];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,true)[0];
        APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, true)[0];
        Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];
        Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', true)[0];

        apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
        apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
        apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
        apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
        apttusContracts.Apttus__Account__c = account.Id;
        dealSupportRequest.APT_Contract__c = apttusContracts.Id;

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);
        ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        MockUtility.Mocks.when(dsrSelector.selectById(new Set<Id>{dealSupportRequest.Id}, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockDsrMap);

        Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContracts.Id => apttusContracts};
        MockUtility.Mocks.when(apttusContractSelector.selectById(new Set<Id>{dealSupportRequest.APT_Contract__c}, new Set<object>{ApttusContractsSelector.Options.WITH_ORGANISATION,ApttusContractsSelector.Options.WITH_CONTACT,ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT,ApttusContractsSelector.Options.WITH_PROPOSAL,ApttusContractsSelector.Options.WITH_OPPORTUNITY})).thenReturn(mockApttusContractMap);
        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);

        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
        // MockUtility.Mocks.when(mockDatabase.dmlInsert((onboardingRequest),(Boolean)fflib_Match.anyBoolean())).thenReturn(externalOnboardingRecord.Id);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();
        String requestLabel;
        Test.startTest();
        CreateTeamsBillingAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateBillingAccountControllerForTeams.generateExternalOnboardingRecord(dealSupportRequest.Id, 'TestBillingAccountName');
        String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
        Continuation con = (Continuation)CreateBillingAccountControllerForTeams.billingAccountCreationRequest(onboardingRecordJson);
        requestLabel = new List<String>(con.getRequests().keySet())[0];
        Test.stopTest();
        String mockResponseBody = '{"errors":[{"detail":"Error in billing account creation"}]}';
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setBody(mockResponseBody);
        Test.setContinuationResponse(requestLabel, response);

        List<String> labels = new List<String>{requestLabel};
        Boolean result = CreateBillingAccountControllerForTeams.processResponse(labels, CreateBillingAccountControllerForTeams.stateInfoVar);
        System.assertEquals(false, result);
    }
}