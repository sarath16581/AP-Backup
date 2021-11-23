/**
 * @author Emmanuel Yap
 * @date 2021-09-10
 * @description Utility class to retrieve Route Template Information
 * @changelog
 * 2021-09-10 - Emmanuel Yap - Created
*/

public with sharing class TDF_RouteTemplateUtil {
    
    public static Route_Template__c getRouteTemplateFromID(String templateId) {
        List<Route_Template__c> result = [
            SELECT  Name
            FROM Route_Template__c 
            WHERE Id = :templateId 
            LIMIT 1
       ];
       if(result.size() > 0){
            return result[0];
       } else{
            return null;
       }
    }

    public static List<Job_Template__c> getJobTemplateFromDutyTemplateId(String templateId) {
        List<Job_Template__c> result = [
            SELECT  Start_Time__c, Activity_Type__c, Duration__c, Job_Instructions__c,
                    Location__r.Name, Location__r.Street__c,Location__r.City__c, Dock_Number__c, 
                    Location__r.Site_Instruction_Notes__c, Location__r.Site_Instructions__c,
                    Route_Template__r.Active_Route_Days__c
            FROM Job_Template__c 
            WHERE Route_Template__c = :templateId 
            ORDER BY Day_Start_Time__c
       ];
       return result;
    }
}