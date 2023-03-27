/**
	* @author       : arjun.singh@auspost.com.au
	* @date         : 23/03/2020
	* @description  : Test class for MyNetworkCaseListController
	*/
	/*******************************  History ************************************************
	 * 19-06-2020 Hara Sahoo Added test method for myNetworkupdatePrintedCaseFlag
	 * 12-08-2020 Disha Kariya Updated http mock for AME API
	 * 28-11-2022 Dattaraj Deshmukh - Removed 'myNetworkAssignToselfMethodTest' and 'myNetworkAssignToUserMethodTest'. 
	 *                                Added 'test_assignSelectedRecords' and 'test_assignSelectedRecords_self' methods to test generic 'assignSelectedRecords' method.
	 *                                Added   'test_GetFilteredCases_StarTrackCasesListViewFilters' & 'test_GetFilteredCases_StarTrackUpdatedListViewFilters' method.
	 * 02-03-2023 Mahesh Parvathaneni - SF-830 Updated method test_validateCaseInvestigations and test_GetFilteredCases_UpdatedStarTrackListViewFilters
	 * 08-03-2023 Mahesh Parvathaneni - SF-873 Added method testGetSafeDropInformationCaseInvestigation
	 * 10-03-2023 Dattaraj Deshmukh   - Added method 'test_filterBasedOnSearchCriteria'.
	 * 16-03-2023 Dattaraj Deshmukh   - Updated 'test_GetFilteredCases_UpdatedStarTrackListViewFilters' to test UPDATED CI records.
	 * ***************************************************************************************/
	@isTest
	private  class MyNetworkCaseListControllerTest {
	// Constants
	private static final String ADMIN_PROFILE = 'System Administrator';
	private static final String SSSW_MYNETWORK_PROFILE = 'MyNetwork Portal';
	private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];
	private static final CaseTeamRole cTeamRorl {
		get{
			if(cTeamRorl == null){
				cTeamRorl = [Select Id from CaseTeamRole LIMIT 1] ;
			}
			return cTeamRorl;
		}
		private set;
	}
	private static final UserRole portalUserRole = [Select id from UserRole where developerName='SSSW_Facility_Manager_VIC'];

	private static User myNetworkUser;
	@testSetup
	static void testDataCreation() {
		//Get Event Message Type based on category
		Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
		//insert standard entitlement
		Account at = new Account(Name=SSSWConstants.ENTITLEMENT_ACC);
		insert at;
		Entitlement ent = new Entitlement(AccountId = at.Id, Name='Standard Entitlement');
		insert ent;

		String oId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;

		//insert article with Account's APCN
		list<Article__c> articleList = new list<Article__c>();
		Article__c testArticle1 = new Article__c();
		testArticle1.Name = 'testArticle1';
		testArticle1.ArticleID__c = 'testArticle1';
		testArticle1.ArticleLodgementDate__c = Date.today();
		testArticle1.ReceiverAddressLine1__c = '300 bourke street';
		testArticle1.SenderPostcode__c = '3000';
		testArticle1.ReceiverPostcode__c = '3006';
		testArticle1.ReceiverCity__c = 'Melbourne';
		testArticle1.ArticleType__c = 'Regular Parcel';
		testArticle1.Receiver_APCN__c = 'abcd1234';
		articleList.add(testArticle1);

		Article__c testArticle2 = new Article__c();
		testArticle2.Name = 'testArticle2';
		testArticle2.ArticleID__c = 'testArticle2';
		testArticle2.ArticleLodgementDate__c = Date.today();
		testArticle2.ReceiverAddressLine1__c = '300 bourke street';
		testArticle2.SenderPostcode__c = '3000';
		testArticle2.ReceiverPostcode__c = '3006';
		testArticle2.ReceiverCity__c = 'Melbourne';
		testArticle2.ArticleType__c = 'Regular Parcel';
		testArticle2.Receiver_APCN__c = 'abcd123';
		articleList.add(testArticle2);

		insert articleList;

		
		//insert network
		List<Network__c> networkList = new List<Network__c>();
		Network__c nw = TestDataProvider.createTestNetwork();
		nw.Email__c = 'top@top.com';
		nw.Name = 'test network';
		nw.Post_Code__c = '3000';
		nw.Geolocation__Latitude__s = -32.927406;
		nw.Geolocation__Longitude__s = 151.62805;
		nw.Contact_Facility__c ='MyNetwork';
		networkList.add(nw);

		Network__c nw2 = TestDataProvider.createTestNetwork();
		nw2.Email__c = 'top@toptest.com';
		nw2.Name = 'another test network';
		nw2.Post_Code__c = '3100';
		nw2.Geolocation__Latitude__s = -32.927406;
		nw2.Geolocation__Longitude__s = 151.62805;
		nw2.Contact_Facility__c ='MyNetwork';
		networkList.add(nw2);

		insert networkList;
		
		List<Facility_User__c> networkUser = ApplicationTestDataFactory.getNetworkUsers(1, networkList[0].Id, UserInfo.getUserId(), false);
		insert networkUser;

		//insert Account
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
				accRecTypeMap.get('Organisation').getRecordTypeId());
		Database.insert(acc);

		//insert contact
		Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
		con.Email = 'bruce@wayne.com';
		Database.insert(con);        
		System.runAs(new user(ID = UserInfo.getUserID())){
			myNetworkUser = TestUtility.createUser('lTest', prof.Id, portalUserRole.Id);
			insert myNetworkUser;
		}
		user uRecr = [Select id, profile.name from user where id=:myNetworkUser.Id];
		System.debug('uRecr>>>'+uRecr);
		//insert Case
		list<case> cList = new list<case>();
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName();
		Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
				caseRecTypeMap.get('SSSWDelivery').getRecordTypeId());
		csRec.ArticleTest__c = testArticle2.Id;
		csRec.ReferenceId__c ='testArticle2';
		csRec.Status = 'Awaiting Network Response';
		csRec.Address2__c = '100 Bourke Street Melbourne 3000';
		csRec.Network__c = networkList[0].id;
		csRec.Type = 'Investigation';
		csRec.CaseOriginator__c = 'Addressee';
		csRec.Checkbox__c = true;
		csRec.PONUser__c = myNetworkUser.Id;
		csRec.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
		cList.add(csRec);
		Case csRecord = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
				caseRecTypeMap.get('SSSWDelivery').getRecordTypeId());
		csRecord.ArticleTest__c = testArticle1.Id;
		csRecord.ReferenceId__c ='testArticle1';
		csRecord.Status = 'Awaiting Network Response';
		csRecord.Network__c = networkList[0].id;
		// csRecord.PONUser__c = userinfo.getuserid();
		csRecord.Type = 'Investigation';
		csRecord.CaseOriginator__c = 'Addressee';
		csRecord.Checkbox__c = true;  
		csRecord.Priority = 'High';       
		csRecord.Root_cause__c = 'Awaiting Network Response';
		csRecord.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
		cList.add(csRecord);

		Case csRecord1 = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
				caseRecTypeMap.get('SSSWDelivery').getRecordTypeId());
		csRecord1.ArticleTest__c = testArticle1.Id;
		csRecord1.ReferenceId__c ='testArticle1';
		csRecord1.Status = 'Awaiting Network Response';
		csRecord1.Network__c = networkList[0].id;
		//csRecord1.PONUser__c = userinfo.getuserid();
		csRecord1.Type = 'Feedback';
		csRecord1.CaseOriginator__c = 'Addressee';
		csRecord1.Checkbox__c = false;       
		csRecord1.Root_cause__c = 'Awaiting Network Response';
		csRecord1.OwnerId = userinfo.getuserid();
		cList.add(csRecord1);



		Database.insert(cList);
		System.debug('cList>>>>>>>>'+cList);

		List<CaseTeamMember> ctmList = new List<CaseTeamMember>();
		CaseTeamMember ctm = new CaseTeamMember(ParentId = csRec.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);
		CaseTeamMember ctm1 = new CaseTeamMember(ParentId = csRecord.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);
		CaseTeamMember ctm2 = new CaseTeamMember(ParentId = csRecord1.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);

		database.insert(ctmList);
		
		
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		EventMessage__c eventMessage = new EventMessage__c();
		eventMessage.Article__c = testArticle2.Id;
		eventMessage.EventType__c = eventMessageType.get('Delivered')[0].Label;
		eventMessage.EventGeoLocation__Longitude__s = 151.62805;
		eventMessage.EventGeoLocation__Latitude__s = -32.927406;
		eventMessages.add(eventMessage);
		//Attempted delivery event message
		EventMessage__c eventMessage1 = new EventMessage__c();
		eventMessage1.Article__c = testArticle2.Id;
		eventMessage1.EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		eventMessage1.EventGeoLocation__Longitude__s = 151.62805;
		eventMessage1.EventGeoLocation__Latitude__s = -32.927406;
		eventMessages.add(eventMessage1);

		insert eventMessages;

		list<Network_Response__c> nrList = new list<Network_Response__c>();
		Network_Response__c nr = new Network_Response__c();
		nr.Related_Case__c = csRec.Id;
		nrList.add(nr);
		Network_Response__c nres = new Network_Response__c();
		nres.Related_Case__c = csRecord.Id;
		nrList.add(nres);
		Network_Response__c nresRec = new Network_Response__c();
		nresRec.Related_Case__c = csRecord1.Id;
		nrList.add(nresRec);
		insert nrList;

		AusPostSettings__c setting = new AusPostSettings__c();
		setting.Name = 'AMEAddressValidation';
		setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
		setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
		setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
		insert setting;
	}
	@isTest
		static void myNetworkupdatePrintedCaseFlag()
		{
			List<Case> caseList = [SELECT Id From Case];
			List<String> caseIds = new List<String>();
			for(Case cs : caseList)
			{
				caseIds.add(cs.Id);
			}
			Test.StartTest();
			MyNetworkCaseListController.updatePrintedCaseFlag(caseIds);
			Test.StopTest();
			List<Case> casesUpdated = [SELECT Id, Checkbox__c FROM Case WHERE Id = :caseIds];
			System.assertEquals(true, casesUpdated[0].Checkbox__c, 'Printed Case flag not set to true');
		}
	@isTest
	static void myNetworkCasesMethodTest() {
		String selectedListView = 'All_Cases';
		list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
		Test.StartTest();
		wrapperList =  MyNetworkCaseListController.myNetworkCases(selectedListView);
		Test.StopTest();
		system.assert(!wrapperList.isEmpty());
	}
	@isTest
	static void myNetworkFiltersCasesMethodTest() {
		String filteredString = '{"isPrinted":"Yes","priorityVal":"High","enquirySubTypeVal":"Carding issue","addressePostcodeVal":"4000,3000","selectedProductCategoryVal":"International Parcels","selectedNetworkRecrdIdVal":"a2K0w0000008cWzEAI","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
		list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
		Test.StartTest();
		wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
		Test.StopTest();
		system.assert(wrapperList.isEmpty());
	}
	@isTest
	static void myNetworkFiltersAllCases() {
		String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
		list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();

		Test.StartTest();

		wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
		Test.StopTest();
		system.assert(!wrapperList.isEmpty());
	}
	@isTest
	static void myNetworkFiltersCasesMyCases() {
		String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"My_Cases","searchButtonClicked":true,"caseNumberVal":""}';
		list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
		case cRecrd = [Select Id, PONUser__c from case where PONUser__c != null And PONUser__r.profileId=:prof.Id limit 1] ;
		User uRecrd = [Select id,name from user where Id=: cRecrd.PONUser__c];
		
		CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
		insert ctmem;
		System.runAs(uRecrd){
			Test.StartTest();
			wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
			Test.StopTest();
			system.assert(!wrapperList.isEmpty());
		}
	}

	@isTest
	static void getSafeDropInformationTest() {
		case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
		
		User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
		
		CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
		insert ctmem;
	//        Test.setMock(HttpCalloutMock.class, new AddressFromGeolocationResGenerator());
		System.debug('cRecrd>>>'+cRecrd);
		String cId =  cRecrd.Id;
		MyNetworkCaseListController.SafeLocationDetails sDetails;
		System.runAs(uRecrd){
			Test.StartTest();
			Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
			sDetails = MyNetworkCaseListController.getSafeDropInformation(cId);
			Test.StopTest();  
		}
		System.assertEquals(sDetails.isValid, true, 'Valid Delivery address not found');
		System.assertEquals(sDetails.addresseeAddress.latitudeValue, String.valueOf(-37.82022851), 'Addressee latitude found from mock');
	}

	/**
	 * Scenario: Testing to get safe drop information related to article associated to case investigation
	 */
	@isTest
	static void testGetSafeDropInformationCaseInvestigation() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		Case c = ApplicationTestDataFactory.getCases(1, true)[0];
		c.ReferenceID__c = consignment.ArticleID__c;
		c.ArticleTest__c = consignment.Id;
		c = (Case) ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{'Article_Receiver_Address__c' => '140 SHARPS ROAD, MELBOURNE AIRPORT, VIC, 3064'});
		consignment = (Article__c)ApplicationTestDataFactory.setUnwritableFields(consignment, new Map<String, Object>{'RecordType.Name' => 'Consignment'});

		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.Consignment__c = consignment.Id;
		article.ReceiverAddressLine1__c = '140 SHARPS ROAD';
		article.ReceiverCity__c = 'MELBOURNE AIRPORT';
		article.ReceiverState__c = 'VIC';
		article.ReceiverPostcode__c = '3064';
		article.ReceiverCountry__c = 'AU';
		article.ReceiverAddress__c = '140 SHARPS ROAD, MELBOURNE AIRPORT, VIC, 3064';
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.EventGeoLocation__Longitude__s = 151.62805;
		eventMessage.EventGeoLocation__Latitude__s = -32.927406;

		//associating articles with consignment.
		consignment = (Article__c)ApplicationTestDataFactory.setChildRelationships(consignment, new Map<String, List<SObject>>{'Articles__r' => new List<SObject>{article}});

		//associating event messages with articles.
		article = (Article__c)ApplicationTestDataFactory.setChildRelationships(article, new Map<String, List<SObject>>{'Event_Messages__r' => new List<SObject>{eventMessage}});

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, c.Id, article, networks[0].Id, true);
		caseInvestigations[0].Article__r = article;
		caseInvestigations[0].Case__r = c;

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
		MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{eventMessage.Id => eventMessage});
		MockUtility.Mocks.stopStubbing();

		User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];

		// =====================================
		// Testing
		// =====================================
		MyNetworkCaseListController.SafeLocationDetails sDetails;
		System.runAs(uRecrd){
			Test.StartTest();
			Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
			sDetails = MyNetworkCaseListController.getSafeDropInformation(caseInvestigations[0].Id);
			Test.StopTest();  
		}
		System.assertEquals(sDetails.isValid, true, 'Valid Delivery address not found');
		System.assertEquals(sDetails.addresseeAddress.latitudeValue, String.valueOf(-37.82022851), 'Addressee latitude found from mock');
	}

	@isTest
	static void getMyNetworkPortalUserTst() {
		case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
		User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
		CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
		insert ctmem;
		String searchTerm = 'lTest';
		String fieldList = 'firstName,lastName,Name';
		String sobjectName = 'User';
		String fieldsToSearch = 'firstName,lastName,Name';
		String cId =  cRecrd.Id;
		List<SObject> uRecord;
		System.runAs(uRecrd){
			Test.StartTest();
			uRecord =  MyNetworkCaseListController.getMyNetworkPortalUser(searchTerm, fieldList,  sobjectName, fieldsToSearch);
			Test.StopTest();  
		}
		System.assert(!uRecord.isEmpty()); 
	}
	@isTest
	static void getAddressFromGeoLocationForEventMeTst() {
		case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
		User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
		CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
		insert ctmem;
		EventMessage__c evMsg = [Select id From EventMessage__c where Article__r.Name = 'testArticle2' limit 1];
	//        Test.setMock(HttpCalloutMock.class, new AddressFromGeolocationResGenerator());
		System.debug('cRecrd>>>'+cRecrd);
		MyNetworkCaseListController.GeoLocationWithAddress  geoAddr;
		String cId =  cRecrd.Id;
		System.runAs(uRecrd){
			Test.StartTest();
			Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
			geoAddr =  MyNetworkCaseListController.getAddressFromGeoLocationForEventMessage(evMsg.Id);
			Test.StopTest();  
		}
		System.assertEquals(geoAddr.geoLatitdue, '-32.927406', 'Latitude for the request.');
		System.assertEquals(geoAddr.addressValue, 'Test Address', 'Address found in AME');
	}

	@isTest
	static void myNetworkgetRelatedEventMsgMethodTest() {
		Case caseRecordVar = [Select id, ArticleTest__c from Case limit 1];
		Test.StartTest();
		MyNetworkCaseListController.getSelectedCases(string.valueOf(caseRecordVar.Id));        
		MyNetworkCaseListController.EventMessagesWithSortingDetails lEventMsg = MyNetworkCaseListController.getRelatedEventMessages(caseRecordVar.Id);
		Test.StopTest();
		System.assert(!lEventMsg.eventMessageWithGeoCodeList.isEmpty());
	}
	@isTest
	static void myNetworkEnqrySubTypeTest() {
		Test.StartTest();
		list<myNetworkPickListFieldValues__mdt> subtypeString = MyNetworkCaseListController.getpickListValues();        
		MyNetworkCaseListController.getFiltersData();
		MyNetworkCaseListController.clearCache();
		Test.StopTest();
		System.assert(!subtypeString.isEmpty());
	}

	@isTest
	static void getCaseFirstMessageTest() {
		Case caseRecordVar = [Select id, ArticleTest__c,type  from Case where ownerId=: userinfo.getuserid()  limit 1];
		
		Test.StartTest();
		list<MyNetworkCaseListController.caseMessage> cMessage = MyNetworkCaseListController.getCaseMessages(string.valueOf(caseRecordVar.Id));
		Test.StopTest();
		System.assertEquals(cMessage[0].messageString ,'This case has received further information and is now under review by the Customer Contact Centre.');
	}


	/**
	 * @Test: Test method to simulate 'Assign to self' button.
	 *			This method assign case investigation ownership to selected user for ST cases and 
		*			if AP Case is selected then it updates PONUser__c field on case.
		*/
	@isTest
	static void test_assignSelectedRecords_withMocks() {
		
		
		// =====================================
		// Data Preparation
		// =====================================
		Id profileId = Application.Cache.profileIds.get('MyNetwork Portal');

		User myNetworkPortalUser = ApplicationTestDataFactory.getUsers(1, profileId, true)[0];
		myNetworkPortalUser.Id = UserInfo.getUserId();
		
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
		

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'Open';
		caseInvestigations[1].Status__c = 'Open';

		String stJson = '{"success":true,"id":' +'"'+ caseInvestigations[0].Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
		List<Database.SaveResult> svResultList = new List<Database.SaveResult>{sr};

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUserSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserSelector.selectById(new Set<Id>{myNetworkPortalUser.Id})).thenReturn(new Map<Id, User>{myNetworkPortalUser.Id => myNetworkPortalUser});
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		//passign 2 CIs and 1 AP Case.
		String[] recordIds = new String[]{caseInvestigations[0].Id, caseInvestigations[1].Id, cases[1].Id};
		String recordIdString = JSON.serialize(recordIds);

		Test.StartTest();
		//assigning records self. 
		MyNetworkCaseListController.assignSelectedRecords(recordIdString, null, true);
		Test.StopTest();  

		// should have updated Case and CI Records
		fflib_ArgumentCaptor updatableRecordsCaptor = fflib_ArgumentCaptor.forClass(List<CaseInvestigation__c>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<CaseInvestigation__c>) updatableRecordsCaptor.capture());

		List<SObject> updatableRecords = (List<Sobject>) updatableRecordsCaptor.getValue();
		System.assertEquals(3, updatableRecords.size(), 'Expected to update 3 records');

		//loop through updated records and asserts if relevant fields are updated.
		for(SObject sobj : updatableRecords){

			//if a case is passed then PONUser__c field will be updated.
			if(sobj.getSObjectType() === Case.getSObjectType()){
				System.assertEquals(UserInfo.getUserId(), ((Case)sobj).PONUser__c, 'Expected to update PONUser__c ID to self for a case');
			}
			//if a case investigation is passed then OwnerId field will be updated.
			if(sobj.getSObjectType() === CaseInvestigation__c.getSObjectType()){
				System.assertEquals(UserInfo.getUserId(), ((CaseInvestigation__c)sobj).OwnerId, 'Expected to update OwnerId ID to self for a case investigation');
			}
		}
		
	}

	/**
	 * @desc: Method to test if cases are returned if List view is changed to 'Updated Cases'.
	 * Expected to return all updated cases. 
	 */

	@isTest
	static void test_GetFilteredCases_APUpdatedListViewFilters() {

		String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"Cases_updated","searchButtonClicked":true,"caseNumberVal":""}';
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName();
		Id apCaseRecordTypeId = caseRecTypeMap.get('SSSWDelivery').getRecordTypeId();

		//get AP cases
		Map<Id, Case> apCasesMap = new Map<Id, Case> ([Select ID, Status,OwnerId from Case WHERE RecordTypeId =:apCaseRecordTypeId]);
		
		list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();

		Test.StartTest();
			wrapperList = MyNetworkCaseListController.getFilteredCases(filteredString);
		Test.StopTest();  

		//asserting list is not empty
		system.assert(!wrapperList.isEmpty());

		//asserting return list contains expected case record.
		system.assert(apCasesMap.containsKey(wrapperList[0].myNetworkCase.Id));

	}

	/**
	 * @desc: Method to test if cases are returned if List view is changed to 'Star Track Cases'.
	 * Expected to return all case investigations. 
	 */

		@isTest
		static void test_GetFilteredCases_StarTrackListViewFilters() {
		String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"star_track_cases","searchButtonClicked":true,"caseNumberVal":""}';

		// =====================================
		// Data Preparation
		// =====================================
		Id profileId = Application.Cache.profileIds.get('MyNetwork Portal');

		User myNetworkPortalUser = ApplicationTestDataFactory.getUsers(1, profileId, true)[0];
		myNetworkPortalUser.Id = UserInfo.getUserId();
		

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		Id stCaseRecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = stCaseRecordTypeId;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';

		List<Facility_User__c> networkUsers = ApplicationTestDataFactory.getNetworkUsers(1, networks[0].Id, UserInfo.getUserId(), true);
		
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		networks[0] = (Network__c)ApplicationTestDataFactory.setChildRelationships(networks[0], new Map<String, List<SObject>>{'Network_Users__r' => new List<SObject>{networkUsers[0]}});

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
			.get('StarTrack_MyNetwork').getRecordTypeId();

		List<CaseInvestigation__c> networkCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(3, cases[0].Id, articles[0], networks[0].Id, true);
		
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => networkCaseInvestigations});

		//setting fieldOverrides for User sobject
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>();
		Set<SObjectField> userFields = new Set<SObjectField>{ User.Name };
		fieldOverrides.put(User.SObjectType, userFields);
		
		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUserSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		NetworkUsersSelector mockNetworkUserSelector = (NetworkUsersSelector)MockUtility.mockSelector(NetworkUsersSelector.class);
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserSelector.selectById(new Set<Id>{myNetworkPortalUser.Id})).thenReturn(new Map<Id, User>{myNetworkPortalUser.Id => myNetworkPortalUser});
		MockUtility.Mocks.when(mockNetworkUserSelector.selectByUserId(new Set<Id>{myNetworkPortalUser.Id}))
							.thenReturn(new Map<Id, Facility_User__c>{networkUsers[0].Id => networkUsers[0]});
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByNetworkId(new Set<Id>{networks[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId}, 
										new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, CaseInvestigationsSelector.Options.WITH_NETWORKS, 
											CaseInvestigationsSelector.Options.WITH_ARTICLES, CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS,
											UsersSelector.Options.WITH_PROFILE} ))
							.thenReturn(new Map<Id, CaseInvestigation__c>(networkCaseInvestigations));
		

		
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		List<MyNetworkCaseListController.MyNetworkCasesWrapper> caseInvWrapperList = MyNetworkCaseListController.getFilteredCases(filteredString);
		Test.StopTest();  

		//verifying methods are called
		((NetworkUsersSelector)MockUtility.Mocks.verify(mockNetworkUserSelector, MockUtility.Mocks.times(1))).selectByUserId(new Set<Id>{myNetworkPortalUser.Id});



		//assert Star Track case is returned.
		System.assert(!caseInvWrapperList.isEmpty());
		
		//asserting method returns expected case investigations.
		System.assertEquals(3, caseInvWrapperList.size());

	}

	/**
	 * @desc: Method to test case and case investigations are return with valid colour schemes for portal. 
	 * Expected to return wrapper object with valid colour schemes.
	 */
	@isTest
	static void test_validateCaseInvestigations() {
		
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<CaseInvestigation__c> networkCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[0].Id, null, null, true);
		networkCaseInvestigations.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, null, null, true));

		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true});

		networkCaseInvestigations[1].Stillunderinvestigation__c = true;
		networkCaseInvestigations[2].Case__r = cases[1];

		// =====================================
		// Stubbing
		// =====================================
		//Not required

		// =====================================
		// Testing
		// =====================================
		Test.StartTest();
		
		//passing case and case investigation
		MyNetworkCaseListController.MyNetworkCasesWrapper updatedCaseInvWrapper = MyNetworkCaseListController.validateCaseInvestigations(networkCaseInvestigations[2]);
		MyNetworkCaseListController.MyNetworkCasesWrapper stillUnderInvestigationCaseInvWrapper = MyNetworkCaseListController.validateCaseInvestigations(networkCaseInvestigations[1]);
		MyNetworkCaseListController.MyNetworkCasesWrapper newCaseInvWrapper = MyNetworkCaseListController.validateCaseInvestigations(networkCaseInvestigations[0]);

		Test.StopTest();  
		
		//asserting passed case investigation is returned with valid color schemes and icons
		system.assertEquals('UPDATED', updatedCaseInvWrapper.caseIcon);
		system.assertEquals('Red', updatedCaseInvWrapper.caseColor);
		
		//asserting passed case investigation is returned with valid color schemes and icons
		system.assertEquals('SUI', stillUnderInvestigationCaseInvWrapper.caseIcon);
		system.assertEquals('orange', stillUnderInvestigationCaseInvWrapper.caseColor);

		//asserting passed case investigation is returned with valid color schemes and icons
		system.assertEquals('NEW', newCaseInvWrapper.caseIcon);
		system.assertEquals('green', newCaseInvWrapper.caseColor);
		
	}


	/**
	 * @desc: Method to test if cases are returned if List view is changed to 'Updated Star Track Case Investigations'.
	 * Expected to return all start track updated case investigations. 
	 */
		@isTest
		static void test_GetFilteredCases_UpdatedStarTrackListViewFilters() {
		// =====================================
		// Data Preparation
		// =====================================
		Id profileId = Application.Cache.profileIds.get('MyNetwork Portal');

		User myNetworkPortalUser = ApplicationTestDataFactory.getUsers(1, profileId, true)[0];
		myNetworkPortalUser.Id = UserInfo.getUserId();

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		Id stCaseRecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = stCaseRecordTypeId;
		cases[0].Status = 'Closed';

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';

		List<Facility_User__c> networkUsers = ApplicationTestDataFactory.getNetworkUsers(1, networks[0].Id, UserInfo.getUserId(), true);
		
		//assigning formula field as it is referred in logic.
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true, 'IsClosed' => true});
		networks[0] = (Network__c)ApplicationTestDataFactory.setChildRelationships(networks[0], new Map<String, List<SObject>>{'Network_Users__r' => new List<SObject>{networkUsers[0]}});

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_MyNetwork').getRecordTypeId();

		List<CaseInvestigation__c> networkCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[0].Id, articles[0], networks[0].Id, true);
		networkCaseInvestigations[0].RecordTypeId = stCaseInvestigationRecordTypeId;
		networkCaseInvestigations[1].RecordTypeId = stCaseInvestigationRecordTypeId;
		
		networkCaseInvestigations[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(networkCaseInvestigations[0], new Map<String, Object>{'IsClosed__c' => true, 'IsCaseClosed__c' => true, 'Case__r' =>  cases[0]});
		networkCaseInvestigations[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(networkCaseInvestigations[1], new Map<String, Object>{'IsClosed__c' => true, 'IsCaseClosed__c' => true, 'Case__r' =>  cases[0]});

		
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{networkCaseInvestigations[0], networkCaseInvestigations[1]}});

		
		String filteredStringWithUpdatedFilter = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"Cases_updated","searchButtonClicked":true,"caseNumberVal":""}';

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUserSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		NetworkUsersSelector mockNetworkUserSelector = (NetworkUsersSelector)MockUtility.mockSelector(NetworkUsersSelector.class);
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserSelector.selectById(new Set<Id>{myNetworkPortalUser.Id})).thenReturn(new Map<Id, User>{myNetworkPortalUser.Id => myNetworkPortalUser});
		MockUtility.Mocks.when(mockNetworkUserSelector.selectByUserId(new Set<Id>{myNetworkPortalUser.Id}))
							.thenReturn(new Map<Id, Facility_User__c>{networkUsers[0].Id => networkUsers[0]});
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByNetworkIdAndClosedCases(new Set<Id>{networks[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId}, 
										new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, CaseInvestigationsSelector.Options.WITH_NETWORKS, 
											CaseInvestigationsSelector.Options.WITH_ARTICLES, CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS,
											UsersSelector.Options.WITH_PROFILE} ))
							.thenReturn(new Map<Id, CaseInvestigation__c>(networkCaseInvestigations));

		
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();
		MyNetworkCaseListController.SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp = MyNetworkCaseListController.constructDynamicFilters(filteredStringWithUpdatedFilter);									
		List<CaseInvestigation__c> cInvList = MyNetworkCaseListController.getStarTrackCases(selectedViewWithFiltersWrp);
		List<MyNetworkCaseListController.MyNetworkCasesWrapper> caseInvWrapperList = MyNetworkCaseListController.processCaseInvWrapper(cInvList);
		
		Test.StopTest();
		
		//verifying methods are called
		((NetworkUsersSelector)MockUtility.Mocks.verify(mockNetworkUserSelector, MockUtility.Mocks.times(1))).selectByUserId(new Set<Id>{myNetworkPortalUser.Id});

			

		//asserting method returns ONLY UPDATED case investigations.
		System.assertEquals(2, caseInvWrapperList.size());
		
		//asserting all CI records are marked as UPDATED as parent case is CLOSED.
		System.assertEquals(networkCaseInvestigations[0].Id, caseInvWrapperList[0].caseInvestigation.Id);
		system.assertEquals('UPDATED', caseInvWrapperList[0].caseIcon);
		system.assertEquals('UPDATED', caseInvWrapperList[1].caseIcon);

	}

	/**
	 * @test: Test if record is return based on Id passed.
	 * Expected: Case/Case Investigation record wrapper if corresponding ID is passed to the method.
	 */
	@isTest
	static void test_GetFilteredCases_getCaseRecord() {
		// =====================================
		// Data Preparation
		// =====================================
		Id stRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_PUD_Enquiry').getRecordTypeId();

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = stRecordTypeId;

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);


		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectById(new Set<Id>{caseInvestigations[0].Id}, 
										new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES} ))
							.thenReturn(new Map<Id, CaseInvestigation__c>(caseInvestigations));
		
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{caseInvestigations[0].Case__c}, 											
											new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS, CaseInvestigationsSelector.Options.WITH_ARTICLES} ))
											.thenReturn(new Map<Id, Case>(cases));
		
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		MyNetworkCaseListController.RecordDetailsWrapper caseDetailsWrapper =  MyNetworkCaseListController.getCaseRecord(cases[0].Id);

		MyNetworkCaseListController.RecordDetailsWrapper caseInvestigationDetailsWrapper =  MyNetworkCaseListController.getCaseRecord(caseInvestigations[0].Id);
		Test.stopTest();

		//asserting if wrapper return contains correct sObjectTypeName.
		system.assertEquals('Case', caseDetailsWrapper.sObjectTypeName);
		system.assertEquals('CaseInvestigation__c', caseInvestigationDetailsWrapper.sObjectTypeName);
		

	}

	/**
	 * @desc: Method to test if cases/case investigations are returned if List view is changed to 'My_Cases'.
	 * Expected to return all start track case investigations where logged in user is an owner. 
	 */
	@isTest
	static void test_GetFilteredCases_MyCasesStarTrackListViewFilters() {
		// =====================================
		// Data Preparation
		// =====================================
		Id profileId = Application.Cache.profileIds.get('MyNetwork Portal');

		User myNetworkPortalUser = ApplicationTestDataFactory.getUsers(1, profileId, true)[0];
		myNetworkPortalUser.Id = UserInfo.getUserId();

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		Id stCaseRecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = stCaseRecordTypeId;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';

		List<Facility_User__c> networkUsers = ApplicationTestDataFactory.getNetworkUsers(1, networks[0].Id, UserInfo.getUserId(), true);
		
		//assigning formula field as it is referred in logic.
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		networks[0] = (Network__c)ApplicationTestDataFactory.setChildRelationships(networks[0], new Map<String, List<SObject>>{'Network_Users__r' => new List<SObject>{networkUsers[0]}});


		List<CaseInvestigation__c> networkCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases[0].Id, articles[0], networks[0].Id, true);
		List<User> myNetworkUserlist = ApplicationTestDataFactory.getUsers(1, true);

		// setting owner Id to  ONLY one CI record. 
		networkCaseInvestigations[0].OwnerId = UserInfo.getUserId();
		networkCaseInvestigations[1].OwnerId = myNetworkUserlist[0].Id; //setting some random owner id other than logged in users id.

		
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{networkCaseInvestigations[0], networkCaseInvestigations[1]}});

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_MyNetwork').getRecordTypeId();

		String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"My_Cases","searchButtonClicked":true,"caseNumberVal":""}';

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUserSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		NetworkUsersSelector mockNetworkUserSelector = (NetworkUsersSelector)MockUtility.mockSelector(NetworkUsersSelector.class);
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserSelector.selectById(new Set<Id>{myNetworkPortalUser.Id})).thenReturn(new Map<Id, User>{myNetworkPortalUser.Id => myNetworkPortalUser});
		MockUtility.Mocks.when(mockNetworkUserSelector.selectByUserId(new Set<Id>{myNetworkPortalUser.Id}))
							.thenReturn(new Map<Id, Facility_User__c>{networkUsers[0].Id => networkUsers[0]});
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByNetworkIdOwnerId(new Set<Id>{networks[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId}, 
		new Set<Id>{UserInfo.getUserId()},
										new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, CaseInvestigationsSelector.Options.WITH_NETWORKS, 
											CaseInvestigationsSelector.Options.WITH_ARTICLES, CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS,
											UsersSelector.Options.WITH_PROFILE} ))
							.thenReturn(new Map<Id, CaseInvestigation__c>{networkCaseInvestigations[0].Id => networkCaseInvestigations[0]});

		
		MockUtility.Mocks.stopStubbing();

		Test.StartTest();

		List<MyNetworkCaseListController.MyNetworkCasesWrapper> caseInvWrapperList = MyNetworkCaseListController.getFilteredCases(filteredString);

		Test.StopTest();
		
		//asserting method returns ONLY one case investigation owned by logged in user.
		System.assertEquals(1, caseInvWrapperList.size());
		
		//asserting only one CI record is returned.
		System.assertEquals(networkCaseInvestigations[0].Id, caseInvWrapperList[0].caseInvestigation.Id, 'only one record should have been returned.');
		system.assertEquals(UserInfo.getUserId(), caseInvWrapperList[0].caseInvestigation.OwnerId,'Owner id of record should match with logged in user');

	}

	/**
	 * @desc: method to test search filters applied on portal home page.
	 * search filters are passed as a JSON for a method and filtered list is returned.
	 * @expected: Filtered list of CI as per search filters.
	 */
	@isTest
	static void test_filterBasedOnSearchCriteria() {
		// =====================================
		// Data Preparation
		// =====================================
		
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		Id stCaseRecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = stCaseRecordTypeId;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> networkCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(5, cases[0].Id, articles[0], networks[0].Id, true);
		
		//assigning a priority to one CI record to test filtering based on priority
		networkCaseInvestigations[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(networkCaseInvestigations[0], new Map<String, Object>{'Priority__c' => 'Medium'});

		// assigning CI records to a case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => networkCaseInvestigations });

		//setting printed flag to true to two CI records.
		networkCaseInvestigations[1].IsPrinted__c = true;
		networkCaseInvestigations[2].IsPrinted__c = true;
		
		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get('StarTrack_MyNetwork').getRecordTypeId();
		
		//setting a filter of Priority='Medium' to search records.
		String filteredStringWithMediumPriority = '{"isPrinted":"","priorityVal":"Medium","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
		
		//setting a filter of Printed = 'Yes' to search records.
		String filteredStringWithPrintedFlag = '{"isPrinted":"Yes","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
		
		// =====================================
		// Stubbing
		// =====================================
		//Not Required

		Test.StartTest();

		Map<string,object> filtersMap = (Map<string,object>)JSON.deserializeUntyped(filteredStringWithMediumPriority);
		List<CaseInvestigation__c> priorityFilteredCiList = MyNetworkCaseListController.filterBasedOnSearchCriteria(networkCaseInvestigations, filtersMap);

		filtersMap = (Map<string,object>)JSON.deserializeUntyped(filteredStringWithPrintedFlag);
		List<CaseInvestigation__c> printedFlagFilteredCiList = MyNetworkCaseListController.filterBasedOnSearchCriteria(networkCaseInvestigations, filtersMap);

		Test.StopTest();

		//asserting only one record is returned with medium priority
		system.assertEquals(1, priorityFilteredCiList.size());
		system.assertEquals(networkCaseInvestigations[0].Priority__c, priorityFilteredCiList[0].Priority__c);

		//asserting two records are returned as per Printed flag
		system.assertEquals(2, printedFlagFilteredCiList.size());
		system.assert(printedFlagFilteredCiList[0].IsPrinted__c);
		system.assert(printedFlagFilteredCiList[1].IsPrinted__c);

	}

}