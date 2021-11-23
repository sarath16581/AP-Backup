/**************************************************
Description:    testing of Retrieve user details
History:
--------------------------------------------------
2019-09-23  hasantha.liyanage@auspost.com.au  Created
**************************************************/
@isTest
public with sharing class AdobeAnalyticsInterfaceCmpControllerTest {

    @testSetup
    static void setupTestData() {
        // to avoid portal account user must have a role error.
        List<Account> accounts = TestDataProvider.createAccount('BAM Test Account', 2);
        insert accounts;

        // create a contact with APCN
        Contact con = TestDataProvider.createContact('Contact 1', accounts[0].Id, null);
        con.APCN__c = 'APCN';
        insert con;

    }

    /**
     * Testing of retrieval of current user details to pass to analytics
     */
    public static testMethod void AdobeAnalyticsController_ACPN_test() {

        // retrieve the record with APCN
        Contact con = [SELECT Id, APCN__c FROM Contact WHERE email = 'example@email.com'];

        // profile for test run as user
        Profile profile = [SELECT Id FROM Profile WHERE Name='DDC Consumer Community User'];

        // create run as user
        User user = new User(Alias = 'newUser', Email='user@testorg.a',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = profile.Id,  ContactId = con.id,
                TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');

        Test.startTest();
            system.runAs(user) {
                AdobeAnalyticsInterfaceCmpController.WrapperUserDetails outPut = AdobeAnalyticsInterfaceCmpController.retrieveUserDetails();
                system.assertEquals('APCN', outPut.apcn, '');
            }
        Test.stopTest();

    }
}