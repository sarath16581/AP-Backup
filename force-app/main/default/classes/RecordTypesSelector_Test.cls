/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag RecordType SObject
 * @domain Core
 * @description Test Class covering RecordTypesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Added test for selectByName
 * 2024-08-30 - Nick Guia 	- added test coverage for overloaded (SObjectType) methods
 * 							- added parallel = true annotation
 * 							- updated class to private; API version
 */
@IsTest(isParallel=true)
private class RecordTypesSelector_Test {

	/**
	 * Test:
	 *  Testing selectBy[Method] methods.
	 */
	@IsTest
	public static void testSelectByMethods() {

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

		RecordTypesSelector selector = RecordTypesSelector.newInstance();
		Map<Id, RecordType> queryResults = selector.selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'});
		Assert.areEqual(1, queryResults.size(), 'Unexpected number of Recordtypes');

		queryResults = selector.selectByName('Case', new Set<String>{'Delivery Enquiry'});
		Assert.areNotEqual(0, queryResults.size(), 'Unexpected number of Recordtypes');

		queryResults = selector.selectByDeveloperNameLike('Case', 'SSSW');
		Assert.areNotEqual(0, queryResults.size(), 'Unexpected number of Recordtypes');

		Test.stopTest();
	}

	/**
	 * @description mainly for test coverage on the inherited methods
	 */
	@isTest
	static void shouldReturnIneritedProperties() {

		// GIVEN
		RecordTypesSelector selector;
		SObjectType typeRes;
		Set<SObjectField> fieldRes;
		
		Test.startTest();

		// WHEN
		selector = RecordTypesSelector.newInstance();
		typeRes =  selector.getSObjectType();
		fieldRes = selector.getSObjectFieldList();

		Test.stopTest();

		Assert.areEqual(RecordType.getSObjectType(), typeRes, 'Invalid SObjectType');
		Assert.isNotNull(fieldRes, 'Unexpected null result');
	}

	/**
	 * @description test that we can pull Record Types from Case object
	 * using Record Type DeveloperNames
	 */
	@isTest
	static void shouldSelectByDeveloperNameWithSObjectType() {
		
		// GIVEN
		Set<String> rtDeveloperNames = new Set<String> {
			'SSSWDelivery',
			'SSSWGeneralEnquiry'
		};
		RecordTypesSelector selector = RecordTypesSelector.newInstance();
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByDeveloperName(Case.SObjectType, rtDeveloperNames);

		Test.stopTest();

		// THEN
		Assert.areEqual(2, rtDeveloperNames.size(), 'Unexpected number of Recordtypes');
	}

	/**
	 * @description test that we can pull Record Types from Case object
	 * using Record Type Names
	 */
	@isTest
	static void shouldSelectByNameWithSObjectType() {
		
		// GIVEN
		Set<String> rtNames = new Set<String> {
			'SSSW Delivery',
			'SSSW General Enquiry'
		};
		RecordTypesSelector selector = RecordTypesSelector.newInstance();
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByName(Case.SObjectType, rtNames);

		Test.stopTest();

		// THEN
		Assert.areEqual(2, rtNames.size(), 'Unexpected number of Recordtypes');
	}

	/**
	 * @description grabs all Case recordtypes that start with 'SSW'.
	 * Assumption: such recordtypes exist
	 * Note: the test method wouldn't check the actual number since they can change
	 */
	@isTest
	static void shouldSelectByDeveloperNameLikeWithString() {
		
		// GIVEN
		String devName = 'SSW';
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', devName);

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}
	

	/**
	 * @description grabs all Case recordtypes that start with 'SSW'.
	 * Assumption: such recordtypes exist
	 * Note: the test method wouldn't check the actual number since they can change
	 */
	@isTest
	static void shouldSelectByDeveloperNameLikeWithSObjectType() {
		
		// GIVEN
		String devName = 'SSW';
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByDeveloperNameLike(Case.SObjectType, devName);

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}

	/**
	 * @description grabs all Case recordtypes that start with 'SSW'.
	 * Assumption: such recordtypes exist
	 * Note: the test method wouldn't check the actual number since they can change
	 */
	@isTest
	static void shouldSelectByDeveloperNamesLikeWithString() {
		
		// GIVEN
		Set<String> devName = new Set<String>{'SSW'};
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByDeveloperNamesLike('Case', devName);

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}

	/**
	 * @description grabs all Case recordtypes that start with 'SSW'.
	 * Assumption: such recordtypes exist
	 * Note: the test method wouldn't check the actual number since they can change
	 */
	@isTest
	static void shouldSelectByDeveloperNamesLikeWithSObjectType() {
		
		// GIVEN
		Set<String> devName = new Set<String>{'SSW'};
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectByDeveloperNamesLike(Case.SObjectType, devName);

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}

	/**
	 * @description test that getting all recordtypes for Case object
	 * results in a non-null map
	 */
	@isTest
	static void shouldSelectBySObjectWithSObjectType() {
		
		// GIVEN
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectBySObject(Case.SObjectType);

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}

	/**
	 * @description test that the selector throws an exception when
	 * provided by an unrecognized SObject string name
	 */
	@isTest
	static void shouldThrowExceptionWhenSObjectNameUnknown() {

		// GIVEN
		String someRandomStr = 'ImAnSObject';

		Test.startTest();

		// WHEN
		try {
			RecordTypesSelector.newInstance().convertNameToType(someRandomStr);
			Assert.fail('Unable to throw an exception');
		} catch(RecordTypesSelector.RecordTypesSelectorException e) {
			// THEN
			Assert.isTrue(true, 'Expected exception type');
		} catch(Exception e) {
			Assert.fail('Unexpected exception type');
		}

		Test.stopTest();
	}

	/**
	 * @description test that getting all recordtypes for Case object
	 * results in a non-null map when provided with a String parameter
	 */
	@isTest
	static void shouldSelectBySObjectWithSObjectName() {

		// GIVEN
		Map<Id, RecordType> output;

		Test.startTest();

		// WHEN
		output = RecordTypesSelector.newInstance().selectBySObject('Case');

		Test.stopTest();

		// THEN
		Assert.isNotNull(output, 'Unexpected null output');
	}
}