/**
* @author Naveen Rajanna
* @date 2023-08-22
* @group Tests
* @tag Email Message
* @description Test class covering EmailMessage_AI_createOutBoundMessage Trigger
* @changelog
* 2014-07-10 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* 2023-08-22 Naveen Rajanna Changed API version, removed hardcoded urls, renamed Class name to follow naming convention
*/
@IsTest
private class EmailMessageAICreateOutBoundMessage_Test {
	
	@IsTest
	private static void testAfterInsert() {
		//Disable trigger execution
		MockUtility.disableTriggerExecution();
		
		//Generate caseList and Email Messages
		Case cs = ApplicationTestDataFactory.getCases(1, false)[0];
		cs.Service_Now_Ticket_Number__c = 'REQ12345';
		insert cs;
		
		//Testing
		Test.startTest();
			EmailMessage em = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, false,true,'from@test.com','to@test.com','cc@atest.com','bcc@test.com','Subject - Inbound Email',cs.Id))[0];
			insert em;
		Test.stopTest();
		// Assert expected results
		EmailMessage retEM = [SELECT Id, Parent.Service_Now_Ticket_Number__c FROM EmailMessage WHERE Id = :em.Id];
		System.Assert.areEqual(cs.Service_Now_Ticket_Number__c, retEM.Parent.Service_Now_Ticket_Number__c, 'Outbound message condition was not met');
	}
}