/**
 * @description Test Class for BSPConsignmentSearch
 * @author David Catindoy
 * @date Feb 23, 2017
 * @group BSP
 * @changelog
 * 2020-08-12 - Nathan Franklin - Bug fix after removing CaseArticleUtility
 * 2024-06-13	Parveen Kaushik Added default value for mapping model on test data. See CSLU-470 (JIRA) for details. 
 */
@isTest
private class BSPConsignmentSearch_Test {

    @testSetup static void testSetup(){

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

		        CommunityId__c = [SELECT Id FROM Network WHERE UrlPathPrefix = 'bsp'].Id

        );
        insert setting;

	    Database.insert(new StarTrackConsignmentProductIDs__c(Name = '002'));

	    Database.insert(new StarTrack_Settings__c(BSP_Community_User_Profile_Id__c = String.valueOf([SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id).left(15), SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
			                                        Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));

        List<Consignment_Search_Settings__c> searchSettings = new List<Consignment_Search_Settings__c>();

        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Consignment No.', Callout_Search_Type__c = 'CONSIGNMENT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Name', Exact_Search__c = true, Article_Case_field__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Billing Account No.', Callout_Search_Type__c = 'BILLINGACCOUNT', Date_Type__c = false, Date_Literal__c = false, Search_Type__c = true, Field_Name__c = 'Billing_Account__r.LEGACY_ID__c', Exact_Search__c = false, Article_Case_field__c = true, Show_Date_Field__c = true, Show_Suburb_Field__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Page title', Field_Name__c = 'Consignment Search'));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Custom', Field_Name__c = 'Custom', Show_Date_Range__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Last Day', Field_Name__c = '1'));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Number of search characters', Field_Name__c = '2'));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'date diffrence', Field_Name__c = '30'));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Special Characters', Field_Name__c = '*,%?\'[]{}'));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Dispatch Date', Field_Name__c = 'Dispatch_Date__c', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Error on Consignment search', Field_Name__c = 'There was an error retrieving Consignment Data', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'No selected Consignment', Field_Name__c = 'No selected Consignment', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'No selected Call Purpose', Field_Name__c = 'No selected Call Purpose', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Case Create Timeout', Field_Name__c = 'Case Create Timeout', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Assign Consignment Timeout', Field_Name__c = 'Assign Consignment Timeout', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Error on Case update', Field_Name__c = 'Error on Case update', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Error on Case create', Field_Name__c = 'Error on Case create', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Enter dates', Field_Name__c = 'Enter dates', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'date validation', Field_Name__c = 'date validation', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'date duration error', Field_Name__c = 'date duration error', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Number of character error', Field_Name__c = 'Number of character error', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Suburb error', Field_Name__c = 'Suburb error', Date_Type__c = true));
        searchSettings.add(new Consignment_Search_Settings__c(Name = 'Invalid character error', Field_Name__c = 'Invalid character error', Date_Type__c = true));
        Database.insert(searchSettings);

        Database.insert(new AusPostSettings__c(Name = BspConstants.TIBCO_ENDPOINTURL, URL__c = 'dummy URL'));

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);

        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);

        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 3, new List<Account>{testAccount});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].MLID__c = '42N';
        testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[2].LEGACY_ID__c = '20355936';
        testBillingAccList[2].MLID__c = 'JDQ';
        Database.insert(testBillingAccList);

        Id artRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId();
        Id conRecTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();

        List<Article__c> consignList = new List<Article__c>();
        consignList.add(new Article__c(ArticleID__c = 'NLP2602263', ArticleLodgementDate__c = System.today() + 10, Billing_Account__c = testBillingAccList[1].Id, ExpectedDeliveryDate__c = System.today() + 10, Name = 'NLP2602263',
                                       ProductCategory__c = 'eParcel', RecordTypeId = artRecTypeId, ServiceCode__c = '08', SubProduct__c = 'eParcel Standard', TrackingID__c = 'NLP2602263'));
        consignList.add(new Article__c(ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669', RecordTypeId = conRecTypeId));
        Database.insert(consignList);

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

        //Insert Enquiry Mappings
        MiniCaseFieldMapping__c mp = new MiniCaseFieldMapping__c(SAPProductCategory__c ='Parcel Post', SAPProductSubcategory__c ='Parcel Post', ProductCategory__c = 'Domestic Parcels', ProductSubcategory__c = 'eParcel- Regular', Type__c = 'type', MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL);
        insert mp;

        //TODO add CCViewAllOrgCases settings if needed
        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = testBillingAccList[1].Id, AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
        Database.insert(newCon);

    }

    /***************************************************
     * Scenario:
     * Searching for an AP article when the user has no access to the billing account it is associated with
     ***************************************************/
    @SuppressWarnings('ApexUnresolvableReference')
    static testMethod void testAusPostUnauthenticatedContinuationSearch() {

        Contact con = [Select Id, AccountId From Contact Limit 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


        //TODO
        //PageReference pageRef = bspConSearch.createCaseFromConsignDetail();
        //ApexPages.currentPage().getParameters().put('consignmentNumber', '');
        //ApexPages.currentPage().getParameters().put('caseRT', 'AP');

        System.runAs(u) {
            Test.setCurrentPage(Page.BSPConsignmentSearch);

            /*=======================================
             * Searching for an UNauthenticated article
             *=======================================*/
            Test.startTest();

            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            bspConSearch.consignmentNumber = 'JDQ0184460';
            Continuation conti = bspConSearch.searchAPAsync();

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
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);

	        System.assertNotEquals(null, bspConSearch.singleCon.Id);

            System.assertEquals(true, bspConSearch.showConDetail);

            // the current user does not have the necessary rules to see this article in authenticated view
            System.assertEquals(false, bspConSearch.isConsignmentAuthenticated);

            Test.stopTest();
        }
    }

    /***************************************************
     * Scenario:
     * Searching for an AP article when the user has access to the billing account it is associated with
     * NOTE: bspBase_Test covers isArticleAccessible better than this method, this method is to ensure we can actually query the consignment
     ***************************************************/
    @SuppressWarnings('ApexUnresolvableReference')
    static testMethod void testAusPostAuthenticatedContinuationSearch() {

        Contact con = [Select Id, AccountId From Contact Limit 1];
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


        System.runAs(u) {
            Test.setCurrentPage(Page.BSPConsignmentSearch);

            /*=======================================
             * Searching for an authenticated article
             *=======================================*/

            Test.startTest();

            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            bspConSearch.consignmentNumber = '42N236054201000935101';
            Continuation conti = bspConSearch.searchAPAsync();

            // Verify that the continuation has the proper requests
            Map<String, HttpRequest> requests = conti.getRequests();
            System.assertEquals(requests.size(), 1);

            // Perform mock callout
            HttpResponse response = new HttpResponse();
            response.setBody(BSPAusPostContinuationCalloutMock.getResponse_article());

            // Set the fake response for the continuation
            String requestLabel = requests.keyset().iterator().next();
            Test.setContinuationResponse(requestLabel, response);

            // Invoke callback method
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);

	        System.assertNotEquals(null, bspConSearch.singleCon.Id);

            System.assertEquals(true, bspConSearch.showConDetail);

            // the current user does not have the necessary rules to see this article in authenticated view
            System.assertEquals(true, bspConSearch.isConsignmentAuthenticated);

	        PageReference createCasePage = bspConSearch.createCaseFromConsignDetail();

            Test.stopTest();

        }
    }

    /***************************************************
     * Scenario:
     * Searching for an ST consignment when the user has no access to the billing account it is associated with
     ***************************************************/
    @SuppressWarnings('ApexUnresolvableReference')
    static testMethod void testStarTrackUnauthenticatedContinuationSearch() {

        Contact con = [Select Id, AccountId From Contact Limit 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


        System.runAs(u) {
            Test.setCurrentPage(Page.BSPConsignmentSearch);

            /*=======================================
             * Searching for an UNauthenticated article
             *=======================================*/
            Test.startTest();

            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            bspConSearch.consignmentNumber = '2AT71923';
            Continuation conti = bspConSearch.searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, bspConSearch.consignmentNumber);

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
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);

            System.assertEquals(false, String.isEmpty(bspConSearch.selectedArticle));

            System.assertEquals(true, bspConSearch.showConDetail);

            // the current user does not have the necessary rules to see this article in authenticated view
            System.assertEquals(false, bspConSearch.isConsignmentAuthenticated);

            Test.stopTest();
        }
    }

    /***************************************************
     * Scenario:
     * Searching for a StarTrack Consignment when the user has access to the billing account it is associated with
     * This scenario tests authenticated view by Primary Billing Account
     * NOTE: bspBase_Test covers isArticleAccessible better than this method, this method is to ensure we can actually query the consignment
     ***************************************************/
    @SuppressWarnings('ApexUnresolvableReference')
    static testMethod void testStarTrackAuthenticatedContinuationSearch() {
        // setup some rules to enable a search to be completed as authenticated

        // populate all the billing accounts we will need to use in this test
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

        System.runAs(u) {

            Test.setCurrentPage(Page.BSPConsignmentSearch);

            /*=======================================
             * Searching for an authenticated article
             *=======================================*/

            Test.startTest();

            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            // perform AP continuation search of an article that is accessible to the user (via primary billing account defined in @testSetup)
            // this will confirm that the article should rendered in 'authenticated' view
            bspConSearch.consignmentNumber = '2AT71923';
            Continuation conti = bspConSearch.searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, bspConSearch.consignmentNumber);

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
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);

            System.assertNotEquals(null, bspConSearch.singleCon.Id);

            System.assertEquals(true, bspConSearch.showConDetail);

            // the current user has the necessary rules to see this article in authenticated view (primary billing account)
            System.assertEquals(true, bspConSearch.isConsignmentAuthenticated);

            Test.stopTest();

	        PageReference createCasePage = bspConSearch.createCaseFromConsignDetail();

