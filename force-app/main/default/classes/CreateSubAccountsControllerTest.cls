/* @author 
 * @date 2021-05-12
 * @group Tests
 * @tag Selector
 * @tag BillingAccount
 * @domain Core
 * @description test class for CreateSubAccountsController
 * @changelog
 * 2021-05-12 - seth.heang@auspost.com.au - created
 * 2021-05-13 - dheeraj.mandavilli@auspost.com.au - Updated the test class to include test methods dealing with SubAccountRequest creation/edit,deletion and finalization.
 * 2022-08-04 - Nasir Jawed - added test method for validate lodgement point search
 */
@IsTest
public with sharing class CreateSubAccountsControllerTest {
    @TestSetup
    private static void setup() {
        AusPostSettings__c setting = new AusPostSettings__c(Name = 'CreateBillingAccountCredentials', ApplicationName__c = 'Camunda', URL2__c = 'callout:LAYER7_CERT/csp/customer/v1/billingaccounts');
        insert setting;
    }
    public static void setMetadata(String query, List<SObject> records){
        CreateSubAccountHelper.MetadataCoverageRecordsMap.put(query, records);
    }

    @IsTest
    private static void generateExternalOnboardingRecordTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class); 
        BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);    

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        
        Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
        MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );
        

        Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
        MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        
        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr}; 
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();      
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);
        CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        Test.stopTest();
    }
    
    @IsTest
    private static void generateExternalOnboardingRecordTestWithDummyConnection() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"No"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class); 
        BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);    

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        
        Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
        MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );
        

        Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
        MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        
        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr}; 
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();      
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);
        CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
        
        Test.stopTest();
    }
    @IsTest
    private static void subAccountCreationRequestSuccessScenarioTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class); 
        BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);    

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        
        Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
        MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );
        

        Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
        MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":true,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        
        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr}; 
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.stopStubbing();
        String requestLabel;
        Test.startTest();      
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);  
        CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
        String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
        System.debug('---onboardingRecordJson>>' + onboardingRecordJson);
        Continuation con = (Continuation)CreateSubAccountsController.subAccountCreationRequest(onboardingRecordJson);
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
        Boolean result = CreateSubAccountsController.processResponse(labels, CreateSubAccountsController.stateInfoVar);
        System.assertEquals(true, result);
    }

    @IsTest
    private static void subAccountCreationRequestErrorScenarioTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
        BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,billingAcc.Id, 'Billing_Account__c', true)[0];

        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class); 
        BillingAccountsSelector billingSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);    

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        
        Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
        MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );
        

        Map<Id, Billing_Account__c> mockBillingAccMap = new Map<Id, Billing_Account__c>{billingAcc.Id => billingAcc};
        MockUtility.Mocks.when(billingSelector.selectById(new Set<Id>{billingAcc.Id},new Set<Object>{BillingAccountsSelector.Options.WITH_ORGANISATION})).thenReturn(mockBillingAccMap);

        List<BAMExternalOnboardingRequest__c> onboardingRequest = new List<BAMExternalOnboardingRequest__c>{externalOnboardingRecord};
        String stJson = '{"success":false,"id":' +'"'+ onboardingRequest[0].Id + '"'+ '}';
        Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
        
        list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr}; 
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
        MockUtility.Mocks.stopStubbing();
        String requestLabel;
        Test.startTest();      
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);  
        CreateSubAccountHelper.externalOnboardingRequestWithConnectionDetails onboardingRecord = CreateSubAccountsController.generateExternalOnboardingRecord(sarList, billingAcc.Id);
        String onboardingRecordJson = System.JSON.serialize(onboardingRecord);
        Continuation con = (Continuation)CreateSubAccountsController.subAccountCreationRequest(onboardingRecordJson);
        requestLabel = new List<String>(con.getRequests().keySet())[0];

        // Test setFailStatus() method which set the Sub Account Request passed in parameter, to 'Error' status
        List<APT_Sub_Account__c> failedSARList = CreateSubAccountsController.setFailStatus(sarList);

        Test.stopTest();

        // Verify that the Sub Account Request status = 'Error' after executing CreateSubAccountsController.setFailStatus() method
        System.assertEquals('Error', failedSARList[0].APT_Sub_Account_Request_Status__c);

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
        Boolean result = CreateSubAccountsController.processResponse(labels, CreateSubAccountsController.stateInfoVar);
        System.assertEquals(false, result);
    }
    
    
    @IsTest
    private static void subAccountRequestFinalizeScenarioTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];

        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);  

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        Map<Id, Account> mockOrganisationMap = new Map<Id, Account>{account.Id => account };
        MockUtility.Mocks.when(acctSelector.selectById(mockOrganisationMap.keyset(),new Set<object>{AccountsSelector.Options.WITH_ORGANISATION_ROLES})).thenReturn(mockOrganisationMap );
        
        Map<Id, APT_Sub_Account__c> mockSarMap = new Map<Id, APT_Sub_Account__c>{subAccountRequest.Id => subAccountRequest };
        MockUtility.Mocks.when(subAccReqSelector.selectByIds(mockSarMap.keyset(),new Set<object>{SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT})).thenReturn(mockSarMap );
        
        Test.startTest();      
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);  

        boolean finalizeSARList = CreateSubAccountsController.setPendingStatus(sarList);

        Test.stopTest();

        // Verify that the Sub Account Request status = 'Error' after executing CreateSubAccountsController.setFailStatus() method
        System.assertEquals('Pending Charge Account', sarList[0].APT_Sub_Account_Request_Status__c);
        System.assertEquals(true, finalizeSARList);

    }

    @IsTest
    private static void subAccountRequestDeleteScenarioTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];
        
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector acctSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);  
        SubAccountRequestsSelector subAccReqSelector = (SubAccountRequestsSelector)MockUtility.mockSelector(SubAccountRequestsSelector.class);  

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        Test.startTest();   
        
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);  

        boolean deleteRec = CreateSubAccountsController.deleteSubAccounts(sarList);

        Test.stopTest();

        // Verify that the Sub Account Requests got successfully deleted from CreateSubAccountsController.deleteSubAccounts method
        System.assertEquals(true, deleteRec);

    }

    @IsTest
    private static void getSubAccountRecordValuesfromProposalTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];
        
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
        subAccountRequest.APT_Quote_Proposal__c = proposalRec.Id;

        Test.startTest();   
        
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);

        List<APT_Sub_Account__c> subAccList = CreateSubAccountsController.getRelatedSubAccountRequestsforProposal(proposalRec.Id);
        
        Test.stopTest();

        System.assertNotEquals(null, subAccList);

    }
    

    @IsTest
    private static void getSubAccountRecordValuesfromBillingAccTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        //Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];
        Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1,account.Id,'SAP',true)[0];
        
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.SubAccountContact__c = contact.id;
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
        subAccountRequest.APT_Billing_Account__c = billingAcc.Id;

        Test.startTest();   
        
        List<APT_Sub_Account__c> sarList = new List<APT_Sub_Account__c>();
        sarList.add(subAccountRequest);

        List<APT_Sub_Account__c> subAccList = CreateSubAccountsController.getRelatedSubAccountRequests(billingAcc.Id);
        
        Test.stopTest();

        System.assertNotEquals(null, subAccList);

    }
    
    @IsTest
    private static void getSubAccountRequestUpsertTest() {
        setMetadata(
        'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
        (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class)
        );
        List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
        Account account = accountList[0];
        
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
        
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposalRec = ApplicationTestDataFactory.getApttusProposals(1,contact.Id,true)[0];
        
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test2',true)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336'; 
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'No';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
        subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 2';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
        subAccountRequest.APT_Quote_Proposal__c = proposalRec.Id;
        
        string lodgementPoints = '[{"recId":"a2K1s0000002TMPEA2","recName":"St Kilda","recWCC":"297832","postCode":"3182"},{"recId":"a2K1s0000002TMAEA2","recName":"Flinder Station","recWCC":"879234","postCode":"3000"}]';

        Test.startTest();   
        
        try
        {
            APT_Sub_Account__c subAccRec = CreateSubAccountsController.createSubAccounts(subAccountRequest,lodgementPoints);
        }
        catch(exception e)
        {
        }     

        Test.stopTest();

    }
	
	/**
	 * Test: When the user select the lodgement zone for Charge Account request during the Linking Billing Account to Contract process,
	 * 		Validate that the lodgement zone selected must match the Agreement line items lodgement Zones in the shopping cart.
	 * */
	@IsTest
	private static void validateSearchLodgementZoneTest() {
		MockUtility.disableTriggerExecution();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];
		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, true)[0];

		Product2 prod = ApplicationTestDataFactory.getPSRProducts(1, true)[0];
		prod.Name='Australia Post Parcel Contract';
		prod.ProductCode='APPC';
		prod.Family='APPC';
		prod.APT_Apttus_Product_Classification__c='APPC';
		prod.IsActive=true;
		prod.Apttus_Config2__ConfigurationType__c='Bundle';

		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, true)[0];
		prodConfig.Apttus_QPConfig__Proposald__c =apttusProposals.id;
		prodConfig.Apttus_Config2__Status__c ='Finalized';
		prodConfig = (Apttus_Config2__ProductConfiguration__c)ApplicationTestDataFactory.setUnwritableFields(prodConfig,new Map<String, Object>{
			'APT_APPC_Count_in_Cart__c' => 1
		});

		APT_Lodgement_Zone__c lodgementZone= APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
		lodgementZone.APT_Zone_Structure__c ='APPC';
		lodgementZone.APT_Postcode__c='3000';
		lodgementZone.Name='Capital';

		Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];  
		lineItem.Apttus_Config2__LineType__c = 'Product/Service'; 
		lineItem.Apttus_Config2__ProductId__c= prod.id;
		lineItem.Apttus_Config2__Description__c='Australia Post Parcel Contract';
		lineItem.Apttus_Config2__ConfigurationId__c=prodConfig.id;

		Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
		pav.APT_Lodgement_Zone__c = lodgementZone.Id;             
		pav.APT_Customer_Tier__c = 'T04';
		pav.Apttus_Config2__LineItemId__c=lineItem.id;        
		pav.APT_Additional_Lodgement_Zone_1__c= 'Capital';
		pav.APT_Additional_Lodgement_Zone_2__c= 'Metro';
		lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
		lineItem = (Apttus_Config2__LineItem__c)ApplicationTestDataFactory.setUnwritableFields(lineItem,new Map<String, Object>{
					'Apttus_Config2__AttributeValueId__r' => pav
				});

		// =====================================
		// Stubbing
		// =====================================
		ProductConfigurationSelector prodConfigSelector = (ProductConfigurationSelector)MockUtility.mockSelector(ProductConfigurationSelector.class);
		APT_LodgementZonesSelector lpZoneSelector = (APT_LodgementZonesSelector) MockUtility.mockSelector(APT_LodgementZonesSelector.class);
		LineItemsSelector lineItemSelector = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(prodConfigSelector.selectByProposalId((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}); 

		MockUtility.Mocks.when(lpZoneSelector.selectByZoneStructure(
			(Set<String>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject())).thenReturn(new List<APT_Lodgement_Zone__c>{lodgementZone}); 

		MockUtility.Mocks.when(lineItemSelector.selectByProdConfigAndLineType(
			(Set<Id>)fflib_Match.anyObject(),
			(Set<String>)fflib_Match.anyObject(),
			(Set<Object>)fflib_Match.anyObject()
			)).thenReturn(new List<Apttus_Config2__LineItem__c>{lineItem});     

		MockUtility.Mocks.stopStubbing();

		Test.startTest(); 
		string propID=String.valueOf(apttusProposals.id);
		Boolean validationResult = CreateSubAccountsController.validateSearchLodgementZone(propID,lodgementZone.APT_Postcode__c);
		Test.stopTest();
		System.assertEquals(true, validationResult, 'Expected matched lodgement point result');
    }
}