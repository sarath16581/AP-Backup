@isTest  
public class bspConstants_Test  {

    @isTest 
    public static void testCurrentCommunityID() {
        Test.startTest();
            System.debug(BspConstants.HAS_NETWORK_CONTEXT);
            System.debug(BspConstants.CURRENT_USER_IS_VIEWING_BSP);
            System.debug(BspConstants.CURRENT_COMMUNITY_ID);
        Test.stopTest();
    }
}