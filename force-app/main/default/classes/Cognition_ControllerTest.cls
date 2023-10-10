/*
History:
	2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
*/
@isTest(SeeAllData = false)
public class Cognition_ControllerTest {


	public static String baseUrl = 'https://test.com.au/test/';
	/**
	 * Test setup method to create test data to be used across test methods
	 **/
	@testSetup static void setupdata() {
		Account acc = new Account();
		contact con;
		UserRole ur = new UserRole(Name = 'CEO');
		insert ur;
		User u = new User(
				ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
				LastName = 'last',
				Email = 'test@test.com',
				Username = 'test@test.com' + System.currentTimeMillis(),
				CompanyName = 'TEST',
				Title = 'title',
				Alias = 'alias',
				TimeZoneSidKey = 'America/Los_Angeles',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				UserRoleId = ur.Id
		);
		insert u;
		User thisUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];

		System.runAs(thisUser) {
			acc.Name = 'Test Account';
			acc.LEGACY_ID__c = '60000000';
			acc.OwnerId = u.id;
			insert acc;

			system.debug('Account==>> ' + [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000'
			limit 1
			]);

			con = new contact();
			con.LastName = 'Test';
			con.FirstName = 'FirstName';
			con.email = 'test@sfdc.com';
			con.AccountId = acc.Id;
			insert con;

			List < CognitionAPIs__c > ListSettings = new List < CognitionAPIs__c > ();
			
			//setup ConsignmentInfo endpoint custome setting
			CognitionAPIs__c setting = new CognitionAPIs__c();
			setting.Name = 'ConsignmentInfo';
			setting.API_Name__c = 'Cognition/v1/ConsignmentInfo';
			setting.Error_Message__c = 'Unable to fetch Consignment details';
			setting.Timeout__c = 15000;
			ListSettings.add(setting);
			
			//setup CustomerDetails endpoint custome setting
			CognitionAPIs__c setting1 = new CognitionAPIs__c();
			setting1.Name = 'CustomerDetails';
			setting1.API_Name__c = 'Cognition/v1/CustomerDetails';
			setting1.Error_Message__c = 'Unable to fetch Consignment details';
			ListSettings.add(setting1);
		
			//setup ConsignmentReportData endpoint custome setting
			CognitionAPIs__c setting2 = new CognitionAPIs__c();
			setting2.Name = 'ConsignmentReportData';
			setting2.API_Name__c = 'Cognition/v1/DeliveryReportData';
			setting2.Error_Message__c = 'Unable to fetch report data';
			setting2.Timeout__c = 15000;
			ListSettings.add(setting2);
			
			//setup SubmitQuery endpoint custome setting
			CognitionAPIs__c setting3 = new CognitionAPIs__c();
			setting3.Name = 'SubmitQuery';
			setting3.API_Name__c = 'Cognition/v1/SubmitQuery';
			setting3.Error_Message__c = 'Error while requesting data';
			ListSettings.add(setting3);
			
			//setup CustomerSummary endpoint custome setting
			CognitionAPIs__c setting4 = new CognitionAPIs__c();
			setting4.Name = 'CustomerSummary';
			setting4.API_Name__c = 'Cognition/v1/CustomerSummary';
			setting4.Error_Message__c = 'Error while getting customer summary data';
			ListSettings.add(setting4);
			
			//setup QueryStatus endpoint custome setting
			CognitionAPIs__c setting5 = new CognitionAPIs__c();
			setting5.Name = 'QueryStatus';
			setting5.API_Name__c = 'Cognition/v1/QueryStatus';
			setting5.Error_Message__c = 'Error while getting consignment status';
			ListSettings.add(setting5);
			
			//setup Timeout endpoint custome setting
			CognitionAPIs__c setting6 = new CognitionAPIs__c();
			setting6.Name = 'Timeout';
			setting6.API_Name__c = 'Cognition/v1/ReceiverETA';
			setting6.Error_Message__c = 'Unable to fetch Consignment details';
			setting6.Timeout__c = 4000;
			ListSettings.add(setting6);
			
			//setup CustomersNotFound endpoint custome setting
			CognitionAPIs__c setting7 = new CognitionAPIs__c();
			setting7.Name = 'CustomersNotFound';
			setting7.Error_Message__c = 'No customers were found.';
			ListSettings.add(setting7);
			
			//setup ReceiverETA endpoint custome setting
			CognitionAPIs__c setting8 = new CognitionAPIs__c();
			setting8.Name = 'ReceiverETA';
			setting8.API_Name__c = 'Cognition/v1/ReceiverETA';
			setting8.Error_Message__c = 'Error while getting consignment status';
			ListSettings.add(setting8);
			
			//setup PickupInfo endpoint custome setting
			CognitionAPIs__c setting9 = new CognitionAPIs__c();
			setting9.Name = 'PickupInfo';
			setting9.API_Name__c = 'Cognition/v1/PickupInfo';
			setting9.Error_Message__c = 'Unable to fetch Pickup booking details';
			setting9.Timeout__c = 15000;
			ListSettings.add(setting9);
			
			//setup Pickup ReportData endpoint custome setting
			CognitionAPIs__c setting10 = new CognitionAPIs__c();
			setting10.Name = 'PickReportData';
			setting10.API_Name__c = 'Cognition/v1/PickupReportData';
			setting10.Error_Message__c = 'Unable to fetch pickup booking report data';
			setting10.Timeout__c = 15000;
			ListSettings.add(setting10);

			insert ListSettings;
		}
		
