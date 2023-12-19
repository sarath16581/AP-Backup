/**
 * Created by vcheng on 13/04/2021.
 * 2023-05-05	Naveen Rajanna	REQ3184691	changed api version and added new constant for custom settings
 */

 @IsTest
 private class BCAFormController_Test {
 
	 private static final String TEST_ABN = '23166100181';
 
	 @IsTest
	 private static void testGetSettings() {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 AusPostSettings__c skipValidationSetting = new AusPostSettings__c();
		 //ApplicationTestDataFactory.generateRecordIds(new List<AusPostSettings__c> {skipValidationSetting});
		 skipValidationSetting.Name = BCAFormConstants.BCA_SKIP_VALIDATION;
		 skipValidationSetting.IsActive__c = true;
		 //insert skipValidationSetting;
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 // N/A
		 CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
				 .thenReturn(new Map<String, AusPostSettings__c>{
				 BCAFormConstants.BCA_SKIP_VALIDATION => skipValidationSetting
		 });
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 Boolean skipValidation = BCAFormController.skipValidationSetting();
		 System.assertEquals(true, skipValidation, 'Expected True, got ' + skipValidation);
		 Test.stopTest();
	 }
 
	 @IsTest
	 private static void testGetCountries()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 CountryCodes__c c = new CountryCodes__c();
		 c.Name = 'Australia';
		 insert c;
 
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 // N/A
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 List<BCAFormController.SelectOptionCustom> optionCountries = BCAFormController.getCountries();
		 System.assertNotEquals(0, optionCountries.size(), 'Expected more than 0, got ' + optionCountries);
		 Test.stopTest();
	 }
 
 
	 @IsTest
	 private static void testSearchNetworks()
	 {
		 String outletName = 'LPO Melbourne';
		 Decimal lat = 0.0;
		 Decimal longitude = 0.0;
		 Integer maxDist = 50;
 
		 // =====================================
		 // Data Preparation
		 // =====================================
		 Network__c outlet = new Network__c();
		 ApplicationTestDataFactory.generateRecordIds(new List<Network__c> {outlet});
		 outlet.Name = outletName;
		 outlet.Geolocation__Latitude__s = lat;
		 outlet.Geolocation__Longitude__s = longitude;
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 NetworksSelector networksSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class);
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
		 MockUtility.Mocks.when(networksSelector.selectByMaxDistance(maxDist, lat, longitude, ''))
				 .thenReturn(new List<Network__c> {outlet});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 List<BCAFormController.postalOutletWrapper> outletWrappers = BCAFormController.searchNetworks(lat, longitude);
		 System.assertEquals(1, outletWrappers.size(), 'Expected 1 outlet, got ' + outletWrappers);
		 Test.stopTest();
	 }
 
 
	 @IsTest
	 private static void testCreateDocument()
	 {
 
		 // =====================================
		 // Data Preparation
		 // =====================================
		 String blobString = 'This is a test';
		 Blob blobFile = Blob.valueOf(blobString);
 
		 Map<String, Object> objFile = new Map<String, Object>{
				 'PathOnClient' => 'testPath',
				 'Title' => 'testTitle',
				 'VersionData' => blobFile
		 };
		 ContentVersion cv = new ContentVersion();
		 ApplicationTestDataFactory.generateRecordIds(new List<SObject> {cv});
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector)MockUtility.mockSelector(ContentVersionsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		 MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, ContentVersion>{cv.Id => cv});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormHelper.SaveFileResult sfr = BCAFormController.uploadFile(objFile);
		 System.assertEquals(BCAFormConstants.OK, sfr.status, 'Expected OK, got ' + sfr);
		 Test.stopTest();
	 }
 
	 @IsTest private static void testUploadFileError()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 String blobString = 'This is a test';
		 Blob blobFile = Blob.valueOf(blobString);
 
		 Map<String, Object> objFile = new Map<String, Object>{
				 'PathOnClient' => 'testPath',
				 'Title' => 'testTitle',
				 'VersionData' => blobFile
		 };
		 ContentVersion cv = new ContentVersion();
		 ApplicationTestDataFactory.generateRecordIds(new List<SObject> {cv});
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector)MockUtility.mockSelector(ContentVersionsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		 MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, ContentVersion>{cv.Id => cv});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormHelper.SaveFileResult sfr = BCAFormController.uploadFile(objFile);
		 System.assertEquals(BCAFormConstants.ERROR, sfr.status, 'Expected ' + BCAFormConstants.ERROR + ', got ' + sfr);
		 Test.stopTest();
	 }
 
	 @IsTest
	 private static void testDeleteFile()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 ContentDocument cd = new ContentDocument();
		 ApplicationTestDataFactory.generateRecordIds(new List<SObject> {cd});
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		 MockUtility.Mocks.when(cdSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, ContentDocument>{cd.Id => cd});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormHelper.SaveFileResult sfr = BCAFormController.deleteUploadedFile(cd.Id);
		 System.assertEquals(BCAFormConstants.OK, sfr.status, 'Expected OK, got ' + sfr);
		 Test.stopTest();
	 }
 
	 @IsTest
	 private static void testDeleteFileError()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 ContentDocument cd = new ContentDocument();
		 ApplicationTestDataFactory.generateRecordIds(new List<SObject> {cd});
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLDeleteFailed());
		 MockUtility.Mocks.when(cdSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, ContentDocument>{});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormHelper.SaveFileResult sfr = BCAFormController.deleteUploadedFile(cd.Id);
		 System.assertEquals(BCAFormConstants.ERROR, sfr.status, 'Expected ' + BCAFormConstants.ERROR + ', got ' + sfr);
		 Test.stopTest();
	 }
 
	 @IsTest
	 private static void testQueryAbn()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
 
		 //ASICReport_element
		 APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
 
		 //OrgIdResult_element
		 List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
		 APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
		 orgIdelement.ASICReport = asicreport;
		 orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
		 orgIdelement.OrgIdResultUniqueNumber = 1;
		 orgidelementList.add(orgIdelement);
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.StartTest();
 
		 Object abnResults = BCAFormController.queryABN('', '');
		 System.assertNotEquals(null, abnResults, 'expected a result:' + abnResults);
 
		 Test.stopTest();
	 }
 
 
	 @IsTest
	 private static void testCreateCreditAssessment()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 // account
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		 // Custom BCA Settings
		 BCAFormHelper.bcaSettings = new Map<String,SObject>{
			BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => new BCA_Settings__c(
				Name = BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD,
				Number_Value__c = 60
			)
		 };
		 // credit assessment
		 APT_Credit_Assessment__c caRecord = new APT_Credit_Assessment__c();
		 caRecord.APT_ABN__c = TEST_ABN;
		 caRecord.APT_Email_Address__c = 'test@example.com';
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
 
		 CreditAssessmentWrapper caWrapper = getTestCreditAssessmentWrapper();
		 caWrapper.userOrgId = testAccount.Id;
		 String sCAWrapper = JSON.serialize(caWrapper);
 
		 // ABN/ABR reports to cache
		 CacheManager.settings.CacheEnabled__c = true;
		 APT_SchemaPartyCustomerService.OrgIdResult_element orgElem = new APT_SchemaPartyCustomerService.OrgIdResult_element();
		 orgElem.ASICReport = getTestASICReport();
		 orgElem.AustralianBusinessRegisterReport = getTestABRReport();
		 BCAFormController.storeAbnDetailsToCache(orgElem);
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		 MockUtility.Mocks.when(mockDatabase.findDuplicates((List<SObject>)fflib_Match.anyObject()))
				.thenReturn(new List<DatacloudProxy.FindDuplicatesResult>());
		 MockUtility.Mocks.when(cdSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, ContentDocument>{});
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormHelper.SaveAssessmentWrapper resultWrapper = BCAFormController.saveAssessment(sCAWrapper);
		 System.assertEquals(BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS, resultWrapper.status, 'Expected ' + BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS + ', got ' + resultWrapper);
		 Test.stopTest();
	 }
 
	 private static APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element getTestABRReport()
	 {
		 APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element abrReport = new APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element();
		 abrReport.ASICNumber = 'test';
		 abrReport.ASICNumberType = 'test';
		 abrReport.ABN = 'test';
		 abrReport.ABNStatus = 'test';
		 //abrReport.ABNStatusFromDate = 'test';
		 abrReport.EntityTypeText = 'test';
		 abrReport.EntityTypeInd = 'test';
		 //abrReport.IndividualName = 'test';
		 abrReport.NonIndividualName = 'test';
		 abrReport.BusinessAddressState = 'test';
		 abrReport.BusinessAddressPostcode = 'test';
		 abrReport.GSTStatus = 'test';
		 //abrReport.GSTStatusFromDate = 'test';
		 abrReport.TradingName = 'test';
		 return abrReport;
	 }
 
	 private static APT_SchemaPartyCustomerService.ASICReport_element getTestASICReport()
	 {
		 APT_SchemaPartyCustomerService.ASICReport_element asicReport = new APT_SchemaPartyCustomerService.ASICReport_element();
		 asicReport.ASICName = 'test';
		 asicReport.ASICOrganisationNumber = 'test';
		 asicReport.ASICABN = 'test';
		 asicReport.ASICOrganisationNumberHeading = 'test';
		 asicReport.ASICPrescribedInterestNumber = 'test';
		 asicReport.ASICUndertakingName = 'test';
		 asicReport.ASICType = 'test';
		 //asicReport.ASICRegistrationDate = 'test';
		 asicReport.ASICStatus = 'test';
		 asicReport.ASICState = 'test';
		 asicReport.ASICBusinessRegistrationNumber = 'test';
		 asicReport.ASICJurisdiction = 'test';
		 asicReport.ASICLocality = 'test';
		 asicReport.ASICAddressState = 'test';
		 asicReport.ASICPostcode = 'Test';
		 return asicReport;
	 }
 
	 private static CreditAssessmentWrapper getTestCreditAssessmentWrapper()
	 {
		 CreditAssessmentWrapper cdw = new CreditAssessmentWrapper();
		 Date dtTest = Date.newInstance(2000, 01, 01);
		 String sDate = dtTest.year() + '-' + dtTest.month() + '-' + dtTest.day();
 
		 cdw.abnDetails = new CreditAssessmentWrapper.ABNDetails();
		 cdw.abnDetails.ABN = TEST_ABN;
		 cdw.abnDetails.LegalEntityName = 'Acme Inc.';
		 cdw.abnDetails.tradingName = 'Looney Tunes';
		 cdw.abnDetails.EntityTypeMasterLabel = BCAFormConstants.ENTITY_TYPE_BUSINESS;
		 cdw.abnDetails.ABNStatusFromDate = sDate;
 
		 // address
		 CreditAssessmentWrapper.StreetAddressAME testAddress = new CreditAssessmentWrapper.StreetAddressAME();
		 testAddress.addressLine1 = '11 Happy St';
		 testAddress.addressLine2 = '';
		 testAddress.postcode = '3000';
		 testAddress.state = 'VIC';
		 testAddress.city = 'Melbourne';
		 testAddress.countryCode = 'AU';
 
		 cdw.businessAddressDetails = new CreditAssessmentWrapper.BusinessAddressDetails();
		 cdw.businessAddressDetails.streetAddress = testAddress;
 
		 // type
		 cdw.businessTypeDetails = new CreditAssessmentWrapper.BusinessTypeDetails();
		 cdw.businessTypeDetails.industryDivision = 'T Testing';
		 cdw.businessTypeDetails.industryClass = 'Testing';
 
		 // business person
		 CreditAssessmentWrapper.BusinessPerson director = new CreditAssessmentWrapper.BusinessPerson();
		 director.firstName = 'Bruce';
		 director.lastName = 'Banner';
		 director.dob = sDate;
		 director.currentResidentialAddress = testAddress;
		 director.previousResidentialAddress = testAddress;
		 director.timeAtAddress = 'less';
		 cdw.directors = new List<CreditAssessmentWrapper.BusinessPerson> {director, director};
 
		 cdw.businessContact = new CreditAssessmentWrapper.BusinessContact();
		 cdw.emailForCorrespondence = new CreditAssessmentWrapper.EmailCorrespondence();
		 cdw.creditAmount = new CreditAssessmentWrapper.CreditAmount();
		 cdw.directDebit = new CreditAssessmentWrapper.DirectDebit();
 
		 // references
		 CreditAssessmentWrapper.BusinessReference ref1 = new CreditAssessmentWrapper.BusinessReference();
		 ref1.businessName = 'Acme';
		 ref1.fullName = 'Bugs Bunny';
		 ref1.phone = '0400111222';
		 ref1.positionTitle = 'CEO';
		 cdw.businessRefs = new List<CreditAssessmentWrapper.BusinessReference>{ref1, ref1, ref1};
 
		 Network__c outlet = new Network__c();
		 ApplicationTestDataFactory.generateRecordIds(new List<Network__c> {outlet});
		 CreditAssessmentWrapper.PostalOutlet postalOutlet = new CreditAssessmentWrapper.PostalOutlet();
		 postalOutlet.id = outlet.Id;
		 cdw.postalOutlets = new List<CreditAssessmentWrapper.PostalOutlet>{postalOutlet};
 
 
		 return cdw;
	 }
	 
	 @IsTest
	 private static void testEquifaxCompanyValidation(){
		 //APT_Credit_Assessment__c caRecord = buildCreditAssesmentObj();
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		 
		 // credit assessment json trust
		 String caJSONStr = '{"directors":[{"firstName":"name","lastName":"surname","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Director","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"middle","dob":"1999-10-10","phone":"0495657544","email":"a@gmail.com","driversLicense":"988766666","index":"1"}],"userOrgId":"ORGIDX","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"83004143239","ABNStatus":"ACT","ABNStatusFromDate":"2000-02-01","ACN":"004143239","entities":[{"entityName":"MYER DIRECT","entityType":"OTN"},{"entityName":"GRACE BROS.","entityType":"OTN"}],"EntityTypeGroup":"Company","EntityTypeMasterLabel":"BUSINESS","EntityTypeText":"Australian Public Company","LegalEntityName":"MYER STORES LIMITED","MatchName":"MYER GRACE BROS ","OrganisationNumber":"F00098033","OrganisationNumberHeading":"Number","State":"ACT","TradingNameStr":"MYER GRACE BROS","statusString":"Active","formattedABN":"83 004 143 239","tradingName":"MYER GRACE BROS","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"N Administrative and Support Services","industryClass":"Building & Oth. Industrial Cleaning Svc.","noOfDirectors":"1"},"digitalIdVerified":true,"businessContact":{"firstName":"name","lastName":"surname","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Director","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"middle","dob":"1999-10-10","phone":"0495657544","email":"a@gmail.com","driversLicense":"988766666","index":"1"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":2000,"recommendedAmount":4000},"directDebit":{"accountName":"name acc","bankName":"3453453","bsb":"345-343","accountNumber":"4343534544"},"businessRefs":[{"businessName":"Business 1","fullName":"Robert","positionTitle":"Account Manger","phone":"0495657544","index":"1"},{"businessName":"Business 2","fullName":"Chris John","positionTitle":"CEO","phone":"0495657544","index":"2"},{"businessName":"Business 3","fullName":"Alex Nath","positionTitle":"Sales Manager","phone":"0495657544","index":"3"}],"postalOutlets":[{"addressLine2":"UNIT 2 1613 OCEAN DRIVE","distance":0.15,"id":"a2K5D000001pj6BUAQ","latitude":-33.814501,"longitude":151.168417,"name":"LANE COVE POST OFFICE","networkAddress":"UNIT 2 1613 OCEAN DRIVE, LANE COVE NSW 2445","orgId":"237032","postcode":"2445","state":"NSW","suburb":"LANE COVE","addressFormatted":"unit 2 1613 ocean drive, lane cove, NSW, 2445","mapLink":"https://maps.google.com/?q=Australia Post - LANE COVE POST OFFICE UNIT 2 1613 OCEAN DRIVE, LANE COVE NSW 2445","disabled":false,"selected":true}]}';
		 caJSONStr = caJSONStr.replace('ORGIDX', testAccount.Id);
		 
		 CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);
		 
		 APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		 System.debug('caRecord Id='+caRecord.Id);
		 
		 // =====================================
		 // Stubbing
		 // =====================================
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject())) //(new Set<Id>{caRecord.Id})
			 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.stopStubbing();
		 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 // Invoke the continuation by calling the action method
		 Continuation conti = (Continuation)BCAFormController.doEquifaxValidations(caRecord.Id);
		 //BCAFormController controller = new BCAFormController();
		 // Verify that the continuation has the proper requests
		 Map<String, HttpRequest> requests = conti.getRequests();
		 system.assert(requests.size() == 1);
		 
		 // Perform mock callout
		 HttpResponse response = new HttpResponse();
		 response.setBody(EquifaxCalloutMock.getCompanyResponse());
		 
		 // Set the fake response for the continuation
		 String requestLabel = requests.keyset().iterator().next();
		 Test.setContinuationResponse(requestLabel, response);
		 
		 // Invoke callback method
		 Object result = Test.invokeContinuationMethod(new BCAFormController(), conti);
		 System.assertNotEquals(null, result, 'testSearchAPSyncAPSingleCon');
		 
		 
		 Test.stopTest();		
		 
	 }
	 
		 @IsTest
	 private static void testEquifaxIndividualValidation(){
		/* APT_Credit_Assessment__c caRecord = buildCreditAssesmentObj();
		 caRecord.APT_Entity_Type__c = 'INDV';
		 caRecord.APT_ACN__c = '';
		 caRecord.APT_ABN__c = '80112125659';*/
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		 
		 // credit assessment json trust
		 String caJSONStr = '{"directors":[{"firstName":"name","lastName":"surname","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Proprietor","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"middle","dob":"2000-10-10","phone":"0495657544","email":"a@gmail.com","driversLicense":"988766666","index":"1"}],"userOrgId":"ORGIDX","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"32658461783","ABNStatus":"ACT","ABNStatusFromDate":"2002-12-01","entities":[],"EntityTypeGroup":"Individual","EntityTypeMasterLabel":"INDV","EntityTypeText":"Individual/Sole Trader","LegalEntityName":"TEXT AUSTRALIA ","MatchName":"TEXT AUSTRALIA ","State":"QLD","TradingNameStr":"RUTLAND COMMUNICATIONS","statusString":"Active","formattedABN":"32 658 461 783","tradingName":"RUTLAND COMMUNICATIONS","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street, 22,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"N Administrative and Support Services","industryClass":"Building & Oth. Industrial Cleaning Svc."},"digitalIdVerified":true,"businessContact":{"firstName":"name","lastName":"surname","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Proprietor","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"middle","dob":"2000-10-10","phone":"0495657544","email":"a@gmail.com","driversLicense":"988766666","index":"1"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":2000,"recommendedAmount":4000},"directDebit":{"accountName":"acc name","bankName":"3453453","bsb":"345-343","accountNumber":"12423535"},"businessRefs":[{"businessName":"Businees 1","fullName":"John Smith","positionTitle":"CEO","phone":"0495657544","index":"1"},{"businessName":"Business 2","fullName":"Alex pal","positionTitle":"Sales Manager","phone":"0495657544","index":"2"},{"businessName":"Businesss 3","fullName":"Ram nath","positionTitle":"CEO","phone":"0495657544","index":"3"}],"postalOutlets":[{"addressLine1":"EDGECLIFF SHOPPING CENTRE","addressLine2":"SHOP 2 203-233 NEW SOUTH HEAD ROAD","distance":9.69,"id":"a2K5D000001piuOUAQ","latitude":-33.87921466,"longitude":151.2355196,"name":"EDGECLIFF LPO","networkAddress":"EDGECLIFF SHOPPING CENTRE SHOP 2 203-233 NEW SOUTH HEAD ROAD, EDGECLIFF NSW 2027","orgId":"288155","postcode":"2027","state":"NSW","suburb":"EDGECLIFF","addressFormatted":"edgecliff shopping centre, shop 2 203-233 new south head road, edgecliff, NSW, 2027","mapLink":"https://maps.google.com/?q=Australia Post - EDGECLIFF LPO EDGECLIFF SHOPPING CENTRE SHOP 2 203-233 NEW SOUTH HEAD ROAD, EDGECLIFF NSW 2027","disabled":false,"selected":true}]}';
		 caJSONStr = caJSONStr.replace('ORGIDX', testAccount.Id);
		 
		 CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);
		 
		 APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		 System.debug('caRecord Id='+caRecord.Id);
		 
		 // =====================================
		 // Stubbing
		 // =====================================
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject())) //(new Set<Id>{caRecord.Id})
			 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.stopStubbing();
		 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 // Invoke the continuation by calling the action method
		 Continuation conti = (Continuation)BCAFormController.doEquifaxValidations(caRecord.Id);
		 //BCAFormController controller = new BCAFormController();
		 // Verify that the continuation has the proper requests
		 Map<String, HttpRequest> requests = conti.getRequests();
		 system.assert(requests.size() == 1);
		 
		 // Perform mock callout
		 HttpResponse response = new HttpResponse();
		 response.setBody(EquifaxCalloutMock.getIndividualResponse());
		 
		 // Set the fake response for the continuation
		 String requestLabel = requests.keyset().iterator().next();
		 Test.setContinuationResponse(requestLabel, response);
		 
		 // Invoke callback method
		 Object result = Test.invokeContinuationMethod(new BCAFormController(), conti);
		 System.assertNotEquals(null, result, 'testSearchAPSyncAPSingleCon');
		 
		 
		 Test.stopTest();		
		 
	 }
	 
	 private static APT_Credit_Assessment__c buildCreditAssesmentObj(){
		 APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
		 // ca.Name ='Credit Assess - 15714';  // @Vicor, how to set non writable fields??
		 ca.APT_Entity_Type__c = 'BUSINESS';
		 ca.APT_Contact_Name__c = 'Test Name';
		 ca.APT_Address_Line_2__c = '';
		 ca.APT_Postal_Address_Line_1__c = '3 finlayson street';
		 ca.APT_Postal_City__c = 'lane cove';
		 ca.APT_Postal_State__c = 'ACT';
		 ca.APT_Postal_Postcode__c = '2066';
		 ca.APT_Requested_Credit_Limit__c = 48000;
		 ca.APT_Legal_Entity_Name__c = 'KAITEK INTERNATIONAL PTY LIMITED';
		 ca.APT_ACN__c = '071728348';
		 ca.APT_ABN__c = '48071728348';
		 ca.APT_Applicant_1_First_Name__c = 'FName';
		 ca.APT_Applicant_1_Street_Number__c = '123';
		 ca.APT_Applicant_1_Street_Name__c = '3 finlayson street';
		 ca.APT_Applicant_1_Suburb__c = 'Lane cove';
		 ca.APT_Applicant_1_State__c = 'ACT';
		 ca.APT_Applicant_1_Last_Name__c ='Lname';
		 ca.APT_Applicant_1_Date_of_Birth__c = Date.newInstance(1990, 12, 9);
		 ca.APT_Applicant_1_Postcode__c = '2066';
		 ca.APT_Applicant_1_Address_Line_2__c = 'Finlayson street';
		 ca.APT_Applicant_1_City__c = 'Lane cove';
		 ca.APT_Email_Address__c = 'a@b.com';
		 return ca;
	 }
	 
	 @IsTest
	 private static void testGeneratePDF(){
		 APT_Credit_Assessment__c caRecord = buildCreditAssesmentObj();
		 caRecord.APT_Entity_Type__c = 'INDV';
		 caRecord.APT_ACN__c = '';
		 caRecord.APT_ABN__c = '80112125659';
		 caRecord.Application_Summary_Content__c = 'pdfContent';
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		 //System.debug('caRecord Id='+caRecord.Id);
		 
		 
		 // =====================================
		 // Stubbing
		 // =====================================
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject())) //(new Set<Id>{caRecord.Id})
			 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.stopStubbing();
	
		 //Test.setCurrentPageReference(new PageReference('Page.bcaSummaryPDF')); 
		 Test.startTest();
		 BCAFormController.createPDFSummary(caRecord.Id);
		 PageReference pageRef =  Page.bcaSummaryPDF;
		 Test.setCurrentPage(pageRef);
		 System.currentPageReference().getParameters().put('caId', caRecord.Id);
		 bcaSummaryPDF bcaPDF = new BCASummaryPDF();
 
		 System.assertEquals(caRecord.Id, bcaPDF.caId, 'expected Id ' + caRecord.Id + ', got ' + bcaPDF.caId);
		 Test.stopTest();
	 }
 
	 @IsTest
	 private static void testGetDigitalIdSetting()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 BCA_Settings__c clientId = new BCA_Settings__c(Text_Value__c = '1234');
		 BCA_Settings__c isProduction = new BCA_Settings__c(Boolean_Value__c = false);
		 BCA_Settings__c creditMatchThreshold = new BCA_Settings__c(Number_Value__c = 60);
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
 
		 MockUtility.Mocks.startStubbing();
		 // Database
		 MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
				 .thenReturn(new Map<String, BCA_Settings__c>{
					 BCAFormConstants.DIGITAL_ID_CLIENT_ID => clientId,
					 BCAFormConstants.DIGITAL_ID_IS_PRODUCTION => isProduction,
					 BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => creditMatchThreshold
				 });
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormController.RequestWrapper reqWrapper = BCAFormController.getDigitalIdClientId();
		 Test.stopTest();
		 
		 System.Assert.areEqual(reqWrapper.clientId, clientId.Text_Value__c, 'Expected ClientId to match');
		 System.Assert.areEqual(reqWrapper.isProduction, isProduction.Boolean_Value__c, 'Expected isProduction to match');
	 }
 
	 @IsTest
	 private static void testDigitalId()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 BCA_Settings__c clientId = new BCA_Settings__c(Text_Value__c = '1234');
		 BCA_Settings__c clientSecret =  new BCA_Settings__c(Text_Value__c = '1234');
		 BCA_Settings__c baseUrl =  new BCA_Settings__c(Text_Value__c = '1234');
 
 
		 BCAFormController.DigitalIdToken idToken = new BCAFormController.DigitalIdToken();
		 idToken.given_name = 'Bruce';
		 idToken.family_name = 'Banner';
 
		 String sToken = JSON.serialize(idToken);
 
		 String sEncoded = JSON.serialize('prefix.' + EncodingUtil.base64Encode(Blob.valueOf(sToken)) + '.suffix');
		 BCAFormController.DigitalIdBody responseBody = new BCAFormController.DigitalIdBody();
		 responseBody.id_token = sEncoded;
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
 
		 BCAFormController.MockHttpDigitalIdResponder responder = new BCAFormController.MockHttpDigitalIdResponder();
		 responder.sBody = JSON.serialize(responseBody);
		 Test.setMock(HttpCalloutMock.class, responder);
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
				 .thenReturn(new Map<String, BCA_Settings__c>{
				 BCAFormConstants.DIGITAL_ID_CLIENT_ID => clientId,
				 BCAFormConstants.DIGITAL_ID_CLIENT_SECRET => clientSecret,
				 BCAFormConstants.DIGITAL_ID_URL => baseUrl
		 });
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
		 BCAFormController.DigitalIdToken result = BCAFormController.queryDigitalId('abcd');
		 System.assertNotEquals(null, result, 'expected a return, got:' + result );
		 Test.stopTest();
	 }
	 
	 @IsTest
	 private static void testTrustCreateCreditAssesment()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 // account
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		 
		 // Custom BCA Settings
		 BCAFormHelper.bcaSettings = new Map<String,SObject>{
			BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => new BCA_Settings__c(
				Name = BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD,
				Number_Value__c = 60
			)
		 };
		 // credit assessment json trust
		 String caJSONStr = '{"userOrgId":"ORGID","skipValidation":true,"abnDetails":{"ABN":"74919129184","ABNStatus":"ACT","ABNStatusFromDate":"2000-01-26","entities":[],"EntityTypeGroup":"Trust","EntityTypeMasterLabel":"TRUST","EntityTypeText":"Other trust","LegalEntityName":"GLENVALE FAMILY TRUST","MatchName":"GLENVALE FAMILY TRUST","State":"NSW","TradingNameStr":"GLENVALE FAMILY TRUST","statusString":"Active","formattedABN":"74 919 129 184","tradingName":"GLENVALE FAMILY TRUST","trustType":"person"},"trustFiles":[],"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"}},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Beef Cattle Farming (Specialised)"},"directors":[{"firstName":"xx","lastName":"xx","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Trustee","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"xx","dob":"2004-04-07","phone":"0495657544","email":"a@gmail.com","index":"1"}],"businessContact":{"firstName":"xx","lastName":"xx","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Trustee","currentResidentialAddress":{"countryName":"Australia","line1":"Finlayson street, 22","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"xx","dob":"2004-04-07","phone":"0495657544","email":"a@gmail.com","index":"1"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":4500,"recommendedAmount":9000},"directDebit":{"accountName":"Acc anme","bankName":"b name","bsb":"345-345","accountNumber":"12423535"},"businessRefs":[{"businessName":"Business 1","fullName":"Alex Nath","positionTitle":"Account Ma","phone":"0495657544","index":"1"},{"businessName":"Business 1","fullName":"Alex Nath","positionTitle":"0495657544","phone":"0495657544","index":"2"},{"businessName":"0495657544","fullName":"0495657544","positionTitle":"0495657544","phone":"0495657544","index":"3"}],"postalOutlets":[{"addressLine2":"SHOP 1 59-63 TANSEY DRIVE","distance":26.89,"id":"a2K5D000001piw4UAA","latitude":-27.67748468,"longitude":153.1751297,"name":"TANAH MERAH CPA","networkAddress":"SHOP 1 59-63 TANSEY DRIVE, TANAH MERAH QLD 4128","orgId":"421702","postcode":"4128","state":"QLD","suburb":"TANAH MERAH","addressFormatted":"shop 1 59-63 tansey drive, tanah merah, QLD, 4128","mapLink":"https://maps.google.com/?q=Australia Post - TANAH MERAH CPA SHOP 1 59-63 TANSEY DRIVE, TANAH MERAH QLD 4128","selected":true,"disabled":false}],"appSummaryHTML":"summary","showSpinner":true}';
		 caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);
		 
		 CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);
		 
		 APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		   // ABN/ABR reports to cache
		 CacheManager.settings.CacheEnabled__c = true;
		 APT_SchemaPartyCustomerService.OrgIdResult_element orgElem = new APT_SchemaPartyCustomerService.OrgIdResult_element();
		 orgElem.ASICReport = getTestASICReport();
		 orgElem.AustralianBusinessRegisterReport = getTestABRReport();
		 BCAFormController.storeAbnDetailsToCache(orgElem);
		 
		 
		 // =====================================
		 // Stubbing
		 // =====================================
		 AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		 MockUtility.Mocks.when(mockDatabase.findDuplicates((List<SObject>)fflib_Match.anyObject()))
				 .thenReturn(new List<DatacloudProxy.FindDuplicatesResult>());
		  MockUtility.Mocks.when(cdSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			   .thenReturn(new Map<Id, ContentDocument>{});
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 
		
		 Test.startTest();
		 BCAFormHelper.SaveAssessmentWrapper resultWrapper = BCAFormController.saveAssessment(caJSONStr);
		System.assertEquals(BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS, resultWrapper.status, 'Expected ' + BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS + ', got ' + resultWrapper);
		 Test.stopTest();
	 }
	 
	  @IsTest
	 private static void testPartnerCreateCreditAssesment()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 // account
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		 // Custom BCA Settings
		 BCAFormHelper.bcaSettings = new Map<String,SObject>{
			BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => new BCA_Settings__c(
				Name = BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD,
				Number_Value__c = 60
			)
		 };
		 // credit assessment PARTNER
		 String caJSONStr = '{"userOrgId":"ORGID","skipValidation":true,"abnDetails":{"ABN":"85813782572","ABNStatus":"ACT","ABNStatusFromDate":"2001-04-01","entities":[],"EntityTypeGroup":"Partnership","EntityTypeMasterLabel":"PARTNERSHIP","EntityTypeText":"Family Partnership","LegalEntityName":"G M HUGGARD & OTHERS PARTNERSHIP","MatchName":"G M HUGGARD & OTHERS PARTNERSHIP","State":"VIC","TradingNameStr":"G M HUGGARD & OTHERS PARTNERSHIP","statusString":"Active","formattedABN":"85 813 782 572","tradingName":"G M HUGGARD & OTHERS PARTNERSHIP","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"address":"2670 THE ADDRESS HOPE ISLAND QLD 4212","delpointId":"81200897","state":"QLD","postcode":"4212","locality":"HOPE ISLAND","countryName":"AUSTRALIA","countryCode":"AU","addressLines":["2670 THE ADDRESS"],"longitude":153.35315368,"latitude":-27.86145012,"addressLine1":"2670 THE ADDRESS","line1":"2670 THE ADDRESS","city":"HOPE ISLAND","dpid":"81200897"},"streetAddressString":"2670 THE ADDRESS,  HOPE ISLAND QLD 4212 "},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Apple & Pear Growing","noOfDirectors":"1"},"directors":[{"firstName":"fn","lastName":"ln","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Partner","currentResidentialAddress":{"address":"2670 THE ADDRESS HOPE ISLAND QLD 4212","delpointId":"81200897","state":"QLD","postcode":"4212","locality":"HOPE ISLAND","countryName":"AUSTRALIA","countryCode":"AU","addressLines":["2670 THE ADDRESS"],"longitude":153.35315368,"latitude":-27.86145012,"addressLine1":"2670 THE ADDRESS","line1":"2670 THE ADDRESS","city":"HOPE ISLAND","dpid":"81200897"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"index":"1","middleName":"mm","phone":"0495657544","email":"a@gmail.com","dob":"2003-04-01"},{"firstName":"partner","lastName":"nn","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Partner","currentResidentialAddress":{"address":"2670 THE ADDRESS HOPE ISLAND QLD 4212","delpointId":"81200897","state":"QLD","postcode":"4212","locality":"HOPE ISLAND","countryName":"AUSTRALIA","countryCode":"AU","addressLines":["2670 THE ADDRESS"],"longitude":153.35315368,"latitude":-27.86145012,"addressLine1":"2670 THE ADDRESS","line1":"2670 THE ADDRESS","city":"HOPE ISLAND","dpid":"81200897"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"middleName":"mm","dob":"2002-04-24","phone":"0495657544","email":"a@gmail.com","index":"2"}],"businessContact":{"firstName":"fn","lastName":"ln","knownByOtherName":"false","timeAtAddress":"More than 12 months","positionTitle":"Partner","currentResidentialAddress":{"address":"2670 THE ADDRESS HOPE ISLAND QLD 4212","delpointId":"81200897","state":"QLD","postcode":"4212","locality":"HOPE ISLAND","countryName":"AUSTRALIA","countryCode":"AU","addressLines":["2670 THE ADDRESS"],"longitude":153.35315368,"latitude":-27.86145012,"addressLine1":"2670 THE ADDRESS","line1":"2670 THE ADDRESS","city":"HOPE ISLAND","dpid":"81200897"},"previousResidentialAddress":{"line1":"","line2":"","city":"","state":"","postcode":"","dpid":"","country":"","countryName":""},"index":"1","middleName":"mm","phone":"0495657544","email":"a@gmail.com","dob":"2003-04-01"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":1234,"recommendedAmount":2500},"directDebit":{"accountName":"se","bankName":"3453453","bsb":"345-343","accountNumber":"12423535"},"businessRefs":[{"businessName":"Business 1","fullName":"john","positionTitle":"Account Ma","phone":"0495657544","index":"1"},{"businessName":"business 2","fullName":"rob ","positionTitle":"CEO","phone":"0495657544","index":"2"},{"businessName":"business 3","fullName":"Chris","positionTitle":"Sales Mana","phone":"0495657544","index":"3"}],"postalOutlets":[{"addressLine2":"SHOP 1 59-63 TANSEY DRIVE","distance":26.93,"id":"a2K5D000001piw4UAA","latitude":-27.67748468,"longitude":153.1751297,"name":"TANAH MERAH CPA","networkAddress":"SHOP 1 59-63 TANSEY DRIVE, TANAH MERAH QLD 4128","orgId":"421702","postcode":"4128","state":"QLD","suburb":"TANAH MERAH","addressFormatted":"shop 1 59-63 tansey drive, tanah merah, QLD, 4128","mapLink":"https://maps.google.com/?q=Australia Post - TANAH MERAH CPA SHOP 1 59-63 TANSEY DRIVE, TANAH MERAH QLD 4128","disabled":false,"selected":true}],"showSpinner":false}';
		 caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);
		 
		 CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);
		 
		 APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
		 ApplicationTestDataFactory.generateRecordIds(new List<APT_Credit_Assessment__c> {caRecord});
		 // ABN/ABR reports to cache
		 CacheManager.settings.CacheEnabled__c = true;
		 APT_SchemaPartyCustomerService.OrgIdResult_element orgElem = new APT_SchemaPartyCustomerService.OrgIdResult_element();
		 orgElem.ASICReport = getTestASICReport();
		 orgElem.AustralianBusinessRegisterReport = getTestABRReport();
		 BCAFormController.storeAbnDetailsToCache(orgElem);
		 
		 
		 // =====================================
		 // Stubbing
		 // =====================================
		 AccountsSelector accSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		 CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		 ContentDocumentsSelector cdSelector = (ContentDocumentsSelector)MockUtility.mockSelector(ContentDocumentsSelector.class);
		 ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
 
		 // set up our responses
		 MockUtility.Mocks.startStubbing();
 
		 // Database
		 MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				 .thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		 MockUtility.Mocks.when(mockDatabase.findDuplicates((List<SObject>)fflib_Match.anyObject()))
				 .thenReturn(new List<DatacloudProxy.FindDuplicatesResult>());
		 MockUtility.Mocks.when(cdSelector.selectById((Set<Id>)fflib_Match.anyObject()))
			   .thenReturn(new Map<Id, ContentDocument>{});
		 MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, APT_Credit_Assessment__c>{caRecord.Id => caRecord});
		 MockUtility.Mocks.when(accSelector.selectById((Set<Id>)fflib_Match.anyObject()))
				 .thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		 MockUtility.Mocks.stopStubbing();
 
		 // =====================================
		 // Testing
		 // =====================================
		 
		
		 Test.startTest();
		 BCAFormHelper.SaveAssessmentWrapper resultWrapper = BCAFormController.saveAssessment(caJSONStr);
		 System.assertEquals(BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS, resultWrapper.status, 'Expected ' + BCAFormConstants.CREDIT_ASSESSMENT_INSERTION_SUCCESS + ', got ' + resultWrapper);
		 Test.stopTest();
	 }
	 
	 @IsTest
	 private static void testAutoApprovedBillingAccCreationWitoutSAPConnection()
	 {
		 // =====================================
		 // Data Preparation
		 // =====================================
		 // account
		 Account testAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		 insert testAccount;
		 
		 // credit assessment GOVT
		 String caJSONStr = '{"directors":[],"userOrgId":"ORGID","skipValidation":true,"lowerCreditLimitVal":1001,"abnDetails":{"ABN":"51824753556","ABNStatus":"ACT","ABNStatusFromDate":"1999-11-01","entities":[{"entityName":"AUSTRALIAN TAXATION OFFICE-SUPERANNUATION GROUP","entityType":"OTN"}],"EntityTypeGroup":"Government","EntityTypeMasterLabel":"GOVT","EntityTypeText":"Commonwealth Government Entity","LegalEntityName":"AUSTRALIAN TAXATION OFFICE","MatchName":"AUSTRALIAN TAXATION OFFICE","State":"ACT","TradingNameStr":"AUSTRALIAN TAXATION OFFICE","statusString":"Active","formattedABN":"51 824 753 556","tradingName":"AUSTRALIAN TAXATION OFFICE","trustType":""},"businessAddressDetails":{"isBusNStreetAddressSame":"yes","streetAddress":{"countryName":"Australia","line1":"Finlayson street, 22","countryCode":"AU","line2":"15","city":"LANE COVE","postcode":"2066","state":"ACT"},"streetAddressString":"Finlayson street, 22,  15, LANE COVE ACT 2066 "},"businessTypeDetails":{"industryDivision":"A Agriculture, Forestry and Fishing","industryClass":"Apple & Pear Growing"},"businessContact":{"index":"_someoneElse","firstName":"xx","lastName":"yut","positionTitle":"Account Manger","email":"a@gmail.com"},"emailForCorrespondence":{"email":"a@gmail.com"},"creditAmount":{"acceptAmount":"true","monthlyAmount":1200,"recommendedAmount":3000},"postalOutlets":[{"addressLine2":"SHOP 2 767-769 PACIFIC HIGHWAY","distance":6.62,"id":"a2K5D000001piuBUAQ","latitude":-33.755039,"longitude":151.152857,"name":"GORDON LPO","networkAddress":"SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","orgId":"288067","postcode":"2072","state":"NSW","suburb":"GORDON","addressFormatted":"shop 2 767-769 pacific highway, gordon, NSW, 2072","mapLink":"https://maps.google.com/?q=Australia Post - GORDON LPO SHOP 2 767-769 PACIFIC HIGHWAY, GORDON NSW 2072","disabled":false,"selected":true},{"addressLine2":"SHOP 1 183 HARRIS STREET","distance":6.88,"id":"a2K5D000001piuIUAQ","latitude":-33.8709777,"longitude":151.1943996,"name":"PYRMONT LPO","networkAddress":"SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","orgId":"288171","postcode":"2009","state":"NSW","suburb":"PYRMONT","addressFormatted":"shop 1 183 harris street, pyrmont, NSW, 2009","mapLink":"https://maps.google.com/?q=Australia Post - PYRMONT LPO SHOP 1 183 HARRIS STREET, PYRMONT NSW 2009","disabled":false,"selected":true}]}';
		 caJSONStr = caJSONStr.replace('ORGID', testAccount.Id);
		 
		 CreditAssessmentWrapper cWrapper = (CreditAssessmentWrapper)System.JSON.deserialize(caJSONStr, CreditAssessmentWrapper.class);
		 
		 APT_Credit_Assessment__c caRecord = cWrapper.creditAssessment();
		 
		 caRecord.L2C_Assessment_Type__c = 'Online';
		 caRecord.APT_Credit_Assessment_Status__c = 'Approved';
		 caRecord.Integration_Status__c = '';
		 caRecord.Billing_Account__c = null;
		 
		 
		 // =====================================
		 // Testing
		 // =====================================
		 CreateBillingAccountHelper.MetadataCoverageRecordsMap.put( 'Select Id ,Connected__c From SAP_Integration__mdt Where DeveloperName = \'SAP_Integration\'',
		 (List<SAP_Integration__mdt>) JSON.deserialize('[{"Connected__c":"Yes"}]', List<SAP_Integration__mdt>.class));
		 Test.startTest();
		 insert caRecord;  // need insert than stubbing to cover a trigger
 
		 System.assertNotEquals(null, caRecord.Id, 'Credit Assessment Record not created ' + caRecord);
		 Test.stopTest();
	 }

	@isTest
	private static void testCreditSuspectRegisterCheck(){
		APT_Credit_Assessment__c caRecord = new APT_Credit_Assessment__c(
			Id = fflib_IDGenerator.generate(APT_Credit_Assessment__c.SObjectType),
			APT_Applicant_1_Last_Name__c = 'LastName',
			APT_Applicant_1_First_Name__c = 'FirstName',
			APT_Applicant_1_Telephone__c = '0400000000',
			APT_Applicant_1_Email_Address__c = 'email@auspost.com.au',
			APT_Applicant_1_Date_of_Birth__c = Date.newInstance(1980, 1, 1),
			APT_Applicant_1_Street_Name__c = '1 StreetAddress',
			APT_Applicant_1_City__c = 'Melbourne',
			APT_Applicant_1_Postcode__c = '3000',
			APT_Applicant_1_State__c = 'VIC',
			Contact_First_Name__c = 'FirstName',
			Contact_Last_Name__c = 'LastName',
			APT_Telephone__c = '0400000000',
			APT_Email_Address__c = 'email@auspost.com.au',
			L2C_Referral_Rejection_Reason__c = BCAFormConstants.FAIL_REASON_CREDIT_SUSPECT
		);
		// =====================================
        // Stubbing
        // =====================================
		BCAFormHelper.bcaSettings = new Map<String,SObject>{
			BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD => new BCA_Settings__c(
				Name = BCAFormConstants.BCASETTING_CREDIT_SUSPECT_MATCH_THRESHOLD,
				Number_Value__c = 60
			)
		};
        
		UserRecordAccessSelector uraSelector = (UserRecordAccessSelector)MockUtility.mockSelector(UserRecordAccessSelector.class);
		CreditsAssessmentSelector caSelector = (CreditsAssessmentSelector)MockUtility.mockSelector(CreditsAssessmentSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        // set up our responses
        MockUtility.Mocks.startStubbing();

        // Database
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject()))
            .thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.when(
			mockDatabase.findDuplicates((List<SObject>)fflib_Match.anyObject())
		).thenReturn(
			new List<DatacloudProxy.FindDuplicatesResult>{
				DatacloudProxy_Test.mockFindDuplicatesResult(
					new CreditSuspect__c(
						Id = fflib_IDGenerator.generate(CreditSuspect__c.SObjectType),
						FirstName__c = 'first',
						LastName__c = 'last'
					), 80
				)
			}
		);

        MockUtility.Mocks.when(
			uraSelector.selectById((Id)fflib_Match.eq(caRecord.Id))
		).thenReturn(
			(UserRecordAccess)UserRecordAccessSelector_Test.mockUserRecordAccess(
				caRecord.Id,
				UserRecordAccessSelector_Test.ACCESS_FULL
			)
		);

        MockUtility.Mocks.when(caSelector.selectById((Set<Id>)fflib_Match.anyObject()))
            .thenReturn(new Map<Id,APT_Credit_Assessment__c>{ caRecord.Id => caRecord });

        MockUtility.Mocks.stopStubbing();

		Test.startTest();

		System.assertEquals(
			true,
			BCAFormController.performSuspectRegisterCheck(caRecord.Id),
			'Should have been referred as a suspect'
		);

		Test.stopTest();
	}
}