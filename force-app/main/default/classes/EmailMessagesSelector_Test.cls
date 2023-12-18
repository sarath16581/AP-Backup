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
 * 2021-11-23 - Nathan Franklin - Added tests for INCOMING/OUTGOING filters
 * 2022-02-22 - Naveen Rajanna - REQ2723199	Added tests for WITH_CASE selector and selectByIdsWithParentStarTrackCase method
 * 2023-05-30 - Mahesh Parvathaneni - Added tests for selectByIdsAndParentRecordTypeId
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
		// None!
		
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
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EmailMessage\\b').matcher(soql).find(), 'Resulting query not select from EmailMessage');

		qb = selector.newQueryBuilder(new Set<Object>{EmailMessagesSelector.Options.FILTER_INCOMING});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EmailMessage\\b.*?Incoming\\s*?=\\s*?true\\b').matcher(soql).find(), 'Resulting query did not filter Incoming');

		qb = selector.newQueryBuilder(new Set<Object>{EmailMessagesSelector.Options.FILTER_OUTGOING});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EmailMessage\\b.*?Incoming\\s*?=\\s*?false\\b').matcher(soql).find(), 'Resulting query did not filter Outgoing');

		qb = selector.newQueryBuilder(new Set<Object>{EmailMessagesSelector.Options.WITH_CASE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bParent.\\b').matcher(soql).find(), 'Resulting query did not contain related Parent field');

		//Test field override
		selector = EmailMessagesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
			EmailMessage.SObjectType => new Set<SObjectField>{EmailMessage.ToAddress, EmailMessage.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ToAddress.*?\\bfrom EmailMessage\\b').matcher(soql).find(), 'Resulting query does not select ToAddress field: ' + soql);

		Test.stopTest();

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

		List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, false, true, 'test@test.com', 'amazonstrategicsupport@auspost.com.au', 'Inbound Email', cases[0].Id));
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

	@IsTest
	private static void testSelectByIdsWithParentStarTrackCase() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		//Create Case and EmailMessage
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.casestarTrackCreditDisputeRecordType;
		insert cases;

		List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, false, true, 'test@test.com', 'amazonstrategicsupport@auspost.com.au', 'Inbound Email', cases[0].Id));
		insert emailMessages;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		EmailMessagesSelector selector = EmailMessagesSelector.newInstance();
		List<EmailMessage> resultEmailMessagesList = selector.selectByIdsWithParentStarTrackCase(new Set<Id>{emailMessages[0].Id}, new Set<Object>{EmailMessagesSelector.Options.WITH_CASE});
		Test.stopTest();

		System.assertEquals(1, resultEmailMessagesList.size(), 'EmailMessage is not returned');
		System.assert(resultEmailMessagesList[0].Parent.Id != null, 'EmailMessage with related Parent is not returned');
	
	}

	@IsTest
	private static void testSelectByIdsAndParentRecordTypeId() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		//Create Case and EmailMessage
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseServiceDeliveryRecordType;
		insert cases;

		List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(1, false, true, 'test@test.com', 'amazonstrategicsupport@auspost.com.au', 'Inbound Email', cases[0].Id));
		insert emailMessages;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		EmailMessagesSelector selector = EmailMessagesSelector.newInstance();
		List<EmailMessage> resultEmailMessagesList = selector.selectByIdsAndParentRecordTypeId(new Set<Id>{emailMessages[0].Id}, new Set<Id>{ApplicationTestDataFactory.caseServiceDeliveryRecordType}, new Set<Object>{});
		Test.stopTest();

		System.assertEquals(1, resultEmailMessagesList.size(), 'EmailMessage is not returned');	
	}
}