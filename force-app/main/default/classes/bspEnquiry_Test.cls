/**************************************************
Description:    Test class to cover bspEnquiry
History:
--------------------------------------------------
2017-02-27  David Catindoy  Created
2019-06-10  nathan.franklin@auspost.com.au  Major refactor and rewrite for BAM integration
2020-0`-05  gunith.devasurendra@auspost.com.au All new AusPost BSP cases to have Sender has Originator (REQ2048088)
2021-10-11  seth.heang@auspost.com.au  Uplift SF API Version to 52
**************************************************/
@isTest
private class bspEnquiry_Test {

	@testSetup static void testSetup() {

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
		transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.ETA_QUEUE, Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
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
		MpbHspMappings.add(new MpbHsp_Mappings__c(Name = 'other enquiry', Case_Enquiry_Sub_Type__c = 'Other', Case_Product_Category__c = 'Web & Apps', Case_Product_Sub_Category__c = 'MyPost Business', Case_Type__c = 'General Enquiry',MpbHspEnquiryType__c = 'Other Enquiry' ));
		MpbHspMappings.add(new MpbHsp_Mappings__c(Name = 'missing item', Case_Enquiry_Sub_Type__c = 'Missing item', Case_Product_Category__c = 'Domestic Parcels', Case_Product_Sub_Category__c = 'Parcel Post', Case_Type__c = 'Investigation',MpbHspEnquiryType__c = 'Delivery Enquiry'	));
		MpbHspMappings.add(new MpbHsp_Mappings__c(Name = 'tracking status', Case_Enquiry_Sub_Type__c = 'Tracking', Case_Product_Category__c = 'Domestic Parcels', Case_Product_Sub_Category__c = 'Parcel Post', Case_Type__c = 'General Enquiry',MpbHspEnquiryType__c = 'Delivery Enquiry'	));
		Database.insert(MpbHspMappings);

		List<BSPMappings__c> bspMappings = new List<BSPMappings__c>();
		bspMappings.add(new BSPMappings__c(Name = 'delivery issue', BSPEnquiryType__c = 'Delivery Issue', CaseEnquirySubType__c = 'Delivery Complaint', CaseType__c = 'Investigation'));
		bspMappings.add(new BSPMappings__c(Name = 'cash on delivery', BSPServiceUsed__c = 'Cash On Delivery', CaseProductSubCategory__c = 'Cash On Delivery'));
		bspMappings.add(new BSPMappings__c(Name = 'item search', BSPEnquiryType__c = 'Item Search', CaseEnquirySubType__c = 'Missing Item', CaseType__c = 'Investigation'));
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
				ArticleID__c = 'NLP2602263', ArticleLodgementDate__c = System.today() + 10,
				Billing_Account__c = testBillingAccList[1].Id, ExpectedDeliveryDate__c = System.today() + 10,
				Name = 'NLP2602263', ProductCategory__c = 'eParcel', RecordTypeId = artRecTypeId,
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
				Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue', PBE_ETA_Enquiry__c = StarTrack_Constants.ETA_QUEUE, PBE_Missed_Futile_Enquiry__c = StarTrack_Constants.WEB_BOOKINGS_QUEUE, Create_Call_Log_using_Future__c = true,
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

	/**
	 * Scenario:
	 *
	 * When the enquiry page first loads, we need to load and display a list of cases that are accessible to the logged in user.
	 * This test will ensure that the correct cases are loaded based on the access rules defined in by BAM
	 */
	public static testMethod void testCaseListAdminRole() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// grab the cases so we can verify the user has access to them or not
		Map<Id, Case> cases = new Map<Id, Case>([Select Id, Subject, AccountId, Related_Billing_Account__c, Related_Billing_Account__r.LEGACY_ID__c, Related_Billing_Account__r.Id, Related_Billing_Account__r.Organisation__c, ContactId, CreatedById From Case]);
		Map<String, Case> billingAccountCaseMap = new Map<String, Case>();
		for (Case c : cases.values()) {
			billingAccountCaseMap.put(c.Related_Billing_Account__r.LEGACY_ID__c, c);
		}
		System.debug(billingAccountCaseMap);

		Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];
		//BAMApplicationRole__c bspUserRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'User'];

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


