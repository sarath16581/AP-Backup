/**
 * @changelog
 * 09-02-2023	Mahesh Parvathaneni		Updated record type for the entitlement rule
 */
@isTest
private class TestCalculateMilestoneTime {
	static testMethod void MethodTest() {
		// create milestonetype
		List<MileStoneType> milestoneTypes = new List<MileStoneType>();
		milestoneTypes.add(new MileStoneType(Name='Customer1'));
		milestoneTypes.add(new MileStoneType(Name='Customer2'));
		milestoneTypes.add(new MileStoneType(Name='Customer3'));
		milestoneTypes.add(new MileStoneType(Name='Network1'));
		milestoneTypes.add(new MileStoneType(Name='Network2'));
		milestoneTypes.add(new MileStoneType(Name='Network3'));
		milestoneTypes.add(new MileStoneType(Name='Network4'));
		milestoneTypes.add(new MileStoneType(Name='Network5'));
		milestoneTypes.add(new MileStoneType(Name='Internal1'));
		System.runAs ( new User(Id = UserInfo.getUserId()) ) {
			insert milestoneTypes;
		}
		// create escalation hierarchy
		Escalation_Hierarchy__c escHierarchy = new Escalation_Hierarchy__c(
			Name='hierarchy1', 
			Customer_Tier_1__c=1, 
			Customer_Tier_2__c=1, 
			Customer_Tier_3__c=1, 
			Facility_Tier_1__c=1, 
			Facility_Tier_2__c=1,
			Facility_Tier_3__c=1,
			Facility_Tier_4__c=1,
			Facility_Tier_5__c=1,
			Internal_Tier_1__c=1,
			Internal_Tier_2__c=1,
			Internal_Tier_3__c=1
		);
		insert escHierarchy;

		Id ssswCaseRecordTypeId = Schema.SObjectType.Entitlement_Rule__c.getRecordTypeInfosByDeveloperName().get('SSSW_Case').getRecordTypeId();
		// create entitlement rule
		List<Entitlement_Rule__c> eRules = new List<Entitlement_Rule__c>();
		String rule1 = 'customer_type__c=SMB||priority=High';
		eRules.add(new Entitlement_Rule__c(Entitlement_Rule_Name__c='Name1', Active__c=true, Rule__c=rule1, Escalation_Hierarchy__c=escHierarchy.Id, RecordTypeId=ssswCaseRecordTypeId));
		
		String rule2 = 'customer_type__c=SMB||benefit__c=2.5||cashondelivery__c=yes||closed_date__c=01-01-2001||laststatusupdate__c=01-01-2001 11:00 am||' +
					  'customer_type__c<>SMB||benefit__c<>2.5||cashondelivery__c<>yes||closed_date__c<>01-01-2001||laststatusupdate__c<>01-01-2001 11:00 am||' +
					  'benefit__c>2.5||closed_date__c>01-01-2001||laststatusupdate__c>01-01-2001 11:00 am||' +
					  'benefit__c<2.5||closed_date__c<01-01-2001||laststatusupdate__c<01-01-2001 11:00 am';	
		eRules.add(new Entitlement_Rule__c(Entitlement_Rule_Name__c='Name2', Active__c=true, Rule__c=rule2, Escalation_Hierarchy__c=escHierarchy.Id, RecordTypeId=ssswCaseRecordTypeId));
		insert eRules;
		
		// create network
		Network__c network = new Network__c(Name='test', Email_1__c='test@test.com');
	 	insert network;
	 	
		// create case
		Case newCase = TestDataProvider.createAndSaveCase();
		newCase.benefit__c=1;
		newCase.Network__c = network.Id;
		update newCase;
		
		Test.startTest();	
		CalculateMilestoneTime cls = new CalculateMilestoneTime();
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[0].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[1].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[2].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[3].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[4].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[5].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[6].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[7].Id);
		cls.calculateMilestoneTriggerTime(newCase.Id, milestoneTypes[8].Id);
		Test.stopTest();
	}

	@IsTest private static void testGetFieldsReferencedInEntitlementRulesWhenNoActiveRules() {
		Map<String, List<String>> entitlementRules = new Map<String, List<String>>();
		CalculateMilestoneTime milestoneTimeCalculator = new CalculateMilestoneTime();

		Test.startTest();

		Set<String> fieldSet = milestoneTimeCalculator.getFieldsReferencedInEntitlementRules(entitlementRules);

		Test.stopTest();

		System.assert(fieldSet != null, 'Expecting "id" field to be returned when there are no active entitlement rules');
		System.assertEquals(1, fieldSet.size(), 'Expecting "id" field to be returned when there are no active entitlement rules');
		System.assert(fieldSet.contains('id'), 'Expecting "id" field to be returned when there are no active entitlement rules');
	}

	@IsTest private static void testGetFieldsReferencedInEntitlementRulesWhenBlankRuleUnitInActiveRule() {
		Map<String, List<String>> entitlementRules = new Map<String, List<String>>();
		entitlementRules.put('rule1', new String[]{' '}); //Rule unit is blank

		CalculateMilestoneTime milestoneTimeCalculator = new CalculateMilestoneTime();

		Test.startTest();

		Set<String> fieldSet = milestoneTimeCalculator.getFieldsReferencedInEntitlementRules(entitlementRules);

		Test.stopTest();

		System.assert(fieldSet != null, 'Expecting "id" field to be returned when there are no valid rule units in active rules');
		System.assertEquals(1, fieldSet.size(), 'Expecting "id" field to be returned when there are no valid rule units in active rules');
		System.assert(fieldSet.contains('id'), 'Expecting "id" field to be returned when there are no active entitlement rules');
	}

	@IsTest private static void testGetFieldsReferencedInEntitlementRulesWhenRuleUnitIsInvalid() {
		Map<String, List<String>> entitlementRules = new Map<String, List<String>>();
		entitlementRules.put('rule1', new String[]{'not+a+valid+rule'});

		CalculateMilestoneTime milestoneTimeCalculator = new CalculateMilestoneTime();

		Test.startTest();

		Set<String> fieldSet = milestoneTimeCalculator.getFieldsReferencedInEntitlementRules(entitlementRules);

		Test.stopTest();

		System.assert(fieldSet != null, 'Expecting an empty set when there are no valid rule units in active rules');
		System.assertEquals(1, fieldSet.size(), 'Expecting an empty set when there are no valid rule units in active rules');
		System.assert(fieldSet.contains('id'), 'Expecting "id" field to be returned when there are no valid rule units in active rules');
	}

	@IsTest private static void testGetFieldsReferencedInEntitlementRulesWhenMultipleRuleUnitsInRule() {
		Map<String, List<String>> entitlementRules = new Map<String, List<String>>();
		entitlementRules.put('rule1', new String[]{'field1=abc', 'field2>10', 'field3<>30'});

		CalculateMilestoneTime milestoneTimeCalculator = new CalculateMilestoneTime();

		Test.startTest();

		Set<String> fieldSet = milestoneTimeCalculator.getFieldsReferencedInEntitlementRules(entitlementRules);

		Test.stopTest();

		System.assert(fieldSet != null, 'Should return the set of fields when there are valid rule units in active rule.');
		System.assertEquals(4, fieldSet.size(), 'Should return each field referenced in the rule plus the "id" field');
		System.assert(fieldSet.contains('id'), 'Expected field - "id" not returned in the set');
		System.assert(fieldSet.contains('field1'), 'Expected field - "field1" not returned in the set');
		System.assert(fieldSet.contains('field2'), 'Expected field - "field2" not returned in the set');
		System.assert(fieldSet.contains('field3'), 'Expected field - "field3" not returned in the set');
	}

	@IsTest private static void testGetFieldsReferencedInEntitlementRulesWhenMultipleActiveRules() {
		Map<String, List<String>> entitlementRules = new Map<String, List<String>>();
		entitlementRules.put('rule1', new String[]{'field1=abc', 'field2>10', 'field3<>30'});
		entitlementRules.put('rule2', new String[]{'field1=xyz', 'field4<100'});
		entitlementRules.put('rule3', new String[]{'id=samplecaseid', 'field4<100'});

		CalculateMilestoneTime milestoneTimeCalculator = new CalculateMilestoneTime();

		Test.startTest();

		Set<String> fieldSet = milestoneTimeCalculator.getFieldsReferencedInEntitlementRules(entitlementRules);

		Test.stopTest();

		System.assert(fieldSet != null, 'Should return the set of fields when there are valid rule units in active rules.');
		System.assertEquals(5, fieldSet.size(), 'Should return each distinct field referenced in the rule');
		System.assert(fieldSet.contains('id'), 'Expected field - "id" not returned in the set');
		System.assert(fieldSet.contains('field1'), 'Expected field - "field1" not returned in the set');
		System.assert(fieldSet.contains('field2'), 'Expected field - "field2" not returned in the set');
		System.assert(fieldSet.contains('field3'), 'Expected field - "field3" not returned in the set');
		System.assert(fieldSet.contains('field4'), 'Expected field - "field4" not returned in the set');
	}
}