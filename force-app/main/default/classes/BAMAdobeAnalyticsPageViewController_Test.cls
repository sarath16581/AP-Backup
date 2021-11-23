/**************************************************
Description:    Test class for covering BAMAdobeAnalyticsPageViewController
History:
--------------------------------------------------
2019-06-27  nathan.franklin@auspost.com.au  Created
**************************************************/
@isTest
public class BAMAdobeAnalyticsPageViewController_Test {

	@testSetup
	public static void testSetup(){

		Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
		testAccount.Business_Solutions_Customer__c = true;
		testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
		testAccount.ServiceSLA__c = 'Enterprise';
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		update testAccount;

		Contact newCon = new Contact(FirstName = 'Nathan', LastName = 'Franklin', MobilePhone = '0400000000', Email = 'mytestemail@testingemails.com', AccountId = testAccount.Id, Status__c = 'Active');
		Database.insert(newCon);

	}

	/**
	 * Basic wrapper test
	 */
	public static testMethod void testWrapper() {
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = :BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');

		System.runAs(u) {
			Test.startTest();

			BAMAdobeAnalyticsPageViewController.WrapperUserDetails details = BAMAdobeAnalyticsPageViewController.retrieveUserDetails();
			System.assert(details.isLoggedIn);

			Test.stopTest();
		}
	}
}