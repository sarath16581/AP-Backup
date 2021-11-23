/*------------------------------------------------------------
Author:        YongLing CHUA
Company:       SFDC
Description:   Class for used by StarTrack LDC Approved Email (Process)
Test Class:    StarTrackCreateLDCEmail_Test
History
December 11, 2015 - YongLing CHUA - Created
------------------------------------------------------------*/

public with sharing class StarTrackCreateLDCApprovedEmail {

    @InvocableMethod
    public static void createLDCApprovedEmail(List<Id> caseIdList){
        StarTrackUtil.createLDCApprovedEmail(caseIdList.get(0));
    }
}