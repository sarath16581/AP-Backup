/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Test class for StarTrack Task Search page
History
September 17, 2015 - Patrick James Franco - Created
February 29, 2016 - David Catindoy - Modified
September 2, 2021 - Steve Judd - Modified test setup for MW0004540 and added testGetAutocloseEnabled
September 26,  2021 - Steve Judd Removed unneeded test - testGetAutocloseEnabled. Handled in StarTrackTaskHandler_Test
------------------------------------------------------------*/

@isTest
private class StarTrackTaskSearch_ControllerX_Test {

    @testSetup static void testSetup(){

        User opUser = new User(
     		ProfileId = [SELECT Id FROM Profile WHERE Name = 'StarTrack Operations'].Id,
     		LastName = 'last',
     		Email = 'test@user.com',
     		Username = 'test@operationsuser123.com',
     		CompanyName = 'TEST',
     		Title = 'title',
     		Alias = 'alias',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US');

        INSERT opUser;

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
        testDepotArea.Area__c = 'Redirection';
        testDepotArea.Depot__c = testNetwork.Id;
        INSERT testDepotArea;

        Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
        testDepotAreaUser.Name = 'Test Depot Area User';
        testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        testDepotAreaUser.User__c = UserInfo.getUserId();
        INSERT testDepotAreaUser;
        
        Depot_Area_User__c opUserDepotAreaUser = new Depot_Area_User__c();
        opUserDepotAreaUser.Name = 'Test Depot Area User - OP';
        opUserDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        opUserDepotAreaUser.User__c = opUser.Id;
        INSERT opUserDepotAreaUser;
        
        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.STServiceType__c = 'Airlock';
        testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;
        
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);

        Case testCase = new Case();
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        testCase.Enquiry_Type__c = 'Check Address';
        testCase.Call_Purpose__c = 'In Transit';
        testCase.ArticleTest__c = testArticle.Id;
        testCase.Network__c = testNetwork.Id;
        testCase.AccountId = testAccount.Id;
        INSERT testCase;
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = testCase.Id, UserOrGroupId = opUser.Id);
        INSERT cs;
        
