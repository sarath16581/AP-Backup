/**************************************************
Description:		Test class for FacilitySearchController

--------------------------------------------------
* 2017-08-01 nathan.franklin@auspost.com.au  - Creating tests to increase code coverage.
* 2017-10-24 nathan.franklin@auspost.com.au  - Recreated facility search test class
* 2019-10-01 gunith.devasurendra@auspost.com.au	- Fixed tests by inserting SSSWNonRoutingEventCodes__c on Setup
--------------------------------------------------
*/
@isTest
private class FacilitySearch_Test {

	@testSetup
	public static void setupTest() {

		FacilitySearchController.isTest = true;

		insert new SSSWNonRoutingEventCodes__c(Codes__c='CE-TR01,CE-TR02,CE-EN01,CE-EN02,NSS-ER42');

		Account acc = TestDataProvider.createPersonAccount();
		acc.PersonMailingStreet='street';
		acc.PersonMailingCity='city';
		acc.PersonMailingState='VIC';
		acc.PersonMailingPostalCode='3000';
		acc.PersonMailingCountry='AU';
		acc.PersonOtherStreet='OtherStreet';
		acc.PersonOtherCity='OtherCity';
		acc.PersonOtherState='VIC';
		acc.PersonOtherPostalCode='2000';
		acc.PersonOtherCountry='AU';
		insert acc;

		Contact con = TestDataProvider.createTestContact();
		con.MailingStreet='street';
		con.MailingCity='city';
		con.MailingState='VIC';
		con.MailingPostalcode='3000';
		con.MailingCountry='AU';
		con.OtherStreet='OtherStreet';
		con.OtherCity='OtherCity';
		con.OtherState='VIC';
		con.OtherPostalCode='2000';
		con.OtherCountry='AU';
		insert con;

		Article__c art = new Article__c();
		art.Name = '123';
		art.TrackingID__c = '123';
		art.ArticleID__c = '123';
		art.ArticleLodgementDate__c = date.today();
		art.SenderPostcode__c = '123';
		art.ReceiverPostcode__c = '3002';
		art.ArticleType__c = 'Regular Parcel';
		insert art;

		List<Network__c> networks = new List<Network__c>();

		Network__c nwMelb1 = TestDataProvider.createTestNetwork();
		nwMelb1.Name = 'Melbourne1';
		nwMelb1.ORG_UNIT_ADDR_3__c = 'Melbourne';
		//nwMelb1.Post_Code__c = '3000';
		nwMelb1.Email__c = 'top@top.com';
		nwMelb1.Geolocation__Latitude__s = -37.814; // Melbourne
		nwMelb1.Geolocation__Longitude__s = 144.96332;
		nwMelb1.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Business_Hub_3'].Id;
		networks.add(nwMelb1);

		Network__c nwMelb2 = TestDataProvider.createTestNetwork();
		nwMelb2.Name = 'Melbourne2';
		nwMelb2.ORG_UNIT_ADDR_3__c = 'Melbourne';
		//nwMelb2.Post_Code__c = '3000';
		nwMelb2.Email__c = 'top@top.com';
		nwMelb2.Geolocation__Latitude__s = -37.814; // Melbourne
		nwMelb2.Geolocation__Longitude__s = 144.96332;
		nwMelb2.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Delivery_1'].Id;
		networks.add(nwMelb2);

		// star track network which should be excluded from all FacilitySearchController functionality.
		Network__c nwMelb3 = TestDataProvider.createTestNetwork();
		nwMelb3.Name = 'Melbourne3';
		nwMelb3.ORG_UNIT_ADDR_3__c = 'Melbourne';
		//nwMelb3.Post_Code__c = '3000';
		nwMelb3.Email__c = 'top@top.com';
		nwMelb3.Geolocation__Latitude__s = -37.814; // Melbourne
		nwMelb3.Geolocation__Longitude__s = 144.96332;
		nwMelb3.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'StarTrack_Metro_9'].Id;
		networks.add(nwMelb3);

