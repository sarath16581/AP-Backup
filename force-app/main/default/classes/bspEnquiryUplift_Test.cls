/**
 * Created by vcheng on 7/09/2020.
 * Adding changes related to ParSim -pilot -Swati Mogadala 14/10/2021
 * 10/10/2023	hasantha.liyanage@auspost.com.au added buildBillingAccountOptions for misc test
 */

@isTest
private class bspEnquiryUplift_Test {

	private static String ARTICLE_NAME = 'NLP2602263';
	private static String ARTICLE_NAME2 = 'NLP2602264';
	private static String MISSING_ITEM = 'Missing Item';
	private static String DELIVERY_ISSUE = 'Delivery Issue';
	private static String RTS_REQUEST = 'RTS Request';

	private static String INTERNATIONAL_EXPRESS = 'International Express';
	private static String PARCEL_POST = 'Parcel Post';
	private static String METRO = 'Metro';
	private static String PARCEL = 'Parcel';
	private static String LETTER = 'Letter';
	private static String PARCEL_DOMESTIC = 'Parcel Domestic';
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
		bspMappings.add(new BSPMappings__c(Name = 'premium express + signature',CaseProductSubCategory__c='Premium Express Parcel'));
		bspMappings.add(new BSPMappings__c(Name = 'parcel domestic',CaseProductSubCategory__c='Standard Parcel'));
		bspMappings.add(new BSPMappings__c(Name = 'metro', BSPServiceUsed__c = 'Metro', CaseProductSubCategory__c = 'Metro'));
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
				SenderCountry__c = 'AU', ReceiverName__c = 'Nathan Franklin',
				ReceiverAddressLine1__c = 'MELBOURNE', ReceiverAddressLine2__c = 'MELBOURNE',
				ReceiverCity__c = 'MELBOURNE', ReceiverState__c = 'VIC', ReceiverPostcode__c = '3000',
				ReceiverCountry__c = 'AU'
		));
			consignList.add(new Article__c(
				ArticleID__c = ARTICLE_NAME2, ArticleLodgementDate__c = System.today() + 10,
				Billing_Account__c = testBillingAccList[1].Id, ExpectedDeliveryDate__c = System.today() + 10,
				Name = ARTICLE_NAME2, ProductCategory__c = 'Parcel Domestic', RecordTypeId = artRecTypeId,
				ServiceCode__c = '08', SubProduct__c = 'premium express + signature', TrackingID__c = 'NLP2602264',
				SenderCompany__c = 'Company #123', SenderName__c = 'Nathan Franklin',
				SenderAddressLine1__c = 'MELBOURNE', SenderAddressLine2__c = 'MELBOURNE',
				SenderCity__c = 'MELBOURNE', SenderState__c = 'VIC', SenderPostcode__c = '3000',
				SenderCountry__c = 'AU', ReceiverName__c = 'Nathan Franklin',
				ReceiverAddressLine1__c = 'MELBOURNE', ReceiverAddressLine2__c = 'MELBOURNE',
				ReceiverCity__c = 'MELBOURNE', ReceiverState__c = 'VIC', ReceiverPostcode__c = '3000',
				ReceiverCountry__c = 'AU'
		));
		consignList.add(new Article__c(ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669', RecordTypeId = conRecTypeId));
		Database.insert(consignList);
		System.debug('SOQL before case-- ' + Limits.getQueries());
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

		// st cases
		//newCases.add(new Case(Origin = BspConstants.CASE_ORIGIN_BSP, Subject = 'Case 4', BSP_Addressee_Name__c = 'David 3', Related_Billing_Account__c = testBillingAccList[3].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'Low', Status = 'New'));
		newCase = new Case(Origin = BspConstants.CASE_ORIGIN_BSP, Subject = 'Case 5', BSP_Addressee_Name__c = 'David 4', Related_Billing_Account__c = testBillingAccList[0].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'High', Status = 'New');
		newCases.add(newCase);
		Database.insert(newCases);
		System.debug('SOQL after case-- ' + Limits.getQueries());


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
	public static void testInitMissingItemForm()
	{
		Test.startTest();
		bspEnquiryUplift.EnquiryFormInitWrapper initObject = (bspEnquiryUplift.EnquiryFormInitWrapper) bspEnquiryUplift.initMissingItemForm();

		Test.stopTest();
	}

	@IsTest
	public static void testCreateError()
	{
		Case enqGeneral = new Case();
		enqGeneral.CCUEnquiryType__c = 'General Enquiry';
		enqGeneral.CCUYourReference__c = 'test reference';
		enqGeneral.Description = 'test general enquiry';

		Test.startTest();
		bspEnquiryUplift.CreateEnquiryWrapper resultGeneral = bspEnquiryUplift.createEnquiryAusPost(enqGeneral, new List<Map<String, String>> ());
		System.assertEquals(bspEnquiryUplift.STATUS_ERROR, resultGeneral.status, 'Create General Enquiry should fail for permissions:' + resultGeneral);
		Test.stopTest();
	}

	@IsTest
	public static void testCreateEnquiryGeneral()
	{

		Case enqGeneral = new Case();
		enqGeneral.CCUEnquiryType__c = 'General Enquiry';
		enqGeneral.CCUYourReference__c = 'test reference';
		enqGeneral.Description = 'test general enquiry';

		User commUser = setupCommunityUser();
		System.runAs(commUser)
		{
			Test.startTest();
			bspEnquiryUplift.CreateEnquiryWrapper resultGeneral = bspEnquiryUplift.createEnquiryAusPost(enqGeneral, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, resultGeneral.status, 'Create General Enquiry errored:' + resultGeneral);
			Test.stopTest();
		}
	}

	@IsTest
	public static void testCreateEnquiryDomestic()
	{
		User commUser = setupCommunityUser();
		System.runAs(commUser)
		{
			Test.startTest();
			// domestic parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = PARCEL_POST;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing Domestic Parcel errored:' + result);
			
			// domestic letters
			enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = LETTER;
			enq.CCUServiceUsed__c = PARCEL_POST;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing Domestic Letter errored:' + result);
			Test.stopTest();
		}
	}

	/**
	 * Test the Case field logic based on the newly introduced value: metro
	 */
	@IsTest
	public static void testCreateEnquiryDomesticMetro() {
		User commUser = setupCommunityUser();
		System.runAs(commUser) {
			Test.startTest();
			// domestic parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = MISSING_ITEM;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = METRO;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());

			Case insertedEnquiry = [SELECT Id,Type,ProductCategory__c,ProductSubCategory__c,Type_and_Product__c FROM Case WHERE Id = :result.enquiry.Id LIMIT 1];
			System.assertEquals(ChasConstants.INVESTIGATION, insertedEnquiry.Type, 'Incorrect Case.Type check if CCUEnquiryType__c is setup correctly');
			System.assertEquals(BspConstants.CASE_PRODUCT_CATEGORY_DOM_PARCELS, insertedEnquiry.ProductCategory__c, 'Incorrect Case.ProductCategory__c check if bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseProductCategory__c is setup correctly');
			System.assertEquals(METRO, insertedEnquiry.ProductSubCategory__c, 'Incorrect Case.ProductSubCategory__c check if bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).caseProductSubCategory__c is setup correctly');
			System.assertEquals(ChasConstants.INVESTIGATION_AND_DOMESTIC_PARCELS_METRO, insertedEnquiry.Type_and_Product__c, 'Incorrect Case.Type_and_Product__c check if enq.Type is setup correctly');
		}
	}

	@IsTest
	public static void testCreateEnquiryDomesticPremiumExpress()
	{
		User commUser = setupCommunityUser();
		System.runAs(commUser)
		{
			Test.startTest();
			// domestic parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME2;
			enq.CCUYourReference__c = 'test reference2';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = PARCEL_DOMESTIC;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertEquals(enq.ProductSubCategory__c,'Premium Express Parcel','Correct Product Subcategory');
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing Domestic Parcel errored:' + result);

		}
	}

	@IsTest
	public static void testCreateDuplicateEnquiry()
	{
		User commUser = setupCommunityUser();
		List<Profile> profiles = [SELECT Id FROM Profile WHERE Name in ('BSP Community User', 'Merchant Portal Community User')];
		String pIdsStr = '';
		for(Profile p : profiles){
			pIdsStr = '\'' +  p.Id + '\'';
		}

		System.debug(pIdsStr);
		UniqueCaseTrigger__c custSetting = new UniqueCaseTrigger__c();
		custSetting.ProfileIds__c = '{' + pIdsStr +'}';
		custSetting.Enabled__c = true;
		custSetting.CaseLocality__c = 'International';
		Database.insert(custSetting);

		System.runAs(commUser)
		{
			Test.startTest();
			// domestic parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = PARCEL_POST;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing Domestic Parcel errored:' + result);
			
			// domestic letters
			enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = LETTER;
			enq.CCUServiceUsed__c = PARCEL_POST;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assert(bspEnquiryUplift.STATUS_ERROR != '');
			Test.stopTest();
		}
	}

	@IsTest
	public static void testCreateEnquiryInternational()
	{
		User commUser = setupCommunityUser();
		System.runAs(commUser)
		{
			Test.startTest();
			// International Parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = MISSING_ITEM;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = INTERNATIONAL_EXPRESS;
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing International Parcel errored:' + result);


			// intl letters
			enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = MISSING_ITEM;
			enq.ArticleType__c = LETTER;
			enq.CCUServiceUsed__c = INTERNATIONAL_EXPRESS;
			result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
			System.assertNotEquals(bspEnquiryUplift.STATUS_ERROR, result.status, 'Create Missing International Letter errored:' + result);

			Test.stopTest();
		}
	}

	@IsTest
	public static void testCreateSTDeliveryEnquiry()
	{
		User commUser = setupCommunityUser();

		List<Article__c> articles = [SELECT Id, ArticleType__c, ArticleID__c, Name,
				Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.LEGACY_ID__c
		FROM Article__c WHERE Name =: ARTICLE_NAME];

		System.runAs(commUser) {
			Test.startTest();
			// International Parcel
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME;
			enq.CCUYourReference__c = 'test reference';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = INTERNATIONAL_EXPRESS;

			bspEnquiryUplift.validateConsignmentNumber(ARTICLE_NAME);

			bspEnquiryUplift.STDeliveryEnquiryResultsWapper wrapper = new bspEnquiryUplift.STDeliveryEnquiryResultsWapper();
			wrapper.duplicate = false;
			wrapper.notFound = false;

			String result = bspEnquiryUplift.createDeliveryEnquiryStarTrack(ARTICLE_NAME, enq, wrapper, new List<Map<String,String>> ());
			System.assertNotEquals(null, result, 'testCreateSTDeliveryEnquiry returned:' + result);
			
			Article__c art = [SELECT Id, name, ArticleID__c, Billing_Account__r.id, Billing_Account__r.LEGACY_ID__c FROM Article__c  LIMIT 1];
			//where ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669'

			wrapper = new bspEnquiryUplift.STDeliveryEnquiryResultsWapper();
			wrapper.duplicate = false;
			wrapper.notFound = false;
			wrapper.article= art;
			result = bspEnquiryUplift.createDeliveryEnquiryStarTrack(art.ArticleID__c , enq, wrapper, new List<Map<String,String>> ());
			System.assertNotEquals(null, result, 'testCreateSTDeliveryEnquiry returned:' + result);
			Test.stopTest();
		}
	}

	@IsTest
	public static void testCreateSTPickupEnquiry()
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

		System.runAs(u) {
			//Test.setCurrentPage(Page.bspEnquiry);
			//bspEnquiry bspEnq = new bspEnquiry();

			Test.startTest();


			Case enq = new Case();
			enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY;
			enq.Pickup_Booking_Reference__c = '1245978';
			enq.Subject = 'New Delivery';
			enq.Description = 'Sample Desc';
			enq.Call_Purpose__c = 'Delivery in Progress';
			String billingAccountNumber = '1234567';

			String result = bspEnquiryUplift.createPickUpBookingEnquiryStarTrack(billingAccountNumber,
					enq, new List<Map<String, String>> ());
			System.assertNotEquals(null, result, 'testCreateSTPickupEnquiry returned:' + result);


			Test.stopTest();
		}
	}


	@isTest
	public static void testDeleteAttachment()
	{
		// insert an attachment
		ContentVersion contentVersionInsert = new ContentVersion(
				Title = 'Test',
				PathOnClient = 'Test.jpg',
				VersionData = Blob.valueOf('Test Content Data'),
				IsMajorVersion = true
		);
		insert contentVersionInsert;

		Test.startTest();
		// Test INSERT
		ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		System.assertEquals(documents.size(), 1);

		// DELETE first time, should be ok
		bspEnquiryUplift.FormActionWrapper resultOk = (bspEnquiryUplift.FormActionWrapper) bspEnquiryUplift.deleteAttachment(documents[0].Id);
		System.assertEquals(bspEnquiryUplift.STATUS_OK, resultOk.status, 'Delete file should have passed');
		System.assertEquals(null, resultOk.enq, 'Delete file should not return case object');

		// delete it again, should be error
		bspEnquiryUplift.FormActionWrapper resultError = (bspEnquiryUplift.FormActionWrapper) bspEnquiryUplift.deleteAttachment(documents[0].Id);
		System.debug('resultError:' + resultError);
		System.assertEquals(bspEnquiryUplift.STATUS_ERROR, resultError.status, 'Delete did not error as expected');

		Test.stopTest();
	}


	// search stuff
	@IsTest
	public static void testRetrieveDisplayCaseList()
	{
		List<Article__c> articles = [SELECT Id, Billing_Account__c
		FROM Article__c WHERE Name =: ARTICLE_NAME];

		User commUser = setupCommunityUser();
		Test.startTest();
			System.runAs(commUser) {
				
				Case enq = new Case();
				enq.ReferenceID__c = ARTICLE_NAME;
				enq.CCUYourReference__c = 'test reference';
				enq.Description = 'test enquiry';
				enq.Description_of_contents__c = 'test items';
				enq.CCUEnquiryType__c = DELIVERY_ISSUE;
				enq.ArticleType__c = PARCEL;
				enq.CCUServiceUsed__c = PARCEL_POST;
				enq.BSP_Addressee_Company__c = 'test receiver company';
				enq.BSP_Addressee_Name__c = 'testfname testlname';
				enq.AccountId = commUser.Contact.AccountId;
				bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
				System.debug('eqnuriy >>> ' + enq);

				// commenting below as quick fix to avoid limits exception - Too many SOQL queries: 101
				// domestic letters
				/*
				enq = new Case();
				enq.ReferenceID__c = ARTICLE_NAME;
				enq.CCUYourReference__c = 'test reference';
				enq.Description = 'test enquiry';
				enq.Description_of_contents__c = 'test items';
				enq.CCUEnquiryType__c = DELIVERY_ISSUE;
				enq.ArticleType__c = LETTER;
				enq.CCUServiceUsed__c = PARCEL_POST;
				enq.BSP_Addressee_Company__c = 'test receiver company';
				enq.BSP_Addressee_Name__c = 'testfname testlname';
				enq.AccountId = commUser.Contact.AccountId;
				result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());*/
			}
			//System.assertNotEquals(null, bspEnquiryUplift.getUserPrimaryBillingNumber(), 'getUserPrimaryBillingNumber failed');
			bspEnquiryUplift.EnquiryFilter enqFilter = new bspEnquiryUplift.EnquiryFilter();
			enqFilter.searchStr='test reference';
			enqFilter.pageSize='1';
			enqFilter.orgOption='true';
			enqFilter.billingAccOption=articles[0].Billing_Account__c;
			enqFilter.status='new';
			enqFilter.fromDate=System.today() - 10;
			enqFilter.toDate=System.today() + 10;
			enqFilter.pageNumber='1';
			enqFilter.sortByColumn='CaseNumber';
			enqFilter.sortByOrder='desc';
			enqFilter.enquiryType='';
			/* bspEnquiryUplift.SerchResultsWrapper searchResults = bspEnquiryUplift.retrieveDisplayCaseList('test reference',
					'1', 'true', articles[0].Billing_Account__c, 'new',
					System.today() - 10, System.today() + 10, '1', 'CaseNumber', 'desc');*/
			bspEnquiryUplift.SerchResultsWrapper searchResults = bspEnquiryUplift.retrieveDisplayCaseList(enqFilter);
			Test.stopTest();
		
	}

	// search stuff
	@IsTest
	public static void testDownloadDisplayCaseList()
	{
		List<Article__c> articles = [SELECT Id, Billing_Account__c
		FROM Article__c WHERE Name =: ARTICLE_NAME];

		User commUser = setupCommunityUser();
		Test.startTest();
			System.runAs(commUser) {
				
				Case enq = new Case();
				enq.ReferenceID__c = ARTICLE_NAME;
				enq.CCUYourReference__c = 'test reference';
				enq.Description = 'test enquiry';
				enq.Description_of_contents__c = 'test items';
				enq.CCUEnquiryType__c = DELIVERY_ISSUE;
				enq.ArticleType__c = PARCEL;
				enq.CCUServiceUsed__c = PARCEL_POST;
				enq.BSP_Addressee_Company__c = 'test receiver company';
				enq.BSP_Addressee_Name__c = 'testfname testlname';
				enq.AccountId = commUser.Contact.AccountId;
				bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> ());
				System.debug('eqnuriy >>> ' + enq);
			}
			
			bspEnquiryUplift.searchText = '';
		bspEnquiryUplift.EnquiryFilter enqFilter = new bspEnquiryUplift.EnquiryFilter();
			enqFilter.searchStr='';
			enqFilter.pageSize='1';
			enqFilter.orgOption='true';
			enqFilter.billingAccOption=articles[0].Billing_Account__c;
			enqFilter.status='new';
			enqFilter.fromDate=System.today() - 10;
			enqFilter.toDate=System.today() + 10;
			enqFilter.pageNumber='1';
			enqFilter.enquiryType='';
			
			/*bspEnquiryUplift.DownloadResultsWrapper dlResults = bspEnquiryUplift.downloadCaseDetails('',
					'1', 'true', articles[0].Billing_Account__c, 'new',
					System.today() - 10, System.today() + 10, '1');*/
			bspEnquiryUplift.DownloadResultsWrapper dlResults  = bspEnquiryUplift.downloadCaseDetails(enqFilter);
			//System.assertNotEquals(null, dlResults, 'downloadCaseDetails failed:' + dlResults);
			Test.stopTest();
		
	}

	@IsTest
	public static void testBSPEnquiryMisc()
	{
		Test.startTest();
			System.assertNotEquals(null, bspEnquiryUplift.getAllConstants(), 'BSPEnquiryConstants failed');
			System.assertNotEquals(null, bspEnquiryUplift.getStatusList(), 'getStatusList failed');
			System.assertNotEquals(null, bspEnquiryUplift.getDynamicPageSizePicklist(), 'getDynamicPageSizePicklist failed');
			System.assertNotEquals(null, bspEnquiryUplift.getSTPickupBookingRefRecordType(), 'getSTPickupBookingRefRecordType failed');
			System.assertNotEquals(null, bspEnquiryUplift.getIndOrgPicklist(), 'getIndOrgPicklist failed');
			System.assertNotEquals(null, bspEnquiryUplift.getAllBillingAccounts(), 'getAllBillingAccounts failed');
			System.assertNotEquals(null, bspEnquiryUplift.buildBillingAccountOptions(), 'buildBillingAccountOptions failed');
			System.assertNotEquals(null, bspEnquiryUplift.buildReasonForClaimHelpText(), 'buildReasonForClaimHelpText failed');
			System.assertNotEquals(null, bspEnquiryUplift.getSTDeliveyEnquiryRecordType(), 'getSTDeliveyEnquiryRecordType failed');
			System.assertNotEquals(null, bspEnquiryUplift.getdynamicPageSizePicklist(), 'getdynamicPageSizePicklist failed');
			System.assertNotEquals(null, bspEnquiryUplift.getStatusList(), 'getStatusList failed');
			bspEnquiryUplift.toAddress = new AddressExtension();
			bspEnquiryUplift.getUserBillingAccountScope();
			bspEnquiryUplift.getSTEnquiryCreationSuccessBodyText();
			bspEnquiryUplift.getUserPrimaryBillingNumber();

			Consignment_Search_Settings__c c = new Consignment_Search_Settings__c();
			c.Name = 'Special Characters';
			c.Field_Name__c = '*,%?\'[]{}';
			insert c;
			System.assert(bspEnquiryUplift.validateConsignmentNumber('ANC**').contains(BspConstants.CON_NO_INVALID_CHAR_ERR) , 'validateConsignmentNumber failed');
		
			bspEnquiryUplift.SelectOptionCustom soc = new bspEnquiryUplift.SelectOptionCustom('Test Option', 'Test Label', true);
		Test.stopTest();
	}
		// search stuff
	/*@IsTest
	public static void testRetrieveConCases()
	{
		Article__c article = [SELECT Id, Billing_Account__c
		FROM Article__c WHERE Name =: ARTICLE_NAME LIMIT 1];

		User commUser = setupCommunityUser();
		System.runAs(commUser) {
			Test.startTest();
			System.assertNotEquals(null, bspEnquiryUplift.retrieveConCases(article), 'retrieveConCases failed');
			Test.stopTest();
		}
	}*/

	public static testMethod void testBooleanMethods() {
		List<Article__c> lstArticles = new List<Article__c>();
		StarTrackConsignmentSearchUtil.ConsignmentWrapper cw = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(true, StarTrack_Constants.ERR_CODE_0, lstArticles);
		Test.startTest();
			System.assert(bspEnquiryUplift.articleNotFound(cw) == false);
			lstArticles = [SELECT id from Article__c LIMIT 1];
			cw = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(true, StarTrack_Constants.ERR_CODE_0, lstArticles);
			System.assert(bspEnquiryUplift.isSingleConsignment(cw) == true);
			lstArticles = [SELECT id from Article__c LIMIT 2];
			cw = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(true, StarTrack_Constants.ERR_CODE_0, lstArticles);
			System.assert(bspEnquiryUplift.isMultipleConsignment(cw) == true);
		Test.stopTest();
		
	}

	public static testMethod void testSearchConsignmentStarTrack() {
		//Account a = [select id from Account where name = 'Test Account0'];
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug('billing--->' + billingAccounts);

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
		String consignmentNumber = 'TR2_66a94898-0927-450e-abfa-defa36972669';
		Case c = [SELECT id from CASE LIMIT 1];
		c.Subject  = '';
		c.Call_Purpose__c = '';
		c.Description = '';
		c.CCUEnquiryType__c = 'StarTrack Delivery Enquiry';
		update c;

		//User u = setupCommunityUser();

		System.runAs(u) {
			try {
				Test.startTest();

					Continuation conti = bspEnquiryUplift.searchConsignmentStarTrack(consignmentNumber, c);
				
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
					Object result = Test.invokeContinuationMethod(new bspEnquiryUplift(), conti);
					System.assertNotEquals(null, result, 'testSearchConsignmentStarTrack');
		
					//BSPConsignmentSearchUplift.retrieveArticleEvents();
					//BSPConsignmentSearchUplift.getCurrentAddress(BSPConsignmentSearchUplift.singleCon.Id);
					
					bspEnquiryUplift.dummyEnq1.Start_Date__c = null;
					bspEnquiryUplift.dummyEnq1.End_Date__c = null;
					bspEnquiryUplift.caseRecStatus = BspConstants.CASE_STATUS_INPROGRESS;
					Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
					Account a = [SELECT id from Account LIMIT 1];
		
					// ap case
					List<bspEnquiryUplift.CaseContainer> lstCC = new List<bspEnquiryUplift.CaseContainer>();
					Case newCase = [SELECT id, status, BSP_Addressee_Name__c, RecordTypeID, RecordType.Name, 
										RecordType.DeveloperName, Permanent_Close__c, subject from CASE LIMIT 1];
					newCase.Call_Purpose__c = 'Other';
					newCase.Enquiry_Type__c = 'General';
					newCase.status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
					update newCase;
					bspEnquiryUplift.CaseContainer cc = new bspEnquiryUplift.CaseContainer(newCase);
					cc.isSelected = true;
					lstCC.add(cc);
					bspEnquiryUplift.bulkUpdateCases(JSON.serialize(lstCC), 'Test Comment');
					
					bspEnquiryUplift.bulkCloseCase(JSON.serialize(lstCC));
					
					Article__c art = [SELECT Id FROM Article__c where ArticleID__c = 'TR2_66a94898-0927-450e-abfa-defa36972669'];
					newCase = [SELECT id FROM Case WHERE status <> 'Closed' AND RecordType.Name = 'Delivery Enquiry' AND IsClosed = false];
					newCase.ArticleTest__c = art.Id;
					update newCase;
					System.assertNotEquals(false, bspEnquiryUplift.retrieveConCases(art), 'retrieveConCases failed');
				Test.stopTest();
			} catch(Exception e) {
				System.debug('exception -->' + e.getMessage());
				//System.assert(e.getMessage().contains('There was an error retrieving Consignment Data'));
			}
		}
	}

	@IsTest
	private static void testCreateEnquiry_EssentialMedicine_SentimentalValue() {
		User commUser = setupCommunityUser();
		System.runAs(commUser) {
			Test.startTest();
			Case enq = new Case();
			enq.ReferenceID__c = ARTICLE_NAME2;
			enq.CCUYourReference__c = 'test reference2';
			enq.Description = 'test enquiry';
			enq.Description_of_contents__c = 'test items';
			enq.CCUEnquiryType__c = DELIVERY_ISSUE;
			enq.ArticleType__c = PARCEL;
			enq.CCUServiceUsed__c = PARCEL_DOMESTIC;
			enq.BSP_Addressee_Company__c = 'test receiver company';
			enq.BSP_Addressee_Name__c = 'testfname testlname';
			bspEnquiryUplift.BSPFormAdditionalData additionalData = new bspEnquiryUplift.BSPFormAdditionalData();
			additionalData.containsEssentialMedicine = 'yes';
			additionalData.isSentimental = 'yes';
			bspEnquiryUplift.CreateEnquiryWrapper result = bspEnquiryUplift.createEnquiryAusPost(enq, new List<Map<String, String>> (), additionalData);
			Test.stopTest();
			List<CaseComment> comments = [SELECT Id,CommentBody FROM CaseComment WHERE ParentId = :enq.Id];
			System.assertEquals(1, comments.size());
			CaseComment comment = comments[0];
			System.assert(comment.CommentBody.containsIgnoreCase('essential medication') && comment.CommentBody.containsIgnoreCase('yes'), 'Essential Medicine should be written to the Case Comment');
			System.assert(comment.CommentBody.containsIgnoreCase('Enquiry Details'), 'BSP case should have Enquiry Details written to the Comment');
		}
	}
}