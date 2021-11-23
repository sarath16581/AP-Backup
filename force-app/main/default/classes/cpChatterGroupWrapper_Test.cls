@isTest
//Test class for chatter group wrapper used by Customer community
private class cpChatterGroupWrapper_Test{
	private static final String groupId = 'testGroupId';
    private static final Integer groupMemberCount = 34;
    private static final String groupName = 'testGroupName';
    private static final String groupDescription = 'testGroupDescription';
    private static final String smallPhotoUrl = 'testSmallPhotoUrl';
    private static final String lastFeedElementPostDate = String.valueof(system.now());

	@isTest
	//Execute testing
	static void testChatterGroupWrapperMethods(){	
		Test.startTest();
		cpChatterGroupWrapper chtrgrpwrprObj = new cpChatterGroupWrapper(groupId,groupMemberCount,groupName,groupDescription,smallPhotoUrl, lastFeedElementPostDate);
		Test.stopTest();
	}
}