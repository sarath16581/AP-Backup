/*------------------------------------------------------------
Author:		Jen Karen Tan
Company:	   Accenture
Description:   Test class for StarTrack StarTrackTaskRListSidePanel controller
History
November 10, 2016 - Jen Karen Tan - Created
2024-09-20	Vasu Gorakati - Case Hand-off - Voice call records visibility to classic users
------------------------------------------------------------*/

@isTest
private class StarTrackTaskRListSidePanel_Cont_Test {
	@testSetup static void testSetup(){
		
		User support = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support'].Id,
			LastName = 'last',
			Email = 'test@user.com',
			Username = 'test@supportuser123.com',
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US');
		INSERT support;
		
		StarTrackDefaultValues__c sdv = new StarTrackDefaultValues__c();
		sdv.Name = 'Task Search';
		sdv.OFFSET__c = 0;
		sdv.LIMIT__c = 10;
		INSERT sdv;

		Task_Search_Settings__c tssA = new Task_Search_Settings__c();
		tssA.Name = 'My Area Tasks';
		tssA.Default__c = true;
		INSERT tssA;

		Task_Search_Settings__c tssB = new Task_Search_Settings__c();
		tssB.Name = 'Custom';
		INSERT tssB;

		Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
		testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
		INSERT testNetwork;

		Postcode__c testPostcode = new Postcode__c();
		testPostcode.Name = 'Test Postcode';
		INSERT testPostcode;

		PostcodeMapping__c testPostcodemap = new PostcodeMapping__c();
		testPostcodemap.Postcode__c = testPostcode.Id;
		testPostcodemap.Network__c = testNetwork.Id;
		testPostcodemap.Run_Dock__c = 'Test Post Code';
		INSERT testPostcodemap;

		Depot_Area__c testDepotArea = new Depot_Area__c();
		testDepotArea.Name = 'Test Depot Area';
		testDepotArea.Depot__c = testNetwork.Id;
		INSERT testDepotArea;

		Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
		testDepotAreaUser.Name = 'Test Depot Area User';
		testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
		testDepotAreaUser.User__c = UserInfo.getUserId();
		INSERT testDepotAreaUser;
		
		Article__c testArticle = TestDataProvider.createTestArticle();
		testArticle.Service_Type__c = 'Express';
		testArticle.ReceiverPostcode__c = '1234';
		testArticle.Receiver_Suburb__c = 'TestSuburb';
		testArticle.STServiceType__c = 'Airlock';
		testArticle.Network__c = testNetwork.Id;
		INSERT testArticle;

		Case testCase = new Case();
		testCase.Origin = 'Email';
		testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
		testCase.ArticleTest__c = testArticle.Id;
		testCase.Network__c = testNetwork.Id;
		INSERT testCase;
		
		CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = testCase.Id, UserOrGroupId = support.Id);
		INSERT cs;
		
		List<Task> taskList = new List<Task>();
		Integer taskSize = 10;
		Id starTrackTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId();
		for (Integer i = 0 ; i <= taskSize ; i++) {
			Task testTask = TestDataProvider.createTask(testCase.Id, null, 'StarTrack Task' + i);
			testTask.Depot_Role__c = testDepotArea.Id;
			testTask.Subject = 'Test' + i;
			testTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
			testTask.CaseObject__c = testCase.Id;
			testTask.Network__r = testNetwork;
			testTask.OwnerId = support.Id;
			testTask.RecordTypeId = starTrackTaskRecordTypeId;
			taskList.add(testTask);
		}
		
		INSERT taskList;
		
		List<VoiceCall> voiceCalls = ApplicationTestDataFactory.getVoiceCalls(1, false);
		voiceCalls.get(0).RelatedRecordId = testCase.Id;
		voiceCalls.get(0).CallType = 'Inbound';
		voiceCalls.get(0).VendorType = 'ContactCenter';
		voiceCalls.get(0).CallStartDateTime = System.now();
		voiceCalls.get(0).CallEndDateTime = System.now().addMinutes(5);
		voiceCalls.get(0).FromPhoneNumber = '+61 432 077 455';
		voiceCalls.get(0).ToPhoneNumber = 'CS_Test';
		insert voiceCalls;
	}
	
		@isTest static void testTaskRListSidePanel(){
			Integer tasksPerPage = 5;
			Case caseRec = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
			User supportUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@supportuser123.com'])[0];	 		 	

			ApexPages.StandardController sc = null;
			StarTrackTaskRListSidePanel_Controller ctrl = null;

			Test.startTest();
				System.runAs(supportUser) {
					sc = new ApexPages.StandardController(caseRec);
					ctrl = new StarTrackTaskRListSidePanel_Controller(sc);
					System.assert(ctrl.getDisablePreviousBtn());
					ctrl.next();
					ctrl.previous();
				}
			Test.stopTest();
			
			System.assert(ctrl.retrievedTasks != null);
			System.assert(ctrl.retrievedTasks.size() > 0);
			System.assertEquals(tasksPerPage, ctrl.taskList.size());
			System.assert(ctrl.voiceCalls.size() > 0);

		}

		
}