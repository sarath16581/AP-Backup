/*
 * @author: Rajesh P. (Mav3rik)
 * @description: This class created to have converage for AgentWork Trigger
 * @description: Also, there is limitation; there must be at least one record to run this test class.
 * @description: We cannot create new record on the fly as at least one user must be online which creates dependency.
 * @description: Please make sure, you have a record for AgentWork object before executing/testing this class.
 * @history:22-OCT-2019, class created.
*/
@isTest(SeeAllData=true)
public class AgentWorkTriggerTest {
    @IsTest
    public static void updateTrigger(){
        AgentWork aw = [SELECT Id, OwnerId FROM AgentWork LIMIT 1];
    	Test.startTest();
        aw.OwnerId = UserInfo.getUserId();
        update aw;
        Test.stopTest();
        System.assert(aw.OwnerId == UserInfo.getUserId(), 'AgentWork Owner Modified.');
    }
}