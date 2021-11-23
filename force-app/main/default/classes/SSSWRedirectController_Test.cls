/**
*  This test class is for SSSWRedirectController.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 81%
*/
@isTest
private class SSSWRedirectController_Test {

    static testMethod void testCustomSettingProfile() {
    	
        User u = TestDataProvider.createTestUsers();
        insert u;
        
        Test.startTest();
        
        system.runAs(u){
        
	        SSSWRedirectController sssw = new SSSWRedirectController(new Apexpages.Standardcontroller(new Case()));
	        sssw.redirectMe();
	        
		}
		string profileName = [Select Name from Profile where Id =: u.ProfileId].name;
		system.assert(profileName != null);
        Test.stopTest();
    }
}