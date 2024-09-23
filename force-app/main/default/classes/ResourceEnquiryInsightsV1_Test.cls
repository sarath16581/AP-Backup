/**
 * @description Test Class used for ResourceEnquiryInsightsV1
 * @author Rejeesh Raghavan
 * @date 2024-09-20
 * @changelog
 * 2024-09-20 - Rejeesh Raghavan - Initial version
 */
@IsTest
public class ResourceEnquiryInsightsV1_Test {
    /**
	 * @description : Create test user
	 * @param hasAccess : `Boolean` Indicate if the user should be granted access to the apex classes
	 * @return  `User`
	 */
	static User setupTestUser(Boolean hasAccess){
		Id integrationProfileId = [SELECT Id FROM Profile 
									WHERE Name = 'AusPost Integration'
									LIMIT 1].Id;
		User integrationUser = ApplicationTestDataFactory.getUsers(1, integrationProfileId, false)[0];
		insert integrationUser;
		if(hasAccess){
			PermissionSetAssignment psa = new PermissionSetAssignment (
				PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='RoutingInsightsAPI' LIMIT 1].Id
				, AssigneeId = integrationUser.Id);
			insert psa;
		}
		return integrationUser;
	}
	/**
	 * @description : Test with no access
	 * Response should return error
	 */
	@IsTest
	static void testUserAccess(){

		//setup test user
		User integrationUser = setupTestUser(false);

		Test.startTest();
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
        request.requestUri =
            '/api/1.0/insights/enquiry';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}

		Assert.areEqual(403, response.statusCode, 'Forbidden');
	}
	/**
	 * @description : Test with no params
	 * Response should return error
	 */
	@IsTest
	static void testNoParams(){

		//setup test user
		User integrationUser = setupTestUser(true);
		
		Test.startTest();
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
        request.requestUri =
            '/api/1.0/insights/enquiry';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		
		Assert.areEqual(400, response.statusCode, 'BAD REQUEST: Due to NO params');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('Bad Request'), 'BAD REQUEST: Due to NO params');
	}
	/**
	 * @description : Test with Invalid trackingId
	 * Response should return error
	 */
    @IsTest
	static void testInvalidTrackingId(){
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		//setup test user
		User integrationUser = setupTestUser(true);
		
		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/enquiry';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		request.params.put('tracking_id', '1234567890123456789012345678901234567890');

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Assert.areEqual(400, response.statusCode, 'BAD REQUEST: Due to tracking Id greater than MAX length');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('Bad Request'), 'BAD REQUEST: Due to tracking Id greater than MAX length');
	}
	@IsTest
	static void testValidTrackingId(){
		//setup test user
		User integrationUser = setupTestUser(true);

		//setup articles
		Article__c article = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ArticleTest__c = article.Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		cases[1].ArticleTest__c = article.Id;
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		article = (Article__c)ApplicationTestDataFactory.setChildRelationships(article,new Map <String, List <SObject>> {'Cases__r' => cases});
		

		Set<Object> selectorOptions = new Set<Object>();
		Map<String, Object> bindMap = new Map<String, Object>();
		Set<String> caseRecordTypes = new Set<String>();
		caseRecordTypes.addAll(ResourceCustomerInsightsV1.AP_CASE_RECORDTYPES);
		caseRecordTypes.addAll(ResourceCustomerInsightsV1.ST_CASE_RECORDTYPES);
		caseRecordTypes.addAll(ResourceCustomerInsightsV1.UNIFIED_CASE_RECORDTYPES);
		bindMap.put('trackingIds', new Set<String>{article.Name});
		bindMap.put('caseRecordTypes',caseRecordTypes);
		bindMap.put('closedCaseCutoffDate',Date.today().addDays(-30));
		Set<String> caseIds = new Set<String>{cases[0].Id, cases[1].Id};

		//stubs
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);

		// mocks
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
			mockArticlesSelector.selectWithCasesByIdOrTrackingOrName(
				bindMap, selectorOptions))
			.thenReturn(new Map<Id, Article__c>{article.Id =>article});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/enquiry';
		request.params.put('tracking_id', article.Name);
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Map<String, Object> jsonResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Map<String, Object> responseBody = (Map<String, Object>)(jsonResponseBody.get('response'));
		List<Object> jsonCases = (List<Object>)(responseBody.get('cases'));
		Map<String, Object> jsonCaseRecord = (Map<String, Object>)jsonCases[0];
		System.debug('jsonCaseRecord: ' + JSON.serialize(jsonCaseRecord));
		System.debug('caseIds: ' + JSON.serialize(caseIds));
		Assert.areEqual(200, response.statusCode,'Response code should be success');
        Assert.areEqual(true, jsonResponseBody.get('success'),'Response code should be success');
        Assert.areEqual(article.Name, responseBody.get('tracking_id'),'Tracking Id should match');
        Assert.areEqual(true, caseIds.contains((String)jsonCaseRecord.get('sfid')),'Case Id should match');
	}
}