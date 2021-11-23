/**
 ** Description: VOC Incident Calculation
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.12.2016
 ** History:--------------------------------------------
 **         JAN.12.2016 David Catindoy - Created
 **/
public class StarTrackVOCIncidentCalculation {

    @InvocableMethod
    public static void VOCIncidentCalculation(List<Id> caseIds){
        
        StarTrackUtil.calculateVOCIncident(caseIds);
        
    }
}