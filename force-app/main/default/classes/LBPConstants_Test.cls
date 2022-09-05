/**
* @description Test class for LBPConstants
* @author Nathan Franklin
* @date 2022-08-24
* @changelog
*/
@IsTest
private class LBPConstants_Test {

	@IsTest
	private static void testMethods() {
		String communityProfileName = LBPConstants.COMMUNITY_PROFILE_NAME;
		Id communityProfileId = LBPConstants.COMMUNITY_PROFILE_ID;
		Profile prof = [SELECT Id, Name FROM Profile WHERE Id = :communityProfileId][0];
		System.assertEquals(communityProfileName, prof.Name);
	}

}