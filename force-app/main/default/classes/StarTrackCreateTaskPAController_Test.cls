/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Test Class for StarTrackCreateTaskPAController
History
October 15, 2015 - Patrick James Franco - Created
May 16, 2016 - David Catindoy - Updated based changes regarding StarTrackCreateTaskPA component
------------------------------------------------------------*/

@isTest
private class StarTrackCreateTaskPAController_Test {

    @testSetup static void testSetup(){
        Network__c testNetwork = TestDataProvider.createTestNetwork();
        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
        testNetwork.ST_Email__c = true;
        testNetwork.Email__c = 'te@st.comz';
        testNetwork.State__c = 'ACT';
        testNetwork.Facility__c = 'Express';
        testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        testNetwork.Email__c = 'te@st.zzz';
        testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId(); 
        INSERT testNetwork;

        Depot_Area__c testDepotArea = new Depot_Area__c();
        testDepotArea.Name = 'Test Depot Area';
        testDepotArea.Depot__c = testNetwork.Id;
        testDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT;
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
        testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;

        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Other';
        testCase.Enquiry_Type__c = 'POD';
        testCase.ArticleTest__c = testArticle.Id;
        testCase.Network__c = testNetwork.Id;
        INSERT testCase;

        StarTrack_Error_Messages__c sem1 = new StarTrack_Error_Messages__c();
        sem1.Name = 'PBE Require Network';
        sem1.Value__c = 'Test';
        INSERT sem1;

        StarTrack_Error_Messages__c sem2 = new StarTrack_Error_Messages__c();
        sem2.Name = 'Network/Consignment is NULL';
        sem2.Value__c = 'Test';
        INSERT sem2;

        StarTrack_Error_Messages__c sem3 = new StarTrack_Error_Messages__c();
        sem3.Name = 'Preferred Method Tasking Not Allowed';
        sem3.Value__c = 'Test';
        INSERT sem3;
    }

    static testMethod void testCreateTask_None(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController();

        Test.startTest();
            // Email
            ctrl.newTask.Type = null;
            //ctrl.checkTaskType();

            ctrl.newTask.Subject = 'Test Subject';
            ctrl.createTask();
            System.assertEquals(true, [SELECT Id FROM Task].isEmpty());

            // System
            ctrl.taskingmethod = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;

            Network__c queryNetwork = [SELECT Preferred_Method_of_Tasking__c, System__c FROM Network__c LIMIT 1];
            queryNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
            queryNetwork.System__c = true;
            UPDATE queryNetwork;

            ctrl.createTask();
            System.assert(![SELECT Id FROM Workflow_Email__c].isEmpty());
        Test.stopTest();
    }

    static testMethod void testCreateTask_Reminder(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController();

        Test.startTest();
            ctrl.newTask.Type = StarTrack_Constants.TASK_TYPE_REMINDER;
            ctrl.checkTaskType();

            // Email
            ctrl.newTask.Type = null;
            ctrl.newTask.Subject = 'Test Subject';
            ctrl.checkTaskType();
            //System.assertEquals(false, [SELECT Id FROM Workflow_Email__c].isEmpty());

            // System
            ctrl.taskingmethod = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;

            Network__c queryNetwork = [SELECT Preferred_Method_of_Tasking__c, System__c FROM Network__c LIMIT 1];
            queryNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
            queryNetwork.System__c = true;
            UPDATE queryNetwork;
            
            ctrl.newTask.Type = StarTrack_Constants.TASK_TYPE_REMINDER;
            ctrl.createTask();
            System.assert(![SELECT Id FROM Task].isEmpty());
        Test.stopTest();
    }

    static testMethod void testCreateTask_OperationSingle(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController();
        ctrl.getDepotAreaRecords();

        Test.startTest();
            // Email
            ctrl.newTask.Type = null;
            ctrl.newTask.Subject = 'Test Subject';
            ctrl.changeNetworkValue();
            ctrl.createTask();
            System.assertEquals(false, [SELECT Id FROM Workflow_Email__c].isEmpty());
            
            // System
            ctrl.taskingmethod = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;

            Network__c queryNetwork = [SELECT Id, Preferred_Method_of_Tasking__c, System__c FROM Network__c LIMIT 1];
            queryNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
            queryNetwork.System__c = true;
            UPDATE queryNetwork;
            ctrl.changeNetworkValue();
            ctrl.newTask.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
            ctrl.createTask();
            ctrl.newTask.Depot_Role__c = [SELECT Id FROM Depot_Area__c WHERE Depot__c = :queryNetwork.Id LIMIT 1].Id;
            ctrl.depotAreaId = ctrl.newTask.Depot_Role__c;
            ctrl.createTask();
            System.assert(![SELECT Id FROM Task].isEmpty());
        Test.stopTest();
    }

