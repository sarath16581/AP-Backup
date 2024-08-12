/**
* @author Naveen Rajanna
* @date 2022-02-22
* @group Tests
* @tag module
* @tag case
* @domain StarTrackEmailMessagesDomain
* @description Test class covering StarTrackEmailMessagesModule
* @changelog
* 2022-02-22	Naveen Rajanna	created - REQ2723199
* 2024-08-07 - Ranjeewa Silva - Test class updates after uplifting the module to new ApplicationModule framework.
*/
@IsTest
private class StarTrackEmailMessagesModule_Test {

	@testSetup
    static void testSetup() { 
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c(
            Check_for_Duplicate_Email__c = true, Duplicate_Email_Check_Interval_Minutes__c=2.0, ST_Duplicate_Inbound_Email_Prefix__c = 'DUPLICATE EMAIL -', ST_Credit_Claim_Inbound_Email_Prefix__c='ccie', DHL1__c='dhlcold.chain@startrack.com.au', DHL2__c='dhl.apple@startrack.com.au', DHL3__c='dhlservices@startrack.com.au', DHL4__c='mailbox.dhlservices@startrack.com.au', DHL5__c='mailbox.dhlservices@startrack.com', BSC_Apple__c='apple@startrack.com.au', BSC_Defence_Force__c='defence@startrack.com.au', BSC_Dell_Schenker__c='dell.sydney@startrack.com.au', BSC_Phillips_Schenker__c='schenkerphillips@startrack.com.au', ST_Acc_Mgr_Supp__c='account.managers@startrack.com.au', BSC_DHL_Road__c='dhlsupplychain@startrack.com.au', BSC_Fedex_Enq__c='fedex.enquiries@startrack.com.au', BSC_Fedex_Pick__c='fedexpkups@startrack.com.au', BSC_HP_Schenker__c='schenkerhp@startrack.com.au', BSC_Optus__c='optus@startrack.com.au', BSC_Samsung__c='samsung@startrack.com.au', BSC_Stop_Delivery__c='stop.delivery@startrack.com.au', BSC_Telstra__c='telstrateam@startrack.com.au', BSC_Optus_Stop_Delivery__c='optusstop@startrack.com.au', Business_Solutions_From_Email__c='businesscentre@startrack.com.au', Investigators_From_Email__c='customerservice@startrack.com.au', Credit_Dispute_From_Email__c='credit.claims@startrack.com.au', Transit_Warranty_From_Email__c='transit.warranty@startrack.com.au', VOC_From_Email__c='customer.satisfaction@startrack.com.au', General_Enquiry_From_Address__c='customerservice@startrack.com.au', Default_From_Email__c='businesscentre@startrack.com.au', Startrackdamages__c='damages@startrack.com.au'
        );
        insert(customSetting);
		List<StarTrackDefaultEmailAddresses__c> defaultAddressList = new List<StarTrackDefaultEmailAddresses__c>();
        defaultAddressList.add(new StarTrackDefaultEmailAddresses__c(Name = 'apple@gmail.com', Description__c = 'BSC - Apple', From_Email_Address__c = 'apple-reply@gmail.com'));
		defaultAddressList.add(new StarTrackDefaultEmailAddresses__c(Name = 'dhl.apple@startrack.com.au', Description__c = 'DHL', From_Email_Address__c = 'dhl.apple-from@startrack.com.au'));
        insert defaultAddressList;
    }

	private class MockException extends Exception {}

