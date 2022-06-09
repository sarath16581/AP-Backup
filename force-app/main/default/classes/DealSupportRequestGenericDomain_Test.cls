/**
 * @description Test class covering DealSupportRequestGenericDomain
 * @author Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date 2022-06-02
 * @group Tests
 * @tag Domain
 * @tag Deal_Support_Request__c
 * @domain Core
 * @changelog
 * 2022-06-02	Dattaraj Deshmukh - created
 */

@IsTest
public with sharing class DealSupportRequestGenericDomain_Test {

    @IsTest
	private static void testDealSupportRequestGenericDomain() {
		List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);

		ApplicationDomain.IConstructable constructableDomain = new DealSupportRequestGenericDomain.Constructor();
		DealSupportRequestGenericDomain domain = (DealSupportRequestGenericDomain) constructableDomain.construct(dealSupportRequests);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(dealSupportRequests[0].Id, domain.records[0].Id, 'Expected record');
	}
}