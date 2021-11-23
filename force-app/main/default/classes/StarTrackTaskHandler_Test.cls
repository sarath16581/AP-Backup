/**
 ** Description: Test Class for StarTrackTaskHandler class
 ** Author: Jen Karen Tan
 ** Date Created: SEP.13.2016
 ** History:--------------------------------------------
 **         SEP.13.2016 Jen Karen Tan - Created
 **         OCT.04.2017 Angelo Rivera - Additional Test Method for Minor Work MWT0004521
 **	    NOV.20.2018 Ramtej Juloori - Additional Test Method coverages
 **/
@isTest
private without sharing class StarTrackTaskHandler_Test {
	
	@testSetup static void testSetup() {
		//create Support User
		User supportUser = new User(
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
     	insert supportUser;
     	
		 //insert Account for Billing Account
		Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
		Database.insert(testAccount);
		
		testAccount.Legacy_Id__c = '60000000';
		Database.update(testAccount);

		list<Billing_Account__c> billingAccountList = TestDataProvider.createBillingAccount('Test Subject', 1, new List<Account>{testAccount});
		billingAccountList[0].Override_BSC__c = false;
		billingAccountList[0].BSC_Transfer_Queue__c = 'Account Manager';
		insert billingAccountList;

     	//create test data as Support User
     	System.runAs(supportUser) {
	     	Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
	        testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
	        insert testNetwork;
	     	
	     	Article__c testArticle = TestDataProvider.createTestArticle();
	        testArticle.Service_Type__c = 'Express';
	        testArticle.ReceiverPostcode__c = '1234';
	        testArticle.Receiver_Suburb__c = 'TestSuburb';
	        testArticle.STServiceType__c = 'Airlock';
	        testArticle.Network__c = testNetwork.Id;
            testArticle.Product_Group__c = 'Next Flight';
	        insert testArticle;
	        
			List<Case> testCaseList = new List<Case>();

	     	Case testCase = new Case();
	        testCase.Origin = 'Email';
	        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
	        testCase.ArticleTest__c = testArticle.Id;
	        testCase.Network__c = testNetwork.Id;
            testCase.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED;
            testCase.Enquiry_Type__c = StarTrack_Constants.CASE_TYPE_DAMAGED;
            testCase.Initial_Caller_Type__c = 'test';
            testCase.Business_Solutions_Customer__c = true;
			//added billing Account to the Case
			//testCase.Related_Billing_Account__c = billingAccountList[0].Id;
	        testCaseList.add(testCase);

	        insert testCaseList;
        
			List<Task> testTaskList = new List<Task>();
        	Task testTask = TestDataProvider.createTask(testCase.Id, null, 'StarTrack Task');
	        testTask.Subject = 'Test';
	        testTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
	        testTask.CaseObject__c = testCase.Id;
	        testTask.Network__r = testNetwork;
	        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
	        testTaskList.add(testTask);	

			insert testTaskList;
        }        
	}

    //October 4, 2017 - APRivera - Additional Test Method for Minor Work MWT0004521
    static testMethod void updateTasksRelatedCaseRecord_CloseTaskTest(){
        //retrieve Task
        Task retTask = new List<Task>([SELECT Id, Status FROM Task LIMIT 1])[0];
        Id queueId = [select Id from Group where Type = 'Queue' AND NAME = 'Sorry We Missed You' limit 1].Id;

        StarTrack_Settings__c cs = new StarTrack_Settings__c();
        cs.SWMYTempQueue__c=queueId;
        insert cs;
        
        Test.startTest();
            retTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
            update retTask;
        Test.stopTest();

        List<Task> taskList = new List<Task>([SELECT Id, Status FROM Task WHERE Id =: retTask.Id]);
        //check if the Task Update field is set to Investigator Responded
        System.assertEquals(taskList[0].Status, StarTrack_Constants.TASK_STATUS_FINISHED);  
    }

//October 4, 2017 - APRivera - Additional Test Method for Minor Work MWT0004521
    static testMethod void updateTasksRelatedCaseRecord_TransferOwnerTest(){
        //retrieve tasks
        List<Task> retTask = new List<Task>([SELECT Id, TaskUpdate__c FROM Task LIMIT 1]);
        Id queueId = [select Id from Group where Type = 'Queue' AND NAME = 'Sorry We Missed You' limit 1].Id;
        String stStream = [Select Id, Account.StarTrack_Customer_Stream__c from Case limit 1].Account.StarTrack_Customer_Stream__c;
        System.debug('***DEBUG - stStream : ' + stStream);
        StarTrack_Settings__c cs = new StarTrack_Settings__c();
        cs.SWMYTempQueue__c=queueId;
        insert cs;

		//inserting multiple transfer case rules to cover scenarios with different queues
		List<StarTrack_Transfer_Case_Rule__c> tcRules = new List<StarTrack_Transfer_Case_Rule__c>();
        StarTrack_Transfer_Case_Rule__c tcRule = new StarTrack_Transfer_Case_Rule__c(
                Business_Solutions_Customer__c = true,
                Case_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED, 
                Case_RecordType__c = 'Delivery Enquiry', 
                Case_Type__c = StarTrack_Constants.CASE_TYPE_DAMAGED, 
                Customer_Stream__c = stStream, 
                Initial_Caller_Type__c = 'test', 
                Order__c = 10, 
                Product_Group__c = 'Next Flight',
                Queue_Name__c =  'Sorry We Missed You',
				Service_Cloud_Rule__c = true
        );
		tcRules.add(tcRule);
		insert tcRules;

        Test.startTest();
            retTask[0].TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
            update retTask;
        Test.stopTest();

        List<Task> taskList = new List<Task>([SELECT Id, TaskUpdate__c FROM Task WHERE Id =: retTask[0].Id]);
        //check if the Task Update field is set to Investigator Responded
        System.assertEquals(taskList[0].TaskUpdate__c, StarTrack_Constants.WAITING_ON_INVESTIGATOR);   
    }

	//Nov 21 2018, Transfer own test with transfer queue rule  satisfied
	static testMethod void updateTasksRelatedCaseRecord_TransferOwnerTestWithTransferQueueRuleSatisfied(){
        //retrieve tasks
        List<Task> retTask = new List<Task>([SELECT Id, TaskUpdate__c FROM Task LIMIT 1]);
		//update case with related billing account
		Billing_Account__c billingAccount = [SELECT Id FROM Billing_Account__c LIMIT 1];
		billingAccount.Override_BSC__c = true;
		update billingAccount;
		Case testCase = [SELECT Id, Related_Billing_Account__c FROM Case LIMIT 1];
		testCase.Related_Billing_Account__c = billingAccount.Id;
		testCase.Business_Solutions_Customer__c = true;
		update testCase;
        Id queueId = [select Id from Group where Type = 'Queue' AND NAME = 'Sorry We Missed You' limit 1].Id;
        String stStream = [Select Id, Account.StarTrack_Customer_Stream__c from Case limit 1].Account.StarTrack_Customer_Stream__c;
        System.debug('***DEBUG - stStream : ' + stStream);
        StarTrack_Settings__c cs = new StarTrack_Settings__c();
        cs.SWMYTempQueue__c=queueId;
        insert cs;
        
		//inserting multiple transfer case rules to cover scenarios with different queues
		List<StarTrack_Transfer_Case_Rule__c> tcRules = new List<StarTrack_Transfer_Case_Rule__c>();
		StarTrack_Transfer_Case_Rule__c tcRuleswithTransferQueueName = new StarTrack_Transfer_Case_Rule__c(
                Business_Solutions_Customer__c = false,
                Case_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED, 
                Case_RecordType__c = 'Delivery Enquiry', 
                Case_Type__c = StarTrack_Constants.CASE_TYPE_DAMAGED, 
                Customer_Stream__c = stStream, 
                Initial_Caller_Type__c = 'test', 
                Order__c = 10, 
                Product_Group__c = 'Next Flight',
                Queue_Name__c =  'Transfer Queue',
				Service_Cloud_Rule__c = true
        );
		tcRules.add(tcRuleswithTransferQueueName);
		insert tcRules;

        Test.startTest();
            retTask[0].TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
            update retTask;
        Test.stopTest();

        List<Task> taskList = new List<Task>([SELECT Id, TaskUpdate__c FROM Task WHERE Id =: retTask[0].Id]);
        //check if the Task Update field is set to Investigator Responded
        System.assertEquals(taskList[0].TaskUpdate__c, StarTrack_Constants.WAITING_ON_INVESTIGATOR);   
    }

    static testMethod void investigatorRespondedTest() {
    	
    	//retrieve User and Task
    	User investigator = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@supportuser123.com'])[0];
    	Task retTask = new List<Task>([SELECT Id FROM Task LIMIT 1])[0];
    	
    	FeedItem fi = new FeedItem(ParentId = retTask.Id, Body = 'Test');
    	//Post comment in the Task as an Investigator
    	System.runAs(investigator) {
    		Test.startTest();
        	insert fi;
        	Test.stopTest();
    	}
    	
    	List<FeedItem> fiList = new List<FeedItem>([SELECT Id FROM FeedItem WHERE Id =: fi.Id]);
    	//check if a comment(FeedItem) was created
    	System.assert(!fiList.isEmpty());
    	List<Task> taskList = new List<Task>([SELECT TaskUpdate__c FROM Task WHERE Id =: retTask.Id]);
    	//check if the Task Update field is set to Investigator Responded
    	System.assertEquals(taskList[0].TaskUpdate__c, StarTrack_Constants.INVESTIGATOR_RESPONDED);    		
    }
    
    static testMethod void investigatorRepliedTest() {
    	
    	//retrieve User and Task
    	User investigator = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@supportuser123.com'])[0];
    	Task retTask = new List<Task>([SELECT Id FROM Task LIMIT 1])[0];
    	
    	FeedItem fi = new FeedItem(ParentId = retTask.Id, Body = 'Test');
    	insert fi;
    	FeedComment fc = new FeedComment(FeedItemId = fi.Id, CommentBody = 'TestComment', CommentType = 'TextComment');
    	//Post comment in the Task as an Investigator
    	System.runAs(investigator) {
    		Test.startTest();
    		insert fc;
        	Test.stopTest();
    	}
    	
    	List<FeedComment> fcList = new List<FeedComment>([SELECT Id FROM FeedComment WHERE Id =: fc.Id]);
    	//check if a comment(FeedComment) was created
    	System.assert(!fcList.isEmpty());
    	List<Task> taskList = new List<Task>([SELECT TaskUpdate__c FROM Task WHERE Id =: retTask.Id]);
    	//check if the Task Update field is set to Investigator Responded
    	System.assertEquals(taskList[0].TaskUpdate__c, StarTrack_Constants.INVESTIGATOR_RESPONDED);    		
    }

	//Nov 21 2018, test queryQueue for exception scenario
	static testMethod void testqueryQueueForException(){
		Id queueId = StarTrackTaskHandler.queryQueue(null);
		system.assertEquals(null,queueId);
	}

	//Sept 22, 2021 - Steve Judd - Additional Test Method for Minor Work MWT0004540
	static testMethod void updateTasksRelatedCaseRecord_CloseCasePendingTest(){

		//retrieve Task
		Task retTask = new List<Task>([SELECT Id, Status FROM Task LIMIT 1])[0];
		Id queueId = [select Id from Group where Type = 'Queue' AND NAME = 'StarTrack Network Customer Notification' limit 1].Id;

		StarTrack_Settings__c cs = new StarTrack_Settings__c();
		cs.StarTrack_Autoclose_Case_from_Task__c = true;
		cs.StarTrack_Network_Notification_Queue__c=queueId;
		insert cs;

		Case testCase = [SELECT Id,  Call_Purpose__c, Enquiry_Type__c FROM Case limit 1];
		testCase.Call_Purpose__c = 'Card Left';
		testCase.Enquiry_Type__c = 'Depot Collection';
		update testCase;

		Test.startTest();
		retTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED;
		update retTask;
		Test.stopTest();

		List<Case> CaseList = new List<Case>([SELECT Id, Status FROM Case WHERE Id =: testCase.Id]);
		//check if the Status changes to Pending as there are no related contacts with emails
		System.assertEquals(caseList[0].Status, StarTrack_Constants.CASE_STAT_PENCUSNOTIF);
	}
}