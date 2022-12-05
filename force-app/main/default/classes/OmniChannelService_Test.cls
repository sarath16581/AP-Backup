/**
 * @File Name		  : OmniChannelService_Test.cls
 * @Description		: 
 * @Author			 : rajesh.punjabi@mav3rik.com
 * @Group			  : 
 * @Last Modified By   : rajesh.punjabi@mav3rik.com
 * @Last Modified On   : 9/25/2019, 12:13:33 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver		 Date					 Author	  			  Modification
 *==============================================================================
 * 1.0	8/21/2019, 10:54:47 AM   rajesh.punjabi@mav3rik.com	 Initial Version
 * 
**/
@IsTest (IsParallel=true)
public class OmniChannelService_Test {

	@TestSetup
	static void setup(){
		/*** Create Case record records. */
		Case cs2 = new Case();
		cs2.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
		cs2.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
		cs2.Type = SSSWConstants.CASE_TYPE;
		cs2.Origin = SSSWConstants.CASE_ORIGIN;
		cs2.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
		cs2.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
		cs2.Priority = SSSWConstants.CASE_PRIORITY;
		cs2.Subject='Testing 5 Days SLA';
		cs2.Status=SSSWConstants.CASE_SLA_STATUS;
		cs2.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
		insert cs2;
		
		/*** Create callback records. */
		Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
		List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
		DateTime dtNow = System.now();
		callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		insert callbackRequestList;
	}

	@IsTest
	static void setOmniRoutingSecondaryPriorityForPSR() {
		Case aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(new Case(), new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-10)});
		PendingServiceRouting psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		List<PendingServiceRouting> psrs = new List<PendingServiceRouting>{psr};
		
		psr.WorkItem.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(4990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(3990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(2990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-51)});
		psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		psrs = new List<PendingServiceRouting>{psr};

		psr.WorkItem.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(4950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(3950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(2950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
	}

	@IsTest
	static void setOmniRoutingSecondaryPriorityForCase() {
		Case aCase = new Case();
		List<Case> cases = new List<Case>{aCase};
		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('1000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('5000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('1000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('4000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('2000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('3000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('2000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-10)});
		cases = new List<Case>{aCase};

		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('4990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('3990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-51)});
		cases = new List<Case>{aCase};
		
		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('4950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('3950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');

		aCase.Priority = 'blahblah';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2500', aCase.OmniRoutingSecondaryPriority__c, 'default priority for un-mapped priorities');
	}

	/*
	* Test that the user belongs to an Omni Group
	*/
	@IsTest
	static void currentUserIsPartOfOmniGroup() {
		User testUser = [SELECT Id FROM User WHERE IsActive = True AND ProfileId IN (SELECT ProfileId FROM PresenceUserConfigProfile) LIMIT 1];
		System.runAs(testUser) {
			System.assertEquals(true, OmniChannelService.currentUserIsPartOfOmniGroup, 'Should be true for users in profiles assigned to Omni');
		}
	}
	
	@IsTest
	public static void assignRemindertoAgent_Test(){
		Boolean bReturn = false;
		Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
		List<Callback_Request__c> cbrlist = [SELECT Id, OwnerId, Status__c,CreatedById FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1];
		Id HoldingQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_Callback_Reminder_Holding_Queue' LIMIT 1].Id;
		
		List<Callback_Request__c> cbrToUpdate = new List<Callback_Request__c>();	

		//.. updating owner to queue to generate pending service id
		for (Callback_Request__c cbr: cbrlist){
			cbrToUpdate.Add(new Callback_Request__c(Id=cbr.Id, OwnerId=HoldingQueueId));
		}
		if(cbrToUpdate.size()> 0){
			update cbrToUpdate;
		}
		
		for (Callback_Request__c cbr: cbrlist){
			cbr.OwnerId=Userinfo.getUserId();
		}
		
		Test.startTest();
		bReturn = OmniChannelService.assignRemindertoAgent(cbrlist);
		Test.stopTest();
		
		System.assert(bReturn, 'Reminder request assigned to agent');
	}
}