/***
 * @author yuanyuan.zhang@bluewolf.com
 * @date Jul-2014
 * @group Tests
 * @domain Core
 * @description Test Class covering ArticleUtil
 * @changelog
 * Sep-2016:  david.e.catindoy@accenture.com Added an additional method to cover updateRelatedCases and subscriptionModel method in ArticleUtil class
 * Jun-2016:  david.e.catindoy@accenture.com  Split positive and negative test method into two
 * Jun-2018:  TDO-190 : hector.huang@coroma.com.au Unit tests re-written with scenario based tests.
 * 2020-04-15 - Nathan Franklin - added new test for Article Type mappings
 * 2020-05-13 - Nathan Franklin - Updated test due to 101 errors
 * 2020-07-12 - Nathan Franklin - Updated test due to 101 errors
 * 2024-10-01 - Nathan Franklin - Quick fix - failing tests
 */

 @isTest
 private class ArticleUtil_Test {
 
	 @testSetup
	 static void testSetup() { // Added by David Catindoy -
		 // Sept 20, 2016
		 // Insert custom setting
		 StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
		 customSetting.Subscription_Automation_Enabled__c = true;
		 customSetting.Subscription_Include_Lock_Records__c = false;
		 customSetting.StarTrack_Subscription_Profiles__c = 'AusPost Integration';
		 customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
		 insert(customSetting);
 
		 // Create consignment
		 Article__c consignment = new Article__c(Last_Update_Type__c = StarTrack_Constants.CON_LASTUP_TYPE, Source_System__c = 'TEAM', CID__c = '20160405', RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId());
		 insert(consignment);
 
		 // Create different user-configured automation rules for testing subscriptionModel method
		 List<StarTrack_Automation_Rule__c> automationRules = new List<StarTrack_Automation_Rule__c>();
 
		 // Create a StarTrack automation rule with Notified consignment summary status and Delivery Update case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 1, Consignment_Summary_Status__c = 'Notified', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Delivery Update', Case_Purpose__c = 'Late Delivery', Case_Status__c = 'Waiting on operations',
				 Case_Action__c = StarTrack_Constants.CASE_ACTSENDEMAIL, Case_Action_Value__c = 'Notify Receiver Case Closed', Task_RecordType__c = StarTrack_Constants.TASK_RECTYPE_OPERATION, Task_Status__c = StarTrack_Constants.TASK_STATUS_WAITING,
				 Task_Action__c = StarTrack_Constants.TASK_ACTFINISHED, WE_Status__c = StarTrack_Constants.WFE_STATUS_OPEN, WE_Action__c = StarTrack_Constants.WF_ACTCLOSED));
 
		 // Create a StarTrack automation rule with Patially Delivered consignment summary status and Incorrect Delivery case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 2, Consignment_Summary_Status__c = 'Partially Delivered', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Incorrect Delivery', Case_Action__c = StarTrack_Constants.CASE_ACTCOMMENT,
				 Case_Action_Value__c = 'Please update case record.', Task_RecordType__c = StarTrack_Constants.TASK_RECTYPE_OPERATION, Task_Status__c = StarTrack_Constants.TASK_STATUS_WAITING,
				 Task_Action__c = StarTrack_Constants.TASK_ACTFINISHED, WE_Status__c = StarTrack_Constants.WFE_STATUS_OPEN, WE_Action__c = StarTrack_Constants.WF_ACTCLOSED));
 
		 // Create a StarTrack automation rule with Delivered consignment summary status and Redlivery case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 3, Consignment_Summary_Status__c = 'Delivered', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Redelivery', Case_Action__c = StarTrack_Constants.CASE_ACTCLOSED,
				 Case_Status__c = 'Waiting on operations'));
 
		 // Create a StarTrack automation rule with Delivered consignment summary status and Stop Delivery case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 4, Consignment_Summary_Status__c = 'Delivered', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Stop Delivery', Case_Action__c = StarTrack_Constants.CASE_ACT_UPDATESTAT,
				 Case_Action_Value__c = StarTrack_Constants.CASE_STATUS_INVESTIGATION, Task_RecordType__c = StarTrack_Constants.TASK_RECTYPE_OPERATION, Task_Action__c = StarTrack_Constants.TASK_ACTFINISHED));
 
		 // Create a StarTrack automation rule with Delivered consignment summary status and short - no scan case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 5, Consignment_Summary_Status__c = 'Delivered', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Short - No Scan', Case_Status__c = 'Awaiting Approval',
				 Case_Action__c = StarTrack_Constants.CASE_ACT_REJECTAPPROVAL));
 
		 // Create a StarTrack automation rule with Forwarded consignment summary status and short - scanned case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 6, Consignment_Summary_Status__c = 'On Forwarded', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Short - Scanned', Case_Status__c = 'Awaiting Approval',
				 Case_Action__c = StarTrack_Constants.CASE_ACT_REJECTAPPROVAL));
 
		 // Create a StarTrack automation rule with Notified consignment summary status and short - no scan case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 7, Consignment_Summary_Status__c = 'Notified', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Short - No Scan', Case_Status__c = 'Awaiting Approval',
				 Case_Action__c = StarTrack_Constants.CASE_ACTSENDEMAIL));
 
		 // Create a StarTrack automation rule with Partially Delivered consignment summary status and short - no scan case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 8, Consignment_Summary_Status__c = 'Partially Delivered', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Short - No Scan', Case_Status__c = 'Awaiting Approval',
				 Case_Action__c = StarTrack_Constants.CASE_ACT_UPDATESTAT, Case_Action_Value__c = StarTrack_Constants.CASE_STATUS_INVESTIGATION));
 
		 // Create a StarTrack automation rule with In Transit consignment summary status and short - no scan case type
		 automationRules.add(new StarTrack_Automation_Rule__c(Order__c = 9, Consignment_Summary_Status__c = 'In Transit', Case_RecordType__c = 'Delivery Enquiry', Case_Type__c = 'Short - No Scan', Case_Status__c = 'Awaiting Approval',
				 Case_Action__c = StarTrack_Constants.CASE_ACTCLOSED));
		 insert(automationRules);
 
		 // Create cases and assign all cases as a child of the consignment.
		 Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
		 List<Case> childCases = new List<Case>();
 
		 // Create a case with Delivery Update enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Delivery Update', Call_Purpose__c = 'Late Delivery', Status = 'Waiting on operations', ArticleTest__c = consignment.Id, SuppliedEmail = 'davidcatindoy@gmail.com'));
 
		 // Create a case with Incorrect Delivery enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Incorrect Delivery', ArticleTest__c = consignment.Id));
 
		 // Create a case with Redelivery enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Redelivery', Status = 'Waiting on operations', ArticleTest__c = consignment.Id));
 
		 // Create a case with Stop Delivery enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Stop Delivery', ArticleTest__c = consignment.Id));
 
		 // Create a case with Short - No Scan enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Short - No Scan', Status = 'Awaiting Approval', ArticleTest__c = consignment.Id));
 
		 // Create a case with Short - Scanned enquiry type
		 childCases.add(new Case(RecordTypeId = deliveryRecType, Enquiry_Type__c = 'Short - Scanned', Status = 'Awaiting Approval', ArticleTest__c = consignment.Id));
		 insert(childCases);
 
		 // Create child task
		 Task newTask = new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(), Subject = 'MySubject', Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = childCases[0].Id);
		 insert(newTask);
 
		 // Create child workflow email
		 workflow_Email__c newWF = new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = childCases[0].Id);
		 insert(newWF);
 
		 // Create LDC case
		 Case testCase = TestDataProvider.createTestCase();
		 testCase.RecordTypeId = deliveryRecType;
		 testCase.Call_Purpose__c = 'Late Delivery';
		 testCase.Subject = 'For LDC';
		 testCase.Enquiry_Type__c = 'LDC';
		 testCase.Origin = 'Phone';
		 testCase.Recent_Caller_First_Name__c = 'David';
		 testCase.Recent_Caller_Last_Name__c = 'Catindoy';
		 testCase.Recent_Caller_Email__c = 'dcat@gmail.com';
		 testCase.Recent_Caller_Phone_Number__c = '+639126893944';
		 testCase.ArticleTest__c = consignment.Id;
		 testCase.Claim_Date__c = System.today() + 1;
		 testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
		 insert(testCase);
 
		 List<Article__c> articles = new List<Article__c>();
		 List<EventMessage__c> eventMessages = new List<EventMessage__c>();
 
		 // create an Article for testing setAdditionalServices
		 Article__c article = new Article__c();
		 article.Name = 'Test Product';
		 article.ArticleLodgementDate__c = date.today();
		 article.SenderPostcode__c = '123';
		 article.ReceiverPostcode__c = '3002';
		 article.ArticleType__c = 'Regular Parcel';
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>';
		 article.ContentsItemsPayload__c = '<?xml version="1.0" encoding="UTF-8"?>';
		 article.CustCommDecisionCode__c = 'Y';
		 article.CustDelPrefOptionCode__c = 'HEIGHTMORETHAN0.5M';
		 articles.add(article);
 
		 // create an Article for testing setAdditionalServices with xml setup
		 Article__c xmlArticle = new Article__c();
		 xmlArticle.Name = 'Test Product xml';
		 xmlArticle.ArticleLodgementDate__c = date.today();
		 xmlArticle.SenderPostcode__c = '456';
		 xmlArticle.ReceiverPostcode__c = '3002';
		 xmlArticle.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>102</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>NON_DL_DAY</ServiceAttributeName>'
				 + '<Weekday>1</Weekday>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
		 articles.add(xmlArticle);
		 insert articles;
 
		 // create an EventMessage linked to the Article above
		 EventMessage__c evtMsg = new EventMessage__c();
		 evtMsg.Article__c = articles[0].Id;
		 evtMsg.SenderID__c = 'bg';
		 evtMsg.ActualDateTime__c = date.today() + 1;
		 evtMsg.EventType__c = 'DD-ER13';
		 evtMsg.SignatureXString__c = '1';
		 eventMessages.add(evtMsg);
 
		 // create an EventMessage linked to the Article above
		 EventMessage__c xmlEvtMsg = new EventMessage__c();
		 xmlEvtMsg.Article__c = articles[1].Id;
		 xmlEvtMsg.SenderID__c = 'bg';
		 xmlEvtMsg.ActualDateTime__c = date.today() + 1;
		 xmlEvtMsg.EventType__c = 'DD-ER13';
		 xmlEvtMsg.SignatureXString__c = '1';
		 eventMessages.add(xmlEvtMsg);
 
		 insert eventMessages;
 
		 // create additional service code to support setAdditionalServices testing
		 List<AdditionalServicesCodes__c> services = new List<AdditionalServicesCodes__c>();
 
		 AdditionalServicesCodes__c addServiceCodes = new AdditionalServicesCodes__c();
		 addServiceCodes.Name = article.Name;
		 addServiceCodes.Description__c = 'This is a test description';
		 services.add(addServiceCodes);
 
		 // create additional service code to support setAdditionalServices with xml config testing
		 AdditionalServicesCodes__c addServiceCodesXml = new AdditionalServicesCodes__c();
		 addServiceCodesXml.Name = xmlArticle.Name;
		 addServiceCodesXml.Description__c = 'This is a test description';
		 services.add(addServiceCodesXml);
 
		 insert services;
 
		 // create CommunicationDecisionCodes to support setCommunicationDecisionDescription testing
		 List<CommunicationDecisionCodes__c> codes = new List<CommunicationDecisionCodes__c>();
		 CommunicationDecisionCodes__c comDecCodes1 = new CommunicationDecisionCodes__c();
		 comDecCodes1.Name = 'Y';
		 comDecCodes1.Description__c = 'This is the first test description';
		 codes.add(comDecCodes1);
 
		 CommunicationDecisionCodes__c comDecCodes2 = new CommunicationDecisionCodes__c();
		 comDecCodes2.Name = 'N';
		 comDecCodes2.Description__c = 'This is the second test description';
		 codes.add(comDecCodes2);
 
		 insert codes;
 
		 // create DeliveryPreferenceOptionCodes to support setCommunicationDecisionDescription testing
		 DeliveryPreferenceOptionCodes__c delPreOpCodes = new DeliveryPreferenceOptionCodes__c();
		 delPreOpCodes.Name = 'D';
		 delPreOpCodes.Description__c = 'Description for PreferenceOptionCodes';
		 insert delPreOpCodes;
 
	 }
 
	 //Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
	 //Added by David Catindoy - Sept 20, 2016
	 @testSetup
	 static void createUser() {
		 List<Profile> p = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support' OR Name = 'AusPost Integration' ORDER BY Name ASC];
		 UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
		 List<User> users = new List<User>();
		 users.add(new User(Alias = 'AAA', Email = 'user@testorg.a', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p[1].Id, UserRoleId = r.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'AAA@testorg.a'));
		 users.add(new User(Alias = 'BBB', Email = 'integration@testorg.a', EmailEncodingKey = 'UTF-8', LastName = 'Integration', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p[0].Id, UserRoleId = r.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'BBB@testorg.a'));
		 Database.insert(users);
	 }
 
	 @isTest
	 /**
	  * SCENARIO: additional services of an article is set successfully
	  **/
	 static void ArticleUtil_Test_setAdditionalServices_set() {
		 test.startTest();
		 // get the article inserted during test setup
		 Article__c article = [
				 SELECT Id,Name,Notification__c,AdditionalServices__c
				 FROM Article__c
				 WHERE Name = 'Test Product'
				 LIMIT 1
		 ];
		 // get the event message inserted during test setup
		 EventMessage__c evtMessage = [SELECT Id FROM EventMessage__c WHERE Article__c = :article.id LIMIT 1];
		 // get the service additional code inserted during test setup
		 AdditionalServicesCodes__c aServCodes = [
				 SELECT Id, Name
				 FROM AdditionalServicesCodes__c
				 WHERE Name = :article.Name
				 LIMIT 1
		 ];
 
		 // create a Service and related elements
		 AuspostProductSchema.Services aps = new AuspostProductSchema.Services();
		 AuspostProductSchema.ServiceCodeGroup_element scge = new AuspostProductSchema.ServiceCodeGroup_element();
		 AuspostProductSchema.ServiceCodes_element sce = new AuspostProductSchema.ServiceCodes_element();
		 AuspostProductSchema.ServiceQualifier_element sqe = new AuspostProductSchema.ServiceQualifier_element();
		 AuspostCommonSchema.TimePeriod tp = new AuspostCommonSchema.TimePeriod();
 
		 tp.Duration = '1';
		 tp.StartTime = datetime.now().format();
		 tp.EndTime = datetime.now().addDays(1).format();
 
		 sqe.Date_x = new List<Date>{
				 date.today()
		 };
		 sqe.TimePeriod = new List<AuspostCommonSchema.TimePeriod>{
				 tp
		 };
		 sqe.Weekday = new List<String>{
				 'Monday'
		 };
		 sqe.ServiceAttributeQualifier = new List<String>{
				 'test'
		 };
 
		 sce.ServiceCode = aServCodes.Name;
 
		 sce.ServiceQualifier = new List<AuspostProductSchema.ServiceQualifier_element>{
				 sqe
		 };
 
		 scge.ServiceCodes = new List<AuspostProductSchema.ServiceCodes_element>{
				 sce
		 };
 
		 aps.ServiceCodeGroup = new List<AuspostProductSchema.ServiceCodeGroup_element>{
				 scge
		 };
 
		 TIBCOEventMessageWrapper tw = new TIBCOEventMessageWrapper(evtMessage);
 
		 // create a list of all possible attributes and loop through
		 List<String> attributes = new List<String>{
				 'NON_DL_DAY', 'EXP_DL_DAT', 'EMBARGO', 'DEL_DAY', 'DEL_DATE', 'DEL_TIME',
				 'REDIRECT', 'UPL_DEL', 'UPL_SIZE', 'UPL_EXP', 'CSP_DEL', 'CDP_DEL', 'SURVEY_REQ'
		 };
 
		 for (String attribute : attributes) {
			 // set the service attribute of of the article
			 sqe.ServiceAttributeName = attribute;
			 ArticleUtil.setAdditionalServices(aps, article, new List<TIBCOEventMessageWrapper>{
					 tw
			 });
 
			 String addService = article.AdditionalServices__c;
 
			 // verify the updated article with different service attribute
			 if (attribute == 'NON_DL_DAY') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : null');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with NON_DL_DAY service fails to be updated');
 
			 } else if (attribute == 'EXP_DL_DAT') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : ' + date.today().format());
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with EXP_DL_DAT service fails to be updated');
 
			 } else if (attribute == 'EMBARGO') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : ' + date.today().format());
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with EMBARGO service fails to be updated');
 
			 } else if (attribute == 'DEL_DAY') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : null');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_DAY service fails to be updated');
 
			 } else if (attribute == 'DEL_DATE') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : ' + date.today().format());
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_DAY service fails to be updated');
 
			 } else if (attribute == 'DEL_TIME') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('Duration = ' + tp.Duration);
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_TIME service fails to be updated');
 
			 } else if (attribute == 'REDIRECT') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : Yes');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with REDIRECT service fails to be updated');
 
			 } else if (attribute == 'UPL_SIZE') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : test');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with UPL_SIZE service fails to be updated');
 
			 } else if (attribute == 'UPL_EXP') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : test') &&
						 addService.contains(sqe.ServiceAttributeQualifier[0]);
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with UPL_EXP service fails to be updated');
 
			 } else if (attribute == 'CSP_DEL') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : Yes');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with CSP_DEL service fails to be updated');
 
			 } else if (attribute == 'CDP_DEL') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : Yes');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with CDP_DEL service fails to be updated');
 
			 } else if (attribute == 'SURVEY_REQ') {
 
				 Boolean isAddService = addService.contains('Service code Group 1') &&
						 addService.contains('This is a test description : test');
				 System.assertEquals(true, isAddService,
						 'ArticleUtil_Test_setAdditionalServices_set : Article with SURVEY_REQ service fails to be updated');
 
			 }
		 }
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: additional services of an article is reset successfully with xml parameter
	  **/
	 static void ArticleUtil_Test_setAdditionalServices_xmlSet() {
		 test.startTest();
		 // get the article with xml config inserted during test setup
		 Article__c article = [
				 SELECT Id,Name,Notification__c,AdditionalServices__c,AdditionalServicesPayload__c
				 FROM Article__c
				 WHERE Name = 'Test Product xml'
				 LIMIT 1
		 ];
 
		 // get the event message inserted during test setup
		 EventMessage__c evtMessage = [SELECT Id FROM EventMessage__c WHERE Article__c = :article.id LIMIT 1];
		 // get the service additional code inserted during test setup
		 AdditionalServicesCodes__c aServCodes = [
				 SELECT Id, Name
				 FROM AdditionalServicesCodes__c
				 WHERE Name = :article.Name
				 LIMIT 1
		 ];
 
		 // create a Service and related elements
		 AuspostProductSchema.Services aps = new AuspostProductSchema.Services();
		 AuspostProductSchema.ServiceCodeGroup_element scge = new AuspostProductSchema.ServiceCodeGroup_element();
		 AuspostProductSchema.ServiceCodes_element sce = new AuspostProductSchema.ServiceCodes_element();
		 AuspostProductSchema.ServiceQualifier_element sqe = new AuspostProductSchema.ServiceQualifier_element();
		 AuspostCommonSchema.TimePeriod tp = new AuspostCommonSchema.TimePeriod();
 
		 tp.Duration = '1';
		 tp.StartTime = datetime.now().format();
		 tp.EndTime = datetime.now().addDays(1).format();
 
		 sqe.Date_x = new List<Date>{
				 date.today()
		 };
		 sqe.TimePeriod = new List<AuspostCommonSchema.TimePeriod>{
				 tp
		 };
		 sqe.Weekday = new List<String>{
				 'Monday'
		 };
		 sqe.ServiceAttributeQualifier = new List<String>{
				 'test'
		 };
 
		 sce.ServiceCode = aServCodes.Name;
 
		 sce.ServiceQualifier = new List<AuspostProductSchema.ServiceQualifier_element>{
				 sqe
		 };
 
		 scge.ServiceCodes = new List<AuspostProductSchema.ServiceCodes_element>{
				 sce
		 };
 
		 aps.ServiceCodeGroup = new List<AuspostProductSchema.ServiceCodeGroup_element>{
				 scge
		 };
 
		 TIBCOEventMessageWrapper tw = new TIBCOEventMessageWrapper(evtMessage);
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
 
		 /**
		  * verify the updated article with different service attribute (NON_DL_DAY, EXP_DL_DAT, EMBARGO, etc.), each
		  * respective article should have specific strings in its Additional Service after the update, which will be verified
		  * in each assert statement below.
		  **/
		 Boolean isAddService = article.AdditionalServices__c.contains('Service code Group 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with NON_DL_DAY service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>EXP_DL_DAT</ServiceAttributeName>'
				 + '<Date>1</Date>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
 
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with EXP_DL_DAT service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>EMBARGO</ServiceAttributeName>'
				 + '<Date>1</Date>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with EMBARGO service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>DEL_DATE</ServiceAttributeName>'
				 + '<Date>1</Date>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_DATE service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>DEL_DAY</ServiceAttributeName>'
				 + '<Weekday>1</Weekday>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : Monday');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_DAY service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>DEL_TIME</ServiceAttributeName>'
				 + '<TimePeriod>'
				 + '<StartTime>1</StartTime>'
				 + '<EndTime>1</EndTime>'
				 + '<Duration>1</Duration>'
				 + '</TimePeriod>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : StartTime = 1 EndTime = 1 Duration = 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with DEL_TIME service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>REDIRECT</ServiceAttributeName>'
				 + '<TimePeriod>'
				 + '<StartTime>1</StartTime>'
				 + '<EndTime>1</EndTime>'
				 + '<Duration>1</Duration>'
				 + '</TimePeriod>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : Yes');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with REDIRECT service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>UPL_DEL</ServiceAttributeName>'
				 + '<TimePeriod>'
				 + '<StartTime>1</StartTime>'
				 + '<EndTime>1</EndTime>'
				 + '<Duration>1</Duration>'
				 + '</TimePeriod>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : Yes');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with UPL_DEL service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>UPL_SIZE</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with UPL_SIZE service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>UPL_EXP</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains(sqe.ServiceAttributeQualifier[0]) &&
				 article.AdditionalServices__c.contains('This is a test description : ');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with UPL_EXP service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>CSP_DEL</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : Yes');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with CSP_DEL service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>CDP_DEL</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : Yes');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with CDP_DEL service fails to be updated');
 
		 article.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>SURVEY_REQ</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setAdditionalServices(article, new List<TIBCOEventMessageWrapper>{
				 tw
		 });
		 isAddService = article.AdditionalServices__c.contains('Service code Group 1') &&
				 article.AdditionalServices__c.contains('This is a test description : 1');
		 System.assertEquals(true, isAddService,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with SURVEY_REQ service fails to be updated');
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: additionalServices of an article is updated successfully
	  **/
	 static void ArticleUtil_Test_processAdditionalServices_updated() {
		 // get the article inserted during test setup
		 Article__c oldArticle = [SELECT Id,AdditionalServices__c FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
		 oldArticle.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>SURVEY_REQ</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 // create a new article with different xml payload
		 Article__c newArticle = oldArticle.clone(true, true, false, false);
		 newArticle.AdditionalServicesPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '<ServiceCode>Test Product xml</ServiceCode>'
				 + '<ServiceQualifier>'
				 + '<ServiceAttributeName>CDP_DEL</ServiceAttributeName>'
				 + '<ServiceAttributeQualifier>1'
 
				 + '</ServiceAttributeQualifier>'
				 + '</ServiceQualifier>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 Map<Id, Article__c> newMap = new Map<Id, Article__c>();
		 newMap.put(newArticle.Id, newArticle);
		 Map<Id, Article__c> oldMap = new Map<Id, Article__c>();
		 oldMap.put(oldArticle.Id, oldArticle);
 
		 // update the articles
		 ArticleUtil.processAdditionalServices(newMap, oldMap);
 
		 // verify the updated article
		 Boolean isContentsItems = newArticle.AdditionalServices__c.contains('This is a test description : Yes');
		 System.assertEquals(true, isContentsItems,
				 'ArticleUtil_Test_processAdditionalServices_updated : Article fails to be updated by updating AdditionalServices');
	 }
 
	 @isTest
	 /**
	  * SCENARIO: contentsItems of an article is set successfully
	  **/
	 static void ArticleUtil_Test_setContentsItems_Set() {
		 test.startTest();
 
		 // get the article inserted during test setup
		 Article__c article = [SELECT Id,Name,ContentsItems__c FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
 
		 // set up relevant values of ProductSchema
		 AuspostMailProductSchema.ArticleContentsItemType acit = new AuspostMailProductSchema.ArticleContentsItemType();
		 AuspostMailProductSchema.InternationalContentsItemType icit = new AuspostMailProductSchema.InternationalContentsItemType();
		 icit.CountryOriginCode = 'test';
		 icit.HSTariff = 'test';
		 icit.ProductClassification = 'test';
		 icit.ProductType = 'test';
 
		 acit.Description = 'test';
		 acit.Quantity = 1;
		 acit.UnitValue = 'test';
		 acit.Value = '1';
		 acit.Weight = '1';
		 acit.InternationalContentsItemDetails = icit;
 
		 // set the ContentsItems of the article
		 ArticleUtil.setContentsItems(new List<AuspostMailProductSchema.ArticleContentsItemType>{
				 acit
		 }, article);
 
		 // verify the updated article with specific Contents Items
		 Boolean isContentsItems = article.ContentsItems__c.contains('Contents Item 1') &&
				 article.ContentsItems__c.contains('Description: test') &&
				 article.ContentsItems__c.contains('Weight: 1') &&
				 article.ContentsItems__c.contains('Quantity: 1') &&
				 article.ContentsItems__c.contains('UnitValue: test') &&
				 article.ContentsItems__c.contains('Value: 1') &&
				 article.ContentsItems__c.contains('ProductType: test') &&
				 article.ContentsItems__c.contains('CountryOriginCode: test') &&
				 article.ContentsItems__c.contains('HSTariff: test') &&
				 article.ContentsItems__c.contains('ProductClassification: test');
		 System.assertEquals(true, isContentsItems,
				 'ArticleUtil_Test_setContentsItems_Set : Article with ContentsItems set by ProductSchema fails to be updated');
 
		 // set the ContentsItems of the article without ProductSchema parameter
		 article.ContentsItemsPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<InternationalContentsItemDetails>'
				 + '<Child2>Some Details'
				 + '</Child2>'
				 + '</InternationalContentsItemDetails>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
		 ArticleUtil.setContentsItems(article);
 
		 // verify the updated article with specific ContentsItems set by xml
		 isContentsItems = article.ContentsItems__c.contains('Contents Item 1') &&
				 article.ContentsItems__c.contains('Child2: Some Details');
		 System.assertEquals(true, isContentsItems,
				 'ArticleUtil_Test_setAdditionalServices_set : Article with ContentsItems set by Payload fails to be updated');
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: contentsItems of an article is set unsuccessfully because of xml parsing exception
	  **/
	 static void ArticleUtil_Test_setContentsItems_Exception() {
		 test.startTest();
 
		 // get the article inserted during test setup
		 Article__c article = [SELECT Id,Name,ContentsItems__c FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
 
		 // set Payload with false xml format </InternationalContentsItemDetails>
		 article.ContentsItemsPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<Child2>'
				 + '</InternationalContentsItemDetails>'
				 + '</Child2>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 ArticleUtil.setContentsItems(article);
		 //Exception will then be handled by catch and print out System.XmlException: Failed to parse XML
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: contentsItems of an article is updated successfully
	  **/
	 static void ArticleUtil_Test_processContentsItems_updated() {
		 // get the article inserted during test setup
		 Article__c oldArticle = [SELECT Id,ContentsItems__c FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
		 oldArticle.ContentsItemsPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<InternationalContentsItemDetails>'
				 + '<Child2>Some Details'
				 + '</Child2>'
				 + '</InternationalContentsItemDetails>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 // create a new article with different xml payload
		 Article__c newArticle = oldArticle.clone(true, true, false, false);
		 newArticle.ContentsItemsPayload__c = '<?xml version="1.0" encoding="UTF-8"?>'
				 + '<ServicecodeGroup>'
				 + '<Child1>'
				 + '<InternationalContentsItemDetails>'
				 + '<Child2>Other Details'
				 + '</Child2>'
				 + '</InternationalContentsItemDetails>'
				 + '</Child1>'
				 + '</ServicecodeGroup>';
 
		 Map<Id, Article__c> newMap = new Map<Id, Article__c>();
		 newMap.put(newArticle.Id, newArticle);
		 Map<Id, Article__c> oldMap = new Map<Id, Article__c>();
		 oldMap.put(oldArticle.Id, oldArticle);
 
		 // update the articles
		 ArticleUtil.processContentsItems(newMap, oldMap);
 
		 // verify the updated article
		 Boolean isContentsItems = newArticle.ContentsItems__c.contains('Other Details');
		 System.assertEquals(true, isContentsItems,
				 'ArticleUtil_Test_processContentsItems_updated : Article fails to be updated by updating ContentsItems');
	 }
 
	 @isTest
	 /**
	  * SCENARIO: communicationDecisionDescription of an article is set successfully
	  **/
	 static void ArticleUtil_Test_setCommunicationDecisionDescription_Set() {
		 test.startTest();
 
		 // get the article inserted during test setup
		 Article__c article = [SELECT Id FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
 
		 article.CustCommDecisionCode__c = 'Y|N';
		 ArticleUtil.setCommunicationDecisionDescription(article);
 
		 // verify the updated article with specific CustCommDecisionDescription
		 Boolean isCustCommDecisionDescription = article.CustCommDecisionDescription__c.contains('This is the first test description')
				 && article.CustCommDecisionDescription__c.contains('This is the second test description');
		 System.assertEquals(true, isCustCommDecisionDescription,
				 'AArticleUtil_Test_setCommunicationDecisionDescription_Set : ' +
						 'Article fails to be updated by changing CustCommDecisionDescription__c');
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: communicationDecisions of an article is updated successfully
	  **/
	 static void ArticleUtil_Test_processCommunicationDecisions_updated() {
		 // get the article inserted during test setup
		 Article__c oldArticle = [SELECT Id FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
		 oldArticle.CustCommDecisionCode__c = 'Y';
 
		 // create a new article with different CustCommDecisionCode__c
		 Article__c newArticle = oldArticle.clone(true, true, false, false);
		 newArticle.CustCommDecisionCode__c = 'N';
 
		 Map<Id, Article__c> newMap = new Map<Id, Article__c>();
		 newMap.put(newArticle.Id, newArticle);
		 Map<Id, Article__c> oldMap = new Map<Id, Article__c>();
		 oldMap.put(oldArticle.Id, oldArticle);
 
		 // update the articles
		 ArticleUtil.processCommunicationDecisions(newMap, oldMap);
 
		 // verify the updated article
		 Boolean isCustCommDecisionDescriptionUpdated = newArticle.CustCommDecisionDescription__c.contains('This is the second test description');
		 System.assertEquals(true, isCustCommDecisionDescriptionUpdated,
				 'ArticleUtil_Test_processContentsItems_updated : Article fails to be updated by updating communicationDecisions');
	 }
 
	 @isTest
	 /**
	  * SCENARIO: deliveryPreferenceOptionDescription of an article is set successfully
	  **/
	 static void ArticleUtil_Test_setDeliveryPreferenceOptionDescription_Set() {
		 test.startTest();
 
		 // get the article inserted during test setup
		 Article__c article = [SELECT Id,Name FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
 
		 article.CustDelPrefOptionCode__c = 'D';
		 ArticleUtil.setDeliveryPreferenceOptionDescription(article);
 
		 // verify the updated article with specific CustDelPrefOptionCode
		 Boolean isDeliveryPreferenceOptionDescription = article.CustDelPrefDescription__c.contains('Description for PreferenceOptionCodes');
		 System.assertEquals(true, isDeliveryPreferenceOptionDescription,
				 'ArticleUtil_Test_setDeliveryPreferenceOptionDescription_Set : ' +
						 'Article fails to be updated by changing CustDelPrefOptionCode__c');
 
		 test.stopTest();
	 }
 
	 @isTest
	 /**
	  * SCENARIO: deliveryPreferenceOptionDescription of an article is updated successfully
	  **/
	 static void ArticleUtil_Test_processDeliveryPreferenceOptions_updated() {
		 // get the article inserted during test setup
		 Article__c oldArticle = [SELECT Id FROM Article__c WHERE Name = 'Test Product' LIMIT 1];
		 oldArticle.CustDelPrefOptionCode__c = 'A';
 
		 // create a new article with different CustDelPrefOptionCode__c
		 Article__c newArticle = oldArticle.clone(true, true, false, false);
		 newArticle.CustDelPrefOptionCode__c = 'D';
 
		 Map<Id, Article__c> newMap = new Map<Id, Article__c>();
		 newMap.put(newArticle.Id, newArticle);
		 Map<Id, Article__c> oldMap = new Map<Id, Article__c>();
		 oldMap.put(oldArticle.Id, oldArticle);
 
		 // update the articles
		 ArticleUtil.processDeliveryPreferenceOptions(newMap, oldMap);
 
		 // verify the updated article
		 Boolean isCustCommDecisionDescriptionUpdated = newArticle.CustDelPrefDescription__c.contains('Description for PreferenceOptionCodes');
		 System.assertEquals(true, isCustCommDecisionDescriptionUpdated,
				 'ArticleUtil_Test_processContentsItems_updated : Article fails to be updated by updating deliveryPreferenceOptionDescription');
	 }
 
	 @isTest
	 /**
	  * SCENARIO: related cases of an article is updated successfully
	  **/
	 static void ArticleUtil_Test_updateRelatedCases_updated() {
		 // get the case inserted during test setup
		 Case caseRec = [SELECT Id, Status, Subject FROM Case WHERE Subject = 'For LDC'];
		 if (StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)) {
			 caseRec.Status = 'Reopened';
			 update caseRec;
		 }
		 User intUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'BBB' LIMIT 1];
 
		 System.runAs(intUser) {
			 Test.startTest();
			 // create a new case linked to the article
			 Case newCase = new Case(Subject = 'Sample Case',
					 RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(),
					 Call_Purpose__c = 'Late Delivery', Enquiry_Type__c = 'LDC', Origin = 'Email', Claim_Date__c = System.today() + 1);
			 insert newCase;
			 // get the article related to StarTrack
			 Article__c consignment = [SELECT Id, Case__c, Freight_Amount__c FROM Article__c WHERE CID__c = '20160405'];
			 consignment.Case__c = newCase.Id;
			 consignment.Freight_Amount__c = 1500;
			 // only update the article and will check if its relevant cases are updated
			 update consignment;
 
			 // verify whether Total_Amount_of_Claim__c of the case has been updated
			 Case updatedCase = [SELECT Total_Amount_of_Claim__c FROM Case WHERE Subject = 'Sample Case' LIMIT 1];
			 System.assertEquals(1500, updatedCase.Total_Amount_of_Claim__c,
					 'ArticleUtil_Test_updateRelatedCases_updated : Relevant cases fail to be updated after updating the article');
			 Test.stopTest();
		 }
	 }
 
	 @isTest
	 /**
	  * SCENARIO: related caseComment and workflow Email of a consignment article is updated successfully
	  * automation case action is to 'Send email', case action is "Update Status"
	  **/
	 static void ArticleUtil_Test_subscriptionModel_updated1() {
		 User intUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'BBB' LIMIT 1];
 
		 System.runAs(intUser) {
			 Test.startTest();
 
			 // get the article inserted during test setup
			 Article__c consignment = [SELECT Id, Case__c, Consignment_Summary_Status__c FROM Article__c WHERE CID__c = '20160405'];
			 consignment.Consignment_Summary_Status__c = 'Notified';
			 update consignment;
 
			 // verify the updated workflow_Email__c
			 System.assertEquals(2, [SELECT Id FROM workflow_Email__c].size(),
					 'ArticleUtil_Test_subscriptionModel_updated1 : Workflow Email fails to be updated after updating the article');
 
			 consignment.Consignment_Summary_Status__c = 'Partially Delivered';
			 update consignment;
 
			 Test.stopTest();
			 // verify the updated CaseComment
			 System.assertEquals(false, [SELECT Id FROM CaseComment].isEmpty(),
					 'ArticleUtil_Test_subscriptionModel_updated1 : Case comment fails to be updated after updating the article');
		 }
	 }
 
	 @isTest
	 /**
	  * SCENARIO: related caseComment and workflow Email of a consignment article is updated successfully
	  * status is CASE_ACT_REJECTAPPROVAL, case action is "Update Status"
	  **/
	 static void ArticleUtil_Test_subscriptionModel_updated2() {
		 User intUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'BBB' LIMIT 1];
 
		 System.runAs(intUser) {
			 Test.startTest();
 
			 // get the article inserted during test setup
			 Article__c consignment = [SELECT Id, Case__c, Consignment_Summary_Status__c FROM Article__c WHERE CID__c = '20160405'];
			 consignment.Consignment_Summary_Status__c = 'Delivered';
			 Database.update(consignment);
			 consignment.Consignment_Summary_Status__c = 'On Forwarded';
			 Database.update(consignment);
 
			 Test.stopTest();
			 // verify the updated CaseComment
			 System.assertEquals(false, [SELECT Id FROM CaseComment].isEmpty(),
					 'ArticleUtil_Test_subscriptionModel_updated2 : Case comment fails to be updated after updating the article');
		 }
	 }
 
	 @isTest
	 /**
	  * SCENARIO: related case of a consignment article is updated successfully but no workflow Email is updated
	  * status is CASE_ACT_UPDATESTAT and CASE_ACTSENDEMAIL"
	  **/
	 static void ArticleUtil_Test_subscriptionModel_updated3() {
		 User intUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'BBB' LIMIT 1];
		 Database.delete([SELECT Id, Consignment_Shortage__c, Subscription_Consign_Summary_Status__c FROM Case WHERE Status != 'Awaiting Approval']);
 
		 System.runAs(intUser) {
 
			 Test.startTest();
 
			 // get the case with Awaiting Approval status inserted during test setup
			 Case approvalCase = [SELECT Id, Consignment_Shortage__c, Subscription_Consign_Summary_Status__c FROM Case WHERE Status = 'Awaiting Approval' AND Enquiry_Type__c = 'Short - No Scan'];
			 approvalCase.Consignment_Shortage__c = true;
			 update approvalCase;
 
			 Article__c consignment = [SELECT Id, Case__c, Freight_Amount__c FROM Article__c LIMIT 1];
			 consignment.Consignment_Summary_Status__c = 'Notified';
			 update consignment;
			 consignment.Consignment_Summary_Status__c = 'Partially Delivered';
			 update consignment;
 
			 Test.stopTest();
 
			 // get the updated case
			 approvalCase = [SELECT Id, Consignment_Shortage__c, Status, Subscription_Consign_Summary_Status__c FROM Case WHERE Id = :approvalCase.Id];
 
			 // verify the updated case
			 System.assertEquals('Partially Delivered', approvalCase.Subscription_Consign_Summary_Status__c,
					 'ArticleUtil_Test_subscriptionModel_updated3 : Subscription Consignment Summary Status of the case fails to be updated after updating the article');
			 System.assertEquals('Awaiting Approval', approvalCase.Status,
					 'ArticleUtil_Test_subscriptionModel_updated3 : Status of the case fails to be updated after updating the article');
		 }
	 }
 
	 @isTest
	 /**
	  * SCENARIO: related case of a consignment article is updated successfully but no workflow Email is updated
	  * status is CASE_ACTCLOSED and case action is "Reject Approval""
	  **/
	 static void ArticleUtil_Test_subscriptionModel_updated4() {
		 User intUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'BBB' LIMIT 1];
		 Database.delete([SELECT Id, Consignment_Shortage__c, Subscription_Consign_Summary_Status__c FROM Case WHERE Status != 'Awaiting Approval']);
 
		 System.runAs(intUser) {
			 Test.startTest();
 
			 // get the case with Awaiting Approval status inserted during test setup
			 Case approvalCase = [SELECT Id, Consignment_Shortage__c, Subscription_Consign_Summary_Status__c FROM Case WHERE Status = 'Awaiting Approval' AND Enquiry_Type__c = 'Short - No Scan'];
			 approvalCase.Consignment_Shortage__c = true;
			 update approvalCase;
			 Article__c consignment = [SELECT Id, Case__c, Freight_Amount__c FROM Article__c LIMIT 1];
			 consignment.Consignment_Summary_Status__c = 'In Transit';
			 update consignment;
			 consignment.Consignment_Summary_Status__c = 'Delivered';
			 update consignment;
 
			 Test.stopTest();
			 // get the updated case
			 approvalCase = [SELECT Id, Consignment_Shortage__c, Status, Subscription_Consign_Summary_Status__c FROM Case WHERE Id = :approvalCase.Id];
 
			 // verify the updated case
			 System.assertEquals('Delivered', approvalCase.Subscription_Consign_Summary_Status__c,
					 'ArticleUtil_Test_subscriptionModel_updated4 : Subscription Consignment Summary Status of the case fails to be updated after updating the article');
			 System.assertEquals('Approval Rejected', approvalCase.Status,
					 'ArticleUtil_Test_subscriptionModel_updated4 : Status of the case fails to be updated after updating the article');
		 }
	 }
 
	 /**
	  * Scenario: Simple test to grab all the event types using the new methods
	  */
	 @IsTest
	 private static void testGetArticleTypes() {
		 // a bit risky using hard-coded items here, but I suspect we won't have any problems
		 ArticleTypeMapping__mdt articleType = ArticleUtil.getArticleType('Parcel Post');
		 System.assertNotEquals(null, articleType, 'Expected ArticleTypeMappings');
	 }
 
 }