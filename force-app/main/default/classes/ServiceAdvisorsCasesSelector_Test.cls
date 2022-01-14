/**
* @author Ashapriya Gadi
* @date 2021-11-23
* @group Tests
* @tag Selector
* @tag Cases
* @domain Core
* @description Test class covering ServiceAdvisorsCasesSelector
* @changelog
* 2021-11-23 - Ashapriya Gadi - Created
*/
@IsTest
private class ServiceAdvisorsCasesSelector_Test {
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
		ServiceAdvisorsCasesSelector selector = ServiceAdvisorsCasesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Case\\b').matcher(soql).find(), 'Resulting query select not from Case');
	}
	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorByIdAndName() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		//create system support user
		User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
		insert uRecord;
		//Create Cases
		System.runAs(uRecord) {
			List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
			cases[0].RecordTypeId = ApplicationTestDataFactory.caseServiceDeliveryRecordType;
			insert cases;
			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			ServiceAdvisorsCasesSelector selector = ServiceAdvisorsCasesSelector.newInstance(0, new Set<SObjectField>{
					Case.Id, Case.EntitlementId, Case.BusinessHoursId
			});
			List<Case> results = selector.selectByIdsAndEntitlementIdAndCreatedBy(new Set<Id>{cases[0].Id}, null, uRecord.id);
			Test.stopTest();
			System.assertEquals(1, results.size(), 'Cases are not returned');
		}
	}
}