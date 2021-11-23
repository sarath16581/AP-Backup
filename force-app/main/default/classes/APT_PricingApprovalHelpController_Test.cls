/**
This apex class is test class for APT_PricingApprovalHelpController.
Created By - Drashtee Shah
Created Date - 18th Feb, 2016
Last Modified By -
Last Modified Date -
**/
@isTest
private class APT_PricingApprovalHelpController_Test {
    /*
        Creating test data
    */
    private static TestMethod void testmethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {   
            Test.StartTest();
            APT_PricingApprovalHelpController ac = new APT_PricingApprovalHelpController();
            ac.doRedirect();
            
            Test.StopTest();
            system.assert(ac!=null);
        }
    }
}