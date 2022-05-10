/*------------------------------------------------------------
Author:        David Catindoy
Company:       Cloud Sherpas
Description:   Class for used by StarTrack Inbound Email Handler (Process)
Test Class:    StarTrackCalculateFromAddress_Test
History
May 31, 2016 - David Catindoy - Created
Mar 25, 2022 - Naveen Rajanna - REQ2723199 
-----------------------------------------------------------
---------------------------------
 THIS CLASS NEEDS TO BE DESTRUCTIVE along with StarTrack_Inbound_Email_Handler.flow after few weeks of REQ2723199 going live
---------------------------------
-----------------------------------------------------------
------------------------------------------------------------*/

public class StarTrackCalculateFromAddress {

    @InvocableMethod
    public static void calculateFromAddress(List<String> paramList){
        System.debug('Temp');
        // Commented as part of REQ2723199
        // StarTrackUtil.calculateFromAddress(paramList[0]);
    }
}