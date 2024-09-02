/**
 * Test class for TIBCOArticleService
 *
 * @author di.chen
 * @date 2014-06-24
 * @changelog
 * 2020-04-10  nathan.franklin@auspost.com.au  Added new test methods
 * 2020-10-28  disha.kariya@auspost.com.au Added test method for transient variable.
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
 * 2021-10-15 - Nathan Franklin - Created transient attribute tests
 * 2024-05-21 - Seth Heang - Updated existing SAP-EM mock response to handle article and consignment search
 */
@isTest
private class TIBCOArticleService_Test {

	/**
	 * Scenario: Make sure that the APCN returned on the sender/receiver details matches a record in Salesforce
	 */
	@IsTest
	private static void testContactMatchingByAPCN() {
		// insert contacts so they can be selected out
		List<Account> personAccounts = new List<Account>{ TestDataProvider.createPersonAccount('Person1'), TestDataProvider.createPersonAccount('Person2'), TestDataProvider.createPersonAccount('Person3') };

		personAccounts[0].APCN__pc = '123';
		personAccounts[1].APCN__pc = '456';
		personAccounts[2].APCN__pc = '789';

		// create the person account records so we can
		insert personAccounts;

		// grab the contacts from the person accounts that were created
		Map<String, Contact> contactAPCNMappings = new Map<String, Contact>();
		List<Contact> contacts = [SELECT Id, Name, APCN__c FROM Contact];
		for (Contact cont : contacts) {
			contactAPCNMappings.put(cont.APCN__c, cont);
		}

		System.debug('contactAPCNMappings: ' + contactAPCNMappings);

		// NOTE: No DML's to minimise database time
		// the articles contain sender/receiver info which will be matched to the contacts created above
		List<Article__c> articles = TIBCO_Test.getArticles();
		articles[0].Id = fflib_IDGenerator.generate(Article__c.SObjectType);
		articles[1].Id = fflib_IDGenerator.generate(Article__c.SObjectType);
		articles[2].Id = fflib_IDGenerator.generate(Article__c.SObjectType);

		Map<Id, Map<String, Contact>> contactMatchOutput = TIBCOArticleService.findMatchingContacts(articles);

		System.debug('contactMatchOutput: ' + contactMatchOutput);

		// all 3 articles should have matched
		System.assertEquals(3, contactMatchOutput.size());

		// make sure the id's line up
		System.assertEquals(contactAPCNMappings.get('123').Id, contactMatchOutput.get(articles[0].Id).get('receiver').Id);
		System.assertEquals(contactAPCNMappings.get('456').Id, contactMatchOutput.get(articles[0].Id).get('sender').Id);
		System.assertEquals(contactAPCNMappings.get('789').Id, contactMatchOutput.get(articles[1].Id).get('receiver').Id);
		System.assertEquals(null, contactMatchOutput.get(articles[1].Id).get('sender'));
		System.assertEquals(contactAPCNMappings.get('456').Id, contactMatchOutput.get(articles[2].Id).get('receiver').Id);
		System.assertEquals(contactAPCNMappings.get('789').Id, contactMatchOutput.get(articles[2].Id).get('sender').Id);
	}

	/**
	 * Scenario: Make sure that the APCN returned on the sender/receiver details matches a record in Salesforce
	 */
	@IsTest
	private static void testContactMatchingByNameEmail() {
		// insert contacts so they can be selected out
		List<Account> personAccounts = new List<Account>{ TestDataProvider.createPersonAccount('Person1'), TestDataProvider.createPersonAccount('Person2'), TestDataProvider.createPersonAccount('Person3') };

		personAccounts[0].FirstName = 'SenderFirstName1';
		personAccounts[0].LastName = 'SenderLastName1';
		personAccounts[0].PersonEmail = 'dsf@163.com';
		personAccounts[1].FirstName = 'ReceiverFirstName2';
		personAccounts[1].LastName = 'ReceiverLastName2';
		personAccounts[1].PersonEmail = 'dsf@163.com';
		personAccounts[2].FirstName = 'SenderFirstName3';
		personAccounts[2].LastName = 'SenderLastName3';
		personAccounts[2].PersonEmail = 'dsf@163.com';

		// create the person account records so we can
		insert personAccounts;

		// grab the contacts from the person accounts that were created
		Map<Id, Contact> accountContactMappings = new Map<Id, Contact>();
		List<Contact> contacts = [SELECT Id, Name, AccountId FROM Contact];
		for (Contact cont : contacts) {
			accountContactMappings.put(cont.AccountId, cont);
		}

		// NOTE: No DML's to minimise database time
		// the articles contain sender/receiver info which will be matched to the contacts created above
		List<Article__c> articles = TIBCO_Test.getArticles();
		articles[0].Id = fflib_IDGenerator.generate(Article__c.SObjectType);
		articles[1].Id = fflib_IDGenerator.generate(Article__c.SObjectType);
		articles[2].Id = fflib_IDGenerator.generate(Article__c.SObjectType);

		Map<Id, Map<String, Contact>> contactMatchOutput = TIBCOArticleService.findMatchingContacts(articles);

		// all 3 articles should have matched
		System.assertEquals(3, contactMatchOutput.size());

		// make sure the id's line up
		System.assertEquals(null, contactMatchOutput.get(articles[0].Id).get('receiver'));
		System.assertEquals(accountContactMappings.get(personAccounts[0].Id).Id, contactMatchOutput.get(articles[0].Id).get('sender').Id);
		System.assertEquals(accountContactMappings.get(personAccounts[1].Id).Id, contactMatchOutput.get(articles[1].Id).get('receiver').Id);
		System.assertEquals(null, contactMatchOutput.get(articles[1].Id).get('sender'));
		System.assertEquals(null, contactMatchOutput.get(articles[2].Id).get('receiver'));
		System.assertEquals(accountContactMappings.get(personAccounts[2].Id).Id, contactMatchOutput.get(articles[2].Id).get('sender').Id);
	}

