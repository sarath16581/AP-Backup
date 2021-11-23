/**************************************************
Purpose:    Main trigger handler class for workday adjustment trigger
History:
--------------------------------------------------
8.9.2017    Adrian Recio Created
**************************************************/
public class WorkDayAdjustmentTriggerHandler {
    public static void populateSalesTeam(List<Work_Day_Adjustments__c> wdaList, Map<Id,Work_Day_Adjustments__c>oldWdaMap, Boolean IsUpdateVar){
        // create sales team type set
        set<string> salesTeamSet = new set<string>();
        for(Work_Day_Adjustments__c wdaVar: wdaList){
            Boolean IsChanged = false;
            if(oldWdaMap!=null && IsUpdateVar == true){
            	Work_Day_Adjustments__c oldWdaVar = oldWdaMap.get(wdaVar.Id);
                if(oldWdaVar!=null){
                    if(oldWdaVar.Sales_Team__c != wdaVar.Sales_Team__c){
                        IsChanged = true;
                    }
                }
            }
            if(IsUpdateVar==false || IsChanged==true){
            	salesTeamSet.add(wdaVar.Sales_Team__c);
            }
        }
        
        if(salesTeamSet.size()>0){
            // query sales segment based on sales team type and build map where key is sales segment and value is the sales director
            Map <String,Sales_Segment_Reference__c> salesSegmentMap = new Map <String,Sales_Segment_Reference__c>();
            for (Sales_Segment_Reference__c ssr : [SELECT Sales_Segment__c, Sales_Director__c, Id FROM Sales_Segment_Reference__c 
                                                   WHERE (Sales_Segment__c in : salesTeamSet) AND (Sales_Director__c!='')]){            
                salesSegmentMap.put( ssr.Sales_Segment__c , ssr);
            }
            
            // Populate sales team information to matching work day adjustment based on sales team type
            for (Work_Day_Adjustments__c wdaVar : wdaList) {                                 
                Sales_Segment_Reference__c ssVar = salesSegmentMap.get(wdaVar.Sales_Team__c);   
                
                if(ssVar!=null){
                    wdaVar.Sales_Team_Manager__c = ssVar.Sales_Director__c;
                    wdaVar.Sales_Team_Reference__c = ssVar.Id ;
                }
            }
        }
    }
}