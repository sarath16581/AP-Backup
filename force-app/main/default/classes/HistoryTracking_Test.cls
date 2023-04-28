/**
 * Description  : Custom History Tracking based on Custom Metadata settings 
 * Author	   : Paul Perry
 **/
@isTest
public class HistoryTracking_Test {

	private static testMethod void runTest() {
		Opportunity opp = new Opportunity(
			Id = fflib_IDGenerator.generate(Opportunity.SObjectType),
			AccountId = fflib_IDGenerator.generate(Account.SObjectType),
			StageName = 'Prospecting',
			Description = ''
		);

		Test.startTest();
		positiveTests(opp);
		negativeTests(opp);
		Test.stopTest();
	}

	private static void positiveTests(Opportunity oldOpp) {
		// =====================================
        // Stubbing
        // =====================================
		HistoryTrackingSelector mockHTSelector = (HistoryTrackingSelector)MockUtility.mockSelector(HistoryTrackingSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
		List<HistoryTracking__mdt> mockedHTConfig = (List<HistoryTracking__mdt>)JSON.deserialize(
			String.join(new String[] {
				'[{',
				'	"attributes": { "type": "HistoryTracking__mdt" },',
				'	"Id": "m1T0k000000CaXAEA0",',
				'	"MatchingValue__c": "Closed Won",',
				'	"TargetValue__c": "Old value: {Opportunity.AccountId} - {Opportunity.StageName}",',
				'   "OverwriteExistingValue__c": false,',
				'	"ObjectName__r": {',
				'		"attributes": { "type": "EntityDefinition" },',
				'		"QualifiedApiName": "Membership__c"',
				'	},',
				'	"TrackedFieldName__r": {',
				'		"attributes": { "type": "FieldDefinition" },',
				'		"QualifiedApiName": "StageName"',
				'	},',
				'	"TargetField__r": {',
				'		"attributes": { "type": "FieldDefinition" },',
				'		"QualifiedApiName": "Description"',
				'	}',
				'},{',
				'	"attributes": { "type": "HistoryTracking__mdt" },',
				'	"Id": "m1T0k000000CaWvEAK",',
				'	"MatchingValue__c": "Closed Won",',
				'	"TargetValue__c": "{TOMORROW}",',
				'   "OverwriteExistingValue__c": true,',
				'	"ObjectName__r": {',
				'		"attributes": { "type": "EntityDefinition" },',
				'		"QualifiedApiName": "Opportunity"',
				'	},',
				'	"TrackedFieldName__r": {',
				'		"attributes": { "type": "FieldDefinition" },',
				'		"QualifiedApiName": "StageName"',
				'	},',
				'	"TargetField__r": {',
				'		"attributes": { "type": "FieldDefinition" },',
				'		"QualifiedApiName": "CloseDate"',
				'	}',
				'}]'
			}, '\r\n'),
			List<HistoryTracking__mdt>.class
		);

        Map<Id,HistoryTracking__mdt> mockedHistoryTrackingConfig = new Map<Id,HistoryTracking__mdt>(mockedHTConfig);

        MockUtility.Mocks.when(mockHTSelector.selectByObjectApiNames(new Set<String>{ String.valueOf(Membership__c.SObjectType) })).thenReturn(mockedHistoryTrackingConfig);
        MockUtility.Mocks.when(mockHTSelector.selectByObjectApiNames(new Set<String>{ String.valueOf(PermissionSet.SObjectType) })).thenReturn(new Map<Id,HistoryTracking__mdt>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================

		Opportunity newOpp = (Opportunity) JSON.deserialize(
			JSON.serialize(oldOpp),
			Opportunity.class
		);

		newOpp.StageName = 'Closed Won';

		// coverage for main constructor / nothing has changed / default config
		/* Custom Metadata solution */
		HistoryTracking.run(
			PermissionSet.SObjectType,	  // Use this SObjectType for testing as it will never have a Trigger
			new List<SObject>(),
			new Map<Id,SObject>()
		);
	
		// Coverage for constructor
		HistoryTracking instanceHistoryTracking = new HistoryTracking(
			PermissionSet.SObjectType,
			new List<HistoryTracking.HistoryTracker>{
				new HistoryTracking.HistoryTracker()
					.setFieldApiName('Name')
					.setMatchingValue('Test')
					.setOverwriteExistingValue(false)
					.setTargetField('Name')
					.setTargetValue('Test')
					.setObjectApiName(String.valueOf(PermissionSet.SObjectType))
			}
		);

		// Simulate insert trigger: no oldMap
		HistoryTracking.run(
			Opportunity.SObjectType,
			new List<SObject>{ newOpp },
			null
		);
			
		// Testing rules as defined above
		HistoryTracking.run(
			Opportunity.SObjectType,
			new List<Opportunity>{ newOpp },
			new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
		);

		HistoryTracking oppHistoryTracking = new HistoryTracking(Opportunity.SObjectType);
		// add the merge value for TOMORROW with date for tomorrow
		oppHistoryTracking.mergeValuesDefs.put(
			'TOMORROW',
			System.today().addDays(1)
		);

		// As the config is set not to overwrite it's value, it should still say today
		oppHistoryTracking.process(
			new List<Opportunity>{ newOpp },
			new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
		);

		// See if the target values are defined correctly
		System.assertEquals(System.today().addDays(1), newOpp.CloseDate);
		System.assertEquals(
			'Old value: ' +
			oldOpp.AccountId +
			' - ' +
			oldOpp.StageName,
			newOpp.Description
		);
	}

	private static void negativeTests(Opportunity oldOpp) {
		// Map of config with expected Exception Type
		/* Custom Metadata Solution: 
		Map<HistoryTracking__mdt, Type> incorrectConfigs = new Map<HistoryTracking__mdt, Type>{
			// Output to Target field with incorrect Type
			new HistoryTracking__mdt(
				Id = fflib_IDGenerator.generate(HistoryTracking__mdt.SObjectType),
				FieldApiName__c = String.valueOf(Opportunity.StageName),
				MatchingValue__c = 'Closed Won',
				OverwriteExistingValue__c = false,
				TargetField__c = String.valueOf(Opportunity.CloseDate), // Date field
				TargetValue__c = 'text test message' // Mismatching type / Text value
			) => SObjectException.class,
			// Track misconfigured field
			new HistoryTracking__mdt(
				Id = fflib_IDGenerator.generate(HistoryTracking__mdt.SObjectType),
				FieldApiName__c = 'NonExistingField__x',
				MatchingValue__c = 'Closed Won',
				OverwriteExistingValue__c = false,
				TargetField__c = String.valueOf(
					Opportunity.CloseDate
				),
				TargetValue__c = '{TODAY}'
			) => HistoryTracking.HistoryTrackingException.class
		};
		*/
		Map<HistoryTracking.HistoryTracker, Type> incorrectConfigs = new Map<HistoryTracking.HistoryTracker, Type>{
			(new HistoryTracking.HistoryTracker()
				.setObjectApiName(String.valueOf(Opportunity.SObjectType))
				.setFieldApiName(String.valueOf(Opportunity.StageName))
				.setMatchingValue('Closed Won')
				// .setOverwriteExistingValue(overwriteExistingValue) // defaults to false
				.setTargetField(String.valueOf(Opportunity.CloseDate))  // Date field
				.setTargetValue('text test message') 					// Mismatching type / Text value
			) => SObjectException.class,
			(new HistoryTracking.HistoryTracker()
				.setObjectApiName(String.valueOf(Opportunity.SObjectType))
				.setFieldApiName('NonExistingField__x')
				.setMatchingValue('Closed Won')
				.setOverwriteExistingValue(true)
				.setTargetField(String.valueOf(Opportunity.Description))
				.setTargetValue('{TODAY}')
			) => HistoryTracking.HistoryTrackingException.class
		};

		Opportunity newOpp = (Opportunity)JSON.deserialize(
			JSON.serialize(oldOpp),
			Opportunity.class
		);
		newOpp.StageName = 'Closed Won';

		for (HistoryTracking.HistoryTracker config :incorrectConfigs.keySet()) {
			try {
				// throws HistoryTrackingException if tracked field doesn't exists
				HistoryTracking oppHistoryTracking = new HistoryTracking(
					Opportunity.SObjectType,
					new List<HistoryTracking.HistoryTracker>{ config }
				);

				oppHistoryTracking.resumeOnError = false;
				// throws SObjectException for incorrect types assignment
				oppHistoryTracking.process(
					new List<Opportunity>{ newOpp },
					new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
				);

				// This line should never be reached
				System.assert(false, 'Exception should have been thrown');
			} catch (Exception ex) {
				System.assertEquals(
					ex.getTypeName(),
					incorrectConfigs.get(config).getName()
				);
			}
		}
	}
}