		//create test Profile
		Profile profileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'
		LIMIT 1
		];
		
		//create test user
		user usrBsp = new User(LastName = 'BSPTestLN',
				FirstName = 'ABC',
				Alias = 'abcC',
				Email = 'abcCompany@test.com',
				Username = 'abcCompany@test.com.devTrans',
				ProfileId = profileId.id,
				TimeZoneSidKey = 'GMT',
				LanguageLocaleKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				LocaleSidKey = 'en_US',
				ContactId = con.id
		);

		insert usrBsp;

	}

	/**
	 * Testmethod to test AccountList being pulled for cognition screen
	 **/
	private static testMethod void testAccountList() {

		//Cognition_Controller.accountList acc = Cognition_Controller.getAccountString();
		Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		Database.update(testAccount);

		List < Billing_Account__c > testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List < Account > {
				testAccount
		});
		testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[0].Legacy_ID__c = '1111111';
		Database.insert(testBillingAccList);

		Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
		Database.insert(newCon);

		system.debug('billing account++++' + testBillingAccList);
		System.assert(testBillingAccList.size()==2);
		// Map <String,Schema.RecordTypeInfo> recordTypesRules = Authorization_Rule__c.sObjectType.getDescribe().getRecordTypeInfosByName();
		Id RecTypeId = Schema.SObjectType.Authorization_Rule__c.getRecordTypeInfosByName().get('Cognition Rules').getRecordTypeId();

		Authorization_Rule__c rule = new Authorization_Rule__c();
		rule.AccessRole__c = Label.Cognition_User;
		rule.Billing_Account__c = testBillingAccList[0].Id;
		rule.Contact__c = newCon.Id;

		rule.RecordTypeId = RecTypeId;
		Database.insert(rule);
		system.debug('Authorization_Rule__c ++++++' + rule);
		System.assert(rule.Contact__c == newCon.Id);
		
		CustomerCognitionSettings__c settings = CustomerCognitionSettings__c.getOrgDefaults();
		settings.MaxAccountsforInternal__c = 10;
		settings.AuthorizationRuleRecordTypeID__c = RecTypeId;
		settings.BasicAuthnHeader__c = 'U0ZDdXN0b21lckNvZ25pdGlvblBURVNUOiRGQ3VzdEMwZ25pdGkwbg';
		upsert settings CustomerCognitionSettings__c.Id;


		Cognition_Controller.accountList acc = Cognition_Controller.getAccountString();
		Cognition_Controller con = new Cognition_Controller();
		con.reportDataList = null;
		Cognition_Controller.CustomerControllerInnerClass conInner = new Cognition_Controller.CustomerControllerInnerClass();
		conInner.conInfoList = null;
		conInner.DueNotOnboard = 0;
	}

	/**
	 * Testmethod to test ReceiverETA callout
	 **/
	public static testMethod void testReceiverETA() {

		user usr = [Select id from user where lastname = 'BSPTestLN'];
		System.runAs(usr) {
			Cognition_Controller.reqGUIDParam = '101992';
			Cognition_Controller.categoryParam = '1';
			Cognition_Controller.categoryNameParam = 'Carded';
			Cognition_Controller.seqValueParam = '100';
			Cognition_DataModel.reportData testCognition_DataModel = new Cognition_DataModel.reportData();
			testCognition_DataModel.Depot = 'ADR';

			String etaID = '1';
			String param1 = 'Test Param';
			Blob aes = Crypto.generateAesKey(128);
			String requestGUID = EncodingUtil.convertToHex(aes);
			System.debug('requestGUID ->' + requestGUID);
			String category = '1';

			CustomerCognitionSettings__c settings = CustomerCognitionSettings__c.getOrgDefaults();
			settings.EndPoint__c = baseUrl;
			settings.BasicAuthnHeader__c = '1234';
			upsert settings CustomerCognitionSettings__c.Id;

			Test.startTest();

			String ReceiverETAUrl = baseUrl + 'Cognition/v1/ReceiverETA';

			MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();

			multimock.setStaticResource(ReceiverETAUrl, 'Cognition_Test_ReceiverETA');

			multimock.setStatusCode(200);
			multimock.setHeader('Content-Type', 'application/json');

			// Set the mock callout mode
			Test.setMock(HttpCalloutMock.class, multimock);

			/****mock response set*/
			Cognition_DataModel.receiverETAResponse resp = (Cognition_DataModel.receiverETAResponse) Cognition_Controller.getReceiverETA(etaID, param1);
			//verify that the consignment value is coming as the value originally set in the mock response static resource
			system.assert(resp.Consignment == '6AUZ00029759');
			String respError = Cognition_CalloutUtility.executeCallout('POST', 'Cognition/v1/QueryStatus', 'body');
			system.assert(respError.containsIgnoreCase('Static Resource not found'));
			Test.stopTest();
		}

	}
	/**
	 * Testmethod to test the callouts made by the cognition page.
	 **/
	private static testMethod void testControllerCallouts() {

		StaticResource StaticResourceConsignmentInfo = [select id, body from StaticResource Where Name = 'Cognition_Test_ConsignmentInfo'];
		String resourceConsignmentInfo = StaticResourceConsignmentInfo.body.toString();
		system.assert(resourceConsignmentInfo != '');
		
		StaticResource StaticResourcePickupInfo = [select id, body from StaticResource Where Name = 'Cognition_Test_PickupInfo'];
		String resourcePickupInfo = StaticResourcePickupInfo.body.toString();
		system.assert(resourcePickupInfo != '');
		
		user usr = [Select id from user where lastname = 'BSPTestLN'];
		System.runAs(usr) {

			Blob aes = Crypto.generateAesKey(128);
			String requestGUID = EncodingUtil.convertToHex(aes);
			System.debug('requestGUID ->' + requestGUID);
			String ConsignmentID = '60739908';
			String BookingNbr = '5291790';
			String category = '1';
			String categoryName = 'Successful';
			String depotName = 'Brisbane';
			String customerNumber = '478001';
			String customerName = 'Apple';
			Integer FromSeq = 0;
			Integer toSeq = 1000;
			String seqValue = '100';
			PageReference pageRef = Page.Cognition_GoogleMap;

			/** set mock response */
			String queryStatusUrl = baseUrl + 'Cognition/v1/QueryStatus';
			String ConsignmentInfoUrl = baseUrl + 'Cognition/v1/ConsignmentInfo';
			String PickupInfoUrl = baseUrl + 'Cognition/v1/PickupInfo';
			String CustomerDetailsUrl = baseUrl + 'Cognition/v1/CustomerDetails';
			String CustomerSummaryUrl = baseUrl + 'Cognition/v1/CustomerSummary';
			String ReceiverETAUrl = baseUrl + 'Cognition/v1/ReceiverETA';
			String ConsignmentReportDataUrl = baseUrl + 'Cognition/v1/ConsignmentReportData';
			String SubmitQueryUrl = baseUrl + 'Cognition/v1/SubmitQuery';
			String PickupReportDataUrl = baseUrl + 'Cognition/v1/PickupReportData';
			CustomerCognitionSettings__c settings = CustomerCognitionSettings__c.getOrgDefaults();
			settings.EndPoint__c = baseUrl;
			settings.BasicAuthnHeader__c = '1234';
			upsert settings CustomerCognitionSettings__c.Id;
			
			/****mock response set*/
			System.Test.setCurrentPage(pageRef);

			System.currentPageReference().getParameters().put('requestGUID', requestGUID);
			System.currentPageReference().getParameters().put('category', category);
			System.currentPageReference().getParameters().put('categoryName', categoryName);

			Cognition_Controller cogController = new Cognition_Controller();
			Cognition_Controller.accountList acc = Cognition_Controller.getAccountString();

			Test.startTest();

			MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
			multimock.setStaticResource(queryStatusUrl, 'Cognition_Test_QueryStatus');
			multimock.setStaticResource(ConsignmentInfoUrl, 'Cognition_Test_ConsignmentInfo');
			multimock.setStaticResource(PickupInfoUrl, 'Cognition_Test_PickupInfo');
			multimock.setStaticResource(CustomerDetailsUrl, 'Cognition_Test_CustomerDetails');
			multimock.setStaticResource(CustomerSummaryUrl, 'Cognition_Test_CustomerSummary');
			multimock.setStaticResource(ReceiverETAUrl, 'Cognition_Test_ReceiverETA');
			multimock.setStaticResource(ConsignmentReportDataUrl, 'Cognition_Test_ConsignmentReportData');
			multimock.setStaticResource(SubmitQueryUrl, 'Cognition_Test_SubmitQuery');
			multimock.setStaticResource(PickupReportDataUrl, 'Cognition_Test_PickupReportData');

			multimock.setStatusCode(200);
			multimock.setHeader('Content-Type', 'application/json');

			// Set the mock callout mode
			Test.setMock(HttpCalloutMock.class, multimock);
			Cognition_Controller.CustomerControllerInnerClass testcon = new Cognition_Controller.CustomerControllerInnerClass();
			// Cognition_Controller.CustomerControllerInnerClass.generateRequestGUID(testcon);
			Cognition_Controller.generateRequestGUID(testcon);
			system.assert(testcon.rGUID != null);

			Cognition_DataModel.queryStatusResponse objQueryResp = Cognition_Controller.queryStatusInfo(requestGUID);
			//verify that the value coming is the same value  set in the mock response static resource
			system.assert(objQueryResp.DisplayMessage == 'All Consignment Information Collected');
			system.assert(objQueryResp.PercentageComplete == 100);
			
			// testing consignment details request
			Continuation contiConsignmentDetails = (Continuation) Cognition_Controller.getConsignmentDetailsAsync(requestGUID, ConsignmentID);

			HttpResponse ConsignmentDetailsresponse = new HttpResponse();
			ConsignmentDetailsresponse.setBody(resourceConsignmentInfo);
			ConsignmentDetailsresponse.setStatusCode(200);
			String consState = '';

			// setting the test data
			Test.setContinuationResponse(consState, ConsignmentDetailsresponse);
			contiConsignmentDetails.state = consState;

			// callback results
			Cognition_DataModel.CustomerViewConInfo CustomerViewConInfo = Cognition_Controller.consDetailsAsyncCallback(consState);

			//verify that the value coming is the same value  set in the mock response static resource
			system.assert(CustomerViewConInfo.Consignment=='50623188ABCD');
			system.assert(CustomerViewConInfo.Type==4);
			system.assert(CustomerViewConInfo.References!=null);

			// testing pickup details request
			Continuation contiPickupDetails = (Continuation) Cognition_Controller.getPickupDetailsAsync(requestGUID, BookingNbr);
			HttpResponse PickupDetailsresponse = new HttpResponse();
			PickupDetailsresponse.setBody(resourcePickupInfo);
			PickupDetailsresponse.setStatusCode(200);
			String pickupState = '';
			// setting the test data
			Test.setContinuationResponse(pickupState, PickupDetailsresponse);
			contiPickupDetails.state = pickupState;
			// callback results
			Cognition_DataModel.CustomerViewPickupInfo CustomerViewPickupInfo = Cognition_Controller.pickupDetailsAsyncCallback(pickupState);
			//verify that the value coming is the same value  set in the mock response static resource
			system.assert(CustomerViewPickupInfo.BookingNbr=='5291790');
			system.assert(CustomerViewPickupInfo.Type==13);
			system.assert(CustomerViewPickupInfo.BookingType=='Recurring');

			Cognition_Controller.CustomerControllerInnerClass custSummaryResp = Cognition_Controller.customerSummaryRequest(requestGUID);
			//verify that the value coming is the same value  set in the mock response static resource
			system.assert(custSummaryResp.displayStatsList != null);
			system.assert(custSummaryResp.depotList != null);
			system.assert(custSummaryResp.notOnboardForDelivery == 86);
			system.assert(custSummaryResp.deliveredEarly == 51);
			system.assert(custSummaryResp.deliveredToday == 47);

			//test Consignment report call
			Continuation conti = (Continuation) Cognition_Controller.getReportInfoRemotingAsync(requestGUID, category, categoryName, seqValue, FromSeq);
			HttpResponse response = new HttpResponse();
			response.setBody('{"RequestGUID":"2d0a3541-12f7-97f2-dcc9-79e4cffba600","Category":"2","FromSeq":0,"ToSeq":10,"CustomerName":null,"AssociatedAccountNbrs":["10138173","10138452","10141436"],"NbrOfReportDataRows":609,"ReportData":[{"Depot":"   ","Consignment":"HESV11952536","Product":"PRM","SenderName":"APPLE","ReceiverName":"Richard Giannopolous","ReceiverSuburb":"4505","NbrOfItems":1,"Category":"Delivered Today","LastEvent":"Delivered","LastEventDateTime":"/Date(1519076971000+1100)/","SendersReference":""}]}');
			response.setStatusCode(200);
			String requestLabel = '';
			Test.setContinuationResponse(requestLabel, response);
			conti.state = requestLabel;
			Cognition_Controller.ConsignmentReportInfoAsyncCallback(requestLabel);
			Cognition_Controller.CustomerControllerInnerClass subQueryResp = Cognition_Controller.submitQueryRequest(depotName, customerNumber, customerName);
			//verify that the value coming is the same value  set in the mock response
			system.assert(subQueryResp.PercentageComplete == 0);
			system.assert(subQueryResp.DisplayMessage == 'Submitted');
			
			//test pickup report call
			category = '30';
			conti = (Continuation) Cognition_Controller.getReportInfoRemotingAsync(requestGUID, category, categoryName, seqValue, FromSeq);
			response = new HttpResponse();
			response.setBody('{"RequestGUID":"2d0a3541-12f7-97f2-dcc9-79e4cffba600","Category":"30","FromSeq":0,"ToSeq":10,"CustomerName":null,"AssociatedAccountNbrs":["10138173","10138452","10141436"],"NbrOfReportDataRows":609,"ReportData":[{"Depot":"   ","Product":"PRM","ReceiverSuburb":"4505","NbrOfItems":1,"Category":"Not Collected","LastEvent":"Not Collected","BookingNbr":"5468514","LastEventDateTime":"/Date(1519076971000+1100)/","Contact":"test"}]}');
			response.setStatusCode(200);
			requestLabel = '';
			Test.setContinuationResponse(requestLabel, response);
			conti.state = requestLabel;
			Cognition_DataModel.PickupReportDataResponse testResp = Cognition_Controller.PickupReportInfoAsyncCallback(requestLabel);
			//verify that the value coming is the same value  set in the mock response
			System.assert(testResp.ReportData.size() == 1);
			System.assert(testResp.ReportData[0].BookingNbr == '5468514');
			System.assert(testResp.ReportData[0].Category == 'Not Collected');
			Test.stopTest();
		}
	}

	/**
	 * Testmethod to cover the wrapper classes used
	 **/
	private static testMethod void testdatamodel() {

		Cognition_DataModel.ReportDataRequest testReportDataReq = new Cognition_DataModel.ReportDataRequest();
		testReportDataReq.RequestGUID = '27866';
		testReportDataReq.Category = 'XYZ';
		testReportDataReq.FromSeq = 0;
		testReportDataReq.ToSeq = 100;
		testReportDataReq.ClientIpAddress = '27866';
		testReportDataReq.ClientUserName = 'XYZ';

		Cognition_DataModel.CustomerViewRequestV2 custreqvew = new Cognition_DataModel.CustomerViewRequestV2();
		custreqvew.RequestGUID = '27866';
		custreqvew.Account = 123;
		custreqvew.AccountString = 'test';
		custreqvew.ETADate = 'test';
		custreqvew.RequestAction = 1;
		custreqvew.CustomerName = 'XYZ';
		custreqvew.DespatchId = '27866';
		custreqvew.Depot = 'XYZ';
		custreqvew.ClientIpAddress = 'test';
		custreqvew.ClientUserName = 'test';
		custreqvew.ToDateTimeForced = 'test';
		
		Cognition_DataModel.reportData testReportData = new Cognition_DataModel.reportData();
		testReportData.Depot = 'ADR';
		testReportData.Consignment = 'HESZ11819146';
		testReportData.Product = 'PRM';
		testReportData.SenderName = 'APPLE';
		testReportData.ReceiverName = 'RICHARD BOSTON BOSTON FORD';
		testReportData.ReceiverSuburb = '5491';
		testReportData.NbrOfItems = 1;
		testReportData.Category = 'DUE_NOTONBOARD_ALREADYDELIVERED';
		testReportData.LastEvent = 'F-Delivery-Delivery_Success';
		testReportData.LastEventDateTime = '1517878418000+1100';
		testReportData.SendersReference = 'test';
		testReportData.ContactArea = 'FRONT STORE';
		testReportData.Contact = 'KRISIN';
		testReportData.BookingInstructions = 'NEW STE PERM';
		testReportData.SFCaseNumber = '';
		testReportData.SFCaseId = '';
		testReportData.ETADate = '';
		testReportData.Suburb = '';
		testReportData.Postcode = '';
		testReportData.CardedDepot = '';
		testReportData.BookingNbr = '4868467';
		testReportData.BookingType = '';
		testReportData.PickupAddress = '243 BURWOOD ROAD';
		testReportData.ReceiverSuburbName = 'suburb name';

		Cognition_DataModel.queryStatusResponse obj = new Cognition_DataModel.queryStatusResponse();
		obj.PercentageComplete = 100;
		obj.DisplayMessage = 'Success';
		Cognition_DataModel.queryStatusRequest obj2 = new Cognition_DataModel.queryStatusRequest();
		obj2.RequestGUID = 'XYZ';

		Cognition_DataModel.CustomerViewConInfo objcon = new Cognition_DataModel.CustomerViewConInfo();
		objcon.Consignment = 'xyz';
		objcon.Type = 1;
		objcon.EventDateTime = 'test';
		objcon.EventDesc = 'test';
		objcon.Network = 'test';
		objcon.depot = 'test';
		objcon.SenderName = 'test';
		objcon.ReceiverName = 'test';
		objcon.Address1 = 'test';
		objcon.Address2 = 'test';
		objcon.SenderSuburb = 'test';
		objcon.ReceiverSuburb = 'test';
		objcon.SenderPostcode = 'test';
		objcon.ReceiverPostcode = 'test';
		objcon.DespatchDate = 'test';
		objcon.ETADateTime = 'test';
		objcon.Latitude = 45.00;
		objcon.Longitude = 90.98;
		objcon.DateString = 'test';
		objcon.DespatchString = 'test';
		objcon.ETAString = 'test';
		objcon.PredictedETADateTime = 'test';
		objcon.PredictedNbrStopsToDelivery = 'test';
		objcon.PredictedDeliveryWindowStart = 'test';
		objcon.PredictedDeliveryWindowEnd = 'test';
		objcon.ContextualParagragh1 = 'test';
		objcon.ContextualParagragh2 = 'test';
		objcon.ContextualParagragh3 = 'test';
		objcon.SignatureImageBase64 = 'test';
		objcon.Type_EnumString = 'test';
		objcon.NbrItems = 5;
		objcon.SendersReference = 'test';
		objcon.ServiceCode = 'test';
		objcon.TruckLink = 'test';
		objcon.CardedDepot = 'test';
		objcon.SFCaseNumber = 'test';
		objcon.SFCaseId = 'test';
		objcon.Category_EnumString = 'test';
		
		List < Cognition_DataModel.cls_References > listString = new List < Cognition_DataModel.cls_References > ();
		Cognition_DataModel.cls_References objref = new Cognition_DataModel.cls_References();
		objref.Type = 'test';
		objref.Value = 'test';
		listString.add(objref);
		objcon.References = listString;

		Cognition_DataModel.CustomerViewPickupInfo objPik = new Cognition_DataModel.CustomerViewPickupInfo();
		objPik.BookingNbr = '4899212';
		objPik.Type = 11;
		objPik.Type_EnumString = 'Pickup Success';
		objPik.EventDateTime = '/Date(1535070283000+1000)/';
		objPik.EventDesc = 'test';
		objPik.Depot = 'ROK';
		objPik.Network = 'test';
		objPik.BookingType = 'Adhoc';
		objPik.BusinessUnit = 'ST100';
		objPik.CustomerNbr = '10140979';
		objPik.ServiceCode = 'FPP';
		objPik.Address1 = 'ANN STREET';
		objPik.Address2 = '';
		objPik.Address3 = '';
		objPik.Latitude = -23.396409;
		objPik.Longitude = 150.490377;
		objPik.Suburb = 'ROCKHAMPTON';
		objPik.Postcode = '4700';
		objPik.State = 'QLD';
		objPik.Contact = 'JEFF';
		objPik.ContactArea = 'FRONT COUNTER';
		objPik.ReadyTime = '/Date(1535065200000+1000)/';
		objPik.CloseTime = '/Date(1535094000000+1000)/';
		objPik.TimeZone = 'test';
		objPik.BookingInstructions = 'RA: 4928156';
		objPik.EventType = 'Pickup';
		objPik.EventSubType = 'Pickup_Success';
		objPik.DeviceId = 'test';
		objPik.EmployeeId = 'test';
		objPik.EmployeeName = 'test';
		objPik.EventReason = '';
		objPik.Category = '31';
		objPik.Category_EnumString = 'Pickup Success';
		objPik.ContextualParagragh1 = 'test';
		objPik.ContextualParagragh2 = 'test';
		objPik.ContextualParagragh3 = 'test';
		objPik.SignatureName = 'test';
		objPik.SignatureImageBase64 = 'test';
		objPik.DriverName = 'test';
		objPik.DriverImageBase64 = 'test';
		objPik.SendersReference = 'test';
		objPik.References = listString;
		objPik.Quantity = 11;
		objPik.SFCaseNumber = 'test';
		objPik.SFCaseId = 'test';

		Cognition_DataModel.ConsignmentInfoRequest objconinforeq = new Cognition_DataModel.ConsignmentInfoRequest();
		objconinforeq.RequestGUID = '27866';
		objconinforeq.Consignment = 'XYZ';
		objconinforeq.ClientIpAddress = '27866';
		objconinforeq.ClientUserName = 'test';

		Cognition_DataModel.CustomerViewResponse objcustviewresp = new Cognition_DataModel.CustomerViewResponse();
		objcustviewresp.RequestGUID = 'test';
		objcustviewresp.ResponseType = 'test';
		objcustviewresp.RequestDateTime = 'test';
		objcustviewresp.FromDateTime = 'test';
		objcustviewresp.ToDateTime = 'test';
		objcustviewresp.DueNbrName = 'test';
		objcustviewresp.OnBoardNbr = 2;
		objcustviewresp.DeliveredSuccessNbr = 10;
		objcustviewresp.DeliveredFailedNbr = 10;
		objcustviewresp.DueOnboard = 1;
		objcustviewresp.DueNotOnboardDeliverySuccess = 1;
		objcustviewresp.DueNotOnboardDeliveryFailed = 1;
		objcustviewresp.NotDueOnboard = 1;
		objcustviewresp.NotDueOnboardDeliverySuccess = 1;
		objcustviewresp.NotDueOnboardDeliveryFailed = 1;
		objcustviewresp.NotDueOnboardLate = 1;
		objcustviewresp.NotDueOnboardEarly = 1;
		objcustviewresp.TDDue = 1;
		objcustviewresp.TDEvents = 1;
		objcustviewresp.DueNotOnboardBeforeCutoff = 1;
		objcustviewresp.DueNbr = 1;
		objcustviewresp.DueOnboardDeliveryFailureCarded = 1;
		objcustviewresp.TotalNbr = 1;
		objcustviewresp.DueOnboardDeliverySuccess = 1;
		objcustviewresp.DueOnboardDeliveryFailed = 1;
		objcustviewresp.DueOnboardStillOutstanding = 1;
		objcustviewresp.DueNotOnboard = 1;
		objcustviewresp.DueNotOnboardAlreadyDelivered = 1;
		objcustviewresp.NotDueOnboardStillOutstanding = 1;
		objcustviewresp.NotDueNotOnboardDeliverySuccess = 1;
		objcustviewresp.NotDueNotOnboardDeliveryFailed = 1;
		objcustviewresp.DueNotOnboardHeldForCollection = 1;
		objcustviewresp.DueNotOnboardNoEvents = 1;
		objcustviewresp.DueUnknown = 1;
		objcustviewresp.customer_logo = 'xyz';
		objcustviewresp.TruckLink = 'test';
		
		Cognition_DataModel.PickupReportData testPickupReportData = new Cognition_DataModel.PickupReportData();
		testPickupReportData.Depot = 'test';
		testPickupReportData.Product = 'test';
		testPickupReportData.ReceiverSuburb = 'test';
		testPickupReportData.NbrOfItems = 1;
		testPickupReportData.Category = 'test';
		testPickupReportData.LastEvent = 'test';
		testPickupReportData.LastEventDateTime = 'test';
		testPickupReportData.ReceiverSuburbName = 'test';
		testPickupReportData.BookingNbr = 'test';
		testPickupReportData.BookingType = 'test';
		testPickupReportData.PickupAddress = 'test';
		testPickupReportData.ReadyTime = 'test';
		testPickupReportData.CloseTime = 'test';
		testPickupReportData.ContactArea = 'test';
		testPickupReportData.Contact = 'test';
		testPickupReportData.BookingInstructions = 'test';
		testPickupReportData.SFCaseNumber = 'test';
		testPickupReportData.SFCaseId = 'test';
	}

	 /**
	 * TEsting of load configs on init of the lightning component
	 */
	private static testMethod void testCognitionConfig() {
		insert new AusPostSettings__c(Name = 'BSP_Community_Base_Url', URL__c = System.URL.getSalesforceBaseUrl().toExternalForm());
		insert new CustomerCognitionSettings__c(AutoRefresh__c = true, RefreshInterval__c = 60000);

		Cognition_DataModel.Config config = Cognition_Controller.loadConfigs();
		System.assertEquals(
				true,
				config.isInternalUser,
				'testCognitionConfig : internal user should return true'
		);

		System.assertNotEquals(
				null,
				config.refreshInterval,
				'testCognitionConfig : refresh interval should be retrieved from custom setting'
		);

	}
	
	private static testMethod void testUtil() {
		Cognition_Util.getSystemCustomSettingListByName(null,null);
	}
	


}