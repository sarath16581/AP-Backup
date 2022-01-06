/*------------------------------------------------------------
Author:        Jen Karen Tan
Description:   Handler class for Task Update
This class is required to run without sharing to allow updating Tasks owned by other users
History
September 1, 2016 - Jen Karen Tan - Created
October 02, 2017 - Angelo Rivera - Added Methods for Minor Work MWT0004521
August 13, 2021 - Steve Judd - Changed method updateTasksRelatedCaseRecord for MW0004540
October 7, 2021 - Steve Judd - Updated pending status logic to fix bug for authorised contacts in updateTasksRelatedCaseRecord
------------------------------------------------------------*/
public without sharing class StarTrackTaskHandler{

    public static Set<Id> taskIds = new Set<Id>();
    public static Set<Id> setTaskIds = new Set<Id>();
    public static List<Task> taskList = new List<Task>();

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   Method that retrieves and updates valid Task for Task Update field update (FeedItem)
    History:
    September 1, 2016 - Jen Karen Tan - Created
    September 27, 2016 - Jen Karen Tan - Updated - moved main logic to updateTaskUpdate method
    ------------------------------------------------------------*/
    public static void updateTaskUpdateField(List<FeedItem> feedItemList) {

        //get user profile details
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];

        //continue if user's profile is StarTrack Support
        if (StarTrack_Constants.PROFILE_ST_SUPPORT.equals(userProfile.Name)) {
            //retrieves tasksids of valid FeedItems
            getValidFeedItems(feedItemList);
            //update Task Update field
            updateTaskUpdate();
            //updateTasksRelatedCaseOwner();            
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   Method that retrieves and updates valid Task for Task Update field update (FeedComment)
    History:
    September 27, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public static void updateTaskUpdateField(List<FeedComment> feedCommentList) {

        //get user profile details
        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];

        //continue if user's profile is StarTrack Support
        if (StarTrack_Constants.PROFILE_ST_SUPPORT.equals(userProfile.Name)) {
            //retrieves tasksids of valid FeedItems
            getValidFeedComments(feedCommentList);
            //update Task Update field
            updateTaskUpdate();
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   Method that retrieves and updates valid Task for Task Update field update
    History:
    September 27, 2016 - Jen Karen Tan - Created - extracted from updateTaskUpdateField(List<FeedItem> feedItemList)
    											   separated method to be reused
    ------------------------------------------------------------*/
    public static void updateTaskUpdate() {
        if (!taskIds.isEmpty()) {
            //query tasks
            taskList = new List<Task>([SELECT Id, RecordTypeId, Type, TaskUpdate__c, Status FROM Task WHERE Id IN: taskIds]);
            if (!taskList.isEmpty()) {

                List<RecordType> recTypes = new List<RecordType>([SELECT Id, DeveloperName
                FROM RecordType WHERE SobjectType = 'Task' AND DeveloperName = 'StarTrack_Task' LIMIT 1]);
                Id starTrackTaskRecordId = recTypes.isEmpty() ? null : recTypes[0].Id;

                List<Task> tasksToUpdate = new List<Task>();

                for (Task t : taskList) {
                    //modifies valid task items
                    if (t.RecordTypeId.equals(starTrackTaskRecordId) && StarTrack_Constants.TASK_TYPE_OPERATION.equals(t.Type)
                            && !(StarTrack_Constants.TASK_STATUS_FINISHED.equals(t.Status))
                            && !(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equals(t.Status))) {
                        t.TaskUpdate__c = StarTrack_Constants.INVESTIGATOR_RESPONDED;
                        tasksToUpdate.add(t);
                        setTaskIds.add(t.Id);
                    }
                }
                if (!tasksToUpdate.isEmpty()) {
                    update tasksToUpdate;
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Angelo Rivera 
    Description:   Minor Work MWT0004521 - Method that updates the case of task's related case object
    History:
    September 28, 2017 - Created
    August 12, 2021 -  Minor Work MW0004540 SJudd Added new filter criteria for Finished - Case Resolved Status
                        for check address, depot collection and redirection
    ------------------------------------------------------------*/
    public static void updateTasksRelatedCaseRecord(List<Task> lstTask){
        StarTrack_Settings__c stSettingsCCR = StarTrack_Settings__c.getOrgDefaults();
        Boolean autoCloseCustomSetting = stSettingsCCR.StarTrack_AutoClose_Case_from_Task__c;
        Boolean autoCloseCustomPermission = FeatureManagement.checkPermission(StarTrack_Constants.ST_CASE_AUTOCLOSE_CUST_PERM);
        Set<Id> setCaseToBeClosed = new Set<Id>();
        Set<Id> setCaseToBeTransferredToInvQueue = new Set<Id>();
        Set<Id> setCaseWithResolvedTasks = new Set<Id>();
        set<Id> setCaseToPending = new Set<Id>();
        Map<Id,Task> mapCaseIdWithTask = new Map<Id,Task>();
        if(!lstTask.isEmpty()){
            Id starTrackTaskRecordId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId();
            // MW0004540 Added status Finished - Case Resolved so that the case closes if functionality is enabled
            // by custom permission or custom setting.
            for(Task tsk : lstTask){
                if(tsk.RecordTypeId.equals(starTrackTaskRecordId) && StarTrack_Constants.TASK_TYPE_OPERATION.equals(tsk.Type)
                        && (StarTrack_Constants.TASK_STATUS_FINISHED.equals(tsk.Status))){
                    setCaseToBeClosed.add(tsk.WhatId);
                }else if(tsk.RecordTypeId.equals(starTrackTaskRecordId) && StarTrack_Constants.TASK_TYPE_OPERATION.equals(tsk.Type)
                        && (StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equals(tsk.Status))){
                    setCaseToBeClosed.add(tsk.WhatId);
                    setCaseWithResolvedTasks.add(tsk.WhatId);
                    // MW0004540 we can reasonably assume only one depot collection will be Finished Resolved for each case
                    if(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(tsk.CaseType__c) && tsk.Network__c != null){
                        mapCaseIdWithTask.put(tsk.CaseObject__c,tsk);
                    }
                }else if(tsk.RecordTypeId.equals(starTrackTaskRecordId) && StarTrack_Constants.TASK_TYPE_OPERATION.equals(tsk.Type)
                        && StarTrack_Constants.WAITING_ON_INVESTIGATOR.equals(tsk.TaskUpdate__c)){
                    setCaseToBeTransferredToInvQueue.add(tsk.WhatId);
                }
            }

            if(!setCaseToBeClosed.isEmpty()){
                List<Case> lstCaseToBeUpdated = new List<Case>();
                for(Case caseRecord : [Select Id, Owner_is_Queue__c, Network__c, Exclude_Notification_Automation__c, All_Manual_Communications_Completed__c,
                                        OwnerId, Case_Update__c, Call_Purpose__c, ResolutionCode__c, Status, Enquiry_Type__c,
                                        (SELECT Id, Calc_Contact_Email__c, Case__c, Calc_Contact_Mobile_Number__c, Calc_First_Name__c, Calc_Last_Name__c, Notification_Required__c, Notified_on_Status__c, Pref_Method_of_Contact__c, Name
                                        FROM Authorised_Contacts__r WHERE Notification_Required__c = :StarTrack_Constants.ST_TRUE AND Pref_Method_of_Contact__c != null)
                                        FROM Case where Id in: setCaseToBeClosed]){
                    if(caseRecord.Call_Purpose__c == StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED){
                        caseRecord.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                        caseRecord.ResolutionCode__c  = StarTrack_Constants.CASE_RESOLUTIONCODE_INVCOMPLETED;
                        caseRecord.Case_Update__c = StarTrack_Constants.CASE_UPDATE_OPERATIONSRESP;
                        caseRecord.OwnerId = stSettingsCCR.SWMYTempQueue__c;
                        lstCaseToBeUpdated.add(caseRecord);
                    }
                    // MW0004540 allow autoclose of cases - only close where the notification is true or manual communication are completed
                    // Otherwise set the status to Pending Customer Notification
                    else if(setCaseWithResolvedTasks.contains(caseRecord.Id) &&
                        (caseRecord.Enquiry_Type__c == StarTrack_Constants.CASEENTYPE_CHECKADDRESS ||
                        caseRecord.Enquiry_Type__c == StarTrack_Constants.CASE_ENQUIRY_REDIRECTION ||
                        caseRecord.Enquiry_Type__c == StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION)
                        && (autoCloseCustomSetting || autoCloseCustomPermission)){

                        caseRecord.Case_Update__c = StarTrack_Constants.CASE_UPDATE_OPERATIONSRESP;
                        
                        for(AuthorisedContacts__c relCont : caseRecord.Authorised_Contacts__r) {
                            if (StarTrack_Constants.CASE_ORIGIN_PHONE.equals(relCont.Pref_Method_of_Contact__c) || (StarTrack_Constants.CASE_ORIGIN_EMAIL.equals(relCont.Pref_Method_of_Contact__c) && String.isBlank(relCont.Calc_Contact_Email__c)) ||
                                    (StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isBlank(relCont.Calc_Contact_Mobile_Number__c)) || //Validate if status must be set to 'Pending Customer Notification.'
                                    (StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isNotBlank(relCont.Calc_Contact_Mobile_Number__c) && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRecord.Enquiry_Type__c) && String.isBlank(relCont.Calc_Contact_Email__c)) // MW0004540 set depot collection to pending as is needs both mobile number and email
                                    && /**!StarTrack_Constants.CASE_STAT_PENCUSNOTIF.equals(caseRecord.Status) && */!caseRecord.All_Manual_Communications_Completed__c) {
                                caseRecord.Status = StarTrack_Constants.CASE_STAT_PENCUSNOTIF;
                                setCaseToPending.add(caseRecord.Id);
                            }
                        }
                        // Set status to Pending Customer Notification if notification excluded or there is no contact with preferred communication method
                        if((caseRecord.Exclude_Notification_Automation__c && !caseRecord.All_Manual_Communications_Completed__c) || caseRecord.Authorised_Contacts__r.size() < 1){
                            caseRecord.Status = StarTrack_Constants.CASE_STAT_PENCUSNOTIF;
                        } else if(setCaseToPending.contains(caseRecord.Id)) {
                            caseRecord.Status = StarTrack_Constants.CASE_STAT_PENCUSNOTIF;
                        } else {
                            caseRecord.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                        }
                            caseRecord.Case_Update__c = StarTrack_Constants.CASE_UPDATE_OPERATIONSRESP;
                        if(caseRecord.Enquiry_Type__c == StarTrack_Constants.CASEENTYPE_CHECKADDRESS){
                            caseRecord.ResolutionCode__c  = StarTrack_Constants.CASE_RESOLUTIONCODE_INVCOMPLETED;
                        } else if(caseRecord.Enquiry_Type__c == StarTrack_Constants.CASE_ENQUIRY_REDIRECTION){
                            caseRecord.ResolutionCode__c  = StarTrack_Constants.CASE_RESOLUTIONCODE_REDIRECTED;
                        } else if(caseRecord.Enquiry_Type__c == StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION){
                            caseRecord.ResolutionCode__c  = StarTrack_Constants.CASE_RESOLUTIONCODE_DEPOTCOLLECTION;
                            //MW0004540 If the closing case has a different network then change to the task network
                            // for depot collection only
                            if(!mapCaseIdWithTask.isEmpty() && mapCaseIdWithTask.get(caseRecord.Id).Network__c != null && caseRecord.Network__c != mapCaseIdWithTask.get(caseRecord.Id).Network__c ){
                                caseRecord.Network__c = mapCaseIdWithTask.get(caseRecord.Id).Network__c;
                            }
                        }
                            lstCaseToBeUpdated.add(caseRecord);
                    }
                }

                if(!lstCaseToBeUpdated.isEmpty()){
                    Update lstCaseToBeUpdated;
                }
            }

            if(!setCaseToBeTransferredToInvQueue.isEmpty()){
                List<Case> lstCaseToBeTransferred = new List<Case>();
                for(Case caseRecord : [Select Id, Owner_is_Queue__c, OwnerId, Call_Purpose__c, ArticleTest__r.Product_Group__c, RecordType.Name,
                        Enquiry_Type__c, Account.StarTrack_Customer_Stream__c, Initial_Caller_Type__c, Business_Solutions_Customer__c,
                        Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c, Network__r.OwnerId
                from Case where Id in: setCaseToBeTransferredToInvQueue]){
                    if(caseRecord.Call_Purpose__c == StarTrack_Constants.CASE_PURPOSE_DEPOTCREATED){
                        lstCaseToBeTransferred.add(caseRecord);
                    }
                }
                if(!lstCaseToBeTransferred.isEmpty()){
                    updateCaseOwner(lstCaseToBeTransferred);
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Angelo Rivera 
    Description:   Minor Work MWT0004521 - Method that updates the case owner
    History:
    October 2, 2017 - Created
    ------------------------------------------------------------*/
    public static void updateCaseOwner(List<Case> lstCaseRecords){
        if(!lstCaseRecords.isEmpty()){
            List<StarTrack_Transfer_Case_Rule__c> tc_rules = new List<StarTrack_Transfer_Case_Rule__c>();
            tc_rules = [SELECT Id, Business_Solutions_Customer__c, Case_Purpose__c, Case_RecordType__c, Case_Type__c,Service_Cloud_Rule__c, Customer_Stream__c, Initial_Caller_Type__c, Order__c, Product_Group__c, Queue_Name__c
            FROM StarTrack_Transfer_Case_Rule__c ORDER BY Order__c];

            if(!tc_rules.isEmpty()){
                Boolean ruleSatisfied = false;
                List<Case> lstCaseToBeUpdated = new List<Case>();
                for(Case c : lstCaseRecords){
                    for(StarTrack_Transfer_Case_Rule__c tc_rule : tc_rules){
                        if((String.isNotBlank(tc_rule.Case_Purpose__c) ? c.Call_Purpose__c == tc_rule.Case_Purpose__c : true)
                                && (String.isNotBlank(tc_rule.Case_RecordType__c) ? c.RecordType.Name == tc_rule.Case_RecordType__c : true)
                                && (String.isNotBlank(tc_rule.Case_Type__c) ? c.Enquiry_Type__c == tc_rule.Case_Type__c : true)
                                && (String.isNotBlank(tc_rule.Customer_Stream__c) ? c.Account.StarTrack_Customer_Stream__c == tc_rule.Customer_Stream__c : true)
                                && (String.isNotBlank(tc_rule.Initial_Caller_Type__c) ? c.Initial_Caller_Type__c == tc_rule.Initial_Caller_Type__c : true)
                                && (String.isNotBlank(tc_rule.Product_Group__c) ? c.ArticleTest__r.Product_Group__c == tc_rule.Product_Group__c : true)
                                && (tc_rule.Business_Solutions_Customer__c ? c.Business_Solutions_Customer__c == tc_rule.Business_Solutions_Customer__c : true)
                                && tc_rule.Service_Cloud_Rule__c){
                            if(tc_rule.Queue_Name__c == StarTrack_Constants.TRANSFER_QUEUE){
                                if(String.isBlank(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c)){
                                    c.OwnerId = null;
                                }else{
                                    c.OwnerId = queryQueue(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c);
                                }
                                ruleSatisfied = true;
                                break;
                            }else{
                                c.OwnerId = queryQueue(tc_rule.Queue_Name__c);
                                ruleSatisfied = true;
                                break;
                            }
                        }
                    }
                    if(!ruleSatisfied && String.isNotBlank(c.Network__r.OwnerId)){
                        c.OwnerId = c.Network__r.OwnerId;
                    }
                    lstCaseToBeUpdated.add(c);
                }

                if(!lstCaseToBeUpdated.isEmpty()){
                    update lstCaseToBeUpdated;
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Angelo Rivera 
    Description:   Minor Work MWT0004521 - Method that queries the queue
    History:
    October 2, 2017 - Created
    ------------------------------------------------------------*/
    public static Id queryQueue(String queueName){
        try{
            return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :queueName].Id;
        }catch(QueryException e){
            return null;
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   Method that retrieves Task Ids from valid FeedItem details
    History:
    September 1, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public static void getValidFeedItems(List<FeedItem> feedItems) {
        for (FeedItem fi : feedItems) {
            if (fi.ParentId != null && String.valueOf(fi.ParentId).startsWith(StarTrack_Constants.ID_PREFIX_TASK)
                    && (StarTrack_Constants.FEED_ITEM_TYP_TEXTPOST).equals(fi.Type)) {
                taskIds.add(fi.ParentId);
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   Method that retrieves Task Ids from valid FeedComment details
    History:
    September 27, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public static void getValidFeedComments(List<FeedComment> feedComments) {
        for (FeedComment fc : feedComments) {
            if (fc.ParentId != null && String.valueOf(fc.ParentId).startsWith(StarTrack_Constants.ID_PREFIX_TASK)
                    && (StarTrack_Constants.FEED_COMM_TYP_TXTCOMM).equals(fc.CommentType)) {
                taskIds.add(fc.ParentId);
            }
        }
    }
}