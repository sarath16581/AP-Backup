/*------------------------------------------------------------
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Class for used by StarTrack Inbound Email Handler (Process)
Test Class:    StarTrackCalculateFromAddress_Test
History
May 31, 2016 - David Catindoy - Created
------------------------------------------------------------*/

public class StarTrackCalculateFromAddress {

    @InvocableMethod
    public static void calculateFromAddress(List<String> paramList){
        StarTrackUtil.calculateFromAddress(paramList[0]);
    }
}