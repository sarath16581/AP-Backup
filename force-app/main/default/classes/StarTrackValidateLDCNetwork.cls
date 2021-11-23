/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Class for used by StarTrack Calculate Case Depot (Process) for LDC Branch Management
Test Class:    StarTrackValidateLDCNetwork_Test
History
December 10, 2015 - Patrick James Franco - Created
------------------------------------------------------------*/

public with sharing class StarTrackValidateLDCNetwork {

    @InvocableMethod
    public static void validateLDCNetwork(List<Id> caseIdList){
        StarTrackUtil.validateLDCNetwork(caseIdList.get(0));
    }
}