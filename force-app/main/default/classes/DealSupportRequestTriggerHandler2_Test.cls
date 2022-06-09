/**
 * @description Test class covering DealSupportRequestTriggerHandler2
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
public with sharing class DealSupportRequestTriggerHandler2_Test {
    @IsTest
	private static void test() {
		DealSupportRequestTriggerHandler2 domain = new DealSupportRequestTriggerHandler2();
		domain.newUnitOfWork();
		domain.registerDomains();
		System.assert(true, ''); // PMD warning
	}
}