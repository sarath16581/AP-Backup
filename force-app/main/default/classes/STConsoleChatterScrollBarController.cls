/**
 * @author S Judd
 * @date 26/4/2021
 * @description Console footer page controller for StarTrack Service and Support app.
 * @domain StarTrack Service & Support Service Cloud
 */

public with sharing class STConsoleChatterScrollBarController {

    public Id chatterGroupId;
    public static String chatterGroupName = 'ST Customer Services – Urgent Messages';

    public STConsoleChatterScrollBarController() {

        chatterGroupId = getChatterGroupId();
    }

    /**
     * @return Chatter Group Id used in VFPage for getting the chatter feed.
     */
    public Id getChatterGroupId() {
        if(Test.isRunningTest()) {
            chatterGroupName = 'Test ST Console Chatter Group Name';
        }
        return [SELECT Id,name FROM CollaborationGroup WHERE name = :chatterGroupName LIMIT 1].Id;
    }
}