/**
 * @description Test class for VoiceCallsSelector
 * @author Stevel
 * @date 2024-08-15
 * @changelog
 * 2024-08-15 - Steve L - created
 * 2024-09-24 - George Nguyen - fixed test errors
 */

 @IsTest
 private class VoiceCallsSelector_Test {
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
 
		 VoiceCallsSelector selector = VoiceCallsSelector.newInstance();
		 QueryBuilder qb = selector.newQueryBuilder();
		 String soql = qb.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select from VoiceCall');
 
		 VoiceCallsSelector selector1 = VoiceCallsSelector.newInstance(1);
		 QueryBuilder qb1 = selector1.newQueryBuilder();
		 String soql1 = qb1.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');
 
		 Set<SObjectField> fieldOverrides=new Set<SObjectField>{VoiceCall.FromPhoneNumber};
		 VoiceCallsSelector selector2 = VoiceCallsSelector.newInstance(1,fieldOverrides);
		 QueryBuilder qb2 = selector2.newQueryBuilder();
		 String soql2 = qb2.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\bFromPhoneNumber\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');
 
		 fieldOverrides = new Set<SObjectField>{VoiceCall.CallerId};
		 selector2 = VoiceCallsSelector.newInstance(fieldOverrides);
		 qb2 = selector2.newQueryBuilder();
		 soql2 = qb2.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)\\bCallerId\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');
 

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
 
		 VoiceCallsSelector selector = VoiceCallsSelector.newInstance();
		 QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{VoiceCallsSelector.Options.WITH_RECIPIENT});
		 String soql = qb.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)Recipient\\..*?\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
 
		 qb = selector.newQueryBuilder(new Set<Object>{VoiceCallsSelector.Options.WITH_CALLER});
		 soql = qb.toSoqlString();
		 System.assertEquals(true, Pattern.compile('(?is)Caller\\..*?\\bfrom VoiceCall\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		 qb = selector.newQueryBuilder(new Set<Object>{VoiceCallsSelector.Options.ORDER_BY_CREATED_DATE_ASC});
		 soql = qb.toSoqlString();
		 System.assertEquals(true, soql.contains('CreatedDate ASC'), 'Resulting query does not have CreatedDate ASC');
 
 
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
 
		 VoiceCall vc = new VoiceCall(
			 CallCenterId = null, 
			 VendorType = 'ContactCenter', 
			 CallType = 'Inbound',
			 FromPhoneNumber = '+19999999999', 
			 ToPhoneNumber = '+19999999999',
			 CallStartDateTime = System.now().addMinutes( - 3 ),
			 CallEndDateTime = System.now(),
			 CallDisposition = 'completed',
			 relatedrecordid = cases[0].id
		 );
		 insert vc;
 
		 // =====================================
		 // Stubbing
		 // =====================================
		 // None!
 
		 // =====================================
		 // Testing
		 // =====================================
		 Test.startTest();
 
		 VoiceCallsSelector selector = VoiceCallsSelector.newInstance(2);
		 List<VoiceCall> results = selector.selectByIds(new Set<Object>(), new Set<Id>{vc.Id});
		 System.assertEquals(1, results.size(), 'Expected result size of 1');
		 results = selector.selectByRelatedRecordIds(new Set<Id>{vc.RelatedRecordId}, new Set<Object>());
		 System.assertEquals(1, results.size(), 'Expected result size of 1');
		 Test.stopTest();
	 }
 }