		Network__c nwSyd1 = TestDataProvider.createTestNetwork();
		nwSyd1.Org_ID__c = '12345';
		nwSyd1.Name = 'Sydney1';
		nwSyd1.ORG_UNIT_ADDR_3__c = 'Sydney';
		//nwSyd1.Post_Code__c = '2000';
		nwSyd1.Email__c = 'top@top.com';
		nwSyd1.Geolocation__Latitude__s = -33.86785; // Sydney
		nwSyd1.Geolocation__Longitude__s = 151.20732;
		nwSyd1.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Delivery_1'].Id;
		networks.add(nwSyd1);

		Network__c nwSyd2 = TestDataProvider.createTestNetwork();
		nwSyd2.Name = 'Sydney2';
		nwSyd2.ORG_UNIT_ADDR_3__c = 'Sydney';
		//nwSyd2.Post_Code__c = '3000';
		nwSyd2.Email__c = 'top@top.com';
		nwSyd2.Geolocation__Latitude__s = -33.86785; // Sydney
		nwSyd2.Geolocation__Longitude__s = 151.20732;
		nwSyd2.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Business_Hub_3'].Id;
		networks.add(nwSyd2);

		// star track network which should be excluded from all FacilitySearchController functionality.
		Network__c nwSyd3 = TestDataProvider.createTestNetwork();
		nwSyd3.Name = 'Sydney3';
		nwSyd3.ORG_UNIT_ADDR_3__c = 'Sydney';
		nwSyd3.Email__c = 'top@top.com';
		nwSyd3.Geolocation__Latitude__s = -33.86785; // Sydney
		nwSyd3.Geolocation__Longitude__s = 151.20732;
		nwSyd3.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'StarTrack_Metro_9'].Id;
		networks.add(nwSyd3);

		Network__c nwMelb4 = TestDataProvider.createTestNetwork();
		nwMelb4.Name = 'Melbourne4';
		nwMelb4.ORG_UNIT_ADDR_3__c = 'Melbourne';
		nwMelb4.Email__c = 'top@top.com';
		nwMelb4.Geolocation__Latitude__s = -37.814; // Melbourne
		nwMelb4.Geolocation__Longitude__s = 144.96332;
		nwMelb4.AlwaysShown__c = true;
		nwMelb4.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Other_8'].Id;
		networks.add(nwMelb4);

