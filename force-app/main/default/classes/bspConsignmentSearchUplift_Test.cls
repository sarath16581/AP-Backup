/**
 * Created by vcheng on 8/09/2020.
 */
@IsTest
public with sharing class bspConsignmentSearchUplift_Test {
    private static String ARTICLE_NAME = 'NLP2602263';
    private static String MISSING_ITEM = 'Missing Item';
    private static String DELIVERY_ISSUE = 'Delivery Issue';
    private static String RTS_REQUEST = 'RTS Request';

    private static String INTERNATIONAL_EXPRESS = 'International Express';
    private static String PARCEL_POST = 'Parcel Post';
    private static String PARCEL = 'Parcel';
    private static String LETTER = 'Letter';
    @testSetup
    static void testSetup() {

        Id deliveryEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId();
        Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
        Id ssswDeliveryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWDelivery').getRecordTypeId();

        CCUSettings__c setting = new CCUSettings__c(
                // startrack
                Exclude_case_types__c = 'LDC',
                StarTrackAsyncWebServiceTimeout__c = 10,
                BSPSyncConsignmentSearchTimeout__c = 5,
                Exclude_Case_Purpose__c = 'Controlled Returns',

                // ap
                IncludedRecordTypes__c = 'SSSW%',
                EmailMsgKeyword__c = '%customerservice%',
                Max_Length_for_Consignment_Number__c = 40,
                Pickup_Booking_Ref_Number_Max_Length__c = 8,
                Pickup_Booking_Ref_Number_Min_Length__c = 7,
                DeliveryRecordTypeId__c = ssswDeliveryRecordTypeId,
                GeneralRecordTypeId__c = ssswGeneralRecordTypeId,
                APSyncWebServiceTimeout__c = 5,
                AusPostAsyncWebServiceTimeout__c = 10,
                UseContinuationforAPConsignSearch__c = true,
                DoNotShowFileNames__c = 'CN08-',
                APConsignmentSearchSourceSystemID__c = 'SFDC_BSP',

                // general
                MaxEnquiryRecords__c = 500,
                EnquiriesPerPage__c = 15,
                BSPCaseStatusList__c = 'In Progress,Action Required,Resolved,Closed',
                CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id,
                AdminCaseSubject__c = 'Enterprise Contact Registration',
                AttachmentSizeLimit__c = 5
        );
        insert setting;

        List<sobject> ls = TestDataProvider.createStartrackErrorMessagesData();

        List<StarTrack_Transfer_Case_Rule__c> transferCaseRules = new List<StarTrack_Transfer_Case_Rule__c>();
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'StarTrack Next Flight Queue', Product_Group__c = 'Next Flight', Order__c = 1, Business_Solutions_Customer__c = true));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.TRANSFER_QUEUE, Business_Solutions_Customer__c = true, Order__c = 2));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'ETA Queue', Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
        Database.insert(transferCaseRules);

        List<Consignment_Search_Settings__c> cssList = new List<Consignment_Search_Settings__c>();

        cssList.add(new Consignment_Search_Settings__c(Name = 'Consignment No.', Callout_Search_Type__c = 'CONSIGNMENT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Name', Exact_Search__c = true, Article_Case_field__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Billing Account No.', Callout_Search_Type__c = 'BILLINGACCOUNT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Billing_Account__r.LEGACY_ID__c', Exact_Search__c = false, Article_Case_field__c = true, Show_Date_Field__c = true, Show_Suburb_Field__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Page title', Field_Name__c = 'Consignment Search'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Custom', Field_Name__c = 'Custom', Show_Date_Range__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Last Day', Field_Name__c = '1'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of search characters', Field_Name__c = '2'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date diffrence', Field_Name__c = '30'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Special Characters', Field_Name__c = '*,%?\'[]{}'));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Dispatch Date', Field_Name__c = 'Dispatch_Date__c', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Consignment search', Field_Name__c = 'There was an error retrieving Consignment Data', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'No selected Consignment', Field_Name__c = 'No selected Consignment', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'No selected Call Purpose', Field_Name__c = 'No selected Call Purpose', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Case Create Timeout', Field_Name__c = 'Case Create Timeout', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Assign Consignment Timeout', Field_Name__c = 'Assign Consignment Timeout', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Case update', Field_Name__c = 'Error on Case update', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Error on Case create', Field_Name__c = 'Error on Case create', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Enter dates', Field_Name__c = 'Enter dates', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date validation', Field_Name__c = 'date validation', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'date duration error', Field_Name__c = 'date duration error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Number of character error', Field_Name__c = 'Number of character error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Suburb error', Field_Name__c = 'Suburb error', Date_Type__c = true));
        cssList.add(new Consignment_Search_Settings__c(Name = 'Invalid character error', Field_Name__c = 'Invalid character error', Date_Type__c = true));

        Database.insert(cssList);

        List<BSPErrorMessages__c> bspErrorMessages = new List<BSPErrorMessages__c>();
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'Column Error', Message__c = 'A few exceptions did not allow bulk upload to create cases- Your file does not seem to have the right number of columns'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'CSV Error', Message__c = 'A few exceptions did not allow bulk upload to create cases-'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'File Error', Message__c = 'A few exceptions did not allow bulk upload to create cases- Your file seems to be incorrect. Please refer to instructions on Bulk Upload'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'Limit Error', Message__c = 'A few exceptions did not allow bulk upload to create cases- If the CSV file has too many rows, please break it into small files with few rows (~20)'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'NoFile Error', Message__c = 'Bulk Upload was not successful - Please attach a file and try again'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'Tech Error', Message__c = 'A few exceptions did not allow bulk upload to create cases- Technical/Validation Exception. Please check for unique values or incorrect formats or contact our agents to help resolve your file.'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'StarTrack-ConsignmentNotFound', Message__c = 'Consignment Number <consignment_number> was not found.'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'StarTrack-MultipleConsignment', Message__c = 'More than one consignment was found with Consignment Number <consignment_number>.'));
        bspErrorMessages.add(new BSPErrorMessages__c(Name = 'StarTrack-NotAutorized', Message__c = 'Consignment Number <consignment_number> was not found against any of your billing accounts.'));
        Database.insert(bspErrorMessages);

        List<MpbHsp_Mappings__c> MpbHspMappings = new List<MpbHsp_Mappings__c>();
        MpbHspMappings.add(new MpbHsp_Mappings__c(Name = 'other enquiry', Case_Enquiry_Sub_Type__c = 'Product & service information', Case_Product_Category__c = 'Domestic Parcels', Case_Product_Sub_Category__c = 'Parcel Post', Case_Type__c = 'General Enquiry'));
        MpbHspMappings.add(new MpbHsp_Mappings__c(Name = 'technical enquiry', Case_Type__c = 'General Enquiry'));
        Database.insert(MpbHspMappings);

        List<MpbHsp_Tech_Enq_Sub_Map__c> MpbHspTechMappings = new List<MpbHsp_Tech_Enq_Sub_Map__c>();
        MpbHspTechMappings.add(new MpbHsp_Tech_Enq_Sub_Map__c(Name = 'sending parcels', Case_Enquiry_Sub_Type__c = 'Self-service support', Case_Product_Category__c = 'Web & Apps', Case_Product_Sub_Category__c = 'Send a Parcel', Case_Type__c = 'General Enquiry'));
        Database.insert(MpbHspTechMappings);

        List<BSPMappings__c> bspMappings = new List<BSPMappings__c>();
        bspMappings.add(new BSPMappings__c(Name = 'delivery issue', BSPEnquiryType__c = 'Delivery Issue', CaseEnquirySubType__c = 'Delivery Complaint', CaseType__c = 'Investigation'));
        bspMappings.add(new BSPMappings__c(Name = 'cash on delivery', BSPServiceUsed__c = 'Cash On Delivery', CaseProductSubCategory__c = 'Cash On Delivery'));
        bspMappings.add(new BSPMappings__c(Name = 'item search', BSPEnquiryType__c = 'Item Search', CaseEnquirySubType__c = 'Missing Item', CaseType__c = 'Investigation'));
        bspMappings.add(new BSPMappings__c(Name = 'missing item', BSPEnquiryType__c = 'Missing Item', CaseEnquirySubType__c = 'Missing Item', CaseType__c = 'Investigation'));
        bspMappings.add(new BSPMappings__c(Name = 'general enquiry', BSPEnquiryType__c = 'General Enquiry', CaseEnquirySubType__c = 'Tracking', CaseType__c = 'General Enquiry', CaseProductCategory__c='Domestic Parcels', CaseProductSubCategory__c='eParcel- Regular'));
        bspMappings.add(new BSPMappings__c(Name = 'rts request', BSPEnquiryType__c = 'RTS Request', CaseEnquirySubType__c = 'RTS Request', CaseType__c = 'Feedback'));
        bspMappings.add(new BSPMappings__c(Name = 'international express',CaseProductSubCategory__c=INTERNATIONAL_EXPRESS));
        bspMappings.add(new BSPMappings__c(Name = 'parcel post',CaseProductSubCategory__c=PARCEL_POST));
        Database.insert(bspMappings);

        Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.Business_Solutions_Customer__c = true;
        testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
        Database.insert(testAccount);

        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);

        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 4, new List<Account>{
                testAccount
        });
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].LEGACY_ID__c = '12039485';
        testBillingAccList[1].MLID__c = '42N';
        testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[2].LEGACY_ID__c = '20355936';
        testBillingAccList[2].MLID__c = 'JDQ';
        testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[3].LEGACY_ID__c = 'P323456';
        Database.insert(testBillingAccList);

        Id artRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId();
        Id conRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();

        List<Article__c> consignList = new List<Article__c>();
        consignList.add(new Article__c(
                ArticleID__c = ARTICLE_NAME, ArticleLodgementDate__c = System.today() + 10,
                Billing_Account__c = testBillingAccList[1].Id, ExpectedDeliveryDate__c = System.today() + 10,
                Name = ARTICLE_NAME, ProductCategory__c = 'eParcel', RecordTypeId = artRecTypeId,
                ServiceCode__c = '08', SubProduct__c = 'eParcel Standard', TrackingID__c = 'NLP2602263',
                SenderCompany__c = 'Company #123', SenderName__c = 'Nathan Franklin',
                SenderAddressLine1__c = 'MELBOURNE', SenderAddressLine2__c = 'MELBOURNE',
                SenderCity__c = 'MELBOURNE', SenderState__c = 'VIC', SenderPostcode__c = '3000',
                SenderCountry__c = 'AU'
        ));
        consignList.add(new Article__c(ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669', RecordTypeId = conRecTypeId));
        Database.insert(consignList);

        // create cases for verification
        List<Case> newCases = new List<Case>();

        // ST case
        Case newCase = new Case(Origin = BspConstants.CASE_ORIGIN_BSP, Subject = 'Nathan 1', BSP_Addressee_Name__c = 'David 1', Related_Billing_Account__c = testBillingAccList[0].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'High', Status = 'New');
        newCases.add(newCase);

        // ap case
        newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswGeneralRecordTypeId);
        newCase.ProductCategory__c = 'Domestic Letters';
        newCase.Related_Billing_Account__c = testBillingAccList[1].Id;
        newCase.Origin = BspConstants.CASE_ORIGIN_BSP;
        newCases.add(newCase);

        // ap case
        newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswGeneralRecordTypeId);
        newCase.ProductCategory__c = 'Domestic Letters';
        newCase.Related_Billing_Account__c = testBillingAccList[2].Id;
        newCase.Origin = BspConstants.CASE_ORIGIN_BSP;
        newCases.add(newCase);

        // st case
        newCases.add(new Case(Origin = BspConstants.CASE_ORIGIN_BSP, Subject = 'Case 4', BSP_Addressee_Name__c = 'David 3', Related_Billing_Account__c = testBillingAccList[3].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'Low', Status = 'New'));

        Database.insert(newCases);

        // set the createddate of 1 of the cases to test the date filter logic
        Test.setCreatedDate(newCases[0].Id, DateTime.newInstance(2019, 1, 10));

        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE, CCUAuthorisedAllOrgCases__c = true);
        Database.insert(newCon);

        Database.insert(new BSPStarTrackCaseTypes__c(Name = 'StarTrack Delivery Enquiry', RecordTypeId__c = deliveryEnquiryRecordTypeId));

        Database.insert(new StarTrack_Settings__c(Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10, Redelivery_Redirection_Enquiry__c = 'Sorry We Missed You', PBE_Controlled_Returns__c = 'Controlled Returns Queue',
                Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue', PBE_ETA_Enquiry__c = 'ETA Queue', PBE_Missed_Futile_Enquiry__c = 'Web Bookings Queue', Create_Call_Log_using_Future__c = true,
                BSP_Community_User_Profile_Id__c = String.valueOf([SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id).left(15),
                StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId(), Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));

        Database.insert(new AusPostSettings__c(Name = BspConstants.TIBCO_ENDPOINTURL, URL__c = 'dummy URL'));

        // BAM Specific functionality
        // creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
        Product2 bspProduct = new Product2(Name = 'BSP');
        insert bspProduct;

        BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
        insert app;

        List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')
        };
        insert appRoles;

    }

    private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
        Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
        for(Billing_Account__c billingAccount : billingAccounts) {
            output.put(billingAccount.LEGACY_ID__c, billingAccount);
        }
        return output;
    }

    private static User setupCommunityUser()
    {
        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

        // grab the application roles for BSP so we can assign them to the user
        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
        BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];

        // populate all the billing accounts we will need to use in this test
        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);

        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = false, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
        insert contactApplication;

        // wee need to assign some roles with billing accounts to the contact to test their access
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
                new BAMContactRole__c(ApplicationRole__c = bspAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
        };
        insert contactRoles;

        // add some linked entities to the contact role
        // in this test, only 3 out of the 4 billing accounts are available to this user
        List<BAMLinkedEntity__c> entities = new List<BAMLinkedEntity__c>{
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P1234567').Id, Status__c = 'Active'),
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('12039485').Id, Status__c = 'Active'),
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('20355936').Id, Status__c = 'Active')
        };
        insert entities;
        System.Debug(entities);

        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');
        return u;

    }


    @IsTest
    public static void testSearch()
    {
        List<Article__c> articles = [SELECT Id, Billing_Account__c
        FROM Article__c WHERE Name =: ARTICLE_NAME];

        User commUser = setupCommunityUser();
        System.runAs(commUser) {
            Test.startTest();
            bspConsignmentSearchUplift.search(ARTICLE_NAME);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSubmitRecall()
    {
        List<Article__c> articles = [SELECT Id, Billing_Account__c
        FROM Article__c WHERE Name =: ARTICLE_NAME];
        User commUser = setupCommunityUser();
        System.runAs(commUser) {
            Test.startTest();
            BSPConsignmentSearchUplift.RedirectDetails redirectAddress = new BSPConsignmentSearchUplift.RedirectDetails();
            redirectAddress.Name = 'Test User';
            redirectAddress.Company = 'Test Company';
            redirectAddress.AddressLine1 = 'Test';
            redirectAddress.AddressLine2 = 'Test';
            redirectAddress.City = 'Test';
            redirectAddress.State = 'Test';
            redirectAddress.Postcode = 'Test';
            redirectAddress.Country= 'Test';

            BSPConsignmentSearchUplift.CaseCreationResultWrapper resultWrapper = (BSPConsignmentSearchUplift.CaseCreationResultWrapper) BSPConsignmentSearchUplift.submitRedirect(articles[0].Id, true, redirectAddress);
            System.assertNotEquals(null, resultWrapper.Enquiry, 'Submit Recall Case not created');
            System.assertNotEquals(null, resultWrapper.RedirectRequest, 'Submit Recall redirect incorrect');
            Test.stopTest();
        }
    }



    /***************************************************
     * Scenario:
     * Searching for an AP article when the user has no access to the billing account it is associated with
     ***************************************************/
    @SuppressWarnings('ApexUnresolvableReference')
    static testMethod void testSearchAPSyncAPSingleCon() {

        User u = setupCommunityUser();

        System.runAs(u) {

            Test.startTest();

            BSPConsignmentSearchUplift.consignmentNumber = 'JDQ0184460';
            BSPConsignmentSearchUplift.selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_AUPOST;
            Continuation conti = BSPConsignmentSearchUplift.searchAPAsync();

            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assertEquals(requests.size(), 1);

            // Perform mock callout
            HttpResponse response = new HttpResponse();
            response.setBody(BSPAusPostContinuationCalloutMock.getResponse_singleConsign());

            // Set the fake response for the continuation
            String requestLabel = requests.keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);

            // Invoke callback method
            Object result = Test.invokeContinuationMethod(new BSPConsignmentSearchUplift(), conti);
            System.assertNotEquals(null, result, 'testSearchAPSyncAPSingleCon');

            Test.stopTest();
        }
    }

    static testMethod void testSearchAPSyncSTUnAuth() {

        User u = setupCommunityUser();

        System.runAs(u) {

            Test.startTest();

            String consignmentNumber = '2AT71923';
            String selectedConsignmentSearchType = BspConstants.CON_SEARCH_TYPE_CONSIGNMENT;
            Continuation conti = BSPConsignmentSearchUplift.searchSTAsync(selectedConsignmentSearchType, consignmentNumber);

            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assertEquals(requests.size(), 1);

            // Perform mock callout
            HttpResponse response = new HttpResponse();
            response.setBody(BSPContinuationCalloutMock.getResponse_singleConsign());

            // Set the fake response for the continuation
            String requestLabel = requests.keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);

            // Invoke callback method
            Object result = Test.invokeContinuationMethod(new BSPConsignmentSearchUplift(), conti);
            System.assertNotEquals(null, result, 'testSearchAPSyncSTUnAuth');

            Test.stopTest();
        }
    }

    @IsTest
    static void testSearchSTConsignmentByUniqueExtId() {

        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);

        // update contact to a TEAM billing account so we can get an authenticated view
        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];
        con.BillingAccount__c = billingAccounts.get('P1234567').Id;
        update con;

        // grab the application roles for BSP so we can assign them to the user
        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
        BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
        insert contactApplication;

        // we need to assign some roles with billing accounts to the contact to test their access
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
                new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
        };
        insert contactRoles;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


        //User u = setupCommunityUser();

        System.runAs(u) {

            Test.startTest();

            String selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
            //String selectedConsignmentSearchType = BspConstants.CON_SEARCH_TYPE_CONSIGNMENT;
            Continuation conti = (Continuation) BSPConsignmentSearchUplift.searchSTConsignmentByUniqueExtId(selectedArticle);

            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assertEquals(requests.size(), 1);

            // Perform mock callout
            HttpResponse response = new HttpResponse();
            response.setBody(BSPContinuationCalloutMock.getResponse_uniqueIdResp());

            // Set the fake response for the continuation
            String requestLabel = requests.keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);

            // Invoke callback method
            Object result = Test.invokeContinuationMethod(new BSPConsignmentSearchUplift(), conti);
            System.assertNotEquals(null, result, 'testSearchSTConsignmentByUniqueExtId');

            BSPConsignmentSearchUplift.retrieveArticleEvents();
            BSPConsignmentSearchUplift.getCurrentAddress(BSPConsignmentSearchUplift.singleCon.Id);

            Test.stopTest();
        }
    }

    /**
     * to further coverage
     */
    @IsTest
    public static void testBSPConsignmentSearchMisc()
    {
        BSPConsignmentSearchUplift.setDefaultValues();

        BSPConsignmentSearchUplift bspInstance = new BSPConsignmentSearchUplift();
        bspInstance.createCaseFromConsignDetail();


        //
        Article__c testArticle = [SELECT Id FROM Article__c WHERE Name =: ARTICLE_NAME];
        List<EventMessage__c> events = new  List<EventMessage__c>();
        events.add(new EventMessage__c());
        BSPConsignmentSearchUplift.labelEvents =events;
        BSPConsignmentSearchUplift.selectedConsignmentSearchType='AusPost';
        BSPConsignmentSearchUplift.ConsignmentSerchResultsWrapper csrw = new BSPConsignmentSearchUplift.ConsignmentSerchResultsWrapper();
        csrw.singleCon = testArticle;
         BSPConsignmentSearchUplift.buildWrapperToSendToLWC();
        //csrw.labelEvents = events;
        BSPConsignmentSearchUplift.setUnAuthenticatedValues(csrw);
        BSPConsignmentSearchUplift.selectedEventArticle= 'TR2_66a94898-0927-450e-abfa-defa36972669';
        Map<String, Map<Id, EventMessage__c>> tempMap = new  Map<String, Map<Id, EventMessage__c>>();
        tempMap.put('TR2_66a94898-0927-450e-abfa-defa36972669', new Map<Id, EventMessage__c>());
        BSPConsignmentSearchUplift.articleEventsMap = tempMap;
        BSPConsignmentSearchUplift.retrieveArticleEvents();
    }
    
    
    @IsTest
    static void testSearchSTConsignmentByUniqueExtId2() {

        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);

        // update contact to a TEAM billing account so we can get an authenticated view
        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];
        con.BillingAccount__c = null;//billingAccounts.get('P1234567').Id;
        update con;

        // grab the application roles for BSP so we can assign them to the user
        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
        BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
        insert contactApplication;

        // we need to assign some roles with billing accounts to the contact to test their access
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
                new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
        };
        insert contactRoles;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


        //User u = setupCommunityUser();

        System.runAs(u) {

            Test.startTest();

            String selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
            //String selectedConsignmentSearchType = BspConstants.CON_SEARCH_TYPE_CONSIGNMENT;
            Continuation conti = (Continuation) BSPConsignmentSearchUplift.searchSTConsignmentByUniqueExtId(selectedArticle);

            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assertEquals(requests.size(), 1);

            // Perform mock callout
            HttpResponse response = new HttpResponse();
            response.setBody(BSPContinuationCalloutMock.getResponse_noConFound());

            // Set the fake response for the continuation
            String requestLabel = requests.keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);

            // Invoke callback method
            Object result = Test.invokeContinuationMethod(new BSPConsignmentSearchUplift(), conti);
           /* System.assertNotEquals(null, result, 'testSearchSTConsignmentByUniqueExtId');

            BSPConsignmentSearchUplift.retrieveArticleEvents();
            BSPConsignmentSearchUplift.getCurrentAddress(BSPConsignmentSearchUplift.singleCon.Id);*/
            
             Test.stopTest();
        }
    }
    

}