    static testMethod void testCreateTask_OperationBulk(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController();

        Test.startTest();
            // Email
            ctrl.newTask.Subject = 'Test Subject';
            ctrl.newTask.Depot_Filter__c = 'Metros Only';
            ctrl.newTask.State__c = 'ACT';
            ctrl.newTask.Is_Bulk_Task__c = true;
            ctrl.checkTaskType();
            ctrl.createTask();
            ctrl.newTask.Depot_Filter__c = 'Regions Only';
            ctrl.checkTaskType();
            ctrl.createTask();
            ctrl.newTask.Depot_Filter__c = 'All by State';
            ctrl.checkTaskType();
            ctrl.createTask();
            System.assert(![SELECT Id FROM Workflow_Email__c].isEmpty());

            Network__c queryNetwork = [SELECT Preferred_Method_of_Tasking__c, System__c FROM Network__c LIMIT 1];
            queryNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
            queryNetwork.System__c = true;
            UPDATE queryNetwork;
            ctrl.newTask.Depot_Filter__c = 'All';
            ctrl.checkTaskType();
            ctrl.createTask();
            System.assert(![SELECT Id FROM Task].isEmpty());
        Test.stopTest();
    }

    static testMethod void testCreateTaskNegative(){
        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController();

        Test.startTest();
            // Subject validation
            try{
                ctrl.createTask();
            }
            catch(Exception e){
                System.assert([SELECT Id FROM Task].isEmpty());
            }

            // Depot Filter validation
            try{
                ctrl.newTask.Is_Bulk_Task__c = true;
                ctrl.newTask.Subject = 'Test Subject';
                ctrl.createTask();
            }
            catch(Exception e){
                System.assert([SELECT Id FROM Task].isEmpty());
            }

            // State validation
            try{
                ctrl.newTask.Is_Bulk_Task__c = true;
                ctrl.newTask.Subject = 'Test Subject';
                ctrl.newTask.Depot_Filter__c = StarTrack_Constants.TASK_DEPOT_FILTER_ALL_STATE;
                ctrl.createTask();
            }
            catch(Exception e){
                System.assert([SELECT Id FROM Task].isEmpty());
            }
        Test.stopTest();
    }

    static testMethod void testOther(){
        Case queryCase = [SELECT Id, RecordTypeId, Network__c, ArticleTest__c FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrlA = new StarTrackCreateTaskPAController();


        Id twClaimRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Transit Warranty Claim').getRecordTypeId();
        queryCase.RecordTypeId = twClaimRecTypeId;
        UPDATE queryCase;
        StarTrackCreateTaskPAController ctrlC = new StarTrackCreateTaskPAController();

        Test.startTest();
            //System.assertEquals(null, ctrlA.changeIsBulk());
            System.assertEquals(null, ctrlA.changeTaskField());

            // Preferred Method of Tasking error
            Network__c queryNetwork = [SELECT Preferred_Method_of_Tasking__c FROM Network__c LIMIT 1];
            queryNetwork.Preferred_Method_of_Tasking__c = 'Email';
            UPDATE queryNetwork;
            System.assert(ctrlC.disabledButton);

            // Network error
            queryCase.Network__c = null;
            queryCase.ArticleTest__c = null;
            UPDATE queryCase;
            StarTrackCreateTaskPAController ctrlB = new StarTrackCreateTaskPAController();
            System.assert(!ctrlB.createTaskAllowed);
        Test.stopTest();
    }

    static testMethod void testPickupBookingEnquiry(){
        Id pbeEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case queryCase = [SELECT Id, RecordTypeId, Network__c FROM Case LIMIT 1];
        queryCase.RecordTypeId = pbeEnquiryRecTypeId;
        UPDATE queryCase;

        Depot_Area__c queryDepotArea = [SELECT Area__c FROM Depot_Area__c LIMIT 1];
        queryDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_OPERATIONS;
        UPDATE queryDepotArea;

        Test.setCurrentPage(Page.StarTrackCreateTaskPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCreateTaskPAController ctrlA = new StarTrackCreateTaskPAController();

        Test.startTest();
            DELETE [SELECT Id FROM Network__c];
            StarTrackCreateTaskPAController ctrlB = new StarTrackCreateTaskPAController();
            System.assert(!ctrlB.createTaskAllowed);
        Test.stopTest();
    }
    
    static testMethod void testConstructorWithParam(){
        Case queryCase = [SELECT Id, RecordTypeId, Network__c, ArticleTest__c FROM Case LIMIT 1];
        Network__c networkRec = [SELECT Id FROM Network__c WHERE Id =: queryCase.Network__c];
        Network__c testNet = TestDataProvider.createTestNetwork();
        testNet.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PHONE;
        testNet.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
        testNet.Phone__c = true;
        testNet.Depot_contact_number__c = '09126893944';
        testNet.State__c = 'ACT';
        testNet.Facility__c = 'Express';
        testNet.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        insert testNet;

        StarTrackCreateTaskPAController ctrl = new StarTrackCreateTaskPAController(queryCase.Id);

        Test.startTest();
            ctrl.newTask.Type = '';
            ctrl.checkTaskType();
            networkRec.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT;
            networkRec.Parent_Network__c = testNet.Id;
            networkRec.Parent_Depot__c = true;
            update networkRec;
            ctrl.refreshRecord();
            ctrl.newTask.Subject = 'Operation Task';
            ctrl.createTask();
            ctrl.existingCase.ArticleTest__r.ReceiverPostcode__c = '';
            ctrl.existingCase.ArticleTest__r.Receiver_Suburb__c = '';
            ctrl.checkTaskType();
        Test.stopTest();
        
        System.assertEquals(true, [SELECT Id, Network__c, CaseObject__c FROM Task WHERE CaseObject__c =: queryCase.Id LIMIT 1].isEmpty());
    }
    
}