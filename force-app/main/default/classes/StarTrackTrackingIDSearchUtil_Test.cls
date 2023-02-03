@IsTest
private class StarTrackTrackingIDSearchUtil_Test {
    @testSetup 
	static void testSetup(){
        List<sobject> ls = TestDataProvider.createStartrackErrorMessagesData();
        
        List<StarTrack_Transfer_Case_Rule__c> transferCaseRules = new List<StarTrack_Transfer_Case_Rule__c>();
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'StarTrack Next Flight Queue', Product_Group__c = 'Next Flight', Order__c = 1, Business_Solutions_Customer__c = true));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.TRANSFER_QUEUE, Business_Solutions_Customer__c = true, Order__c = 2));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'ETA Queue', Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
        Database.insert(transferCaseRules); 

        // Verify all custom settings are created
        System.assertEquals(ls.size(),[SELECT Id FROM StarTrack_Error_Messages__c].size());

        List<Account> lst_account = TestDataProvider.createAccount('test', 8);

        for(Integer i = 0; i < 2; i++){
            lst_account[i].Transfer_Case_Queue__c = 'Delivery Queue';
            lst_account[i].Business_Solutions_Customer__c = true;
        }

        for(Integer i = 2; i < 4; i++){
            lst_account[i].Business_Solutions_Customer__c = true;
            lst_account[i].Transfer_Case_Queue__c = '';
        }

        for(Integer i = 4; i < 6; i++){
            lst_account[i].Business_Solutions_Customer__c = true;
            lst_account[i].Transfer_Case_Queue__c = 'WRONG_QUEUE_NAME';
        }

        for(Integer i = 6; i < 8; i++){
            lst_account[i].Business_Solutions_Customer__c = false;
        }

        Database.insert(lst_account);
        System.debug('** List of Account ** ' + lst_account);
        System.assertEquals(lst_account[0].Legacy_Id__c,'60000000');
        lst_account[0].Legacy_Id__c = '60000000';
        Database.Update(lst_account[0]);

        List<Network__c> lst_network = TestDataProvider.createNetwork('Test network', 8);

        User u = TestDataProvider.createTestUsers();
        Database.insert(u);
        for(Network__c n : lst_network){
            n.ownerid = u.id;
        }

        Database.insert(lst_network);

        List<Billing_Account__c> lst_billingAccount = TestDataProvider.createBillingAccount('', 8,lst_account);
        Database.insert(lst_billingAccount);

        List<Article__c> lst_article = TestDataProvider.createArticle('Subject', 8,lst_billingAccount);
        for(Integer i = 0; i < 8; i++){
            lst_article[i].Network__c = lst_network[i].Id;
            lst_article[i].Billing_Account__c = lst_billingAccount[i].Id;
        }

        Database.insert(lst_article);

        List<case> lst_cases = TestDataProvider.createCases('Subject', 8,lst_article);
        for(Integer i = 0; i < 8; i++){
            lst_cases[i].AccountId = lst_account[i].id;
            lst_cases[i].Related_Billing_Account__c = lst_billingAccount[i].id;
			lst_cases[i].Origin = StarTrack_Constants.CASE_ORIGIN_WEB;
			lst_cases[i].ReferenceID__c = 'XYZ';
            lst_cases[i].RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId();
        }
        Database.insert(lst_cases);

        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        System.runAs(usr) {

            List<Group> testQueues = new List<Group>();
            testQueues.add(new Group(Name='StarTrack Next Flight Queue',  Type='Queue'));
            testQueues.add(new Group(Name='ETA Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Web Bookings Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Controlled Returns Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Sorry We Missed You',  Type='Queue'));
            testQueues.add(new Group(Name='Delivery Queue',  Type='Queue'));
            Database.insert(testQueues);
            
            
            List<QueuesObject> queueAssignments = new List<QueueSObject>();
            queueAssignments.add(new QueuesObject(QueueID = testQueues[0].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[1].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[2].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[3].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[4].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[5].Id, SObjectType = 'Case'));
            Database.insert(queueAssignments);
        }
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue';
        customSetting.PBE_ETA_Enquiry__c = 'ETA Queue';
        customSetting.PBE_Missed_Futile_Enquiry__c = 'Web Bookings Queue';
        customSetting.PBE_Controlled_Returns__c = 'Controlled Returns Queue';
        customSetting.Redelivery_Redirection_Enquiry__c = 'Sorry We Missed You';
        Database.insert(customSetting);
        

    }
    
    @isTest 
	static void testCaseTransferForBusinessSolutionsPositiveNetworkOwner() {
        Case testCase = [
                        SELECT Id,
							Call_Purpose__c, 
							RecordTypeId, 
							Enquiry_Type__c, 
							Business_Solutions_Customer__c, 
							Initial_Caller_Type__c,
							Status, 
							OwnerId, 
							Article_Service_Type__c, 
							ReferenceID__c, 
							Origin, 
							ArticleTest__c, 
							ArticleTest__r.Product_Group__c,
							RecordType.Name, 
							Network__r.OwnerId, 
							Network__r.Name, 
							Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
							Account.StarTrack_Customer_Stream__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];

		System.debug('testCase: ' + testCase);

        Test.startTest();
        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();


			// mock database, set response for DML update
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

        MockUtility.Mocks.stopStubbing();

		//process the case transfer
		System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

        Test.stopTest();

        // Check if the Case record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());


    }


    @isTest static void testCaseTransferForBusinessSolutionsPositive() {
        Case testCase = [
						SELECT Id,
								Call_Purpose__c, 
								RecordTypeId, 
								Enquiry_Type__c, 
								Business_Solutions_Customer__c, 
								Initial_Caller_Type__c,
								Status, 
								OwnerId, 
								Article_Service_Type__c, 
								ReferenceID__c, 
								Origin, 
								ArticleTest__c, 
								ArticleTest__r.Product_Group__c,
								RecordType.Name, 
								Network__r.OwnerId, 
								Network__r.Name, 
								Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
								Account.StarTrack_Customer_Stream__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c =  'Delivery Queue'
                        LIMIT 1
                        ];

		Test.startTest();
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();


			// mock database, set response for DML update
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		//process the case transfer
		System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

		Test.stopTest();

		// Check if the Case record has been updated once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @isTest static void testCaseTransferForBusinessSolutionsNoQueueNegative() {
        Case testCase = [
                        SELECT
                                Id,
								Call_Purpose__c, 
								RecordTypeId, 
								Enquiry_Type__c, 
								Business_Solutions_Customer__c, 
								Initial_Caller_Type__c,
								Status, 
								OwnerId, 
								Article_Service_Type__c, 
								ReferenceID__c, 
								Origin, 
								ArticleTest__c, 
								ArticleTest__r.Product_Group__c,
								RecordType.Name, 
								Network__r.OwnerId, 
								Network__r.Name, 
								Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c,
								Account.StarTrack_Customer_Stream__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c = 'WRONG_QUEUE_NAME'
                                LIMIT 1
                        ];

		Test.startTest();
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();


			// mock database, set response for DML update
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		//process the case transfer
		System.enqueueJob(new StarTrackTrackingIDSearchUtil.TransferCaseQueueable(testCase));

		Test.stopTest();

		// Check if the Case record has been updated once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

/*	
    @isTest static void testCaseTransferForBusinessSolutionsInCorrectQueueNegative() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c = ''
                                LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testCaseTransferForBusinessSolutionsNoTransferReasonNegative() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
        Test.stopTest();
    }

    @isTest static void testCatchError() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];
        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
        Test.stopTest();
    }

*/


}