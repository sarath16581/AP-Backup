@isTest
public with sharing class CSQCloneService_Test {
	@isTest
	public static void testCSQCloneService() {
		fflib_ApexMocks mocks = new fflib_ApexMocks();

		// Construct CSQ record with embedded child records
		Id freightMock1Id = fflib_IDGenerator.generate(Freight_Offering__c.SObjectType);
		Id freightMock2Id = fflib_IDGenerator.generate(Freight_Offering__c.SObjectType);
		Id fakeOppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
		Id fakeCSQId = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType);

		Map<Id,Customer_Scoping_Questionnaire__c> csqMocksMap = new Map<Id,Customer_Scoping_Questionnaire__c>(
			assembleChildRelationships(
				new Map<Customer_Scoping_Questionnaire__c,Map<SObjectField,List<SObject>>>{
					new Customer_Scoping_Questionnaire__c(
						Id = fakeCSQId,
						Opportunity__c = fakeOppId
					) => new Map<SObjectField,List<SObject>>{
						// Add related Pick-up location records
						Pick_Up_Location__c.CSQ__c => new List<Pick_Up_Location__c>{
							new Pick_Up_Location__c(
								Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
								Freight_Offering__c = freightMock1Id
							),
							new Pick_Up_Location__c(
								Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
								Freight_Offering__c = freightMock2Id
							)
						},
						// Add related Freight Offering records
						Freight_Offering__c.Customer_Scoping_Questionnaire__c => new List<Freight_Offering__c>{
							new Freight_Offering__c(
								Id = freightMock1Id,
								Product_Description__c = 'Test 1'
							),
							new Freight_Offering__c(
								Id = freightMock2Id,
								Product_Description__c = 'Test 2'
							)
						}
					}
				}
			)
		);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		CSQCloneServiceTest csqCloneUtil;
		csqCloneUtil = new CSQCloneServiceTest(csqMocksMap.values());
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert(
			(List<SObject>)fflib_Match.anyObject(),
			fflib_Match.anyBoolean()
		)).thenReturn(csqCloneUtil.saveResults);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		CSQCloneService.CloneResult result = csqCloneUtil.execute(csqMocksMap.keySet());

		System.assertEquals(true, result.success, 'Shoud return success');
		System.assert(result.dmlResults[0].errors.isEmpty(), 'No errors expected');
		System.assertNotEquals(null, result.dmlResults[0].sourceId, 'Shoud\'ve been populated');
		System.assertNotEquals(null, result.dmlResults[0].targetId, 'Shoud\'ve been populated');
		
		fflib_ArgumentCaptor insertCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 3)).dmlInsert(
			(List<SObject>)insertCaptor.capture(),
			fflib_Match.anyBoolean()
		);

		// Use JSON Serialisation roundtrip to prevent invalid runtime conversion issue
		List<List<SObject>> captorResults = (List<List<SObject>>)JSON.deserialize(
			JSON.serialize(insertCaptor.getAllValues()),
			List<List<SObject>>.class
		);
		List<SObject> insertedList = new List<SObject>();

		for (List<SObject> captorResult :captorResults) {
			insertedList.addAll(captorResult);
		}

		// test the negative scenario
		csqCloneUtil.positiveTest = false;
		result = csqCloneUtil.execute(csqMocksMap.keySet());
		Test.stopTest();	

		Customer_Scoping_Questionnaire__c sourceCSQ = csqMocksMap.get(fakeCSQId);
		Customer_Scoping_Questionnaire__c clonedCSQ = (Customer_Scoping_Questionnaire__c)csqCloneUtil.cloneBySource.get(fakeCSQId);
		System.assert(clonedCSQ != null, 'Cloning failed');
		System.assertEquals(false, result.success, 'Commit should\'ve been rolled back to savepoint');
		System.assertEquals(sourceCSQ.Opportunity__c, clonedCSQ.Opportunity__c, 'Cloning failed');
		System.assertEquals(fakeOppId, clonedCSQ.Opportunity__c, 'Incorrect Value');
		
		Map<SObjectType,List<SObject>> mappedResult = new Map<SObjectType,List<SObject>>();
		for (SObject clone :insertedList) {
			SObjectType sObjType = clone.getSObjectType();

			if (!mappedResult.containsKey(sObjType)) {
				mappedResult.put(sObjType, new List<SObject>());
			}			

			mappedResult.get(sObjType).add(clone);
		}

		System.assertEquals(1, mappedResult.get(Customer_Scoping_Questionnaire__c.SObjectType).size(), 'Incorrect amount of records');
		System.assertEquals(2, mappedResult.get(Pick_Up_Location__c.SObjectType).size(), 'Incorrect amount of records');
		System.assertEquals(2, mappedResult.get(Freight_Offering__c.SObjectType).size(), 'Incorrect amount of records');
	}

	@isTest
	public static void testGeneric() {
		SObjectType csqSObjType = Customer_Scoping_Questionnaire__c.SObjectType;
		String query = CSQCloneService.getQueryBuilder(
			csqSObjType, 
			new Set<SObjectField>{ Customer_Scoping_Questionnaire__c.Name },
			CSQCloneService.csqChildRelations.get(csqSObjType).keySet()
		)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition('Id IN :recordIds'))
			.endConditions()
			.addOrderDesc('Id')
			.toSoqlString();
		
		System.debug(query);
		System.assert(query.contains('Locations__r'), 'Missing relationship');
	}

	/***
	 * @param childMapBySObj Map of Child records by child-parent relationship field, mapped by parent SObject record
	 * @return `List<SObject>` List of records with embedded provided child records
	 */
	public static List<Customer_Scoping_Questionnaire__c> assembleChildRelationships(Map<Customer_Scoping_Questionnaire__c,Map<SObjectField,List<SObject>>> childMapBySObj) {
		List<Customer_Scoping_Questionnaire__c> result = new List<Customer_Scoping_Questionnaire__c>();

		for (Customer_Scoping_Questionnaire__c record :childMapBySObj.keySet()) {
			Map<SObjectField,List<SObject>> childRelationsMap = childMapBySObj.get(record);
			// Add each list of child records to its parent SObject
			for (SObjectField parentReferenceField :childRelationsMap.keySet()) {
				record = ((List<Customer_Scoping_Questionnaire__c>)fflib_ApexMocksUtils.makeRelationship(
					List<Customer_Scoping_Questionnaire__c>.class,
					new List<Customer_Scoping_Questionnaire__c>{ record },
					parentReferenceField,
					new List<List<SObject>>{ childRelationsMap.get(parentReferenceField) }
				))[0];	
			}

			result.add(record);
		}

		return result;
	}

	public class CSQCloneServiceTest extends CSQCloneService {
		List<SObject> mockRecords;
		Boolean positiveTest;
		public Database.SaveResult[] saveResults;

		public CSQCloneServiceTest(List<SObject> mockRecords) {
			this.cloneOptions = new Set<String>{ 
				CSQCloneService.OPTION_CLONE_REAPPROVE
			};
			this.positiveTest = true;
			this.mockRecords = mockRecords;
			saveResults = new List<Database.SaveResult>();
		}

		public override List<SObject> getSourceRecords(Set<Id> recordIds, SObjectType sObjType) {
			return this.mockRecords;
		}

		public override void afterCommit(Map<SObject,SObject> clonedBySource) {
			super.afterCommit(clonedBySource);

			for (SObject record :clonedBySource.values()) {
				record.Id = generateId(record.getSObjectType());
			}
		}
		
		public Id generateId(SObjectType sObjType) {
			Id result = fflib_IDGenerator.generate(sObjType);
	
			Database.SaveResult saveResult = (Database.SaveResult)JSON.deserialize(
				'{ "success":' + String.valueOf(positiveTest) + ', "id":"' + result + '" }',
				Database.SaveResult.class
			);
	
			if (saveResults.isEmpty()) {
				saveResults.add(saveResult);
			} else {
				saveResults.add(0, saveResult);
			}
	
			return result;
		}
	}
}