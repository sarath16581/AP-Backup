/**
 * @description Test Class to cover ApplicationRecursion class
 * @author Nathan Franklin
 * @date 2023-05-05
 * @changelog
 */
@IsTest
private class ApplicationRecursion_Test {

	/**
	 * Scenario: Ensures the correct records are returned during an exclusive onupdate scenario
	 */
	@isTest
	public static void testEnsureOnUpdateIsolatedTriggerCallReturnsRecordsForProcessing() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case1OldState = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan2', Origin = 'Web');

		Case case2 = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2OldState = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		Map<Id, SObject> newMap = new Map<Id,SObject>{
			case1.Id => case1,
			case2.Id => case2
		};

		Map<Id, SObject> oldMap = new Map<Id,SObject>{
			case1OldState.Id => case1OldState,
			case2OldState.Id => case2OldState
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, changedRecords.size());
		System.assertEquals(case1.Id, changedRecords[0].record.Id);
		System.assertEquals(new Set<String>{'Description'}, changedRecords[0].changedFields);

		System.assertEquals(case1OldState.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case1OldState.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(case1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(case1.Subject, ((Case)changedRecords[0].record).Subject);

		// Testing second pass - no changes means, no record returned
		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// Third pass - making changes to both records passed in
		Case thirdPassCase1 = case1.clone(true);
		Case thirdPassCase2 = case2.clone(true);
		thirdPassCase1.put('Subject', 'changed');
		thirdPassCase1.put('Description', 'changed');
		thirdPassCase2.put('Subject', 'changed');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{thirdPassCase1, thirdPassCase2}, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(2, changedRecords.size());
		System.assertEquals(case1.Id, changedRecords[0].record.Id);
		System.assertEquals(case2.Id, changedRecords[1].record.Id);

		// verifying case1
		System.assertEquals(2, changedRecords[0].changedFields.size());
		System.assert(changedRecords[0].changedFields.contains('Description'));
		System.assert(changedRecords[0].changedFields.contains('Subject'));

		System.assertEquals(case1.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case1.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(thirdPassCase1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(thirdPassCase1.Subject, ((Case)changedRecords[0].record).Subject);

		// verifying case2
		System.assertEquals(1, changedRecords[1].changedFields.size());
		System.assert(changedRecords[1].changedFields.contains('Subject'));

		System.assertEquals(case2.Subject, changedRecords[1].previousState.get('Subject'));
	
		System.assertEquals(thirdPassCase2.Subject, ((Case)changedRecords[1].record).Subject);

	}

	/**
	 * Scenario: Ensures the correct records are returned during a hybrid onafterinsert onafterupdate execution cycle
	 * It's expected that on after insert should return all records and the records returned in subsequent calls should be based on changes to the current values
	 */
	@isTest
	public static void testEnsureHybridCycleTriggerCallReturnsRecordsForProcessing() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case1OldState = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan2', Origin = 'Web');

		Case case2 = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2OldState = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		Map<Id, SObject> newMap = new Map<Id,SObject>{
			case1.Id => case1,
			case2.Id => case2
		};

		Map<Id, SObject> oldMap = new Map<Id,SObject>{
			case1OldState.Id => case1OldState,
			case2OldState.Id => case2OldState
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass - onAfterInsert (note the NULL for oldMap)
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', newMap.values(), null, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(2, changedRecords.size());
		System.assertEquals(case1.Id, changedRecords[0].record.Id);
		System.assertEquals(case2.Id, changedRecords[1].record.Id);

		// case1
		// the previous state should contain null since it's an on after insert scenario
		System.assertEquals(null, changedRecords[0].previousState.get('Description'));
		System.assertEquals(null, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(case1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(case1.Subject, ((Case)changedRecords[0].record).Subject);

		// case2
		// the previous state should contain null since it's an on after insert scenario
		System.assertEquals(null, changedRecords[1].previousState.get('Description'));
		System.assertEquals(null, changedRecords[1].previousState.get('Subject'));
		
		System.assertEquals(case2.Description, ((Case)changedRecords[1].record).Description);
		System.assertEquals(case2.Subject, ((Case)changedRecords[1].record).Subject);

		// Second pass - making changes to one record passed in
		Case thirdPassCase1 = case1.clone(true);
		thirdPassCase1.put('Subject', 'changed');
		thirdPassCase1.put('Description', 'changed');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{thirdPassCase1, case2}, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, changedRecords.size());
		System.assertEquals(case1.Id, changedRecords[0].record.Id);

		// verifying case1
		System.assertEquals(2, changedRecords[0].changedFields.size());
		System.assert(changedRecords[0].changedFields.contains('Description'));
		System.assert(changedRecords[0].changedFields.contains('Subject'));

		System.assertEquals(case1.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case1.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(thirdPassCase1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(thirdPassCase1.Subject, ((Case)changedRecords[0].record).Subject);

	}


	/**
	 * Scenario: When a piece of code is not monitoring certain fields that have changed, then processable records should not be returned
	 */
	@isTest
	public static void testEnsureChangesToNonMonitoredFieldsAreIgnored() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case1OldState = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Phone');

		Case case2 = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2OldState = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		Map<Id, SObject> newMap = new Map<Id,SObject>{
			case1.Id => case1,
			case2.Id => case2
		};

		Map<Id, SObject> oldMap = new Map<Id,SObject>{
			case1OldState.Id => case1OldState,
			case2OldState.Id => case2OldState
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// Second pass - making changes to one record passed in
		Case thirdPassCase1 = case1.clone(true);
		thirdPassCase1.put('Origin', 'Chat');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{thirdPassCase1, case2}, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

	}

}