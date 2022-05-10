/**
 * @description Test class covering APRTrigger
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Tests
 * @tag Domain
 * @tag APR__c
 * @domain Core
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 */
@IsTest
private class APRTrigger_Test {
	@IsTest
	private static void test() {
		Profile prof = [SELECT Id, Name FROM profile WHERE Name = 'System Administrator' LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne', prof.id, null)) {
			APR__c apr = new APR__c();
            apr.Type__c = 'StarTrack APR';

			Test.startTest();
			    insert apr;
			Test.stopTest();

			System.assert(apr.Id != null, 'Expected apr to be inserted');
		}
	}
}