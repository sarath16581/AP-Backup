/**
* @author Ashapriya Gadi
* @date 2021-11-23
* @group Tests
* @tag Selector
* @tag EmailMessage
* @domain Core
* @description Test class covering ServiceAdvisorsEmailMessagesDomain
* @changelog
* 2021-11-23 - Ashapriya Gadi - Created
*/
@IsTest
private class ServiceAdvisorsEmailMessagesDomain_Test {
    @IsTest
    private static void testEmailMessagesDomain() {

        List<Case> cases = ApplicationTestDataFactory.getCases(2, false);
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseServiceDeliveryRecordType;

        List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(2, true,true,'test@test.com','amazonstrategicsupport@auspost.com.au','Inbound Email',cases[0].Id));

        ApplicationDomain.IConstructable constructableDomain = new ServiceAdvisorsEmailMessagesDomain.Constructor();
        ServiceAdvisorsEmailMessagesDomain domain = (ServiceAdvisorsEmailMessagesDomain)constructableDomain.construct(emailMessages);

        System.assertEquals(2, domain.records.size(), 'Records should have been filtered in call to newInstance');
        System.assertEquals(emailMessages[0].Id, domain.records[0].Id, 'Expected record');
    }

}