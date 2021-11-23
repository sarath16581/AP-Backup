/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Class for used by StarTrack LDC System Check (Process)
Test Class:    StarTrackCreateLDCTask_Test
History
December 9, 2015 - Patrick James Franco - Created
------------------------------------------------------------*/

public with sharing class StarTrackCreateLDCTask {

    @InvocableMethod
    public static void createLDCTask(List<Id> caseIdList){
        StarTrackUtil.createLDCTask(caseIdList.get(0));
    }
}