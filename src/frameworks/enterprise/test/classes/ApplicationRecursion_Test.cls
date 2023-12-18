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
		System.assertEquals(new Set<SObjectField>{Case.Description}, changedRecords[0].changedFields);

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
		System.assert(changedRecords[0].changedFields.contains(Case.Description));
		System.assert(changedRecords[0].changedFields.contains(Case.Subject));

		System.assertEquals(case1.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case1.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(thirdPassCase1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(thirdPassCase1.Subject, ((Case)changedRecords[0].record).Subject);

		// verifying case2
		System.assertEquals(1, changedRecords[1].changedFields.size());
		System.assert(changedRecords[1].changedFields.contains(Case.Subject));

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
		System.assert(changedRecords[0].changedFields.contains(Case.Description));
		System.assert(changedRecords[0].changedFields.contains(Case.Subject));

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

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Subject'));

		// Second pass - making changes to one record passed in
		Case thirdPassCase1 = case1.clone(true);
		thirdPassCase1.put('Origin', 'Chat');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{thirdPassCase1, case2}, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Subject'));

	}



	/**
	 * Scenario: Handles the usage of on before insert scenario where the recursion method is called from on before insert then subsequently from on after insert
	 */
	@isTest
	public static void testEnsureOnBeforeInsertOnAfterInsertTriggerCallReturnsRecordsForProcessing() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		List<Case> cases = new List<Case>{case1, case2};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass - onAfterInsert (note the NULL for oldMap)
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', cases, null, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(2, changedRecords.size());

		// check the internal state of our variables inside the class
		System.assertEquals(2, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[0].get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[0].get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[1].get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[1].get('Subject'));
		System.assertEquals(0, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());

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

		// in between before insert and after insert, Salesforce internal processes will update any of the instances of the SObjects we are storing from the on before insert iteration
		// here we mimic this process by setting an id for these records, updating these should also update the stored values stored by the recursion method
		case1.Id = '500000000000001';
		case2.Id = '500000000000002';

		// Second pass - making changes to one record passed in
		Case secondPassCase1 = case1.clone(true);
		secondPassCase1.put('Subject', 'changed');
		secondPassCase1.put('Description', 'changed');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{secondPassCase1, case2}, null, new Set<SObjectField>{Case.Subject, Case.Description});

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(secondPassCase1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(secondPassCase1.Id).get('Description'));
		System.assertEquals(secondPassCase1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(secondPassCase1.Id).get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Subject'));

		System.assertEquals(1, changedRecords.size());
		System.assertEquals(case1.Id, changedRecords[0].record.Id);

		// verifying case1
		System.assertEquals(2, changedRecords[0].changedFields.size());
		System.assert(changedRecords[0].changedFields.contains(Case.Description));
		System.assert(changedRecords[0].changedFields.contains(Case.Subject));

		System.assertEquals(case1.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case1.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(secondPassCase1.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(secondPassCase1.Subject, ((Case)changedRecords[0].record).Subject);

		// Another pass - making changes to the second record now
		Case thirdPassCase2 = case2.clone(true);
		thirdPassCase2.put('Subject', 'changed');
		thirdPassCase2.put('Description', 'changed');

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{secondPassCase1, thirdPassCase2}, null, new Set<SObjectField>{Case.Subject, Case.Description});

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(secondPassCase1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(secondPassCase1.Id).get('Description'));
		System.assertEquals(secondPassCase1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(secondPassCase1.Id).get('Subject'));
		System.assertEquals(thirdPassCase2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(thirdPassCase2.Id).get('Description'));
		System.assertEquals(thirdPassCase2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(thirdPassCase2.Id).get('Subject'));

		System.assertEquals(1, changedRecords.size());
		System.assertEquals(case2.Id, changedRecords[0].record.Id);

		// verifying case2
		System.assertEquals(2, changedRecords[0].changedFields.size());
		System.assert(changedRecords[0].changedFields.contains(Case.Description));
		System.assert(changedRecords[0].changedFields.contains(Case.Subject));

		System.assertEquals(case2.Description, changedRecords[0].previousState.get('Description'));
		System.assertEquals(case2.Subject, changedRecords[0].previousState.get('Subject'));
		
		System.assertEquals(thirdPassCase2.Description, ((Case)changedRecords[0].record).Description);
		System.assertEquals(thirdPassCase2.Subject, ((Case)changedRecords[0].record).Subject);

	}

	/**
	 * Scenario: Handles the usage of on before insert scenario where the recursion method is called from on before insert then subsequently from on before update (with an old state set with no changes)
	 */
	@isTest
	public static void testEnsureOnBeforeInsertOnBeforeUpdateTriggerCallReturnsRecordsForProcessing() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		List<Case> cases = new List<Case>{case1, case2};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass - onAfterInsert (note the NULL for oldMap)
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', cases, null, new Set<SObjectField>{Case.Subject, Case.Description});

		// check the internal state of our variables inside the class
		System.assertEquals(2, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[0].get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[0].get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[1].get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[1].get('Subject'));
		System.assertEquals(0, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());

		System.assertEquals(2, changedRecords.size());

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

		// in between before insert and after insert, Salesforce internal processes will update any of the instances of the SObjects we are storing from the on before insert iteration
		// here we mimic this process by setting an id for these records, updating these should also update the stored values stored by the recursion method
		case1.Id = '500000000000001';
		case2.Id = '500000000000002';
		
		Case case1Old = case1.clone(true);
		Case case2Old = case2.clone(true);

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{case1, case2}, new Map<Id, Case>{case1Old.Id => case1Old, case2Old.Id => case2Old}, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Subject'));

	}

	/**
	 * Scenario: When a method is modifying values it's modifying, sometimes the tracked state needs to be update to prevent subsequent processing on next recursion iteration
	 * 				Test to make sure record state can be updated and no further processing will happen when the getprocessable records method is invoked again
	 */
	@isTest
	public static void testEnsureWhenStateIsManuallyModifiedOnUpdateDuplicateProcessingIsPrevented() {

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
		
		((Case)changedRecords[0].record).Subject = '1'; // this will also set case1.Subject, since it's a reference

		ApplicationRecursion.getInstance().updateRecordState('mycontext1', changedRecords, new Set<SObjectField>{Case.Subject, Case.Description});

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
		System.assertEquals(case1.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Description'));
		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case1.Id).get('Subject'));
		System.assertEquals(case2.Description, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Description'));
		System.assertEquals(case2.Subject, ApplicationRecursion.getInstance().stateStore.get('mycontext1').get(case2.Id).get('Subject'));

	}

	/**
	 * Scenario: When a method is modifying values it's modifying, sometimes the tracked state needs to be update to prevent subsequent processing on next recursion iteration
	 * 				Test to make sure record state can be updated and no further processing will happen when the getprocessable records method is invoked again
	 */
	@isTest
	public static void testEnsureWhenStateIsManuallyModifiedOnBeforeInsertDuplicateProcessingIsPrevented() {

		// =====================================
		// Data Preparation
		// =====================================
		Case case1 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');
		Case case2 = new Case(Subject = 'Nathan', Description = 'Nathan1', Origin = 'Web');

		List<Case> cases = new List<Case>{case1, case2};

		// =====================================
		// Stubbing
		// =====================================
		// None!


		// =====================================
		// Testing
		// =====================================

		// Testing first pass - onAfterInsert (note the NULL for oldMap)
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', cases, null, new Set<SObjectField>{Case.Subject, Case.Description});

		// check the internal state of our variables inside the class
		System.assertEquals(2, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1').size());
		System.assertEquals(2, changedRecords.size());

		((Case)changedRecords[0].record).Subject = '1'; // will also update case1 variable

		ApplicationRecursion.getInstance().updateRecordState('mycontext1', changedRecords, new Set<SObjectField>{Case.Subject, Case.Description});

		System.assertEquals(case1.Subject, ApplicationRecursion.getInstance().sobjectStateStoreStaticValuesMapStore.get('mycontext1')[0].get('Subject'));

		// in between before insert and after insert, Salesforce internal processes will update any of the instances of the SObjects we are storing from the on before insert iteration
		// here we mimic this process by setting an id for these records, updating these should also update the stored values stored by the recursion method
		case1.Id = '500000000000001';
		case2.Id = '500000000000002';
		
		Case nextPassCase1 = case1.clone(true);
		Case nextPassCase2 = case2.clone(true);

		changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('mycontext1', new List<SObject>{nextPassCase1, nextPassCase2}, null, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, changedRecords.size());

		// check the internal state of our variables inside the class
		System.assertEquals(0, ApplicationRecursion.getInstance().sobjectStateStore.get('mycontext1').size());
		System.assertEquals(2, ApplicationRecursion.getInstance().stateStore.get('mycontext1').size());
	}

}