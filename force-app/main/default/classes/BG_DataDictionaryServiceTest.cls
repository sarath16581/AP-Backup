/**
 * @author alexvolkov
 * @date 2/3/20
 * @description Test Class for BG_DataDictionaryService
 * --------------------------------------- History --------------------------------------------------
 * 02.03.2020		alex.volkov@auspost.com.au		Initial creation
 * 03.03.2020		alex.volkov@auspost.com.au		Added method testGetFieldTripDetails
 * 04.03.2020		alex.volkov@auspost.com.au		Added method testGetFieldUsageDetails
**/

@IsTest
private with sharing class BG_DataDictionaryServiceTest
{
	/**
	* @description Test for getFieldDetails method
	*/
	@IsTest
	static void testGetFieldDetails()
	{
		/** Query a field definition */
		EntityDefinition vRandomObject = [SELECT QualifiedApiName FROM EntityDefinition WHERE IsCustomSetting = TRUE ORDER BY LastModifiedDate DESC LIMIT 1];
		FieldDefinition vRandomField = [SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :vRandomObject.QualifiedApiName ORDER BY LastModifiedDate DESC LIMIT 1];
		/** Mock the Tooling API response */
		Test.setMock(HttpCalloutMock.class, new CalloutMock(200, 'Success', '{"records":[{"InlineHelpText":"Test Text","CreatedBy":{"Name":"Test Name"}}]}'));
		Test.startTest();
		/** Assert results */
		System.assertNotEquals(null, BG_DataDictionaryService.getFieldDetails(vRandomObject.QualifiedApiName, vRandomField.QualifiedApiName));
		Test.stopTest();
	}

	/**
	* @description Test for getFieldTripDetails method
	*/
	@IsTest
	static void testGetFieldTripDetails()
	{
		/** Query a field definition */
		EntityDefinition vRandomObject = [SELECT QualifiedApiName FROM EntityDefinition WHERE IsCustomSetting = TRUE ORDER BY LastModifiedDate DESC LIMIT 1];
		FieldDefinition vRandomField = [SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :vRandomObject.QualifiedApiName ORDER BY LastModifiedDate DESC LIMIT 1];
		Test.startTest();
		/** Assert results */
		System.assertNotEquals(null, BG_DataDictionaryService.getFieldTripDetails(vRandomObject.QualifiedApiName, vRandomField.QualifiedApiName));
		Test.stopTest();
	}

	/**
	* @description Test for getFieldUsageDetails method
	*/
	@IsTest
	static void testGetFieldUsageDetails()
	{
		/** Query a field definition */
		EntityDefinition vRandomObject = [SELECT QualifiedApiName FROM EntityDefinition WHERE IsCustomSetting = TRUE ORDER BY LastModifiedDate DESC LIMIT 1];
		FieldDefinition vRandomField = [SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :vRandomObject.QualifiedApiName ORDER BY LastModifiedDate DESC LIMIT 1];
		/** Mock the Metadata Dependency API response */
		Test.setMock(HttpCalloutMock.class, new CalloutMock(200, 'Success', '{"records":[{"MetadataComponentId":"00h1m000000FT2TAAW","MetadataComponentName":"Test Name", "MetadataComponentType":"Layout"}]}'));
		Test.startTest();
		/** Assert results */
		System.assertNotEquals(null, BG_DataDictionaryService.getFieldUsageDetails(vRandomObject.QualifiedApiName, vRandomField.QualifiedApiName));
		Test.stopTest();
	}

	/**
	* @description REST API callout mock
	*/
	private class CalloutMock implements HttpCalloutMock
	{
		private HttpResponse res = new HttpResponse();

		CalloutMock(Integer code, String status, String body)
		{
			res.setBody(body);
			res.setStatusCode(code);
			res.setStatus(status);
		}

		public HttpResponse respond(HttpRequest req)
		{
			return res;
		}

	}
}