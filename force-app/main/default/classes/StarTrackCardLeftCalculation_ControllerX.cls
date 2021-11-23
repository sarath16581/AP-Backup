/**
 ** Description: Run Dock and Depot Area Calculation
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: SEPT.28.2015
 ** History:--------------------------------------------
 **         SEPT.28.2015 David Catindoy - Created
 **/
public class StarTrackCardLeftCalculation_ControllerX {
    
    @InvocableMethod
    public static void RunDockANDDepotAreaCalculation(List<Id> taskIds)
    {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Depot_Area__c> depotAreaMap = new Map<Id, Depot_Area__c>();
        Map<Id, String> runDockMap = new Map<Id, String>();
        List<Task> listOfTasks = [  SELECT Id, WhatId,
                                    Depot_Role__c, Run_Dock__c
                                    FROM Task
                                    WHERE Id IN :taskIds
                                    AND (WhatId != null OR WhatId != '')];
        
        for(Task newTask : listOfTasks){
            String taskWhatId = newTask.WhatId;
            if(taskWhatId.startsWith('500')){
                caseIds.add(newTask.WhatId);
            }
        }
        List<Case> updateCases = [  SELECT Id, Origin, Network__c, Network__r.Parent_Network__c,
                                    ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.ReceiverName__c,
                                    ArticleTest__r.Receiver_Suburb__c, Priority,
                                    Enquiry_Type__c, Network__r.Preferred_Method_of_Tasking__c,
                                    ArticleTest__r.ActualWeight__c, ArticleTest__r.Number_of_Items__c,
                                    ArticleTest__r.Unit_Type__c, Network__r.RecordType.DeveloperName
                                    FROM Case
                                    WHERE Id IN :caseIds AND Network__c != null];
        depotAreaMap = StarTrackTaskingRuleUtility.taskingRule(updateCases);
        runDockMap = StarTrackRunDockUtility.queryPostCodeMapping(updateCases);
        for (Task newTask : listOfTasks){
            newTask.Depot_Role__c = depotAreaMap.containsKey(newTask.WhatId)?depotAreaMap.get(newTask.WhatId).Id:null;
            newTask.Run_Dock__c = runDockMap.containsKey(newTask.WhatId)?runDockMap.get(newTask.WhatId):null;        
        }
        update listOfTasks;
    }
}