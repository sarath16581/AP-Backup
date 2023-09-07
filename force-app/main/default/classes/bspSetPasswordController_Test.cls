/*
History:
2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version
*/
@isTest
private class bspSetPasswordController_Test {

	static testMethod void testController() {
	
		User u = TestDataProvider.createTestUsers();
		insert u;
		
		Test.startTest();
		
		Test.setCurrentPage(Page.bspSetPassword);
		ApexPages.currentPage().getParameters().put('myId', u.Id);
		ApexPages.currentPage().getParameters().put('myEmail', u.Email);
		
		bspSetPasswordController cont = new bspSetPasswordController();    
		
		System.assertEquals(u.Email.toLowerCase(), cont.email.toLowerCase());
		System.assert(!cont.hasException);
		System.assert(!cont.passwordSet);
		
		String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
		
		if (!sfdcBaseURL.startsWithIgnoreCase('https')) {
			System.assert(cont.securePage().getUrl().startsWithIgnoreCase('https'));
		} else {
			System.assertEquals(null, cont.securePage());
		}
		
		cont.password1 = 'pw';
		cont.password2 = 'pw';
		cont.save();
		System.assert(cont.hasException);
		System.assert(!cont.passwordSet);
		
		cont.password1 = 'pw1!#$%-_=+<>';
		cont.password2 = 'pw1!#$%-_=+<>';
		cont.save();
		//System.assert(!cont.hasException);
		System.assert(cont.passwordSet);     
		
		Test.stopTest();
	}
}