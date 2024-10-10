/**
* @description Test Class for TIBCOArticleSubscriptionSchema
* @author Seth Heang
* @date 2024-09-20
* @changelog
* 2024-09-20 - Seth Heang - created
**/
@IsTest
private class TIBCOArticleSubscriptionSchemaTest {

	/**
	 * Test and validate the schema attributes for AggregateResult class
	 */
	@IsTest
	static void testSchemaAttributesForAggregateResult() {
		// Create an instance of AggregateResult
		TIBCOArticleSubscriptionSchema.AggregateResult aggregateResult = new TIBCOArticleSubscriptionSchema.AggregateResult();

		// Test default values (fieldsToNull should be null or empty, Id should be null, and anyElement should be null)
		Assert.isTrue(aggregateResult.fieldsToNull == null || aggregateResult.fieldsToNull.size() == 0, 'fieldsToNull should be null or empty');
		Assert.areEqual(null, aggregateResult.Id, 'Id should be null');
		Assert.areEqual(null, aggregateResult.anyElement, 'anyElement should be null');

		// Modify and test the fields
		aggregateResult.fieldsToNull = new String[] {'Field1', 'Field2'};
		Id caseId = ApplicationTestDataFactory.getCases(1, true)[0].Id;
		aggregateResult.Id = caseId;

		// Check the modified values
		Assert.areEqual(2, aggregateResult.fieldsToNull.size(), 'fieldsToNull should have 2 elements');
		Assert.areEqual(caseId, aggregateResult.Id, 'Id should be set to the correct value');
	}

	/**
	 * Test and validate the schema attributes for Case_x class
	 */
	@IsTest
	static void testSchemaAttributesForCase_x() {
		// Create an instance of Case_x
		TIBCOArticleSubscriptionSchema.Case_x caseInstance = new TIBCOArticleSubscriptionSchema.Case_x();

		// Test default values
		Assert.isTrue(caseInstance.fieldsToNull == null || caseInstance.fieldsToNull.size() == 0, 'fieldsToNull should be null or empty');
		Assert.areEqual(null, caseInstance.Id, 'Id should be null');
		Assert.areEqual(null, caseInstance.ArticleCount_xc, 'ArticleCount_xc should be null');
		Assert.areEqual(null, caseInstance.CaseNumber, 'CaseNumber should be null');
		Assert.areEqual(null, caseInstance.EventCode_xc, 'EventCode_xc should be null');
		Assert.areEqual(null, caseInstance.FacilityOrOutletWCC_xc, 'FacilityOrOutletWCC_xc should be null');
		Assert.areEqual(null, caseInstance.LastModifiedDate, 'LastModifiedDate should be null');
		Assert.areEqual(null, caseInstance.OwnerUserName_xc, 'OwnerUserName_xc should be null');
		Assert.areEqual(null, caseInstance.ReferenceID_xc, 'ReferenceID_xc should be null');
		Assert.areEqual(null, caseInstance.Subject, 'Subject should be null');
		Assert.areEqual(null, caseInstance.Type_x, 'Type_x should be null');


		Id caseId = ApplicationTestDataFactory.getCases(1, true)[0].Id;
		// Modify and test the fields
		caseInstance.fieldsToNull = new String[] {'Field1', 'Field2'};
		caseInstance.Id = caseId;
		caseInstance.ArticleCount_xc = '10';
		caseInstance.CaseNumber = '00012345';
		caseInstance.EventCode_xc = 'EC123';
		caseInstance.FacilityOrOutletWCC_xc = 'FO567';
		caseInstance.LastModifiedDate = DateTime.now();
		caseInstance.OwnerUserName_xc = 'user@example.com';
		caseInstance.ReferenceID_xc = 'REF987';
		caseInstance.Subject = 'Test Case';
		caseInstance.Type_x = 'Standard';

		// Check the modified values
		Assert.areEqual(2, caseInstance.fieldsToNull.size(), 'fieldsToNull should have 2 elements');
		Assert.areEqual(caseId, caseInstance.Id, 'Id should be set to the correct value');
		Assert.areEqual('10', caseInstance.ArticleCount_xc, 'ArticleCount_xc should be set to 10');
		Assert.areEqual('00012345', caseInstance.CaseNumber, 'CaseNumber should be set to 00012345');
		Assert.areEqual('EC123', caseInstance.EventCode_xc, 'EventCode_xc should be set to EC123');
		Assert.areEqual('FO567', caseInstance.FacilityOrOutletWCC_xc, 'FacilityOrOutletWCC_xc should be set to FO567');
		Assert.areEqual('user@example.com', caseInstance.OwnerUserName_xc, 'OwnerUserName_xc should be set to user@example.com');
		Assert.areEqual('REF987', caseInstance.ReferenceID_xc, 'ReferenceID_xc should be set to REF987');
		Assert.areEqual('Test Case', caseInstance.Subject, 'Subject should be set to Test Case');
		Assert.areEqual('Standard', caseInstance.Type_x, 'Type_x should be set to Standard');
	}

	/**
	 * Test and validate the schema attributes for sObject_x class
	 */
	@IsTest
	static void testSchemaAttributesForSObject_x() {
		// Create an instance of sObject_x
		TIBCOArticleSubscriptionSchema.sObject_x sObjectInstance = new TIBCOArticleSubscriptionSchema.sObject_x();

		// Test default values (fieldsToNull should be null or empty, Id should be null)
		Assert.isTrue(sObjectInstance.fieldsToNull == null || sObjectInstance.fieldsToNull.size() == 0, 'fieldsToNull should be null or empty');
		Assert.areEqual(null, sObjectInstance.Id, 'Id should be null');

		// Modify and test the fields
		sObjectInstance.fieldsToNull = new String[] {'Field1', 'Field2'};
		Id caseId = ApplicationTestDataFactory.getCases(1, true)[0].Id;
		sObjectInstance.Id = caseId;

		// Check the modified values
		Assert.areEqual(2, sObjectInstance.fieldsToNull.size(), 'fieldsToNull should have 2 elements');
		Assert.areEqual(caseId, sObjectInstance.Id, 'Id should be set to the correct value');
	}
}