        StarTrack_Settings__c ss = new StarTrack_Settings__c(OperationsTaskSearchQueryLimit__c = 200);
        INSERT ss;
    }

    @isTest static void testGetCurrentUserInfo(){
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        Test.startTest();
            System.assert(ctrl.thisUserDepotRole.size() > 0);
        Test.stopTest();
    }

    @isTest static void testGetCurrentUserInfo_Negative(){
        DELETE [SELECT Id FROM Depot_Area_User__c];

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();

        Test.startTest();
            System.assert(ctrl.thisUserDepotRole.isEmpty());
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyAreaTasks(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;
        testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);

            // Sort Task
            ctrl.sortExpression = 'OwnerId';
            ctrl.searchTasks();

            // Sort Case
            ctrl.sortExpression = 'Case__c';
            ctrl.searchTasks();
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyAreaTasks_Negative(){
        DELETE [SELECT Id FROM Depot_Area_User__c];

        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.resultTaskWrapper.isEmpty());
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyAcknowledged(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Acknowledged';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyAcknowledged_Negative(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = 'Completed';
        testTask.Network__r = net;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Acknowledged';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.resultTaskWrapper.isEmpty());
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyFinishedTasks(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Finished Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
        Test.stopTest();
    }

    @isTest static void testSearchTask_MyFinishedTasks_Negative(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
        testTask.Network__r = net;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Finished Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.resultTaskWrapper.isEmpty());
        Test.stopTest();
    }

    @isTest static void testSearchTask_Custom(){
        Case queryCase = [SELECT Id, Network__c, OwnerId FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        PostcodeMapping__c queryPostcodeMap = [SELECT Name FROM PostcodeMapping__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];
        Network__c caseNet = [SELECT Id FROM Network__c WHERE Id =: queryCase.Network__c];
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_NOTSTARTED;
        testTask.Network__r = caseNet;
        testTask.Run_Dock__c = queryPostcodeMap.Name;
        testTask.Network__r = net;
        INSERT testTask;
        testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;

		System.runAs(opUser){
			Test.setCurrentPage(Page.StarTrackTaskSearch);
	        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
	        ctrl.filterType = 'Custom';
	        Test.startTest();
	            // No Filter
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Network
	            ctrl.dummyTaskA.Network__r = net;
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Depot Role
	            ctrl.dummyTaskA.Depot_Role__c = queryDepotArea.Id;
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Owner
	            ctrl.dummyTaskA.OwnerId = queryCase.OwnerId;
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Run Dock
	            ctrl.runDock.add(queryPostcodeMap.Name);
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Status
	            ctrl.taskStatus.add(testTask.Status);
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	
	            // Date Range
	            ctrl.dummyTaskA.Case_Delivery_Collection_Date__c = Date.today() - 1;
	            ctrl.dummyTaskB.Case_Delivery_Collection_Date__c = Date.today() + 1;
	            ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	        Test.stopTest();
		}        
    }

    @isTest static void testSearchTask_Custom_Negative(){
        Case queryCase = [SELECT Id, Network__c, OwnerId FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id FROM Depot_Area__c LIMIT 1];
        PostcodeMapping__c queryPostcodeMap = [SELECT Name FROM PostcodeMapping__c LIMIT 1];

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'Custom';
        Test.startTest();
            // Network
            ctrl.dummyTaskA.Network__c = queryCase.Network__c;

            // Depot Role
            ctrl.dummyTaskA.Depot_Role__c = queryDepotArea.Id;

            // Owner
            ctrl.dummyTaskA.OwnerId = queryCase.OwnerId;

            // Run Dock
            ctrl.runDock.add(queryPostcodeMap.Name);

            // Status
            ctrl.taskStatus.add(StarTrack_Constants.TASK_STATUS_NOTSTARTED);

            // Date Range
            ctrl.dummyTaskA.Case_Delivery_Collection_Date__c = Date.today() - 1;
            ctrl.dummyTaskB.Case_Delivery_Collection_Date__c = Date.today() + 1;
            ctrl.searchTasks();
            System.assert(ctrl.resultTaskWrapper.isEmpty());
        Test.stopTest();
    }

    @isTest static void testAcknowledgeTasks_Detail(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;
        testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
            ctrl.detailAcknowledge = true;
            ctrl.getSelectedTaskDetails();
            ctrl.acknowledgeTasks();
            System.assert(ctrl.totalResultSize > 0);
            System.assertEquals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, ctrl.resultTaskWrapper[0].twTask.Status);
        Test.stopTest();
    }

    @isTest static void testAcknowledgeTasks_Result(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;
        testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
            ctrl.resultTaskWrapper[0].isSelected = true;
            ctrl.acknowledgeTasks();
            System.assert(ctrl.totalResultSize > 0);
            System.assertEquals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, ctrl.resultTaskWrapper[0].twTask.Status);
        Test.stopTest();
    }

    @isTest static void testSaveTaskDetails(){

        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];
        User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__c = net.Id;
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
        testTask.OwnerId = opUser.Id;
        INSERT testTask;

        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
        System.runAs(opUser) {
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
            ctrl.resultTaskWrapperMap.get(Id.valueOf(ctrl.selectedTaskId)).twTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
            ctrl.resultTaskWrapperMap.get(Id.valueOf(ctrl.selectedTaskId)).twTask.Operations_Outcome__c = 'Test';
            ctrl.saveTaskDetails();
            ctrl.filterType = 'My Finished Tasks';
            ctrl.searchTasks();
        }
        Test.stopTest();
        System.assertEquals(StarTrack_Constants.CASE_STAT_AWAITINGREVIEW, [SELECT Status FROM Case LIMIT 1].Status);
        List<Task> retTask = [SELECT Id, Status, Operations_Outcome__c FROM Task WHERE Id =: testTask.Id];
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, retTask[0].Status);
        System.assertEquals('Test', retTask[0].Operations_Outcome__c);
    }

    @isTest static void testOther(){
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        Test.startTest();
            System.assert(ctrl.getTaskStatuses().size() >= 0);
            System.assert(ctrl.getRunDocks().size() > 0);
            System.assert(ctrl.getFilterTypes().size() > 0);
            System.assertEquals(null, ctrl.first());
            System.assertEquals(null, ctrl.last());
            System.assertEquals(null, ctrl.next());
            System.assertEquals(null, ctrl.previous());
            System.assert(ctrl.getDisableNext());
            ctrl.limitBy = -1;
            System.assert(!ctrl.getDisableNext());
            System.assert(ctrl.getDisablePrevious());
            ctrl.offset = 1;
            System.assert(!ctrl.getDisablePrevious());
            ctrl.filterType = 'My Area Tasks';
            ctrl.changeFilter();
            System.assert(!ctrl.displayCustomFilters);
            ctrl.filterType = 'Custom';
            ctrl.changeFilter();
            System.assert(ctrl.displayCustomFilters);
            ctrl.resetFilter();
        Test.stopTest();
    }
    
     @isTest static void testRemainingScenarios(){
        Case queryCase = [SELECT Id, ArticleTest__c FROM Case LIMIT 1];
        Task newTask = new Task(CaseObject__c = queryCase.Id, Subject='Operation Task', Type=StarTrack_Constants.TASK_TYPE_OPERATION, Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED);
        insert newTask;
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        Test.startTest();
            //ctrl.getConsignments();
            ctrl.previousRecord = new StarTrackTaskSearch_ControllerX.TaskWrapper(newTask);
            ctrl.selectedTaskId = newTask.Id;
            ctrl.previousRecord.twTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
            ctrl.saveTaskDetails();
            ctrl.filterType = 'Custom';
            ctrl.dummyTaskA.Network__c = null;
            ctrl.dummyTaskA.Depot_Role__c = [SELECT Id FROM Depot_Area__c LIMIT 1].Id;
            ctrl.searchTasks();
            ctrl.dummyTaskA.Depot_Role__c = null;
            ctrl.dummyTaskA.OwnerId = UserInfo.getUserId();
            ctrl.searchTasks();
            ctrl.dummyTaskA.OwnerId = null;
            ctrl.runDock = new List<String>{'726378'};
            ctrl.searchTasks();
            ctrl.runDock.clear();
            ctrl.taskStatus = new List<String>{'Finished'};
            ctrl.searchTasks();
            ctrl.taskStatus.clear();
            ctrl.dummyTaskA.Case_Delivery_Collection_Date__c = System.today();
            ctrl.dummyTaskB.Case_Delivery_Collection_Date__c = System.today()+1;
            ctrl.consignment = 'SAMPLEDAVID';
            ctrl.searchTasks();
            ctrl.dummyTaskA.Case_Delivery_Collection_Date__c = null;
            ctrl.dummyTaskB.Case_Delivery_Collection_Date__c = null;
            ctrl.searchTasks();
        Test.stopTest();
        
        queryCase = [SELECT Id, Status FROM Case WHERE Id =: queryCase.Id];
        System.assertEquals(StarTrack_Constants.CASE_STATUS_NEW, queryCase.Status);
        
    }

    @isTest static void testFinishedTaskInvalid(){
        Case queryCase = [SELECT Id, ArticleTest__c FROM Case LIMIT 1];
        Task newTask = new Task(CaseObject__c = queryCase.Id, Subject='Operation Task', Type=StarTrack_Constants.TASK_TYPE_OPERATION, Status = StarTrack_Constants.TASK_STATUS_FINISHED);
        insert newTask;
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        Test.startTest();
            ctrl.resultTaskWrapperMap.put(newTask.Id, new StarTrackTaskSearch_ControllerX.TaskWrapper(newTask));
            ctrl.getBulkFields();
            ctrl.changeDepotAreaVisibility();
            ctrl.getDepotAreas();
            //ctrl.getConsignments();
            ctrl.detailAcknowledge = true;
            ctrl.previousRecord = new StarTrackTaskSearch_ControllerX.TaskWrapper(newTask);
            ctrl.selectedTaskId = newTask.Id;
            ctrl.acknowledgeTasks();           
        Test.stopTest();
        
        newTask = [SELECT Id, Status FROM Task WHERE Id =: newTask.Id];
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, newTask.Status);
        
    }

    @isTest static void testAcknowledgedTaskInvalid(){
        Case queryCase = [SELECT Id, ArticleTest__c FROM Case LIMIT 1];
        Task ackTask = new Task(CaseObject__c = queryCase.Id, Subject='Operation Task', Type=StarTrack_Constants.TASK_TYPE_OPERATION, Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED);
        Task finTask = new Task(CaseObject__c = queryCase.Id, Subject='Operation Task', Type=StarTrack_Constants.TASK_TYPE_OPERATION, Status = StarTrack_Constants.TASK_STATUS_FINISHED);
        List<Task> tasks = new List<Task>{ackTask, finTask};
        insert tasks;
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        Test.startTest();
            StarTrackTaskSearch_ControllerX.TaskWrapper tskwrap1 = new StarTrackTaskSearch_ControllerX.TaskWrapper(ackTask);
            tskwrap1.isSelected = true;
            StarTrackTaskSearch_ControllerX.TaskWrapper tskwrap2 = new StarTrackTaskSearch_ControllerX.TaskWrapper(finTask);
            tskwrap2.isSelected = true;
            ctrl.resultTaskWrapperMap.put(ackTask.Id, tskwrap1);
            ctrl.resultTaskWrapperMap.put(finTask.Id, tskwrap2);
            ctrl.getBulkFields();
            //ctrl.getConsignments();
            ctrl.detailAcknowledge = false;
            ctrl.acknowledgeTasks();           
        Test.stopTest();
        
        ackTask = [SELECT Id, Status FROM Task WHERE Id =: ackTask.Id];
        System.assertEquals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, ackTask.Status);
        finTask = [SELECT Id, Status FROM Task WHERE Id =: finTask.Id];
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, finTask.Status);
        
    }
    
    @isTest static void testRenderPDF() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];
        
        List<Task> tasks = new List<Task>();
        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        tasks.add(testTask);
        
        Task testTask1 = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask1.Depot_Role__c = queryDepotArea.Id;
        testTask1.Subject = 'Test';
        testTask1.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask1.CaseObject__c = queryCase.Id;
        testTask1.Network__r = net;
        tasks.add(testTask1);

        INSERT tasks;
        
        Test.setCurrentPage(Page.StarTrackTaskSearch);
        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
        ctrl.filterType = 'My Area Tasks';
        Test.startTest();
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
            ctrl.detailPrint = true;
            ctrl.renderTasksAsPDF();
            System.assert(ctrl.idForPDFPrinting != '');
            System.assert(ctrl.idsForPDFPrinting == '');
            System.assertEquals(String.valueOf(ctrl.resultTaskWrapper[0].twTask.Id), ctrl.idForPDFPrinting);
            
            ctrl.resultTaskWrapper[0].isSelected = true;
            ctrl.resultTaskWrapper[1].isSelected = true;
            ctrl.detailPrint = false;
            ctrl.renderTasksAsPDF();
            System.assert(ctrl.idsForPDFPrinting != '');
            System.assertEquals(String.valueOf(ctrl.resultTaskWrapper[0].twTask.Id) + ',' 
                + String.valueOf(ctrl.resultTaskWrapper[1].twTask.Id), ctrl.idsForPDFPrinting);
                
        Test.stopTest();
    }
    
    @isTest static void testPostToFeed() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;        
        INSERT testTask;        
		testTask.Depot_Role__c = queryDepotArea.Id;
		testTask.OwnerId = opUser.Id;
        UPDATE testTask;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'My Area Tasks';
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
	            ctrl.chatterComment = 'test comment';
	            ctrl.postToFeed();
        	}                                       
        Test.stopTest();                
        List<FeedItem> fiList = new List<FeedItem>([SELECT Id, Body, ParentId FROM FeedItem WHERE ParentId =: testTask.Id]);    	
    	//check if a comment(FeedItem) was created
    	System.assert(!fiList.isEmpty());    	    	
    }
    
    @isTest static void testReassignDepotArea() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];  	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        testTask.WhatId = queryCase.Id;
        testTask.OwnerId = opUser.Id;
        INSERT testTask;        
		testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'My Area Tasks';
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
	            ctrl.showDetailPopup();
	            System.assert(ctrl.displayDetailPopUp);
	            ctrl.detailReassign = true;
	            ctrl.getDepotAreaRecords();
	            ctrl.reassignTasks();
	            ctrl.closeDetailPopup();
        	}                                       
        Test.stopTest();                
    }
    
    @isTest static void testReassignDepotAreaList() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        testTask.WhatId = queryCase.Id;
        testTask.OwnerId = opUser.Id;
        INSERT testTask;        
		testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'My Area Tasks';
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.resultTaskWrapper[0].isSelected = true;
	            ctrl.showListPopUp();
	            System.assert(ctrl.displayListPopUp);
	            ctrl.reassignTasks();
	            ctrl.closeListPopUp();
        	}                                       
        Test.stopTest();                
    }

    @isTest static void testReassignDepotAreaList_negative() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        testTask.WhatId = queryCase.Id;
        INSERT testTask;
		testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.OwnerId = opUser.Id;
        UPDATE testTask;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'My Area Tasks';
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.showListPopUp();
	            System.assert(ctrl.funcErr);
        	}                                       
        Test.stopTest();                
    }
    
    @isTest static void testReassignDepotAreaList_negative_finished() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        testTask.WhatId = queryCase.Id;
        testTask.OwnerId = opUser.Id;
        INSERT testTask;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'Custom';
		        ctrl.taskStatus.add(StarTrack_Constants.TASK_STATUS_FINISHED);
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.resultTaskWrapper[0].isSelected = true;
	            ctrl.showListPopUp();
	            System.assert(ctrl.funcErr);
	            System.assert(!ctrl.displayListPopUp);
        	}                                       
        Test.stopTest();                
    }
    
    @isTest static void testReassignDepotAreaList_negative_closed() {
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c, Depot__r.Id FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];        
		User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];     	     	
     	        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        testTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
        testTask.WhatId = queryCase.Id;
        testTask.OwnerId = opUser.Id;
        INSERT testTask;        
		testTask.Depot_Role__c = queryDepotArea.Id;
        UPDATE testTask;
        
        queryCase.ResolutionCode__c = 'Closed - Invalid';
        queryCase.Status = StarTrack_Constants.CASE_STAT_CLOSED;
        queryCase.Call_Purpose__c = 'Other';
        queryCase.Enquiry_Type__c = 'Delivery Update';
        UPDATE queryCase;
                
        Test.startTest();
        	System.runAs(opUser) {
        		Test.setCurrentPage(Page.StarTrackTaskSearch);
		        StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
		        ctrl.filterType = 'Custom';
        		ctrl.searchTasks();
	            System.assert(ctrl.totalResultSize > 0);
	            ctrl.resultTaskWrapper[0].isSelected = true;
	            ctrl.showListPopUp();
	            System.assert(ctrl.funcErr);
	            System.assert(!ctrl.displayListPopUp);
        	}                                       
        Test.stopTest();                
    }
    // Test for negative - Finished - Case Resolved task status should not be
    // selectable unless StarTrack_Settings.StarTrack_Autoclose_Case_from_Task__c is true so save should fail.
    @isTest static void testGetIsAutoCloseEnabled_negative(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];
        User opUser = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@operationsuser123.com'])[0];

        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__c = net.Id;
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
        INSERT testTask;

        System.runAs(opUser) {
            Test.startTest();
            Test.setCurrentPage(Page.StarTrackTaskSearch);
            StarTrackTaskSearch_ControllerX ctrl = new StarTrackTaskSearch_ControllerX();
            ctrl.filterType = 'My Area Tasks';
            ctrl.searchTasks();
            System.assert(ctrl.totalResultSize > 0);
            ctrl.selectedTaskId = ctrl.resultTaskWrapper[0].twTask.Id;
            ctrl.resultTaskWrapperMap.get(Id.valueOf(ctrl.selectedTaskId)).twTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED;
            ctrl.resultTaskWrapperMap.get(Id.valueOf(ctrl.selectedTaskId)).twTask.Operations_Outcome__c = 'Test';
            ctrl.saveTaskDetails();
            //ctrl.filterType = 'My Finished Tasks';
            //ctrl.searchTasks();
        }
        Test.stopTest();
        // user cannot update with Finished - Case Resolved Status as custom setting is false.
        List<Task> retTask = [SELECT Id, Status, Operations_Outcome__c FROM Task WHERE Id =: testTask.Id];
        System.assertEquals(StarTrack_Constants.TASK_STATUS_WAITING, retTask[0].Status);
        System.assertEquals(null, retTask[0].Operations_Outcome__c);

    }
}