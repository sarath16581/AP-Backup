/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Class for used by StarTrack Update Workflow Email on Case Close (Process)
Test Class:    StarTrackCloseCaseTaskEmail_Test
History
January 19, 2016 - Patrick James Franco - Created
------------------------------------------------------------*/

public without sharing class StarTrackCloseCaseTaskEmail {

    @InvocableMethod
    public static void closeCaseTaskEmail(List<Id> caseIdList){
        StarTrackUtil.closeCaseTaskEmail(caseIdList[0]);
    }
}