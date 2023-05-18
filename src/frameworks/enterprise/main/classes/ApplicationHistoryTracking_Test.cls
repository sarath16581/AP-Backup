/**
 * Description  : Custom History Tracking based on Custom Metadata settings 
 * Author	   : Paul Perry
 **/
@isTest
public class ApplicationHistoryTracking_Test {

	@isTest private static void runTest() {
		Opportunity opp = new Opportunity(
			Id = fflib_IDGenerator.generate(Opportunity.SObjectType),
			AccountId = fflib_IDGenerator.generate(Account.SObjectType),
			StageName = 'Prospecting',
			Description = null
		);

		// =====================================
		// Stubbing
		// =====================================
		HistoryTrackingSelector mockHTSelector = (HistoryTrackingSelector)MockUtility.mockSelector(HistoryTrackingSelector.class);

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
				'		"QualifiedApiName": "Opportunity"',
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
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockHTSelector.selectByObjectApiNames((List<String>)fflib_Match.listContains(String.valueOf(Opportunity.SObjectType)))
		).thenReturn(mockedHistoryTrackingConfig);

		MockUtility.Mocks.when(
			mockHTSelector.selectByObjectApiNames((List<String>)fflib_Match.listContains(String.valueOf(PermissionSet.SObjectType)))
		).thenReturn(new Map<Id,HistoryTracking__mdt>());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Opportunity processedOpp = positiveTests(opp);
		// See if the target values are defined correctly
		System.assertEquals(System.today().addDays(1), processedOpp.CloseDate, 'Incorrectly calculated');
		System.assertEquals(
			'Old value: ' + opp.AccountId + ' - Prospecting',
			processedOpp.Description,
			'Incorrectly calculated'
		);

		processedOpp = negativeTests(opp);

		System.assertEquals(
			opp.CloseDate,
			processedOpp.CloseDate,
			'No changes should\'ve ben applied'
		);

		Test.stopTest();
	}

	private static Opportunity positiveTests(Opportunity oldOpp) {
		Opportunity newOpp = (Opportunity) JSON.deserialize(
			JSON.serialize(oldOpp),
			Opportunity.class
		);

		List<ApplicationHistoryTracking.HistoryTracker> psTrackingConfig = new List<ApplicationHistoryTracking.HistoryTracker>{
			new ApplicationHistoryTracking.HistoryTracker()
				.setFieldApiName('Name')
				.setMatchingValue('Test')
				.setOverwriteExistingValue(false)
				.setTargetField('Name')
				.setTargetValue('Test')
				.setObjectApiName(String.valueOf(PermissionSet.SObjectType))
		};

		newOpp.StageName = 'Closed Won';

		// coverage for main constructor / nothing has changed / default config
		/* Custom Metadata solution */
		ApplicationHistoryTracking.run(
			PermissionSet.SObjectType,	  // Use this SObjectType for testing as it will never have a Trigger
			new List<SObject>(),
			null
		);

		ApplicationHistoryTracking.run(
			psTrackingConfig,
			PermissionSet.SObjectType,
			new List<PermissionSet>{ new PermissionSet(Name = 'Non Matching PermissionSet')},
			null
		);

		// Simulate insert trigger: no oldMap
		ApplicationHistoryTracking.run(
			Opportunity.SObjectType,
			new List<SObject>{ newOpp },
			null
		);
			
		// Testing rules as defined above
		ApplicationHistoryTracking.run(
			Opportunity.SObjectType,
			new List<Opportunity>{ newOpp },
			new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
		);

		ApplicationHistoryTracking oppHistoryTracking = new ApplicationHistoryTracking(Opportunity.SObjectType);
		// add the merge value for TOMORROW with date for tomorrow
		oppHistoryTracking.mergeValuesDefs.put(
			'TOMORROW',
			System.today().addDays(1)
		);

		// reset the Description as this one is not overwritten once populated
		newOpp.Description = null;

		// As the config is set not to overwrite it's value, it should still say today
		oppHistoryTracking.process(
			new List<Opportunity>{ newOpp },
			new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
		);

		return newOpp;
	}

	private static Opportunity negativeTests(Opportunity oldOpp) {
		List<ApplicationHistoryTracking.HistoryTracker> incorrectConfigs = new List<ApplicationHistoryTracking.HistoryTracker>{
			new ApplicationHistoryTracking.HistoryTracker()
				.setObjectApiName(String.valueOf(Opportunity.SObjectType))
				.setFieldApiName(String.valueOf(Opportunity.StageName))
				.setMatchingValue('Closed Won')
				// .setOverwriteExistingValue(false) 					// already defaults to false
				.setTargetField(String.valueOf(Opportunity.CloseDate))  // Date field
				.setTargetValue('text test message') 					// Mismatching type / Text value
			,
			new ApplicationHistoryTracking.HistoryTracker()
				.setObjectApiName(String.valueOf(Opportunity.SObjectType))
				.setFieldApiName('NonExistingField__x')
				.setMatchingValue('Closed Won')
				.setOverwriteExistingValue(true)
				.setTargetField(String.valueOf(Opportunity.Description))
				.setTargetValue('{TODAY}')
		};

		Opportunity newOpp = (Opportunity)JSON.deserialize(
			JSON.serialize(oldOpp),
			Opportunity.class
		);
		newOpp.StageName = 'Closed Won';

		Type exceptionType;
		
		for (ApplicationHistoryTracking.HistoryTracker config :incorrectConfigs) {
			try {
				exceptionType = ApplicationHistoryTracking.HistoryTrackingException.class;
				// throws HistoryTrackingException if tracked field doesn't exists
				ApplicationHistoryTracking oppHistoryTracking = new ApplicationHistoryTracking(
					Opportunity.SObjectType,
					new List<ApplicationHistoryTracking.HistoryTracker>{ config }
				);

				oppHistoryTracking.resumeOnError = false;

				exceptionType = SObjectException.class;
				// throws SObjectException for incorrect types assignment
				oppHistoryTracking.process(
					new List<Opportunity>{ newOpp },
					new Map<Id, Opportunity>{ oldOpp.Id => oldOpp }
				);

				// This line should never be reached
				System.assert(false, 'Exception should have been thrown');
			} catch (Exception ex) {
				System.assertEquals(
					exceptionType.getName(),
					ex.getTypeName(),
					'Unexpected Exception Type'
				);
			}
		}

		return newOpp;
	}
}