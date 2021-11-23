/**************************************************
Description: Controller Class for Lightning components Startrack task search

History:
--------------------------------------------------
2008-09-18  clint.dsilva@auspost.com.au Created
2020-01-24  Lija.Jawahar@auspost.com.au  Added the related files and enhanced the feed search
**************************************************/
public without sharing class stp_TaskSearch {

    public stp_TaskSearch() {}
    public static Task selTask ;

    public class PickListValue {
        @AuraEnabled public string label {
            get;
            set;
        }
        @AuraEnabled public string value {
            get;
            set;
        }

        public PickListValue(string label, string value) {
            this.label = label;
            this.value = value;
        }
    }

/**
 * User selects search filter and then clicks on search button
 * @param filterType
 * @param consignmentId
 *
 * @return
 */
    @AuraEnabled
    public static List < Task > searchTask(string filterType, string consignmentId) {
        try {
            List < String > taskFields = new List < String > ();
            List < String > taskColumnFields = new List < String > ();

            System.debug('filterType=' + filterType);
            System.debug('consignmentId=' + consignmentId);

            // reading fields of the fieldset to build the query
            for (Schema.FieldSetMember fsm : SObjectType.Task.FieldSets.getMap().get('Task_Results_Community').getFields()) {
                taskColumnFields.add(fsm.getFieldPath());
                System.debug('Task Search Field: ' + fsm.getFieldPath());
            }

            // Identify Network the user has access to, to control task search results
            Set<Id> userNetworkIDs = new Set<Id>();
            for (Depot_Area_User__c userNetwork : [SELECT Depot_Role__r.Depot__r.Id FROM Depot_Area_User__c WHERE User__c = :UserInfo.getUserId()]) {
                userNetworkIDs.add(userNetwork.Depot_Role__r.Depot__r.Id);
            }

            taskFields.addAll(taskColumnFields);

            // Include CaseObject__c to populate scan events section
            String taskQuery = 'SELECT ' + String.join(taskFields, ',') + ' FROM Task WHERE CaseObject__c != null AND CaseObject__r.Enquiry_Type__c != \'' + StarTrack_Constants.CASE_ENQUIRY_LDC + '\'  ';
            String taskQueryFilterType = '';

            taskQuery += ' AND Network__c IN: userNetworkIDs';

            // Include Consignment in the Task search query, when entered
            if (String.isNotBlank(consignmentId)) {
                taskQuery += ' AND Consignment__c =:consignmentId ';
            }

            // When user selects My Team’s Tasks, retrieve Tasks in Status - Waiting for Operations, Not Started or Acknowledged
            // Showing Acknowledged Tasks in this list so a Controlling Depot User will have visibility over Tasks under that Network
            if (String.isNotBlank(filterType) && filterType.equals('My Team’s Tasks')) {
                taskQueryFilterType = ' AND (Status = \'' + StarTrack_Constants.TASK_STATUS_WAITING + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_NOTSTARTED + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED + '\' ) ';

            } else if (String.isNotBlank(filterType) && filterType.equals('My Acknowledged')) {
                // If user selects My Acknowledged
                taskQueryFilterType = ' AND Status = \'' + StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED + '\' AND OwnerId = \'' + UserInfo.getUserId() + '\' ';
            } else if (String.isNotBlank(filterType) && filterType.equals('My Finished Tasks')) {
                // If user selects My Finished Tasks
                taskQueryFilterType = ' AND ( Status = \'' + StarTrack_Constants.TASK_STATUS_FINISHED + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_COMPLETED + '\'  ) AND OwnerId = \'' + UserInfo.getUserId() + '\' ';
            } else {
                // Only include tasks that are in status - Waiting for Operations, Not Started or Acknowledged
                taskQuery += ' AND (Status = \'' + StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_WAITING + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_NOTSTARTED + '\' ) ';
            }

            // User didn't select a filter criteria, and hit Search button
            List < RecordType > startTrackRecTypes = new List < RecordType > ([
                    SELECT Id
                    FROM RecordType
                    WHERE SobjectType = 'Task' AND DeveloperName LIKE '%StarTrack%'
            ]);

            List < String > startTrackRecTypeIds = new List < String > ();
            for (RecordType recType : startTrackRecTypes) {
                startTrackRecTypeIds.add(recType.Id);
            }

            // check to avoid SOQL errors
            if (startTrackRecTypeIds.size() > 0) {
                // restricted to Startrack record types
                taskQueryFilterType += ' AND RecordTypeId IN : startTrackRecTypeIds AND WhatId != NULL';
            }
            // SOQL to be executed
            taskQuery += taskQueryFilterType;
            System.debug('taskQuery=' + taskQuery);

            List <Task> taskList = new List <Task> ();
            taskList = Database.query(taskQuery);

            return taskList;

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            System.debug('[StarTrackPortalTaskSearch] : searchTask() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

/**
 * read the filed set requested via fieldSetName on the object passed in objectName
 *
 * @param fieldSetName
 * @param objectName
 *
 * @return
 */
    @auraEnabled
    public static Object readFieldSet(String fieldSetName, String objectName) {
        try {
            if (String.isBlank(fieldSetName) && String.isBlank(objectName)) {
                return '{error:FieldSet is blank or Object name is blank}';
            }
            Map < String, Schema.SObjectType > GlobalDescribeMap = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
            return JSON.deserializeUntyped(JSON.serialize(fieldSetObj.getFields()));
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            System.debug('[StarTrackPortalTaskSearch] : searchTask() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /**
     *  Method to retrieve Status values for Task Detail
     *  10-10-2019 Added new status - My Finished Task
     *  */
    @AuraEnabled
    public static List < PickListValue > getStatus() {
        //List to hold the Status values.
        List < PickListValue > pickListStatus = new List < PickListValue > ();

        pickListStatus.add(new PickListValue(StarTrack_Constants.TASK_STATUS_NOTSTARTED, StarTrack_Constants.TASK_STATUS_NOTSTARTED));
        pickListStatus.add(new PickListValue(StarTrack_Constants.TASK_STATUS_WAITING, StarTrack_Constants.TASK_STATUS_WAITING));
        pickListStatus.add(new PickListValue(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED));
        pickListStatus.add(new PickListValue(StarTrack_Constants.TASK_STATUS_FINISHED, StarTrack_Constants.TASK_STATUS_FINISHED));

        return pickListStatus;
    }

    /**
    * Method to retrieve Task Update values for Task Detail
    * */
    @AuraEnabled
    public static List < PickListValue > getTaskUpdate() {
        //List to hold the task update values.
        List < PickListValue > pickListTaskUpdate = new List < PickListValue > ();
        Schema.DescribeFieldResult fieldResult = Task.TaskUpdate__c.getDescribe();
        List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();

        //Loop through and add the picklist label and values to the list.
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListTaskUpdate.add(new PickListValue(pickListVal.getLabel(), pickListVal.getLabel()));
        }

        return pickListTaskUpdate;
    }

    /**
     *  Method to retrieve Depot area of the parent Network
     *  This is needed when the agents are Reassigning the task back to Parent Network
     *  */
    @AuraEnabled
    public static List < PickListValue > getDepotArea(string parentNetworkId) {

       System.debug('getDepotAreaList parentNetworkId ==>' + parentNetworkId);
        //Task theTask = getTask(taskId);
        List < PickListValue > depotPickList = new List < PickListValue > ();

        Network__c parentNetwork = [
                SELECT Parent_Network__c, (
                        SELECT Id, Name
                        FROM Depot_Roles__r
                )
                FROM Network__c
                WHERE Id = :parentNetworkId
                LIMIT 1
        ];
        List<Depot_Area__c> depotAreaList = new List<Depot_Area__c>();
        depotAreaList.addAll(parentNetwork.Depot_Roles__r);
        for (Depot_Area__c pickListVal : depotAreaList) {
            depotPickList.add(new PickListValue(pickListVal.Name, pickListVal.Id));
            System.debug(' pickListVal.Name ==>' + pickListVal.Name);
        }
        return depotPickList;
    }

/* Method to retrieve Task details based on taskId */
    @AuraEnabled
    public static Task getTaskDetails(Id taskId) {
        //@deprecate : might need to remove this, we need to refer a method which uses a fieldset+hard coded fields
        //Retrieve the task details based on taskId.
        String taskQuery = 'SELECT ' +
                'CreatedDate, Subject,Network__r.Parent_Network__c, CaseObject__r.Priority_icon__c, CaseObject__r.CaseNumber, ' +
                'CaseObject__r.ArticleTest__c, CaseObject__r.Calc_Case_Consignment__c, CaseObject__r.Enquiry_Type__c, Depot_Role__c, Run_Dock__c, ' +
                'CaseObject__c, CaseObject__r.Article_Receiver_Name__c,CaseObject__r.ATL__c, CaseObject__r.Article_Receiver_Suburb__c, ' +
                'CaseObject__r.Case_Delivery_Collection_Date__c,  CaseObject__r.Case_ATL_Instructions__c, CaseObject__r.Case_Other_ATL_Instructions__c, CaseObject__r.Case_Delivery_Instructions__c'+
                'CaseObject__r.Article_Receiver_Postcode__c, CaseObject__r.AccountId, CaseObject__r.Related_Billing_Account__c, ' +
                'CaseObject__r.Business_Solutions_Customer__c, CaseObject__r.Customer_Stream__c, CaseObject__r.Related_Billing_Account__r.Name, OwnerId, Status, TaskUpdate__c, ' +
                'Priority, TaskSubtype, Network__c' +
                'FROM Task ' +
                'WHERE Id =: taskId';
        sObject rtnTsk = Database.query(taskQuery);
        system.debug(rtnTsk);
        return (Task) rtnTsk;
    }

/**
 * get task by task id, field set is Task_detail
 *
 * @param taskId
 *
 * @return
 */
    @AuraEnabled
    public static Task getTask(string taskId) {
        try {
            Task rtnTsk;
            List < String > taskColumnFields = new List < String > ();
            if (!String.isBlank(taskId)) {
                for (Schema.FieldSetMember fsm : SObjectType.Task.FieldSets.getMap().get('Task_Detail').getFields()) {
                    taskColumnFields.add(fsm.getFieldPath());
                    System.debug('Task Search Field: ' + fsm.getFieldPath());
                }
                String fields = String.join(taskColumnFields, ',') + ',Network__r.Parent_Network__c, CaseObject__r.Priority_icon__c, CaseObject__r.CaseNumber, CaseObject__r.Calc_Case_Consignment__c,   ' +
                        ' CaseObject__r.Business_Solutions_Customer__c,CaseObject__r.ATL__c,CaseObject__r.DeliveryInstructions__c,CaseObject__r.Delivery_Collection_Date__c,CaseObject__r.ATL_Instructions__c,'+
                        ' CaseObject__r.Other_ATL_Instructions__c,CaseObject__r.Customer_Stream__c, CaseObject__r.Related_Billing_Account__r.Name, ' +
                        'Priority, TaskSubtype, Network__r.Name, Owner.Name';

                String taskQuery = 'SELECT ' + fields + ' FROM Task where id = :taskId';
                system.debug('getTask taskQuery=' + taskQuery);
                rtnTsk = Database.query(taskQuery);
                return rtnTsk;
            }
            return null;
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalTaskSearch] : getTask() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

/* Method to save Task details based on taskId */
    @AuraEnabled
    public static String saveTaskDetails(Id taskId, Task taskObj, Id depotAreaId) {

        try {
            String successMsg = 'Record saved successfully';
            String errorMsg = '';
            //Retrieve the status and task update values.
            Task updTask = [SELECT Id, Status,Depot_Role__c,Network__c, TaskUpdate__c, Resolution_Code__c, LastModifiedBy.Name FROM Task WHERE Id = :taskId];
            //Call the validate method to check the status.
            if (validateTask(taskObj)) {
                if (String.isNotBlank(taskObj.CaseObject__c)) {
                    Case thisCase = new Case();
                    //Set the Case Id
                    thisCase.Id = taskObj.CaseObject__c;
                    //Check if task update value is Waiting on Investigator.
                    if (StarTrack_Constants.WAITING_ON_INVESTIGATOR.equals(taskObj.TaskUpdate__c)) {
                        //Set case update and update time fields.
                        thisCase.Case_Update__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
                        thisCase.Case_Update_Time__c = System.now();
                        //Update the case.
                        update thisCase;
                    }
                }

                //if the task Update is to reassign without completeing the task
                if (taskObj.TaskUpdate__c == StarTrack_Constants.TASK_UPDATE_REASSIGN && taskObj.Status != StarTrack_Constants.TASK_STATUS_FINISHED) {
                    System.debug(updTask.Network__c);
                    System.debug(depotAreaId);
                    Network__c network = [
                            SELECT Parent_Network__c,Parent_Network__r.Name, Name
                            FROM Network__c
                            WHERE Id = :updTask.Network__c
                            LIMIT 1
                    ];
                    System.debug(network.Parent_Network__r.Name + '::' + network.Name);
                    if (network != NULL) {
                        updTask.Network__c = network.Parent_Network__c;
                    }
                    updTask.Depot_Role__c = depotAreaId;
                   
                }
                //Set status 
                updTask.Status = taskObj.Status;
                 updTask.TaskUpdate__c = taskObj.TaskUpdate__c;
               
                update updTask;
                return successMsg;
            } else {
                //Build and return the error message.
                errorMsg = 'Task has already been ' + updTask.Status + ' by ' + updTask.LastModifiedBy.Name;
                return errorMsg;
            }
        } catch (Exception ex) {
            // Throw any other exceptions to lightning component as AuraHandled exceptions
            System.debug('[StarTrackPortalTaskSearch] : saveTaskDetails() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

/* Method to validate status based on TaskId */
    public static Boolean validateTask(Task taskObj) {
        selTask = [SELECT Id, Status,TaskUpdate__c FROM Task WHERE Id = :taskObj.Id];
        if (selTask.Status != null) {
            // Check if status value is Finished or Reassigned
            if (selTask.Status == StarTrack_Constants.TASK_STATUS_FINISHED || selTask.Status == StarTrack_Constants.TASK_UPDATE_REASSIGN) {
                return false;
            }
        }
        return true;
    }

/* Method to acknowledge Task details based on TaskId */
    @AuraEnabled
    public static String acknowledgeTaskDetails(Id taskId) {
        try {
            //Retrieve  status and task update values.
            Task updTask = [SELECT Id, Status, TaskUpdate__c, Resolution_Code__c, LastModifiedBy.Name FROM Task WHERE Id = :taskId];
            //Call validate method to check the status.
            if (updTask.Status != StarTrack_Constants.TASK_STATUS_FINISHED) {
                updTask.OwnerId = UserInfo.getUserId();
                updTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
                update updTask;
                return 'Record acknowledged successfully!';
                //return getTaskDetails(taskId);
            } else {
                //Build and return the error message.
                String errMsg = 'Task has already been ' + updTask.Status + ' by ' + updTask.LastModifiedBy.Name;
                AuraHandledException e = new AuraHandledException(errMsg);
                e.setMessage(errMsg);
                throw e;
            }

        } catch (Exception ex) {
            // Throw any other exceptions to lightning component as AuraHandled exceptions
            System.debug('[StarTrackPortalTaskSearch] : saveTaskDetails() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            AuraHandledException e = new AuraHandledException(ex.getMessage());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }

/* Method to acknowledge Task details based on taskId */
    @AuraEnabled
    public static String acknowledgeTasksList(String tasks) {
        try {
            List < Task > updTaskList = new List < Task > ();
            List < Task > tasksList = (List < Task >) JSON.deserialize(tasks, List < Task > .class);
            Set < Id > taskIds = new Set < Id > ();

            // Collect task IDs passed
            for (Task tsk : tasksList) {
                taskIds.add(tsk.Id);
            }

            // Query for tasks in database to compare
            Map < Id, Task > exsistingTasks = new Map < Id, Task > ([SELECT Id, Status FROM Task WHERE Id = :taskIds]);

            // Retrieve the status and task update values.
            for (Task tsk : tasksList) {
                // Call the validate method to check the status.
                if (exsistingTasks.get(tsk.Id).Status == StarTrack_Constants.TASK_STATUS_FINISHED || exsistingTasks.get(tsk.Id).Status == StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED) {
                    // Build and return the error message
                    String errMsg = 'One or more of the selected Task/s have already been updated to Acknowledged or Finished';
                    AuraHandledException e = new AuraHandledException(errMsg);
                    e.setMessage(errMsg);
                    throw e;
                } else {
                    tsk.OwnerId = UserInfo.getUserId();
                    tsk.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
                    updTaskList.add(tsk);
                }
            }

            update updTaskList;

            return 'Record/s acknowledged successfully';

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalTaskSearch] : saveTaskDetails() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            AuraHandledException e = new AuraHandledException(ex.getMessage());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }



/**
 * This is to create new chatter feeds and the standard Feed Publisher is not used
 * any changes to the task should also be saved together with the chatter feed.
 *
 * @param taskObj
 * @param chatterComment
 *
 * @return
 */
    @AuraEnabled
    public static String postToFeed(Task taskObj, String chatterComment) {

        try {
            String message = 'Comment saved';
            //Retrieve the status and task update values.
            Task updTask = [SELECT Id, Status, CaseObject__r.Calc_Case_Consignment__c, TaskUpdate__c, Resolution_Code__c, LastModifiedBy.Name FROM Task WHERE Id = :taskObj.id];
            FeedItem fi = new FeedItem(ParentId = taskObj.id, Body = chatterComment, Visibility = 'AllUsers');
            Database.SaveResult fiSaveResult = Database.insert(fi);
            // we know we are saving a single record here
            // If errors exist, add to a List collection for later notification to admin
            if (!fiSaveResult.isSuccess()) {
                Database.Error error = fiSaveResult.getErrors()[0];
                return 'Unable to comment on consignment ' + updTask.CaseObject__r.Calc_Case_Consignment__c + ' - ' + +error.getStatusCode() + ':' + error.getMessage();
            }

            // If editable fields are changed
            if (updTask.Status != taskObj.Status || updTask.TaskUpdate__c != taskObj.TaskUpdate__c) {
                // Call the validate method to check the status.
                if (validateTask(taskObj)) {
                    // Update task with new details
                    updTask.Operations_Outcome__c = chatterComment;
                    updTask.Status = taskObj.Status;
                    updTask.TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
                    Database.SaveResult caseSaveResult = Database.update(updTask);
                    // we know we are saving a single record here
                    // If errors exist, add to a List collection for later notification to admin
                    if (!caseSaveResult.isSuccess()) {
                        Database.Error error = caseSaveResult.getErrors()[0];
                        return 'Unable to save the Task for consignment ' + updTask.CaseObject__r.Calc_Case_Consignment__c + ' - ' + +error.getStatusCode() + ':' + error.getMessage();
                    } else {
                        return message + ', and task Record saved successfully!';
                    }
                } else {
                    //Build and return the error message.
                    message = 'Task has already been ' + updTask.Status + ' by ' + updTask.LastModifiedBy.Name;
                    return message;
                }
            }
            return message;
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[StarTrackPortalTaskSearch] : saveTaskDetails() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * retreive  the files attached on the mentioned task
    *  Query the files visible to All Users
    *  return the content Documents sorted by created  date Desc
    */
    @AuraEnabled
    public static List<ContentDocumentLink> getContentDocs(Id taskId)
    {
        List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocumentId, Visibility,  ContentDocument.title , ContentDocument.ContentModifiedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :taskId
                AND Visibility = 'AllUsers'
                ORDER BY ContentDocument.ContentModifiedDate DESC
        ];

        if (cdLinks.size() < 1) return new List<ContentDocumentLink>();
        system.debug('ContentDocumentLink.size()== '+ cdLinks.size() );
        return cdLinks;
    }
}