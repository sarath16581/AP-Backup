/**
 * @description Test Class to cover ApplicationRecursion class
 * @author Nathan Franklin
 * @date 2023-05-05
 * @changelog
 */
@IsTest
private class ApplicationRecursion_Test {

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

		Map<Id, ApplicationRecursion.RecordState> output1 = ApplicationRecursion.getInstance().getProcessableRecords('n', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, output1.size());
		System.assertEquals(new Set<Id>{'500000000000001'}, output1.keySet());
		System.assert(output1.get('500000000000001').changedFields.contains('Description'));
		System.assertEquals(c1Old.get('Description'), output1.get('500000000000001').previousState.get('Description'));
		System.assertEquals(c1Old.get('Subject'), output1.get('500000000000001').previousState.get('Subject'));
		System.assertEquals(c1.get('Description'), output1.get('500000000000001').record.get('Description'));
		System.assertEquals(c1.get('Subject'), output1.get('500000000000001').record.get('Subject'));

		Map<Id, ApplicationRecursion.RecordState> output2 = ApplicationRecursion.getInstance().getProcessableRecords('n', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(0, output2.size());

		c1.put('Subject', 'changed');
		c1.put('Description', 'changed');

		Map<Id, ApplicationRecursion.RecordState> output3 = ApplicationRecursion.getInstance().getProcessableRecords('n', newMap.values(), oldMap, new Set<SObjectField>{Case.Subject, Case.Description});
		System.assertEquals(1, output3.size());
		System.assertEquals(new Set<Id>{'500000000000001'}, output3.keySet());
		System.assert(output3.get('500000000000001').changedFields.contains('Description'));
		System.assert(output3.get('500000000000001').changedFields.contains('Subject'));
		System.assertEquals('Nathan1', output3.get('500000000000001').previousState.get('Description'));
		System.assertEquals('Nathan', output3.get('500000000000001').previousState.get('Subject'));
		System.assertEquals(c1.get('Description'), output3.get('500000000000001').record.get('Description'));
		System.assertEquals(c1.get('Subject'), output3.get('500000000000001').record.get('Subject'));

	}

}