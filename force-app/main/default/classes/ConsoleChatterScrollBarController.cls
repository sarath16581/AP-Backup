/**
 * @author S Judd
 * @date 26/4/2021
 * @description Console footer page controller for Customer Service app.
 * @domain Contact Centre Service Cloud
 */
public with sharing class ConsoleChatterScrollBarController {

    public Id chatterGroupId;
    public static String chatterGroupName = 'Customer Service – Urgent Notifications';

    public ConsoleChatterScrollBarController(){

        chatterGroupId = getChatterGroupId();

    }
    /**
     * @return Chatter Group Id used in VFPage for getting the chatter feed.
     */
    public Id getChatterGroupId(){
        if(Test.isRunningTest()){
            chatterGroupName = 'Test Console Chatter Group Name';
        }
        return [SELECT Id,name FROM CollaborationGroup WHERE name = :chatterGroupName LIMIT 1].Id;
    }
}