	@IsTest
	private static void testAfterInsertExceptionScenario() {
		//Disable trigger execution
		MockUtility.disableTriggerExecution();
		
		//Generate caseList and Email Messages
		List<Case> caseList = ApplicationTestDataFactory.getCases(1, true);
		caseList[0].Status = StarTrack_Constants.CASE_STAT_CLOSED;
		caseList[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		EmailMessage em0 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[0].Id))[0];
		em0 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em0, new Map<String, Object>{'Parent' => caseList[0]});
		List<EmailMessage> emailList = new List<EmailMessage>{em0};
        
		//Stubbing
		// set up our responses
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		
		MockUtility.Mocks.startStubbing();
			// throw an exception to simulate an unexpected error
			MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsWithParentStarTrackCase((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();
		
		//Testing
		Test.startTest();
			try {
				new StarTrackEmailMessagesModule().onAfterInsert((List<SObject>) emailList, mockUow);
			} catch (Exception e) {
				System.assert(true, 'Expected Exception to be thrown');
			}
		Test.stopTest();
	}

	@IsTest
	private static void testAfterInsertUpdateRelatedcaseList() {
		//Disable trigger execution
		MockUtility.disableTriggerExecution();

		//setup
		List<Case> caseList = ApplicationTestDataFactory.getCases(8, true);
		RecordType caseStarTrackVoiceOfCustRecordType = [Select Id,DeveloperName From RecordType Where SObjectType = 'Case' And DeveloperName = :StarTrack_Constants.CASE_VOC_RT_DEV];
		RecordType caseStarTrackDeliveryEnquiryRecordType = [Select Id,DeveloperName From RecordType Where SObjectType = 'Case' And DeveloperName = :StarTrack_Constants.CASE_DELIVERY_RT_DEV];
		RecordType caseStarTransitWarrantyClaimRecordType = [Select Id,DeveloperName From RecordType Where SObjectType = 'Case' And DeveloperName = :StarTrack_Constants.CASE_TWC_RT_DEV];
		RecordType casestarTrackCreditDisputeRecordType = [Select Id,DeveloperName From RecordType Where SObjectType = 'Case' And DeveloperName = :StarTrack_Constants.CASE_CREDIT_RT_DEV];
		
		//Scenario to cover Incoming Email for StarTrack Open cases with StarTrack_Calc_Email_Address__c populated having received first email response
		//sub scenario 1
		caseList[0].First_Email_Response__c = true;
		caseList[0].StarTrack_Calc_Email_Address__c = 'test@test.com.au';
		caseList[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[0], new Map<String, Object>{'RecordType' => caseStarTrackVoiceOfCustRecordType, 'RecordTypeId' => caseStarTrackVoiceOfCustRecordType.Id});
		EmailMessage em0 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[0].Id))[0];

		//sub scenario 2
		caseList[1].First_Email_Response__c = true;
		caseList[1].StarTrack_Calc_Email_Address__c = 'test@test.com.au';
		caseList[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[1], new Map<String, Object>{'RecordType' => caseStarTrackDeliveryEnquiryRecordType, 'RecordTypeId' => caseStarTrackDeliveryEnquiryRecordType.Id, 'Owner_is_Queue__c' => false});
		EmailMessage em1 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[1].Id))[0];
		
		//sub scenario 3
		caseList[2].First_Email_Response__c = true;
		caseList[2].StarTrack_Calc_Email_Address__c = 'test@test.com.au';
		caseList[2].Approval_Status__c = 'Approved';
		caseList[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[2], new Map<String, Object>{'RecordType' => caseStarTransitWarrantyClaimRecordType, 'RecordTypeId' => caseStarTransitWarrantyClaimRecordType.Id});
		EmailMessage em2 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[2].Id))[0];

		//Scenario for Closed Case Replies
		caseList[3].Status = StarTrack_Constants.CASE_STAT_CLOSED;
		caseList[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[3], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		EmailMessage em3 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[3].Id))[0];

		//Scenario for Outbound Email
		caseList[4].First_Email_Response__c = false;
		caseList[4] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[4], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		EmailMessage em4 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,false,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Outbound Email',caseList[4].Id))[0];
		em4.Status = EmailMessageUtil.STATUS_REPLIED;

		//Scenario for Incoming Email for StarTrack Cases having empty StarTrack_Calc_Email_Address__c - starTrackCreditDisputeRecordType
		caseList[5].StarTrack_Calc_Email_Address__c = null;
		caseList[5].Business_Solutions_Customer__c = false;
		caseList[5].Origin = StarTrack_Constants.CASE_ORIGIN_BSC;
		caseList[5].Subject ='SUB and [ ref:_00D7Fyj4X._5007Fyruem:ref ] ';
		caseList[5] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[5], new Map<String, Object>{'StarTrack_RecordType__c' => true, 'RecordType' => casestarTrackCreditDisputeRecordType, 'RecordTypeId' => casestarTrackCreditDisputeRecordType.Id, 'CreatedDate' => System.now()});
		EmailMessage em5 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategicsuppor@auspost.com.au;credit.claims@startrack.com.au','','',StarTrack_Constants.CREDITCLAIM_INVSUBJECT+'Inbound Email',caseList[5].Id))[0];
		MilestoneType milestoneType = ApplicationTestDataFactory.getMilestoneTypes(1, true)[0];
		milestoneType.Name = StarTrack_Constants.CASEMILESTONE_CUST_FIRST_RESP;		
		CaseMilestone milestone = ApplicationTestDataFactory.getCaseMilestones(1, true, true, false, milestoneType.Id, caseList[5].Id)[0];
		milestone = (CaseMilestone)ApplicationTestDataFactory.setUnwritableFields(milestone, new Map<String, Object>{'MilestoneType' => milestoneType});
		List<CaseMilestone> milestoneList = new List<CaseMilestone>{milestone};

		//Scenario for Incoming Email for StarTrack Cases having empty StarTrack_Calc_Email_Address__c - caseStarTrackVoiceOfCustRecordType
		caseList[6].StarTrack_Calc_Email_Address__c = null;
		caseList[6].Subject = 'testDuplicate';
		caseList[6].Auto_Email_Response_sent__c = false;
		caseList[6] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[6], new Map<String, Object>{'StarTrack_RecordType__c' => true,'RecordType' => caseStarTrackVoiceOfCustRecordType, 'RecordTypeId' => caseStarTrackVoiceOfCustRecordType.Id});
		EmailMessage em6 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au;dhl.apple@startrack.com.au','amazonstategic@auspost.com.au','apple@startrack.com.au','Inbound Email',caseList[6].Id))[0];

		//Scenario for Incoming Email for StarTrack Cases having empty StarTrack_Calc_Email_Address__c - caseStarTrackDeliveryEnquiryRecordType
		caseList[7].StarTrack_Calc_Email_Address__c = null;
		caseList[7].Subject = 'testDuplicate';
		caseList[7].Auto_Email_Response_sent__c = false;
		caseList[7] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[7], new Map<String, Object>{'StarTrack_RecordType__c' => true,'RecordType' => caseStarTrackDeliveryEnquiryRecordType, 'RecordTypeId' => caseStarTrackDeliveryEnquiryRecordType.Id});
		EmailMessage em7 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','as@auspost.com.au','amazonstategic@auspost.com.au','apple@startrack.com.au','Inbound Email',caseList[7].Id))[0];
		
		//link related Case parent relationship fields to EmailMessage
		em0 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em0, new Map<String, Object>{'Parent' => caseList[0]});
		em1 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em1, new Map<String, Object>{'Parent' => caseList[1]});
		em2 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em2, new Map<String, Object>{'Parent' => caseList[2]});
		em3 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em3, new Map<String, Object>{'Parent' => caseList[3]});
		em4 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em4, new Map<String, Object>{'Parent' => caseList[4]});
		em5 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em5, new Map<String, Object>{'Parent' => caseList[5]});
		em6 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em6, new Map<String, Object>{'Parent' => caseList[6], 'CreatedDate' => System.now()});
		em7 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em7, new Map<String, Object>{'Parent' => caseList[7], 'CreatedDate' => System.now()});
		List<EmailMessage> emailList = new List<EmailMessage>{em0, em1, em2, em3, em4, em5, em6, em7};

		//Stubbing, set up our responses
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector)MockUtility.mockSelector(CaseMilestonesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		
		MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsWithParentStarTrackCase((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(emailList);
			MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCaseAndMilestoneNames((Set<Id>)fflib_Match.anyObject(),(Set<String>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(milestoneList);
			MockUtility.Mocks.when(mockEmailMessagesSelector.getDuplicateEmailMessagesCount((Id)fflib_Match.anyObject(),(String)fflib_Match.anyObject(),(String)fflib_Match.anyObject(),(DateTime)fflib_Match.anyObject())).thenReturn(0);
			MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		
		//Testing
		Test.startTest();
			new StarTrackEmailMessagesModule().onAfterInsert((List<SObject>) emailList, mockUow);
		Test.stopTest();
		
		//Assert or Verify
		((EmailMessagesSelector)MockUtility.Mocks.verify(mockEmailMessagesSelector, MockUtility.Mocks.times(1))).selectByIdsWithParentStarTrackCase((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		
		System.assertEquals(9, MockUtility.mockUnitOfWorkDMLs.size());
		
		System.assertEquals(StarTrack_Constants.CASE_STAT_AWAITINGREVIEW, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected Case to be updated to Awaiting Review');
		System.assertEquals(StarTrack_Constants.KEYWRD_NEWEMAILRECVD, ((Case)MockUtility.mockUnitOfWorkDMLs[1]).Case_Update__c, 'Expected Case_Update__c field to be updated to New Email Received');
		System.assertEquals(StarTrack_Constants.KEYWRD_NEWEMAILRECVD, ((Case)MockUtility.mockUnitOfWorkDMLs[2]).Case_Update__c, 'Expected Case_Update__c field to be updated to New Email Received');
		System.assertEquals(StarTrack_Constants.CASE_STAT_REOPENED, ((Case)MockUtility.mockUnitOfWorkDMLs[3]).Status, 'Expected Case to be updated to Reopened');
		System.assertEquals(true, ((Case)MockUtility.mockUnitOfWorkDMLs[4]).First_Email_Response__c, 'Expected Case First_Email_Response__c field to be set to true');
		
		System.assertEquals(true, ((Case)MockUtility.mockUnitOfWorkDMLs[5]).Business_Solutions_Customer__c, 'Expected Case Business_Solutions_Customer__c field to be set to true');
		System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEF, ((Case)MockUtility.mockUnitOfWorkDMLs[5]).Call_Purpose__c, 'Expected Case Call_Purpose__c field to be set to Other');

		System.assertEquals(true, ((Case)MockUtility.mockUnitOfWorkDMLs[6]).Send_Auto_Response_Email__c, 'Expected Case Send_Auto_Response_Email__c field to be set to true');
		System.assertEquals('dhl.apple-from@startrack.com.au', ((Case)MockUtility.mockUnitOfWorkDMLs[6]).StarTrack_Calc_Email_Address__c, 'Expected Case StarTrack_Calc_Email_Address__c field to be set to dhl.apple-from@startrack.com.au');

		System.assertEquals(true, ((Case)MockUtility.mockUnitOfWorkDMLs[7]).Send_Auto_Response_Email__c, 'Expected Case Send_Auto_Response_Email__c field to be set to true');
		
		System.assert(((CaseMilestone)MockUtility.mockUnitOfWorkDMLs[8]).CompletionDate != null, 'Expected CaseMilestone CompletionDate to be set');
	}

	@IsTest
	private static void testAfterInsertUpdateRelatedcaseDuplicateCheckSuccess() {
		//Disable trigger execution
		MockUtility.disableTriggerExecution();

		//setup
		List<Case> caseList = ApplicationTestDataFactory.getCases(1, true);
		caseList[0].StarTrack_Calc_Email_Address__c = null;
		caseList[0].Subject = 'testDuplicate';
		caseList[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(caseList[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});
		EmailMessage em0 = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, true,true,'test@test.com','amazonstrategic@auspost.com.au','amazonstategic@auspost.com.au','amazonstrategicsuppor@auspost.com.au','Inbound Email',caseList[0].Id))[0];

		//link related Case parent relationship fields to EmailMessage
		em0 = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(em0, new Map<String, Object>{'Parent' => caseList[0], 'CreatedDate' => System.now()});
		List<EmailMessage> emailList = new List<EmailMessage>{em0};

		//Stubbing, set up our responses
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
		CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector)MockUtility.mockSelector(CaseMilestonesSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		
		MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockEmailMessagesSelector.selectByIdsWithParentStarTrackCase((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(emailList);
			MockUtility.Mocks.when(mockEmailMessagesSelector.getDuplicateEmailMessagesCount((Id)fflib_Match.anyObject(),(String)fflib_Match.anyObject(),(String)fflib_Match.anyObject(),(DateTime)fflib_Match.anyObject())).thenReturn(1);
			MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
			
			//Testing
		Test.startTest();
			new StarTrackEmailMessagesModule().onAfterInsert((List<SObject>) emailList, mockUow);
		Test.stopTest();

		//Assert or Verify
		((EmailMessagesSelector)MockUtility.Mocks.verify(mockEmailMessagesSelector, MockUtility.Mocks.times(1))).selectByIdsWithParentStarTrackCase((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals(StarTrack_Constants.DUPLICATE_EMAIL + caseList[0].Subject, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Subject, 'Expected Subject to have prefix DUPLICATE EMAIL -');
		System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).ResolutionCode__c, 'Expected ResolutionCode__c to be set to Closed - Duplicate');
		System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected Status to be set to Closed');
		System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, ((Case)MockUtility.mockUnitOfWorkDMLs[0]).Enquiry_Type__c, 'Expected ResolutionCode__c to be set to Other');
	}
}