//Closed Business Hubs shouldn't appear in results
		Network__c nwSyd4 = TestDataProvider.createTestNetwork();
		nwSyd4.Name = 'Sydney4';
		nwSyd4.ORG_UNIT_ADDR_3__c = 'Sydney';
		nwSyd4.Email__c = 'top@top.com';
		nwSyd4.Status__c = 'Closed';
		nwSyd4.Geolocation__Latitude__s = -33.86785; // Sydney
		nwSyd4.Geolocation__Longitude__s = 151.20732;
		nwSyd4.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'Business_Hub_3'].Id;
		networks.add(nwSyd4);

		Network__c nwGerm = TestDataProvider.createTestNetwork();
		nwGerm.Name = 'Germany Network';
		nwGerm.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Network__c' And DeveloperName = 'International_4'].Id;
		networks.add(nwGerm);

		insert networks;

		Case case1 = new Case();
		case1.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Case' And DeveloperName = 'SSSWGeneralEnquiry'].Id;
		case1.ContactId = con.Id;
		case1.Type = 'Feedback';
		case1.Subject = 'Newsdd';
		case1.Status = 'Awaiting Customer Response';
		case1.ProductCategory__c = 'Travel & ID';
		case1.EnquirySubType__c = 'Product Support';
		case1.ProductSubCategory__c = 'KeyPass';
		case1.ArticleTest__c = art.Id;
		case1.Address1Postcode__c = '3000';
		case1.Address2Postcode__c = '3000';
		case1.Network__c = networks[0].Id;
		case1.ReferenceID__c = '123';
		insert case1;

		EventMessage__c em = new EventMessage__c();
		em.Article__c = art.Id;
		em.SenderID__c = 'bg';
		em.ActualDateTime__c = date.today() + 1;
		em.EventType__c = 'DD-ER13';
		em.SignatureXString__c = '1';
		em.Facility__c = networks[1].Id;
		insert em;

		StatusTracking__c st = TestDataProvider.createTestStatusTracking();
		st.Case__c = case1.Id;
		st.StatusValue__c = 'Awaiting Network Response';
		st.StartDate__c = Date.today();
		st.EndDate__c = st.StartDate__c.addDays(180);
		st.Network__c = networks[0].Id;
		insert st;

		// log a bypass from the first to second network and vice versa
		FacilityByPass__c fbp = new FacilityByPass__c();
		fbp.Facility_By_Pass_From__c = networks[1].Id;
		fbp.Facility_By_Pass_To__c = networks[0].Id;
		insert fbp;

		FacilityByPass__c fbp2 = new FacilityByPass__c();
		fbp2.Facility_By_Pass_From__c = networks[0].Id;
		fbp2.Facility_By_Pass_To__c = networks[1].Id;
		insert fbp2;

		FacilitySearchRange__c fsr = new FacilitySearchRange__c();
		fsr.Range_In_KM__c = 12;
		insert fsr;

		// these are the recordtypes allowed to be used int he network search page
		List<SSSW_Facility_Search_Record_Types__c> allowedTypes = new List<SSSW_Facility_Search_Record_Types__c>();
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Business_Hub_3'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Delivery_1'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Digital_7'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'International_4'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Lockers_5'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Other_8'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Retail_2'));
		allowedTypes.add(new SSSW_Facility_Search_Record_Types__c(Name = 'Street_Posting_Box_6'));
		insert allowedTypes;

		List<Postcode__c> postcodes = new List<Postcode__c>();
		postcodes.add(new Postcode__c(Locality_Postcode_ID__c = '3164', Name = '2000', State__c = 'NSW', Suburb__c = 'SYDNEY'));
		postcodes.add(new Postcode__c(Locality_Postcode_ID__c = '3114', Name = '3000', State__c = 'VIC', Suburb__c = 'MELBOURNE'));
		insert postcodes;

		System.Debug('>>> Postcodes: ' + postcodes);

		List<PostcodeMapping__c> postCodeMappings = new List<PostcodeMapping__c>();
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwSyd1.Id, Postcode__c = postcodes[0].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwSyd2.Id, Postcode__c = postcodes[0].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwSyd3.Id, Postcode__c = postcodes[0].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwMelb1.Id, Postcode__c = postcodes[1].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwMelb2.Id, Postcode__c = postcodes[1].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwMelb3.Id, Postcode__c = postcodes[1].Id));
		postCodeMappings.add(new PostcodeMapping__c(Network__c = nwMelb4.Id, Postcode__c = postcodes[1].Id));
		insert postCodeMappings;

		System.Debug('>>> postCodeMappings: ' + postCodeMappings);


	}

	/**
	  * Scenario test the case aspects of Facility Search.
	  */
	public static testMethod void testCaseNetworks() {

		Test.startTest();
		SSSWRouting__c routing = TestUtility.createSSSWRouting(null,'KeyPass','General Enquiry',null,'Consumer','Social','Any',SSSWConstants.RECTYPEESCALATION);
		routing.AutoEscalate__c = true;
		routing.IsActive__c = true;
		insert routing;

		Case case1 = [Select Id From Case LIMIT 1];
		Contact contact1 = [Select Id From Contact LIMIT 1];

		ApexPages.currentPage().getParameters().put('id', case1.Id);
		ApexPages.currentPage().getParameters().put('address1Label', '123');
		ApexPages.currentPage().getParameters().put('address2Label', '123');

		FacilitySearchController search = new FacilitySearchController();
		List<RecordType> recordTypes = FacilitySearchController.networkRecordTypes;
		Map<String, String> recordTypeIdNameMappings = FacilitySearchController.networkRecordTypeIdNameMappings;

		Apexpages.currentPage().getParameters().put('geocode', '-37.814_144.96332');
		search.postback_searchFacilitiesByGeoCode();

		// make sure we have the right number of tabs
		System.assertEquals(recordTypes.size()+1, search.networkTabs.tabCount());

		// make sure we have the right number of networks
		Map<String, Integer> networkCountByRecordType = new Map<String, Integer>();
		Integer networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}

			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId) + tab.networks.size());
		}

		// 2 should appear on Case Related tab (one is on Network__c field and one is in Event Message)
		// 1 always shown network
		// 2 networks returned from search.
		System.assertEquals(5, networkCount);

		System.assertEquals(1, networkCountByRecordType.get('Delivery_1'));
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));
		System.assertEquals(1, networkCountByRecordType.get('Other_8'));


		// search geocode with postcode
		Apexpages.currentPage().getParameters().put('geocode', '-37.814_144.96332_3000');
		search.postback_searchFacilitiesByGeoCode();

		// make sure we have the right number of tabs
		System.assertEquals(recordTypes.size()+1, search.networkTabs.tabCount());

		// make sure we have the right number of networks
		networkCountByRecordType = new Map<String, Integer>();
		networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}

			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId) + tab.networks.size());
		}

		// 2 should appear on Case Related tab (one is on Network__c field and one is in Event Message)
		// 1 always shown network
		// 2 networks returned from search.
		System.assertEquals(5, networkCount);

		System.assertEquals(1, networkCountByRecordType.get('Delivery_1'));
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));
		System.assertEquals(1, networkCountByRecordType.get('Other_8'));

		Test.stopTest();

	}

	/**
	  * Scenario test the suburb postcode search
	  */
	public static testMethod void testNetworksSearchPostcodeSuburb() {
		Test.startTest();

		FacilitySearchController search = new FacilitySearchController();
		List<RecordType> recordTypes = FacilitySearchController.networkRecordTypes;

		search.keyword = '2000 - SYDNEY';
		search.postback_searchFacilitiesBySuburbPostcode();

		// make sure we have the right number of tabs (no case tab)
		System.assertEquals(recordTypes.size(), search.networkTabs.tabCount());

		// make sure we have the right number of networks
		Map<String, Integer> networkCountByRecordType = new Map<String, Integer>();
		Integer networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			for(FacilitySearchController.NetworkWrapper nw : tab.networks) {
				System.Debug('Found Network: ' + nw.network.Name);
			}

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}
			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId)+tab.networks.size());
		}

		System.Debug('>>> networkCountByRecordType: ' + networkCountByRecordType);

		// 1 always shown network
		// 2 networks returned from search.
		System.assertEquals(3, networkCount);

		System.assertEquals(1, networkCountByRecordType.get('Delivery_1')); // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));  // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Other_8')); // always shown network (even though it's in melbourne)

		search.keyword = 'SYDNEY';
		search.postback_searchFacilitiesBySuburbPostcode();

		// make sure we have the right number of networks
		networkCountByRecordType = new Map<String, Integer>();
		networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}
			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId)+tab.networks.size());
		}

		// 1 always shown network
		// 2 networks returned from search.
		System.assertEquals(3, networkCount);

		System.assertEquals(1, networkCountByRecordType.get('Delivery_1')); // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));  // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Other_8')); // always shown network (even though it's in melbourne)

		search.keyword = '2000';
		search.postback_searchFacilitiesBySuburbPostcode();

		// make sure we have the right number of networks
		networkCountByRecordType = new Map<String, Integer>();
		networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}
			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId)+tab.networks.size());
		}

		// 1 always shown network
		// 2 networks returned from search.
		System.assertEquals(3, networkCount);

		System.assertEquals(1, networkCountByRecordType.get('Delivery_1')); // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));  // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Other_8')); // always shown network (even though it's in melbourne)

		Test.stopTest();

	}

	/**
	  * Scenario:
	  *	Test to make sure that bypass networks are appearing in search results
	  */
	public static testMethod void testNetworkBypasses() {

		Test.startTest();

		// link network in Sydney to network in melbourne as a bypass
		Network__c nwSyd = [Select Id From Network__c Where ORG_UNIT_ADDR_3__c = 'Sydney' And RecordType.DeveloperName = 'Delivery_1'];
		Network__c nwMelb = [Select Id From Network__c Where ORG_UNIT_ADDR_3__c = 'Melbourne' And RecordType.DeveloperName = 'Delivery_1'];

		// log a bypass from the first to second network and vice versa
		FacilityByPass__c fbp = new FacilityByPass__c();
		fbp.Facility_By_Pass_From__c = nwSyd.Id;
		fbp.Facility_By_Pass_To__c = nwMelb.Id;
		insert fbp;

		fbp = new FacilityByPass__c();
		fbp.Facility_By_Pass_From__c = nwMelb.Id;
		fbp.Facility_By_Pass_To__c = nwSyd.Id;
		insert fbp;

		FacilitySearchController search = new FacilitySearchController();
		search.keyword = '2000 - SYDNEY';
		search.postback_searchFacilitiesBySuburbPostcode();

		// make sure we have the right number of networks
		Map<String, Integer> networkCountByRecordType = new Map<String, Integer>();
		Integer networkCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			networkCount += tab.networks.size();

			for(FacilitySearchController.NetworkWrapper nw : tab.networks) {
				System.Debug('Found Network: ' + nw.network.Name);
			}

			if(networkCountByRecordType.get(tabId) == null) {
				networkCountByRecordType.put(tabId, 0);
			}

			networkCountByRecordType.put(tabId, networkCountByRecordType.get(tabId) + tab.networks.size());
		}

		// 1 always shown network
		// 2 networks returned from search.
		// 1 bypassnetwork (located in melbourne)
		System.assertEquals(4, networkCount);

		System.assertEquals(2, networkCountByRecordType.get('Delivery_1')); // Sydney network + 1 bypass
		System.assertEquals(1, networkCountByRecordType.get('Business_Hub_3'));  // Sydney network
		System.assertEquals(1, networkCountByRecordType.get('Other_8')); // always shown network (event though it's in melbourne)

		Test.stopTest();
	}

	/**
	  * Scenario:
	  *	Test to make sure that bypass networks are appearing in search results
	  */
	public static testMethod void testNetworkInternationalSearch() {

		Test.startTest();

		// pass case so international networks dig into prodStdMessageCapture
		Case case1 = [Select Id From Case LIMIT 1];
		Contact contact1 = [Select Id From Contact LIMIT 1];
		SSSWRouting__c routing = TestUtility.createSSSWRouting(null,'KeyPass','General Enquiry',null,'Consumer','Social','All',SSSWConstants.RECTYPEESCALATION);
		routing.AutoEscalate__c = true;
		routing.IsActive__c = true;
		insert routing;
		ApexPages.currentPage().getParameters().put('id', case1.Id);

		FacilitySearchController search = new FacilitySearchController();
		search.countryName = 'Germany';
		search.loadInternationalNetworks();

		FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get('International_4');
		System.assertEquals(1, tab.networks.size());

		Test.stopTest();
	}

	/**
	  * Scenario:
	  *	Test to make sure that bypass networks are appearing in search results
	  */
	public static testMethod void testNetworkIncidents() {

		Test.startTest();
		Id CriticalIncidentRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Knowledge__kav', new Set<String>{'Critical_Incident'}).values()[0].Id;
		Knowledge__kav kav = new Knowledge__kav(NetworkOrgId__c = '12345;2222;', URLNAme = 'test1244', Title = 'tt', language = 'en_US', Timetoremind__c = Date.today(), RecordTypeId = CriticalIncidentRecordTypeId);
		insert kav;

		//retrieve master article Id created on FAQ__kav record insertion
		//in order to get the KnowledgeArticleId
		kav = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id = :kav.Id];

		//publish it
		KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);

		FacilitySearchController search = new FacilitySearchController();
		search.keyword = '2000 - SYDNEY';
		search.postback_searchFacilitiesBySuburbPostcode();

		// make sure we have the right number of networks
		Integer incidentCount = 0;
		for(String tabId : search.networkTabs.getTabs().keySet()) {
			FacilitySearchController.NetworkTab tab = search.networkTabs.getTabs().get(tabId);
			for(FacilitySearchController.NetworkWrapper networkWrapper : tab.networks) {
				incidentCount += (networkWrapper.criticalIncidents != null ? networkWrapper.criticalIncidents.size() : 0);
			}
		}

		// ensure at least 1 incident was found
		// in the testSetup a sydney network was given the Org Id 12345
		//  given that we are searching for Sydney, the incident should be found and attached to that network.
		System.assertEquals(1, incidentCount);

		Test.stopTest();
	}

	/**
	  * Scenario test the case aspects of Facility Search.
	  */
	public static testMethod void testCaseLodgementPoint() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];
		Network__c network1 = [Select Id From Network__c Limit 1];

		String output = FacilitySearchController.lodgementPoint(case1.Id, network1.Id);
		Boolean result = !(output.contains('Error'));
		System.assert(result);

		Test.stopTest();
	}

	/**
	  * Scenario test the case aspects of Facility Search.
	  */
	public static testMethod void testEmailTemplateSend() {
		System.Debug('TEST: testEmailTemplateSend');
		
		Test.startTest();

		FacilitySearchController.isTest = true;

		// create a custom setting
		QM__c configSetting = new QM__c();
		configSetting.NetworkEmail__c = 'fromaddress@test.com';
		configSetting.CusEmail__c = 'fromaddress@test.com';
		insert configSetting;

		Case case1 = [Select Id From Case Limit 1];
		Network__c network1 = [Select Id From Network__c Limit 1];

		FacilitySearchController.EmailParticipant ep = new FacilitySearchController.EmailParticipant('test', 'test@test.com');
		String output = FacilitySearchController.getEmailTemplateAndSendMail('test@test.com', case1.Id, new List<FacilitySearchController.EmailParticipant>{ep});
		System.Debug('>>> output: ' + output);
		Boolean result = !(output.contains('Error'));
		System.Debug('>>> result: ' + result);
		System.assert(result);

		Test.stopTest();
	}



	/**
	  * SCENARIO:
	  *   After a case has been created and the user click Network Search from within the Case.
	  *   Scenario will test the contactViaManually functionality where the user finds a network and attempts to contact them
	  */
	public static testMethod void testContactViaManually() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];

		Network__c network1 = [Select Id From Network__c Limit 1];
		network1.Contact_Facility__c = 'Manually';
		update network1;

		System.Debug(FacilitySearchController.contactViaManually(case1.Id, network1.Id, 'External System ABC'));
		case1 = [Select Id, Status From Case Where Id = :case1.Id];
		System.assertEquals('Closed', case1.Status);

		Test.stopTest();
	}

	/**
	  * SCENARIO:
	  *   After a case has been created and the user click Network Search from within the Case.
	  *   Scenario will test the contactViaFax functionality where the user finds a network and attempts to contact them
	  */
	public static testMethod void testContactViaFax() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];

		Network__c network1 = [Select Id From Network__c Limit 1];
		network1.Contact_Facility__c = 'Fax';
		update network1;

		System.Debug(FacilitySearchController.contactViaFax(network1.Id, case1.Id, 'Comment for Fax Send', false));

		// check to make sure the case was closed
		case1 = [Select Id, Status From Case Where Id = :case1.Id];
		System.assertEquals('Closed', case1.Status);

		// check to make sure a fax record was created
		List<Fax__c> faxes = [Select Id, Name From Fax__c LIMIT 1];
		System.assertNotEquals(0, faxes.size());

		// Now we need to attach the fax to the case
		FacilitySearchController.addAttachmentToFax(case1.Id, faxes[0].Id);
		case1 = [Select Id, EscalationEmail__c From Case Where Id = :case1.Id];
		System.assertNotEquals(null, case1.EscalationEmail__c);

		Test.stopTest();
	}

	/**
	  * SCENARIO:
	  *   After a case has been created and the user click Network Search from within the Case.
	  *   Scenario will test the contactViaSalesforce functionality where the user finds a network and attempts to contact them
	  */
	public static testMethod void testContactViaSalesforce() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];

		Network__c network1 = [Select Id From Network__c Limit 1];
		network1.Email__c = 'top@top.com';
		network1.Contact_Facility__c = 'MyNetwork';
		network1.Portal_Licenses__c = 10;
		network1.WCVIC_AVAIL__c = true;
		update network1;

		Facility_User__c facilityUser1 = new Facility_User__c(Network__c = network1.Id, User__c = UserInfo.getUserId());
		insert facilityUser1;

		System.Debug(FacilitySearchController.contactViaSalesforce(case1.Id, 'test@test.com.sf', network1.Id, false));

		// check to make sure the case was closed
		case1 = [Select Id, Status From Case Where Id = :case1.Id];
		System.assertEquals('Closed', case1.Status);

		Test.stopTest();
	}

	/**
	  * SCENARIO:
	  *   After a case has been created and the user click Network Search from within the Case.
	  *   Scenario will test the contactViaEmail functionality where the user finds a network and attempts to contact them
	  */
	public static testMethod void testContactViaEmail() {

		Test.startTest();

		FacilitySearchController.isTest = true;

		// create a custom setting
		QM__c configSetting = new QM__c();
		configSetting.NetworkEmail__c = 'fromaddress@test.com';
		configSetting.CusEmail__c = 'fromaddress@test.com';
		insert configSetting;

		Case case1 = [Select Id From Case Limit 1];

		Network__c network1 = [Select Id From Network__c Limit 1];
		network1.Email__c = 'top@top.com';
		network1.Contact_Facility__c = 'Email';
		update network1;

		System.Debug(FacilitySearchController.contactViaEmail('email comment', network1.Id, case1.Id, false, true, 'test@test.com.sf'));

		Test.stopTest();

		// check to make sure the case was closed
		case1 = [Select Id, Status From Case Where Id = :case1.Id];
		System.assertEquals('Closed', case1.Status);
	}

	/**
	  * SCENARIO:
	  *   Test Email Content
	  */
	public static testMethod void testEscEmailContent() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];
		String output = FacilitySearchController.setEscEmailContent(case1.Id);
		System.assertEquals(false, String.isEmpty(output));

		Test.stopTest();
	}

	/**
	  * SCENARIO:
	  *   User is passing in an account Id and and also a contact id
	  */
	public static testMethod void testAccountParam() {
		Test.startTest();

		Case case1 = [Select Id From Case Limit 1];
		Account acc = [Select Id From Account Where RecordType.DeveloperName != 'Organisation' LIMIT 1];
		Contact con = [Select Id From Contact LIMIT 1];

		ApexPages.currentPage().getParameters().put('contactId', acc.Id);
		FacilitySearchController search = new FacilitySearchController();
		System.assertNotEquals(true, (!String.isEmpty(search.keyword) ? String.isEmpty(search.keyword.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.senderAddress) ? String.isEmpty(search.senderAddress.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.recipientAddress) ? String.isEmpty(search.recipientAddress.trim()) : true));

		ApexPages.currentPage().getParameters().put('contactId', con.Id);
		search = new FacilitySearchController();
		System.assertNotEquals(true, (!String.isEmpty(search.keyword) ? String.isEmpty(search.keyword.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.senderAddress) ? String.isEmpty(search.senderAddress.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.recipientAddress) ? String.isEmpty(search.recipientAddress.trim()) : true));

		ApexPages.currentPage().getParameters().put('id', acc.Id);
		search = new FacilitySearchController();
		System.assertNotEquals(true, (!String.isEmpty(search.senderAddress) ? String.isEmpty(search.senderAddress.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.recipientAddress) ? String.isEmpty(search.recipientAddress.trim()) : true));

		ApexPages.currentPage().getParameters().put('id', con.Id);
		search = new FacilitySearchController();
		System.assertNotEquals(true, (!String.isEmpty(search.senderAddress) ? String.isEmpty(search.senderAddress.trim()) : true));
		System.assertNotEquals(true, (!String.isEmpty(search.recipientAddress) ? String.isEmpty(search.recipientAddress.trim()) : true));

		Test.stopTest();
	}

	/**
	  * SCENARIO:
	  *   ensure json variables are correct
	  */
	public static testMethod void testJSON() {
		Test.startTest();

		FacilitySearchController search = new FacilitySearchController();
		search.keyword = '2000 - SYDNEY';
		search.postback_searchFacilitiesBySuburbPostcode();

		String jsonOutput = '[' + FacilitySearchController.jsonNetworkRecordTypes + ']';
		String listOfLocations = '[' + search.listOfLocations + ']';

		System.Debug('>>> jsonOutput: ' + jsonOutput);
		System.Debug('>>> listOfLocations: ' + listOfLocations);


		// these will error if JSON is invalid and the test will fail
		Object recordTypes = JSON.deserializeUntyped(jsonOutput);
		Object locations = JSON.deserializeUntyped(listOfLocations);

		System.assert(true);

		Test.stopTest();
	}

}