	/**
	 * In TibcoArticleService, after a SAPEM search, the TIBCOSearchResult object is repopulated from the local cache (to incorporate formula field calculations I guess)
	 * The transient attributes populated in the original TIBCOSearchResult are lost because
	 * This scenario tests the code that pulls the transient attributes out and repopulates the transient attributes on the new TIBCOSearchResult object that is built from the local db cache
	 */
	@IsTest
	private static void testTransientAttributesAreCorrectlyMappedAndMerged_EndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// This mock uses TIBCO_Test.createArticleDetailElement(); which contains EVENT_REASON as a transient attribute for events and PREDICT_WIN_START and PREDICT_WIN_END as transient attributes for article
		Test.setMock(WebServiceMock.class, new SearchInSapMockResponse('auysgdagsd'));

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TIBCOSearchResult searchResult = TIBCOArticleService.searchArticles(new List<String>{ 'auysgdagsd' }, true);

		Test.stopTest();

		Assert.areNotEqual(null, searchResult.trackResults[0].articleDetails, 'articleDetails should not be null');
		Assert.areEqual(null, searchResult.trackResults[0].consignmentDetails, 'consignmentDetails should be null');
		System.assertEquals('1.30PM', searchResult.trackResults[0].articleDetails.transientAttributes.predictedWindowStart, 'Transient attribute predictedWindowStart was not set correctly');
		System.assertEquals('3.30PM', searchResult.trackResults[0].articleDetails.transientAttributes.predictedWindowEnd, 'Transient attribute predictedWindowEnd was not set correctly');

		// check for the event reason transient attribute
		Boolean foundEventReason = false;
		for (TIBCOEventMessageWrapper eventMessageWrapper : searchResult.trackResults[0].articleDetails.eventMessages) {
			if (!String.isEmpty(eventMessageWrapper.transientAttributes.eventReason)) {
				foundEventReason = true;
				break;
			}
		}

		System.assert(foundEventReason, 'Event reason was not mapped to transient attribute');
		System.assertEquals(1, [SELECT COUNT() FROM Article__c]);
	}

	public class SearchInSapMockResponse implements WebServiceMock {
		public String trackingNumber;

		public SearchInSapMockResponse(String trackingNumber) {
			this.trackingNumber = trackingNumber;
		}

		/**
		 * @description	   Mock webservice which simulates the response for article tracking
		 * @param			 stub, request, response, endpoint, soapAction, requestName, responseNS, responseName, responseType
		 * @return			Void
		 * @throws			NA
		 */
		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element resp = new AuspostQueryTrackEventsSchema.QueryTrackEventsResponse_element();
			AuspostQueryTrackEventsSchema.TrackingResults_element resultsElem = new AuspostQueryTrackEventsSchema.TrackingResults_element();
			List<AuspostQueryTrackEventsSchema.TrackingResults> trackingResults = new List<AuspostQueryTrackEventsSchema.TrackingResults>();
			AuspostQueryTrackEventsSchema.TrackingResults trackResult = new AuspostQueryTrackEventsSchema.TrackingResults();

			AuspostQueryTrackEventsSchema.ArticleDetails_element article = TIBCO_Test.createArticleDetailElement();

			trackResult.ArticleDetails = article;
			trackResult.TrackingID = trackingNumber;
			trackingResults.add(trackResult);

			resultsElem.TrackingResult = trackingResults;
			resp.TrackingResults = resultsElem;
			response.put('response_x', resp);
		}
	}
}