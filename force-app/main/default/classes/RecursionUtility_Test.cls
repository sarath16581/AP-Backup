/**
 * @description Test Class to cover RecursionUtility class
 * @author Nathan Franklin
 * @date 2019-02-23
 * @changelog
 * 2019-03-12  gunith.devasurendra@auspost.com.au  Updated test
 * 2023-05-04 - Nathan Franklin - Reimagine the method to get processable records
 */
@IsTest
private class RecursionUtility_Test {

	/**
	 * Scenario: Ensures the correct records are returned
	 */
	@isTest
	public static void testGetProcessableRecords() {

		SObject c1 = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan1');
		SObject c1Old = new Case(Id = '500000000000001', Subject = 'Nathan', Description = 'Nathan2');

		SObject c2 = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1');
		SObject c2Old = new Case(Id = '500000000000002', Subject = 'Nathan', Description = 'Nathan1');

		Map<Id, SObject> newMap = new Map<Id,SObject>{
			c1.Id => c1,
			c2.Id => c2
		};

		Map<Id, SObject> oldMap = new Map<Id,SObject>{
			c1Old.Id => c1Old,
			c2Old.Id => c2Old
		};

		Map<Id, RecursionUtility.RecordState> output1 = RecursionUtility.getInstance().getProcessableRecords('n', newMap, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, output1.size());
		System.assertEquals(new Set<Id>{'500000000000001'}, output1.keySet());
		System.assert(output1.get('500000000000001').changedFields.contains('Description'));
		System.assertEquals(c1Old.get('Description'), output1.get('500000000000001').previousState.get('Description'));
		System.assertEquals(c1Old.get('Subject'), output1.get('500000000000001').previousState.get('Subject'));
		System.assertEquals(c1.get('Description'), output1.get('500000000000001').record.get('Description'));
		System.assertEquals(c1.get('Subject'), output1.get('500000000000001').record.get('Subject'));

		Map<Id, RecursionUtility.RecordState> output2 = RecursionUtility.getInstance().getProcessableRecords('n', newMap, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, output2.size());

		c1.put('Subject', 'changed');
		c1.put('Description', 'changed');

		Map<Id, RecursionUtility.RecordState> output3 = RecursionUtility.getInstance().getProcessableRecords('n', newMap, oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, output3.size());
		System.assertEquals(new Set<Id>{'500000000000001'}, output3.keySet());
		System.assert(output3.get('500000000000001').changedFields.contains('Description'));
		System.assert(output3.get('500000000000001').changedFields.contains('Subject'));
		System.assertEquals('Nathan1', output3.get('500000000000001').previousState.get('Description'));
		System.assertEquals('Nathan', output3.get('500000000000001').previousState.get('Subject'));
		System.assertEquals(c1.get('Description'), output3.get('500000000000001').record.get('Description'));
		System.assertEquals(c1.get('Subject'), output3.get('500000000000001').record.get('Subject'));

	}

	/**
	 * Scenario:
	 *  Test to make sure that each time we pass a list in with the same context that it will remove any items that have already been 'processed' (passed through this method)
	 */
	public static testMethod void testUnprocessedRecords() {

		List<Case> cases = new List<Case>{
				new Case(Id = '500000000000000'),
				new Case(Id = '500000000000001'),
				new Case(Id = '500000000000002')
		};

		List<Case> unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
		System.assertEquals(3, unprocessedCases.size());

		unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
		System.assertEquals(0, unprocessedCases.size());

		cases.add(new Case(Id = '500000000000003'));
		unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
		System.assertEquals(1, unprocessedCases.size());

	}

	/**
	 * Scenario:
	 *  Test to ensure that when we are tracking specific field values, that any records that have already been processed and the tracked field values haven't changed we make sure these records aren't returned
	 */
	public static testMethod void testTrackedValues() {

		List<Case> cases = new List<Case>{
				new Case(Id = '500000000000000', ReferenceID__c = 'test123456', Subject = 'Subject #1'),
				new Case(Id = '500000000000001', ReferenceID__c = 'test123789', Subject = 'Subject #2'),
				new Case(Id = '500000000000002', ReferenceID__c = 'test34542342', Subject = 'Subject #3')
		};

		List<Case> unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
		System.assertEquals(3, unprocessedCases.size());

		unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
		System.assertEquals(0, unprocessedCases.size());

		// this test is catch the changed values (records 1 and 2 since the field values have changed)
		cases = new List<Case>{
				new Case(Id = '500000000000000', ReferenceID__c = 'test123456', Subject = 'Changed Subject #1'),
				new Case(Id = '500000000000001', ReferenceID__c = 'Changed test123789', Subject = 'Subject #2'),
				new Case(Id = '500000000000002', ReferenceID__c = 'test34542342', Subject = 'Subject #3'),
				new Case(Id = '500000000000003', ReferenceID__c = 'test4354555', Subject = 'New Subject #4')
		};

		unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
		System.assertEquals(3, unprocessedCases.size());

		Map<Id, SObject> unprocessed = new Map<Id, SObject>(unprocessedCases);
		System.assertEquals(true, unprocessed.containsKey('500000000000000'));
		System.assertEquals(true, unprocessed.containsKey('500000000000001'));
		System.assertEquals(true, unprocessed.containsKey('500000000000003'));
	}

}