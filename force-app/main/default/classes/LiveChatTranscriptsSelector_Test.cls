/**
 * @description Test class for LiveChatTranscriptsSelector
 * @author George Nguyen
 * @date 2024-09-24
 * @changelog
 * 2024-09-24	George Nguyen	created
 */
 @IsTest
 private class LiveChatTranscriptsSelector_Test {
	 /**
	  * Test:
	  *  Ensures that the selectors QueryBuilder is generating the correct output
	  */
	 @IsTest
	 private static void testEnsureQueryBuilderProducesCorrectString() {
 
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
 
		 LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance();
		 QueryBuilder qb = selector.newQueryBuilder();
		 String soql = qb.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\bfrom LiveChatTranscript\\b').matcher(soql).find(), 'Resulting query does not select from LiveChatTranscript');
 
		 LiveChatTranscriptsSelector selector1 = LiveChatTranscriptsSelector.newInstance(1);
		 QueryBuilder qb1 = selector1.newQueryBuilder();
		 String soql1 = qb1.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');
 
		 Set<SObjectField> fieldOverrides=new Set<SObjectField>{LiveChatTranscript.Id, LiveChatTranscript.ChatKey};
		 LiveChatTranscriptsSelector selector2 = LiveChatTranscriptsSelector.newInstance(1,fieldOverrides);
		 QueryBuilder qb2 = selector2.newQueryBuilder();
		 String soql2 = qb2.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\bChatKey\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');
 
		 Test.stopTest();
	 }
 
	 /**
	  * Test:
	  *  Ensures that the selectors QueryBuilder is generating the correct output
	  */
	 @IsTest
	 private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {
 
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
 
		 LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance();
		 QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{LiveChatTranscriptsSelector.Options.WITH_CASE});
		 String soql = qb.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)Case\\..*?\\bfrom LiveChatTranscript\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
 
		 Test.stopTest();
	 }
 
	 /**
	  * Executes a query to ensure it returns expected results with actual inserted data
	  */
	 @IsTest
	 private static void testSelectorIntegration() {
 
		 // =====================================
		 // Data Preparation
		 // =====================================
		 MockUtility.disableTriggerExecution();
 
		 List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		 Insert cases;
 
		 LiveChatVisitor lcv = new LiveChatVisitor();
		 insert lcv;
		 
		 LiveChatTranscript lc = new LiveChatTranscript();
		 lc.ChatKey =  '8f441452-eb7d-4142-8ae6-5b3f4a44fxxx';
		 lc.Body = 'test';
		 lc.LiveChatVisitorid = lcv.id;
		 lc.CaseId = cases[0].id;
		 insert lc;
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 // None!
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
 
		 LiveChatTranscriptsSelector selector = LiveChatTranscriptsSelector.newInstance(2);
		 List<LiveChatTranscript> results = selector.selectByIds(new Set<Object>(), new Set<Id>{lc.Id});
		 System.assertEquals(1, results.size(), 'Expected result size of 1');
		 
		 Test.stopTest();
	 }
 }