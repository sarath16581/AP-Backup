/**
* @author Ashapriya Gadi
* @date 2021-11-23
* @group Tests
* @tag Selector
* @tag Emailmessage
* @domain Core
* @description Test class covering EmailMessageSelector
* @changelog
* 2021-11-23 - Ashapriya Gadi - Created
*/
@IsTest
private class EmailMessagesSelector_Test {
	/**
		 * Test:
		 *  Ensures that the selectors QueryBuilder is generating the correct output
		 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		
		// =====================================
		// Data Preparation
		// =====================================
		// None!-
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		EmailMessagesSelector selector = EmailMessagesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom EmailMessage\\b').matcher(soql).find(), 'Resulting query not select from EmailMessage');
	
	
	}
	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectById() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		//Create Case and EmailMessage
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseServiceDeliveryRecordType;
		insert cases;
		List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, false,true,'test@test.com','amazonstrategicsupport@auspost.com.au','Inbound Email',cases[0].Id));
		insert emailMessages;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		EmailMessagesSelector selector = EmailMessagesSelector.newInstance(EmailMessage.CreatedDate, 'asc', 1);
		List<EmailMessage> resultEmailMessagesList = selector.selectById(new Set<Id>{emailMessages[0].Id});
		Test.stopTest();
		System.assertEquals(1, resultEmailMessagesList.size(), 'EmailMessage is not returned');
	
	}
}