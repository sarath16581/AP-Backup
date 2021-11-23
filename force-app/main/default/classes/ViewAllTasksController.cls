/**
* @author Steve W.
* @date 2020-03-03
* @description: server side controller for LWC - viewAllTasks. Runs without sharing to expose
* any task (including ones created by Auspost staff) to an LBP Community User.
* @changelog
* 2020-03-03 - Steve W - Created
*/

public without sharing class ViewAllTasksController {
    
    /**
     * @description: query for any tasks related to an account
     * @param: recordId - accountId
     * @param: openOrClosed - string specifying which tasks to get
     * @param: offset - Integer used to retrieve additional tasks
     * @return: TaskWrapper - apex class with a list of tasks and integer of the total number of tasks
     */
    @AuraEnabled(cacheable=true)
    public static TaskWrapper getTasks(Id recordId, String openOrClosed, Integer offSet) {
        //as per agreed solution, the oldest date to retrieve tasks from is below 01/07/2019
        String referenceDate = Datetime.newinstance(2019, 07, 01).format('yyyy-MM-dd');
        //build a list of query where clause statements
        Map<String, Object> searchParams = new Map<String, Object>();
        searchParams.put('ActivityDate', referenceDate);
        searchParams.put('WhatId', recordId);

        if(!String.isBlank(openOrClosed) && openOrClosed == 'open'){
            searchParams.put('IsClosed', false);
        } else if(!String.isBlank(openOrClosed) && openOrClosed == 'closed'){
            searchParams.put('IsClosed', true);
        }

        Integer offsetToUse = (offSet != null ? offSet : 0);

        //get tasks with the contact name and owner name
        Set<Object> selectorOpts = new Set<Object>{TasksSelector.Options.WITH_OWNER, TasksSelector.Options.WITH_CONTACT};
        Map<SObjectType, Set<SObjectField>> fieldOverride = new Map<SObjectType, Set<SObjectField>>();
        Set<SobjectField> fields = new Set<SobjectField>();
        //Add field overrides for related fields
        
        fields.add(User.Name);
        fields.add(User.Id);
        fieldOverride.put(((SObject) Type.forName('User').newInstance()).getSObjectType(), fields);
        fields.clear();

        fields.add(Contact.Name);
        fields.add(Contact.Id);
        fieldOverride.put(((SObject) Type.forName('Contact').newInstance()).getSObjectType(), fields);

   
        TasksSelector sel = TasksSelector.newInstance(offSetToUse);
        sel.setFieldOverrides(fieldOverride);
        
        List<Task> allTasks = sel.search(searchParams, selectorOpts, true).values();

        List<Task> limitedTasksToReturn = new List<Task>();

        //Return the first 10 tasks
        for(Integer i = 0; i < 10; i++){
            if(allTasks.size() > i){
                limitedTasksToReturn.add(allTasks[i]);
            }
        }
        
        TaskWrapper tw = new TaskWrapper();
        tw.tasks = limitedTasksToReturn;
        tw.total = allTasks.size();

        return tw;
    }

    /**
     * @description wrapper class for Task Data
    */
    public class TaskWrapper {
        @AuraEnabled
        public List<Task> tasks { get; set; }
        @AuraEnabled
        public Integer total { get; set; }
    }
}