//			List<EventMessage__c> labelEvents = bspConSearch.childConsignments[0].Event_Messages__r;
//			BSPConsignmentSearch.SortWrapper sw1 = new BSPConsignmentSearch.SortWrapper(labelEvents[0], 'ActualDateTime__c', 'DESC');
//			BSPConsignmentSearch.SortWrapper sw2 = new BSPConsignmentSearch.SortWrapper(labelEvents[1], 'ActualDateTime__c', 'DESC');
//			sw1.compareTo(sw2);
//			sw2.compareTo(sw1);
//
//			sw1 = new BSPConsignmentSearch.SortWrapper(labelEvents[0], 'ActualDateTime__c', 'ASC');
//			sw2 = new BSPConsignmentSearch.SortWrapper(labelEvents[1], 'ActualDateTime__c', 'ASC');
//			sw1.compareTo(sw2);
//			sw2.compareTo(sw1);


        }
    }

	/***************************************************
     * Scenario:
     * Searching for a StarTrack Consignment by a unique external id
     * This is used when multiple consignments are returned for the same Consignment Number
     ***************************************************/
	@SuppressWarnings('ApexUnresolvableReference')
	static testMethod void testStarTrackUniqueExternalIdContinuationSearch() {
		// setup some rules to enable a search to be completed as authenticated

		// populate all the billing accounts we will need to use in this test
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

		System.runAs(u) {
			Test.setCurrentPage(Page.BSPConsignmentSearch);
            ApexPages.currentPage().getParameters().put('caseRT', 'ST');

			Test.startTest();


			BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

			// perform AP continuation search of an article that is accessible to the user (via primary billing account defined in @testSetup)
			// this will confirm that the article should rendered in 'authenticated' view
			bspConSearch.selectedArticle = 'TR2_66a94898-0927-450e-abfa-defa36972669';
			Continuation conti = bspConSearch.searchSTConsignmentByUniqueExtId();

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
			Object result = Test.invokeContinuationMethod(bspConSearch, conti);

			System.assertNotEquals(null, bspConSearch.singleCon.Id);
			System.assertEquals(true, bspConSearch.showConDetail);

			// the current user has the necessary rules to see this article in authenticated view (primary billing account)
			System.assertEquals(true, bspConSearch.isConsignmentAuthenticated);

			Test.stopTest();

		}
	}

	/***************************************************
     * Scenario:
     * Search for a StartTrack consignment which is also surfaced within SAP-EM. This will search SAP-EM first and determine it's a startrack product and then will complete the search in the .net interface.
     * NOTE: This is also covers validationError scenario
     ***************************************************/
	@SuppressWarnings('ApexUnresolvableReference')
	static testMethod void testStarTrackSAPEMSearch() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// create the BAMContactApplication__c record to enable the user to search for all consignments within their account (not just the consignments from billing accounts they have access to)
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;


		Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {
			Test.setCurrentPage(Page.BSPConsignmentSearch);
            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
			/*=======================================
			 * Searching for an authenticated article
			 *=======================================*/

			Test.startTest();

			BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

			// trigger validation error to cover validation error scenario
			bspConSearch.consignmentNumber = '7234723476947623497562*';
			System.assertEquals(false, bspConSearch.validateFields());

			// trigger to entry search method which will begin by searching SAP-EM followed by .net since SAP-EM will return a ST product id
			bspConSearch.consignmentNumber = '2AT71923';
			Continuation conti = bspConSearch.search();

			// confirm the starting search context is AusPost
			System.assertEquals(BspConstants.CONSEARCH_TYPE_AUPOST, bspConSearch.selectedConsignmentSearchType);

			// Verify that the continuation has the proper requests
			Map<String, HttpRequest> requests = conti.getRequests();
			System.assertEquals(requests.size(), 1);

			// Perform mock callout
			HttpResponse response = new HttpResponse();
			response.setBody(BSPAusPostContinuationCalloutMock.getResponse_APConsignWithSTProdID());

			// Set the fake response for the continuation
			String requestLabel = requests.keyset().iterator().next();
			Test.setContinuationResponse(requestLabel, response);

			// Invoke callback method
			// this should trigger another search, but this time to the .net interface for StarTrack
			Continuation newContinuation = (Continuation)Test.invokeContinuationMethod(bspConSearch, conti);

			// confirm the search context was switched to .net interface
			System.assertEquals(BspConstants.CONSEARCH_TYPE_STARTRACK, bspConSearch.selectedConsignmentSearchType);

			// Verify that the continuation has the proper requests
			Map<String, HttpRequest> newRequests = newContinuation.getRequests();
			System.assertEquals(newRequests.size(), 1);

			// Perform mock callout
			HttpResponse newResponse = new HttpResponse();
			newResponse.setBody(BSPContinuationCalloutMock.getResponse_singleConsign());

			// Set the fake response for the continuation
			String newRequestLabel = newRequests.keyset().iterator().next();
			Test.setContinuationResponse(newRequestLabel, newResponse);

			// finalise the startrack call and get the results
			Object result = Test.invokeContinuationMethod(bspConSearch, newContinuation);

			System.assertNotEquals(null, bspConSearch.singleCon);
			System.assertEquals(true, bspConSearch.showConDetail);
			System.assertEquals(true, bspConSearch.isConsignmentAuthenticated);

			Test.stopTest();

		}
	}


	/***************************************************
     * Scenario:
     * Searching for a StarTrack Consignment that returns multiple results
     * NOTE: as per existing startrack capability where consignment numbers can be recycled
     ***************************************************/
	@SuppressWarnings('ApexUnresolvableReference')
	static testMethod void testStarTrackMultipleConsignmentsSearch() {

		// populate all the billing accounts we will need to use in this test
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug(billingAccounts);

		// update contact to a TEAM billing account so an 'Authenticated' view is set
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

		System.runAs(u) {
			Test.setCurrentPage(Page.BSPConsignmentSearch);
            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
			Test.startTest();

			BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

			// trigger a search. based on current access, this will trigger a StarTrack search
			bspConSearch.consignmentNumber = '2AT71886';
			Continuation conti = bspConSearch.search();

			// Verify that the continuation has the proper requests
			Map<String, HttpRequest> requests = conti.getRequests();
			System.assertEquals(requests.size(), 1);

			// Perform mock callout
			HttpResponse response = new HttpResponse();
			response.setBody(BSPContinuationCalloutMock.getResponse_multConsign());

			// Set the fake response for the continuation
			String requestLabel = requests.keyset().iterator().next();
			Test.setContinuationResponse(requestLabel, response);

			// Invoke callback method
			Object result = Test.invokeContinuationMethod(bspConSearch, conti);

			// make sure a list will be displayed with the 2 consignments
			System.assertEquals(true, bspConSearch.showConList);
			System.assertEquals(2, bspConSearch.conList.size());

			Test.stopTest();

		}
	}

	/***************************************************
     * Scenario:
     * Searching for a StarTrack Consignment that returns no results
     ***************************************************/
	public static testMethod void testSTConsignmentSearch_NoConFound() {

		// populate all the billing accounts we will need to use in this test
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug(billingAccounts);

		// update contact to a TEAM billing account
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

        System.runAs(u) {

            Test.setCurrentPage(Page.BSPConsignmentSearch);
            ApexPages.currentPage().getParameters().put('consignmentNumber', '2AT71034');
            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            Test.startTest();

            Continuation conti = bspConSearch.search();

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
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);

            System.assert(ApexPages.hasMessages(ApexPages.severity.Error));

            Test.stopTest();

        }
    }

	/***************************************************
     * Scenario:
     * After completing an article search we add a redirect request
     ***************************************************/
	public static testMethod void testAPRedirectRequest() {

		// populate all the billing accounts we will need to use in this test
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug(billingAccounts);

		// update contact to a SAP-ERP billing account that contains an article eligible for redirection
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];
		con.BillingAccount__c = billingAccounts.get('20355936').Id;
		update con;

		Profile p = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'];
		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

        System.runAs(u) {
            Test.setCurrentPage(Page.BSPConsignmentSearch);

	        // force that the user is viewing BSP
	        BspConstants.CURRENT_USER_IS_VIEWING_BSP = true;

            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();

            Test.startTest();

            bspConSearch.consignmentNumber = 'JDQ0184460';

            Continuation conti = bspConSearch.searchAPAsync();

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
            Object result = Test.invokeContinuationMethod(bspConSearch, conti);


            System.assert(bspConSearch.singleCon != null);
            System.assertEquals(false, bspConSearch.childConsignments.isEmpty());

            bspConSearch.selectedEventArticle = bspConSearch.childConsignments[0].Id;
            bspConSearch.retrieveArticleEvents();

            // Test Redirect/Recall
            BSPConsignmentSearch.RedirectDetails redirectDetails = new BSPConsignmentSearch.RedirectDetails();
            redirectDetails.AddressLine1 = 'New Address 1';
            redirectDetails.State = 'VIC';
            redirectDetails.City = 'Meloburne';
            redirectDetails.Name = 'New Name';
            redirectDetails.Postcode = '1234';
            BSPConsignmentSearch.submitRedirect(bspConSearch.singleCon.Id, true, redirectDetails);
            BSPConsignmentSearch.getCurrentAddress(bspConSearch.singleCon.Id);
            System.assertEquals(false, bspConSearch.articleEvents.isEmpty());
            System.assertEquals(5, bspConSearch.articleEvents.size());
            system.assertEquals(1, [SELECT Count(Id) FROM Case WHERE ArticleTest__c = :bspConSearch.singleCon.Id].size());
            system.assertEquals(1, [SELECT Count(Id) FROM RedirectRequest__c WHERE Article__c = :bspConSearch.singleCon.Id].size());

	        Test.stopTest();
        }
    }

