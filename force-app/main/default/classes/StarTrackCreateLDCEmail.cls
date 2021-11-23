/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Class for used by StarTrack LDC System Check (Process)
Test Class:    StarTrackCreateLDCEmail_Test
History
December 11, 2015 - Patrick James Franco - Created
------------------------------------------------------------*/

public with sharing class StarTrackCreateLDCEmail {

    @InvocableMethod
    public static void createLDCEmail(List<Id> caseIdList){
        StarTrackUtil.createLDCEmail(caseIdList.get(0));
    }
}