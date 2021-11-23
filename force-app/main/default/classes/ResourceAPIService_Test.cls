/**************************************************
Description:    Test class for ResourceAPIService
History:
--------------------------------------------------
2018-07-16  nathan.franklin@auspost.com.au Created
**************************************************/
@isTest
public class ResourceAPIService_Test {

	/**
	 * Scenario:
	 *      Test serialize functionality
	 */
	@isTest
	public static void testSerializeBackwardsCompatibility() {

		ResourceAPIService.ResourceResponse response = new ResourceAPIService.ResourceResponse(true, '', 'Test');

		// backward compatible
		ResourceAPIService.serializeResponse(response, 200);

		String responseBody = RestContext.response.responseBody.toString();

		// ensure status code was set properly
		System.assertEquals(200, RestContext.response.statusCode);

		// ensure response body was serialized as JSON
		Map<String, Object> output = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
		System.assertEquals('true', String.valueOf(output.get('success')));
		System.assertEquals('Test', String.valueOf(output.get('response')));

	}

	/**
	 * Scenario:
	 * 	Ensuring RestResponse returns apprioriate responses
	 */
	public static testMethod void testResourceResponse() {

		ResourceAPIService.ResourceResponse response;

		// test just a status code to ensure success is set correctly
		response = new ResourceAPIService.ResourceResponse(200);
		System.assertEquals(true, response.success);

		// test a status code with error message to ensure success (false) and error is set correctly
		response = new ResourceAPIService.ResourceResponse(500, 'Custom Error');
		System.assertEquals(false, response.success);
		System.assertEquals('Custom Error', response.error);

		// make sure success is set to false with an error message again (backwards compatibility)
		response = new ResourceAPIService.ResourceResponse(false, 'Custom Error');
		System.assertEquals(false, response.success);
		System.assertEquals('Custom Error', response.error);

		// make sure success is set to true without an error message and a response (backwards compatibility)
		response = new ResourceAPIService.ResourceResponse(true, '', 'OK');
		System.assertEquals(true, response.success);
		System.assertEquals(true, String.isEmpty(response.error));
		System.assertEquals('OK', response.response);

		// make sure success is set to true by using a status code without an error message and a response
		response = new ResourceAPIService.ResourceResponse(200, '', 'OK');
		System.assertEquals(true, response.success);
		System.assertEquals(true, String.isEmpty(response.error));
		System.assertEquals('OK', response.response);

		// test the serialization of the response
		String json = response.serialize();
		System.assertEquals(false, String.isEmpty(json));

	}

	/**
     * Scenario:
     *      A very basic test for the abstract class. This is just mostly a coverage test since the abstract class is tested in details by consuming the API's that implement it.
     */
	public static testMethod void testApiExtender() {

		ResourceAPIService.RequestParams params = new ResourceAPIService.RequestParams('/api/1.0/alive', '');
		System.assertEquals(1.0, params.version);
		System.assertEquals('alive', params.uriParts[0]);
		System.assertEquals(1, params.uriParts.size());

		IApiExtender extenderTest = new IApiExtender();
		extenderTest.requestParams = params;

		ResourceAPIService.IResourceResponse response = extenderTest.post();
		System.assertEquals(501, response.getResponseCode());

		response = extenderTest.query();
		System.assertEquals(501, response.getResponseCode());

		extenderTest.getQueryCacheKeySuffix();
		extenderTest.getPaginationOffset();

		// ensure we can find the 'alive' api endpoint in the API Config custom metadata
		ResourceAPIService.ResourceAPIConfigWrapper config = ResourceAPIService.getResourceApiConfig(params, 'GET');
		System.assertNotEquals(null, config);

//		// pass a record in to be 'normalised'
//		Contact con = new Contact(FirstName = 'Nathan', LastName = 'Franklin', Email = 'nathan.franklin@auspost.com.au');
//		List<Map<String, Object>> output = extenderTest.normaliseSObjectOutput(new List<Contact>{con}, new Map<String, String>{'FirstName' => 'firstName1', 'LastName' => 'lastName1', 'Email' => 'email1'});
//		System.assertEquals(true, output[0].containsKey('firstName1'));
//		System.assertEquals(true, output[0].containsKey('lastName1'));
//		System.assertEquals(true, output[0].containsKey('email1'));


	}


	class IApiExtender extends ResourceAPIService.IApi {}



}