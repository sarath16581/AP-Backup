//Test class for cpBannedWordDetector
@isTest
private class cpBannedWordDetector_Test {
	@isTest
	static void bannedWordDetectorMethods() {
        System.runAs(new User(Id=Userinfo.getUserId())){
            test.startTest();
            // Set mock callout class 
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new cpWebServiceMockImpl());
            // Call the method that invokes a callout
            set<String> bannedWords = cpBannedWordDetector.fetchBannedWords(userInfo.getSessionId());
            test.stopTest();
        }
	}
}