/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Apex class used by StarTrack Update Case Details (Process Builder)
Test Class:    StarTrackCreateAutomatedSWMYTask_Test
History
September 9, 2016 - David Catindoy - Created
------------------------------------------------------------*/

public with sharing class StarTrackCreateAutomatedSWMYTask {
    @InvocableMethod    
    public static void createAutomatedTask(List<Id> caseIdList){
        
        new StarTrackCardLeft_ControllerX(caseIdList[0]);
    }
}