/**
 ** Description: Controller for StarTrackTaskRListSidePanel page
 ** Author: Jen Karen Tan
 ** Date Created: OCT.26.2016
 ** History:--------------------------------------------
 **     OCT.26.2016     Jen Karen Tan - Created
 **/
 public class StarTrackTaskRListSidePanel_Controller {
    public Case caseRecord {get; set;}
    public List<Task> taskList {get; set;}
    public List<Task> retrievedTasks {get; set;}
    public Integer currentPage;
    public Integer startIndex;
    public Integer endIndex;
    public Integer taskListSize;
    public Integer REC_PER_PAGE = 5;
    public boolean disableNextBtn {get; set;}
    
    public StarTrackTaskRListSidePanel_Controller(ApexPages.StandardController controller) {
        caseRecord = (Case) controller.getRecord();
        getTasks(caseRecord.Id);
        currentPage = 1;
        startIndex = 0;
        endIndex = REC_PER_PAGE;
        taskList = getTasksToFrom();
    }
    
    /**********************************************************
    **Description: Method for getting tasks related to Case
    **Parameters: N/A
    **Returns: void
    **Author: Jen Karen Tan
    **Date Created: OCT.26.2016
    **********************************************************/
    public void getTasks(Id caseId) {
        retrievedTasks = new List<Task>();
        if (caseId != null) {
            Id starTrackTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId();
            retrievedTasks = new List<Task>([SELECT Id, WhatId, Status, Subject, TaskUpdate__c, OwnerId, Type, Sub_Type__c 
                FROM Task WHERE WhatId =: caseId AND RecordTypeId =: starTrackTaskRecordTypeId]);
        }
        taskListSize = retrievedTasks.size();
    }
    
    /**********************************************************
    **Description: Method for getting tasks depending on start and end index
    **Parameters: N/A
    **Returns: List<Task>
    **Author: Jen Karen Tan
    **Date Created: OCT.26.2016
    **********************************************************/
    public List<Task> getTasksToFrom() {
        List<Task> tasks = new List<Task>();
        if (endIndex >= taskListSize) {
            endIndex = taskListSize;
            disableNextBtn = true;
        } else {
            disableNextBtn = false;
        }
        for(Integer i = startIndex ; i < endIndex ; i++ ) {
            tasks.add(retrievedTasks[i]);
        }
        return tasks;
    }
    
    /**********************************************************
    **Description: Method for getting tasks on the next page
    **Parameters: N/A
    **Returns: void
    **Author: Jen Karen Tan
    **Date Created: OCT.26.2016
    **********************************************************/
    public void next() {
        currentPage++;
        startIndex += REC_PER_PAGE;
        endIndex = REC_PER_PAGE * currentPage;
        taskList = getTasksToFrom();
    }
    
    /**********************************************************
    **Description: Method for getting tasks on the previous page
    **Parameters: N/A
    **Returns: void
    **Author: Jen Karen Tan
    **Date Created: OCT.26.2016
    **********************************************************/
    public void previous() {
        currentPage--;
        startIndex -= REC_PER_PAGE;
        endIndex = REC_PER_PAGE * currentPage;
        taskList = getTasksToFrom();
    }
    
    /**********************************************************
    **Description: Method for setting previous btn visibility
    **Parameters: N/A
    **Returns: void
    **Author: Jen Karen Tan
    **Date Created: OCT.26.2016
    **********************************************************/
    public boolean getDisablePreviousBtn () {
        if (currentPage == 1) {
            return true;
        } else {
            return false;
        }
    }

}