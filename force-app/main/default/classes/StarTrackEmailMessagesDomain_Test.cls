/**
* @author Naveen Rajanna
* @date 2022-02-10
* @group Tests
* @tag Selector
* @tag EmailMessage
* @domain Core
* @description Test class covering StarTrackEmailMessagesDomain
* @changelog
*/
@IsTest
private class StarTrackEmailMessagesDomain_Test {
	@IsTest
	private static void testStarTrackEmailMessagesDomain() {
		
		List<Case> cases = ApplicationTestDataFactory.getCases(2, false);
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		cases[0].First_Email_Response__c = true;

        List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(2, true,true,'test@test.com','amazonstrategicsupport@auspost.com.au','Inbound Email',cases[0].Id));

        ApplicationDomain.IConstructable constructableDomain = new StarTrackEmailMessagesDomain.Constructor();
        StarTrackEmailMessagesDomain domain = (StarTrackEmailMessagesDomain)constructableDomain.construct(emailMessages);

        System.assertEquals(2, domain.records.size(), 'Records should have been filtered in call to newInstance');
        System.assertEquals(emailMessages[0].Id, domain.records[0].Id, 'Expected record');
	}
}