		Test.startTest();

		System.runAs(u) {

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();

			// special flag to make the controller think we are dealing with BSP community
			bspEnq.currentNetworkId = bspCommunity.Id;

			// make sure only 3 cases were returned
			System.assertEquals(3, bspEnq.completeList_Paginated.size());

			// check the cases that were returned
			Set<Id> expectedBillingAccountIds = new Set<Id>{ billingAccounts.get('P1234567').Id, billingAccounts.get('12039485').Id, billingAccounts.get('20355936').Id };
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[0].caseObj.Related_Billing_Account__c));
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[1].caseObj.Related_Billing_Account__c));
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[2].caseObj.Related_Billing_Account__c));

			// sorting records to make sure that the order is changed
			bspEnquiry.sortBy = BspConstants.SORTBY_CREATEDDATE;
			bspEnquiry.sortColumnDir = BspConstants.ASC_DIR;
			bspEnq.sortRecords();

			// in these tests our first case is created with a different created date
			// we can verify the sorting here by checking the first case in the list from when we inserted them
			System.assertEquals(billingAccountCaseMap.get('P1234567').Id, bspEnq.completeList_Paginated[0].caseObj.Id);

			// make sure the order changed
			bspEnquiry.sortBy = BspConstants.SORTBY_CREATEDDATE;
			bspEnquiry.sortColumnDir = BspConstants.DESC_DIR;
			bspEnq.sortRecords();
			System.assertEquals(billingAccountCaseMap.get('P1234567').Id, bspEnq.completeList_Paginated[bspEnq.completeList_Paginated.size()-1].caseObj.Id);


			bspEnquiry.sortBy = BspConstants.SORTBY_SENDINGTO;
			bspEnquiry.sortColumnDir = BspConstants.ASC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_SENDINGTO;
			bspEnquiry.sortColumnDir = BspConstants.DESC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_ARTNAME;
			bspEnquiry.sortColumnDir = BspConstants.ASC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_ARTNAME;
			bspEnquiry.sortColumnDir = BspConstants.DESC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_STATUS;
			bspEnquiry.sortColumnDir = BspConstants.ASC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_STATUS;
			bspEnquiry.sortColumnDir = BspConstants.DESC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_ENQUIRY;
			bspEnquiry.sortColumnDir = BspConstants.ASC_DIR;
			bspEnq.sortRecords();

			bspEnquiry.sortBy = BspConstants.SORTBY_ENQUIRY;
			bspEnquiry.sortColumnDir = BspConstants.DESC_DIR;
			bspEnq.sortRecords();

			// search for a case the user does not have access to
			// and make sure no cases were returned

			// to perform sosl searches in TEST classes we need to use setFixedSearchResults to preset our records or else an empty recordset is returned
			// the where/limit/order clauses are applied to the preset list based on the logic that executes the SOSL query
			Test.setFixedSearchResults(new List<Id>{billingAccountCaseMap.get('P323456').Id}); // <-- user does not have access to this account

			bspEnq.searchText = 'Case 4';
			bspEnq.displayCaseList();
			System.assertEquals(0, bspEnq.completeList_Paginated.size());

			// search for a case the user has access to
			// and make sure only the 1 case is returned

			// to perform sosl searches in TEST classes we need to use setFixedSearchResults to preset our records or else an empty recordset is returned
			// the where/limit/order clauses are applied to the preset list based on the logic that executes the SOSL query
			Test.setFixedSearchResults(new List<Id>{billingAccountCaseMap.get('P1234567').Id});

			bspEnq.searchText = 'Case 1';
			bspEnq.displayCaseList();
			System.assertEquals(1, bspEnq.completeList_Paginated.size());
			expectedBillingAccountIds = new Set<Id>{ billingAccounts.get('P1234567').Id };
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[0].caseObj.Related_Billing_Account__c));

			// make sure that only AP cases are returned which should total 2
			// this is also determined by the billing accounts that user has access to
			bspEnq.searchText = '';
			bspEnq.relatedTo = BspConstants.ACCOUNT_TYPE_AUSPOST;
			bspEnq.displayCaseList();
			System.assertEquals(2, bspEnq.completeList_Paginated.size());
			expectedBillingAccountIds = new Set<Id>{ billingAccounts.get('12039485').Id, billingAccounts.get('20355936').Id };
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[0].caseObj.Related_Billing_Account__c));
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[1].caseObj.Related_Billing_Account__c));

			// make sure that only ST cases are returned which should only be 1 based on the only ST billing account the user has access to
			bspEnq.searchText = '';
			bspEnq.relatedTo = BspConstants.ACCOUNT_TYPE_STARTRACK;
			bspEnq.displayCaseList();
			System.assertEquals(1, bspEnq.completeList_Paginated.size());
			expectedBillingAccountIds = new Set<Id>{ billingAccounts.get('P1234567').Id };
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[0].caseObj.Related_Billing_Account__c));

			// make sure the date filter works as expected
			bspEnq.relatedTo = '';
			bspEnq.dummyEnq1.Start_Date__c = Date.newInstance(2019, 1, 1);
			bspEnq.dummyEnq1.End_Date__c = Date.newInstance(2019, 2, 1);
			bspEnq.displayCaseList();
			System.assertEquals(1, bspEnq.completeList_Paginated.size());
			expectedBillingAccountIds = new Set<Id>{ billingAccounts.get('P1234567').Id };
			System.assertEquals(true, expectedBillingAccountIds.contains(bspEnq.completeList_Paginated[0].caseObj.Related_Billing_Account__c));

			// filter and get a list of closed cased which shouldn't be any
			bspEnq.dummyEnq1.Start_Date__c = null;
			bspEnq.dummyEnq1.End_Date__c = null;
			bspEnq.caseRecStatus = BspConstants.CASE_STATUS_CLOSED;
			bspEnq.displayCaseList();
			System.assertEquals(true, bspEnq.myCaseList_Paginated.isEmpty());

			// filter and get a list of in progress cases which should return all cases
			bspEnq.dummyEnq1.Start_Date__c = null;
			bspEnq.dummyEnq1.End_Date__c = null;
			bspEnq.caseRecStatus = BspConstants.CASE_STATUS_INPROGRESS;
			bspEnq.displayCaseList();
			System.assertEquals(3, bspEnq.myCaseList_Paginated.size());

		}

		Test.stopTest();

	}


	/**
	 * Scenario:
	 *
	 * When the enquiry page first loads, we need to load and display a list of cases that are accessible to the logged in user.
	 * This test will ensure that the correct cases are loaded based on the access rules defined in by BAM (as a super admin)
	 */
	public static testMethod void testCaseListSuperAdminRole() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = false, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;

		// wee need to assign some roles with billing accounts to the contact to test their access
		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
				new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
		};
		insert contactRoles;

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();

			// make sure only 3 cases were returned
			System.assertEquals(4, bspEnq.completeList_Paginated.size());

		}

		Test.stopTest();

	}

	/**
	 * Scenario:
	 *
	 * When the enquiry page first loads, we need to load and display a list of cases that are accessible to the logged in user.
	 * This is for the MPB context
	 */
	public static testMethod void testCaseListMPB() {

		Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// special flag to make the controller think we are dealing with BSP community
		Network mpbCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'MpbHelpAndSupport'];

		// should only select 2 cases
		List<Case> cases = [Select Id From Case Where RecordTypeId = :ssswGeneralRecordTypeId];
		for(Case c : cases) {
			c.ContactId = con.Id;
		}
		update cases;

		cases = [Select Id, ContactId From Case Where RecordTypeId = :ssswGeneralRecordTypeId];
		System.debug('CASE DEBUG LIST: ' + cases);

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();
			bspEnq.currentNetworkId = mpbCommunity.Id;
			bspEnq.displayCaseList();

			// make sure only 2 cases are found
			System.assertEquals(2, bspEnq.completeList_Paginated.size());

		}

		Test.stopTest();

	}

	/**
	 * Scenario:
	 *
	 * Tests Bulk Update and Bulk Close
	 */
	public static testMethod void testCaseBulkActions() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// grab the cases so we can verify the user has access to them or not
		Map<Id, Case> cases = new Map<Id, Case>([Select Id, Subject, AccountId, Related_Billing_Account__c, Related_Billing_Account__r.LEGACY_ID__c, Related_Billing_Account__r.Id, Related_Billing_Account__r.Organisation__c, ContactId, CreatedById From Case]);
		Map<String, Case> billingAccountCaseMap = new Map<String, Case>();
		for (Case c : cases.values()) {
			billingAccountCaseMap.put(c.Related_Billing_Account__r.LEGACY_ID__c, c);
		}
		System.debug(billingAccountCaseMap);

		Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];
		//BAMApplicationRole__c bspUserRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'User'];

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


		Test.startTest();

		System.runAs(u) {

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();

			// special flag to make the controller think we are dealing with BSP community
			bspEnq.currentNetworkId = bspCommunity.Id;

			// make sure only 3 cases were returned
			System.assertEquals(3, bspEnq.completeList_Paginated.size());

			// filter and get a list of in progress cases which should return all cases
			bspEnq.dummyEnq1.Start_Date__c = null;
			bspEnq.dummyEnq1.End_Date__c = null;
			bspEnq.caseRecStatus = BspConstants.CASE_STATUS_INPROGRESS;
			bspEnquiry.Pagination page = new bspEnquiry.Pagination(10, new List<Case>());
			page.getTotalPages();
			bspEnq.displayCaseList();
			System.assertEquals(3, bspEnq.myCaseList_Paginated.size());

			// check bulk case closure

			// test code where one of the cases is in an approval process
			Id approvalCaseId = bspEnq.myCaseListContainer_Paginated[0].caseObj.Id;
			//Approval.lock(bspEnq.myCaseListContainer_Paginated[0].caseObj);

			bspEnq.myCaseListContainer_Paginated[0].isSelected = true;
			bspEnq.myCaseListContainer_Paginated[1].isSelected = true;

			// this will close 2 cases and also will reset myCaseList_Paginated var
			// since our current filter is only IN PROGRESS cases then, we should only have 1 case left.
			bspEnq.bulkCloseCase();
			System.assertEquals(1, bspEnq.myCaseList_Paginated.size());

			List<CaseComment> comments = [Select Id From CaseComment Where ParentId = :approvalCaseId];
			System.assertEquals(0, comments.size());

			// bulk update the case and add a case comment
			Id caseIdWithComment = bspEnq.myCaseListContainer_Paginated[0].caseObj.Id;
			bspEnq.myCaseListContainer_Paginated[0].isSelected = true;
			bspEnq.validateCasesToUpdate();
			bspEnq.caseCommentBulk = 'My Test Comment';
			bspEnq.bulkUpdateCases();

			// make sure a comment was created
			comments = [Select Id From CaseComment Where ParentId = :caseIdWithComment];
			System.assertEquals(1, comments.size());

		}

		Test.stopTest();

	}

	/**
	 * Scenario:
	 *
	 * Testing all the non asserting getters/setters
	 */
	public static testMethod void testGetterSetterMisc() {

		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();

			bspEnq.getIndOrgPicklist();
			bspEnq.getRelatedToList();
			bspEnq.getStatusList();
			bspEnq.getdynamicPageSizePicklist();
			bspEnq.getCaseType();
			bspEnq.getEnquiryType();
			bspEnq.getStates();
			bspEnq.getSearchResultMessage();
			bspEnq.getFromRadio();
			bspEnq.getArticleTypes();
			bspEnq.getServiceUsed();
			bspEnq.getItemContents();
//			bspEnq.getBillingAccounts();

			Boolean maxReach = bspEnq.getMaxResultsFound();
			String maxReachError = bspEnq.getMaxResultsFoundMessage();

			Boolean hasNext = bspEnq.getHasNext();
			System.assert(!hasNext);

			Boolean hasPrev = bspEnq.getHasPrevious();
			System.assert(!hasPrev);

			Integer pageNum = bspEnq.getPageNumber();
			System.assertEquals(pageNum, 1);

			bspEnq.next();

			bspEnq.previous();

		}

		Test.stopTest();

	}


	public static testMethod void testCreateSTDeliveryEnquiry() {

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

		System.runAs(u) {

			Test.startTest();

			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();


			bspEnq.createCase();
			bspEnq.enquiryTypeOnChange();
			bspEnq.refreshPage();

			bspEnq.selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
			bspEnq.enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY;
			bspEnq.consignmentNumber = '2AT71923';
			bspEnq.enq.Subject = 'New Delivery';
			bspEnq.enq.Description = 'Sample Desc';
			bspEnq.enq.Call_Purpose__c = 'Delivery in Progress';

			// the case creation triggers an integration search to retrieve the latest details from the consignment/article
			Continuation conti = bspEnq.createEnquiryStarTrack();

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
			Object result = Test.invokeContinuationMethod(bspEnq, conti);

			System.assertEquals(BspConstants.PAGE_SECTION_THANK_YOU, bspEnq.section);
			System.assertNotEquals(null, bspEnq.newCase);
			System.assertNotEquals(null, bspEnq.newCase.Id);

			bspEnq.refreshPage();
			bspEnq.refreshCreateEnquiryPage();

			Test.stopTest();
		}
	}

	public static testMethod void testCreateSTPickupBookingEnquiry() {
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

		System.runAs(u) {
			Test.setCurrentPage(Page.bspEnquiry);
			bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();

			bspEnq.createCase();
			bspEnq.enquiryTypeOnChange();

			bspEnq.selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
			bspEnq.enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY;
			bspEnq.enq.Pickup_Booking_Reference__c = '1245978';
			bspEnq.enq.Subject = 'New Delivery';
			bspEnq.enq.Description = 'Sample Desc';
			bspEnq.enq.Call_Purpose__c = 'Delivery in Progress';
			bspEnq.billingAccountNumber = '1234567';
			bspEnq.createEnquiryStarTrack();
			bspEnq.refreshPage();

			System.assertNotEquals(null, bspEnq.newCase);
			System.assertNotEquals(null, bspEnq.newCase.Id);
			System.assertEquals(BspConstants.PAGE_SECTION_THANK_YOU, bspEnq.section);

			Test.stopTest();
		}
	}

	/**
	 * Scenario:
	 * In this scenario an AP case is created and linked to an article. The article is queired in SAP-EM to make sure it exists first before creating case.
	 */
	public static testMethod void testAusPostCreateDeliveryEnquiry() {
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

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		System.runAs(u) {
			Test.setCurrentPage(Page.bspEnquiry);
			bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();

			bspEnq.createCase();
			bspEnq.enquiryTypeOnChange();

			bspEnq.selectedEnquiryType = BspConstants.ENQUIRY_TYPE_AP;
			bspEnq.setFirstNameLastName();
			bspEnq.enq.CCUEnquiryType__c = 'Delivery Issue';
			bspEnq.enq.ReferenceID__c = '42N236054201000935101';
			bspEnq.enq.BSPLodgementDate__c = System.today() + 3;
			bspEnq.enq.ArticleType__c = 'Parcel';
			bspEnq.enq.CCUServiceUsed__c = 'Cash On Delivery';
			bspEnq.enq.CCUItemContents__c = 'Computer - Laptop';
			bspEnq.descript = 'Broken Laptop';
			bspEnq.descofcontents = 'This is a broken laptop';
			// TODO WHAT IS THIS??
			//			bspEnq.SF_DisplayAttachmentButton();
			//			bspEnq.fileBody = Blob.valueOf('Unit Test Attachment Body');
			//			bspEnq.fileName = 'Sample';
			//			bspEnq.fileContentType = '.pdf';
			//			bspEnq.fileBodyLength = bspEnq.fileBody.size();
			bspEnq.fromWhoRadio = 'you';
			bspEnq.enq.SecondaryContactFirstName__c = 'David';
			bspEnq.enq.SecondaryContactLastName__c = 'Catindoy';
			bspEnq.enq.SecondaryAccount__c = 'Accenture';
			bspEnq.toAddress = new AddressExtension('line1', 'line2', 'suburb', 'state', 'postcode', 'dpid', 'country');

			// the case creation triggers an integration search to retrieve the latest details from the consignment/article
//			Continuation conti =
			bspEnq.createEnquiryAusPost();

			// Verify that the continuation has the proper requests
//			Map<String, HttpRequest> requests = conti.getRequests();
//			System.assertEquals(requests.size(), 1);
//
//			// Perform mock callout
//			HttpResponse response = new HttpResponse();
//			response.setBody(BSPAusPostContinuationCalloutMock.getResponse_article());
//
//			// Set the fake response for the continuation
//			String requestLabel = requests.keyset().iterator().next();
//			Test.setContinuationResponse(requestLabel, response);
//
//			// Invoke callback method
//			Object result = Test.invokeContinuationMethod(bspEnq, conti);

			System.assertEquals(BspConstants.PAGE_SECTION_THANK_YOU, bspEnq.section);
			System.assertEquals(true, bspEnq.showSuccessMessage);
			System.assertNotEquals(null, bspEnq.enq.Id);
			System.assertEquals('Sender', bspEnq.enq.CaseOriginator__c);

			bspEnq.refreshPage();
			bspEnq.refreshCreateEnquiryPage();

			Test.stopTest();

		}
	}

	/**
	 * Scenario:
	 * In this scenario, the user has first queried an article on the consignment search page and has clicked the 'Create Enquiry' button. It will redirect to bspEnquiry page and pass querystring params that will cause the create enquiry sections to render.
	 */
	public static testMethod void testCaseCreationOnPageLoad() {
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

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		// existing article used for testing
		Article__c article = [Select Id From Article__c Where Name = 'NLP2602263'];

		System.runAs(u) {
			Test.setCurrentPage(Page.bspEnquiry);

			// trigger the logic that will render the page in create mode
			Apexpages.currentPage().getParameters().put('conId', article.Id);
			Apexpages.currentPage().getParameters().put('conSearch', BspConstants.AUTH_SCOPE_AP);

			bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();

			System.assertEquals('NLP2602263', bspEnq.enq.ReferenceID__c);
			System.assertEquals(true, bspEnq.creationFromConsignSearch);

			bspEnq.selectedEnquiryType = BspConstants.ENQUIRY_TYPE_AP;
			bspEnq.enq.CCUServiceUsed__c = 'Cash On Delivery';
			bspEnq.enq.CCUItemContents__c = 'Computer - Laptop';
			bspEnq.descript = 'Broken Laptop';
			bspEnq.descofcontents = 'This is a broken laptop';

			// make sure the correct values got inputted to the case
			bspEnq.setFirstNameLastName();

			System.assertEquals('Company #123', bspEnq.enq.PrimaryAccount__c);
			System.assertEquals('Nathan', bspEnq.enq.PrimaryContactFirstname__c);
			System.assertEquals('Franklin', bspEnq.enq.PrimaryContactLastname__c);

			bspEnq.fromWhoRadio = 'you';
			bspEnq.enq.SecondaryContactFirstName__c = 'David';
			bspEnq.enq.SecondaryContactLastName__c = 'Catindoy';
			bspEnq.enq.SecondaryAccount__c = 'Accenture';
			bspEnq.toAddress = new AddressExtension('line1', 'line2', 'suburb', 'state', 'postcode', 'dpid', 'country');

			// the case creation triggers an integration search to retrieve the latest details from the consignment/article
//			Continuation conti =
			bspEnq.createEnquiryAusPost();

			// Verify that the continuation has the proper requests
//			Map<String, HttpRequest> requests = conti.getRequests();
//			System.assertEquals(requests.size(), 1);
//
//			// Perform mock callout
//			HttpResponse response = new HttpResponse();
//			response.setBody(BSPAusPostContinuationCalloutMock.getResponse_article());
//
//			// Set the fake response for the continuation
//			String requestLabel = requests.keyset().iterator().next();
//			Test.setContinuationResponse(requestLabel, response);
//
//			// Invoke callback method
//			Object result = Test.invokeContinuationMethod(bspEnq, conti);

			System.assertEquals(BspConstants.PAGE_SECTION_THANK_YOU, bspEnq.section);
			System.assertEquals(true, bspEnq.showSuccessMessage);
			System.assertNotEquals(null, bspEnq.enq.Id);

			bspEnq.refreshPage();
			bspEnq.refreshCreateEnquiryPage();

			Test.stopTest();

		}
	}


	static testMethod void testEnquiryPage_CreateMpbHspEnquiry() {
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {

			Test.setCurrentPage(Page.MpbHspEnquiry);
			bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();
			bspEnq.createCase();
			bspEnq.enquiryTypeOnChange();
			bspEnq.getMpbCaseType();
			bspEnq.getTechMpbCaseType();
			bspEnq.setFirstNameLastName();

			bspEnq.enq.MPB_BSP_Enquiry_Type__c = 'Delivery enquiry';
			bspEnq.enq.MPB_BSP_Tech_Enquiry_Type__c = 'Tracking status';
			bspEnq.enq.ReferenceID__c = '00093459160047634904';
			bspEnq.enq.BSPLodgementDate__c = System.today() + 3;
			bspEnq.enq.ArticleType__c = 'Parcel';
			bspEnq.enq.CCUServiceUsed__c = 'Cash On Delivery';
			bspEnq.enq.CCUItemContents__c = 'Computer - Laptop';
			bspEnq.descript = 'Broken Laptop';
			bspEnq.descofcontents = 'This is a broken laptop';
			bspEnq.SF_DisplayAttachmentButton();
			bspEnq.fromWhoRadio = 'you';
			bspEnq.enq.SecondaryContactFirstName__c = 'David';
			bspEnq.enq.SecondaryContactLastName__c = 'Catindoy';
			bspEnq.enq.SecondaryAccount__c = 'Accenture';
			bspEnq.toAddress = new AddressExtension('line1', 'line2', 'suburb', 'state', 'postcode', 'dpid', 'country');
			bspEnq.submitPageMpbHsp();
			bspEnq.getCaseNo();

			System.assertNotEquals(null, bspEnq.enq);
			System.assertNotEquals(null, bspEnq.enq.Id);

			Test.stopTest();
		}
	}


	static testMethod void testCreateSTEnquiry_NoConFound() {
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

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {
			Test.setCurrentPage(Page.bspEnquiry);
			bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();
			bspEnq.createCase();
			bspEnq.enquiryTypeOnChange();
			bspEnq.selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
			bspEnq.enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY;
			bspEnq.consignmentNumber = '2AT71034';
			bspEnq.enq.Subject = 'New Delivery';
			bspEnq.enq.Description = 'Sample Desc';
			bspEnq.enq.Call_Purpose__c = 'Delivery in Progress';
			Continuation conti = bspEnq.createEnquiryStarTrack();

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
			Object result = Test.invokeContinuationMethod(bspEnq, conti);

			System.assertEquals(true, ApexPages.hasMessages());

			Test.stopTest();
		}
	}

	/*
	 test submitEnquiryFileUpload method when files size exceeds limit
	 */
	static testMethod void testsubmitEnquiryFileUploadLimitExceed() {
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {
			bspEnquiry bspEnq = new bspEnquiry();
			bspEnq.fileBodyLengthdz = '52428801';
			Test.startTest();
			bspEnq.submitEnquiryFileUpload();
			Test.stopTest();
		}
	}

	/*
	 test submitEnquiryFileUpload method when files uploads successfully
	 */
	static testMethod void testsubmitEnquiryFileUpload() {
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {
			Test.setCurrentPage(Page.bspEnquiry);

			bspEnquiry bspEnq = new bspEnquiry();
			bspEnq.fileBodyLengthdz = '1048576';
			bspEnq.fileBodydz = 'testfile';
			bspEnq.fileContentTypedz = 'jpg';
			bspEnq.fileNamedz = 'TestFile';

			Case cs = [SELECT Id FROM Case LIMIT 1];

			Test.startTest();
			bspEnq.submitEnquiryFileUpload();
			bspEnq.convertFilesToAttachmentsAndDeleteFiles(cs.Id, true);
			Test.stopTest();
		}
	}

	private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
		Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
		for(Billing_Account__c billingAccount : billingAccounts) {
			output.put(billingAccount.LEGACY_ID__c, billingAccount);
		}
		return output;
	}

}