//
//    static testMethod void testSTConsignmentSearch_SingleCon() {
//
//        Database.insert(new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            ApexPages.currentPage().getParameters().put('consignmentNumber', '');
//            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//            bspConSearch.getConsignmentSearchType();
//            Boolean validBillingAcc = bspConSearch.isUserAuthBillAccount('P1234567');
//            System.assertEquals(true, validBillingAcc);
//            PageReference pageRef = bspConSearch.createCaseFromConsignDetail();
//
//            Test.startTest();
//                Continuation conti = bspConSearch.searchConsignment();
//                bspConSearch.consignmentNumber = 'NLP260226312';
//                conti = bspConSearch.searchConsignment();
//                bspConSearch.consignmentNumber = '{}';
//                conti = bspConSearch.searchConsignment();
//                bspConSearch.consignmentNumber = '2AT71923';
//                conti = bspConSearch.searchConsignment();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPContinuationCalloutMock.getResponse_singleConsign());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//
//                List<EventMessage__c> labelEvents = bspConSearch.childConsignments[0].Event_Messages__r;
//                BSPConsignmentSearch.SortWrapper sw1 = new BSPConsignmentSearch.SortWrapper(labelEvents[0], 'ActualDateTime__c', 'DESC');
//                BSPConsignmentSearch.SortWrapper sw2 = new BSPConsignmentSearch.SortWrapper(labelEvents[1], 'ActualDateTime__c', 'DESC');
//                sw1.compareTo(sw2);
//                sw2.compareTo(sw1);
//
//                sw1 = new BSPConsignmentSearch.SortWrapper(labelEvents[0], 'ActualDateTime__c', 'ASC');
//                sw2 = new BSPConsignmentSearch.SortWrapper(labelEvents[1], 'ActualDateTime__c', 'ASC');
//                sw1.compareTo(sw2);
//                sw2.compareTo(sw1);
//            Test.stopTest();
//
//            System.assert(!bspConSearch.childConsignments.isEmpty());
//            System.assert(!bspConSearch.labelEvents.isEmpty());
//        }
//    }
//
//    static testMethod void testSTConsignmentSearch_MultipleCon() {
//
//        Database.insert(new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10, StarTrack_ConSearch_Client_Cert__c = 'testCert',
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 2, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            ApexPages.currentPage().getParameters().put('consignmentNumber', '2AT71886');
//            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                Continuation conti = bspConSearch.searchConsignment();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPContinuationCalloutMock.getResponse_multConsign());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//            Test.stopTest();
//
//            System.assert(bspConSearch.showConList);
//            System.assert(!bspConSearch.conList.isEmpty());
//        }
//    }
//
//    static testMethod void testSTConsignmentSearch_NoConFound() {
//
//        Database.insert(new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        Database.delete([SELECT Id FROM Authorization_Rule__c WHERE AccessRole__c LIKE 'AusPost%']);
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            ApexPages.currentPage().getParameters().put('consignmentNumber', '2AT71034');
//            ApexPages.currentPage().getParameters().put('caseRT', 'ST');
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                Continuation conti = bspConSearch.searchConsignment();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPContinuationCalloutMock.getResponse_noConFound());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//            Test.stopTest();
//        }
//
//        System.assert(ApexPages.hasMessages(ApexPages.severity.Error));
//    }
//
//    static testMethod void testAPSyncandSTConsignmentSearch() {
//
//        Database.insert(new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        Database.insert(new StarTrackConsignmentProductIDs__c(Name = '002'));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                bspConSearch.consignmentNumber = '2AT71923';
//                Test.setMock(WebServiceMock.class, new BSPAPSynchronousMockWithSTProdID());
//
//                Continuation conti = bspConSearch.searchAPAndSTConsignment();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPContinuationCalloutMock.getResponse_singleConsign());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//
//                System.assert(bspConSearch.proceedWithSTConSearch);
//            Test.stopTest();
//
//            System.assertEquals(BspConstants.CONSEARCH_TYPE_STARTRACK, bspConSearch.selectedConsignmentSearchType);
//            System.assertEquals(false, [SELECT Id FROM Article__c WHERE Name = '2AT71923'].isEmpty());
//        }
//    }
//
//    static testMethod void testAPAsyncandSTConsignmentSearch() {
//
//        Database.insert(new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        Database.upsert(new CCUSettings__c(UseContinuationforAPConsignSearch__c = true, APConsignmentSearchSourceSystemID__c = 'dummy', APSyncWebServiceTimeout__c = 5, AusPostAsyncWebServiceTimeout__c = 60, StarTrackAsyncWebServiceTimeout__c = 60, Max_Length_for_Consignment_Number__c = 20, BSP_StarTrack_Auth_Rule_Limit__c = 20));
//
//        Database.insert(new StarTrackConsignmentProductIDs__c(Name = '002'));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                bspConSearch.consignmentNumber = '2AT71923';
//
//                Continuation conti = bspConSearch.searchAPAndSTConsignment();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPAusPostContinuationCalloutMock.getResponse_APConsignWithSTProdID());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//
//                System.assert(bspConSearch.proceedWithSTConSearch);
//            Test.stopTest();
//        }
//    }
//
//    static testMethod void testAPAsyncConsignmentSearch_WithAuth() {
//
//        Database.insert(new StarTrack_Settings__c(BSP_Community_User_Profile_Id__c = String.valueOf([SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id).left(15), SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                bspConSearch.consignmentNumber = 'JDQ0184460';
//
//                Continuation conti = bspConSearch.searchAPConsignmentAsync();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPAusPostContinuationCalloutMock.getResponse_singleConsign());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//
//                System.assert(bspConSearch.singleCon != null);
//                System.assertEquals(false, bspConSearch.childConsignments.isEmpty());
//
//                bspConSearch.selectedEventArticle = bspConSearch.childConsignments[0].Id;
//                bspConSearch.retrieveArticleEvents();
//                // Test Redirect/Recall
//                BSPConsignmentSearch.RedirectDetails redirectDetails = new BSPConsignmentSearch.RedirectDetails();
//                redirectDetails.AddressLine1 = 'New Address 1';
//                redirectDetails.State = 'VIC';
//                redirectDetails.City = 'Meloburne';
//                redirectDetails.Name = 'New Name';
//                redirectDetails.Postcode = '1234';
//                BSPConsignmentSearch.submitRedirect(bspConSearch.singleCon.Id, true, redirectDetails);
//            Test.stopTest();
//
//            System.assertEquals(false, bspConSearch.articleEvents.isEmpty());
//            System.assertEquals(5, bspConSearch.articleEvents.size());
//            system.assertEquals(1, [SELECT Count(Id) FROM Case WHERE ArticleTest__c = :bspConSearch.singleCon.Id].size());
//            system.assertEquals(1, [SELECT Count(Id) FROM RedirectRequest__c WHERE Article__c = :bspConSearch.singleCon.Id].size());
//        }
//    }
//
//    static testMethod void testAPAsyncConsignmentSearch_WithoutAuth() {
//
//        Database.insert(new StarTrack_Settings__c(BSP_Community_User_Profile_Id__c = String.valueOf([SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id).left(15), SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = false, EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
//                                                  Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true, Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 1, Sync_Web_Service_Callout_Timeout__c = 5));
//
//        User bspUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'bspUser' LIMIT 1];
//
//        System.runAs(bspUser) {
//            Test.setCurrentPage(Page.BSPConsignmentSearch);
//            BSPConsignmentSearch bspConSearch = new BSPConsignmentSearch();
//
//            Test.startTest();
//                bspConSearch.consignmentNumber = 'JDQ0184460';
//
//                Continuation conti = bspConSearch.searchAPConsignmentAsync();
//
//                // Verify that the continuation has the proper requests
//                Map<String, HttpRequest> requests = conti.getRequests();
//                System.assertEquals(requests.size(), 1);
//
//                // Perform mock callout
//                HttpResponse response = new HttpResponse();
//                response.setBody(BSPAusPostContinuationCalloutMock.getResponse_singleConsign_NoMLID());
//
//                // Set the fake response for the continuation
//                String requestLabel = requests.keyset().iterator().next();
//                Test.setContinuationResponse(requestLabel, response);
//
//                // Invoke callback method
//                Object result = Test.invokeContinuationMethod(bspConSearch, conti);
//
//                System.assert(bspConSearch.singleCon != null);
//                System.assertEquals(false, bspConSearch.childConsignments.isEmpty());
//
//                bspConSearch.selectedEventArticle = bspConSearch.childConsignments[0].Id;
//                bspConSearch.retrieveArticleEvents();
//            Test.stopTest();
//
//            System.assertEquals(false, bspConSearch.articleEvents.isEmpty());
//            System.assertEquals(3, bspConSearch.articleEvents.size());
//        }
//    }

	private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
		Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
		for(Billing_Account__c billingAccount : billingAccounts) {
			output.put(billingAccount.LEGACY_ID__c, billingAccount);
		}
		return output;
	}

    @IsTest
    public static void testBuildAddress(){
        Article__c article = new Article__c(SenderAddressLine1__c='Line1', SenderCity__c='City', SenderState__c='State', SenderPostcode__c='3000');
        System.assertEquals('Line1, City State 3000', BSPConsignmentSearch.buildSenderAddress(article), 'Address not correctly concatenated');

        article.SenderAddressLine2__c='Line2';
        System.assertEquals('Line1, Line2, City State 3000', BSPConsignmentSearch.buildSenderAddress(article), 'Address not correctly concatenated');

        article.SenderAddressLine3__c='Line3';
        System.assertEquals('Line1, Line2, Line3, City State 3000', BSPConsignmentSearch.buildSenderAddress(article), 'Address not correctly concatenated');

        article.SenderAddressLine4__c='Line4';
        System.assertEquals('Line1, Line2, Line3, Line4, City State 3000', BSPConsignmentSearch.buildSenderAddress(article), 'Address not correctly concatenated');
    }
}