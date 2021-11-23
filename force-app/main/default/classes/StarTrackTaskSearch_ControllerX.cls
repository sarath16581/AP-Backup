/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Contoller class for StarTrack Task Search page
Inputs:
Test Class:    StarTrackTaskSearch_ControllerX_Test
History
September 10, 2015 - Patrick James Franco - Created
September 17, 2015 - David Catindoy - Modified
February 23, 2016 - David Catindoy (Modified to include additional logic)
December 21, 2016 - Davey Yu   - Updated searchTasks method to improve performance 
August 28, 2017 - Ramya CHintakula  Added validation to not let LDC tasks reassigned.
August 24, 2021 - Steve Judd MW0004540 - Modified validation for Task Status Finished - Case Resolved
September 10, 2021 - Steve Judd MW0004540 - Modified saveTaskDetails for setting Finished Time.
September 16, 2021 - Steve Judd MW0004540 - Added Task Status of Finished - Case Resolved to selectOption
------------------------------------------------------------*/

public class StarTrackTaskSearch_ControllerX {

    // Pagination
    public Integer limitBy {get; set;}
    public Integer offset {get; set;}
    public Integer listCounter {get; set;}
    public Integer totalResultSize {get; set;}
    public Integer currentTaskResultPage {get; set;}
    public Integer totalTaskResultPage {get; set;}
    public String pageResultText {get; set;}

    // Filters
    public String filterType {get; set;}
    public List<String> taskStatus {get; set;}
    public List<String> runDock {get; set;}
    public List<String> bulkField {get; set;}
    public List<String> depotAreaList {get; set;}
    public String consignment {get; set;}
    public Task dummyTaskA {get; set;}
    public Task dummyTaskb {get; set;}
    public Case dummyCase {get; set;}
    public Set<Id> thisUserDepotRole {get; set;}

    // Search results
    public List<TaskWrapper> resultTaskWrapper {get; set;}
    public Map<Id, TaskWrapper> resultTaskWrapperMap {get; set;}
    public TaskWrapper selectedTaskWrapper {get; set;}
    public TaskWrapper previousRecord {get; set;}
    public String selectedTaskId {get; set;}
    public String selectedConsignmentId {get; set;}
    public Boolean displayCustomFilters {get; set;}
    public Boolean displayAreaTasksFilters {get; set;}
    List<String> taskColumnFields = new List<String>();
    List<String> taskDetailFields = new List<String>();
    List<String> taskFields = new List<String>();

    Map<String, Id> taskIdByArticleId = new Map<String, Id>();

    // Search result sorting
    String sortExp = '';
    String sortDir = '';
    public String sortExpression {get; set;}
    public Boolean detailAcknowledge {get; set;}
    public Boolean detailPrint {get; set;}

    public Boolean showScanEventsNoConsign {get; set;}
    public Boolean taskJustAcknowledged {get; set;}
    public Boolean limitExceeded {get; set;}
    public Boolean funcErr {get; set;}
    public Boolean initChatterLoad {get; set;}
    public Boolean displayDepotAreaFilter {get; set;}

    public String idsForPDFPrinting {get; set;}
    public String idForPDFPrinting {get; set;}

    public String chatterComment {get; set;}
    
    public String depotAreaId {get; set;}

    List<Task> taskList = new List<Task>();
    
    StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
    public Boolean isAutoCloseEnabled { get; set; }

    //Depot Area reassign
    public boolean displayListPopUp {get; set;}     
    public boolean displayDetailPopUp {get; set;}    
    public Id bulkTaskNetworkId = null;
    public Task bulkTaskObj = null;
    public List<TaskWrapper> bulkTaskList = new List<TaskWrapper>();
    public boolean detailReassign {get; set;}
    public TaskWrapper twSelectedCont {get; set;}

    public StarTrackTaskSearch_ControllerX(){
        initChatterLoad = true;
        limitExceeded = false;
        showScanEventsNoConsign = false;
        detailAcknowledge = false;
        detailPrint = false;
        taskJustAcknowledged = false;
        displayDepotAreaFilter = false;
        previousRecord = new TaskWrapper(null);
        setDefaultValues();
        dummyTaskA = new Task();
        dummyTaskB = new Task();
        dummyCase = new Case();

        filterType = '';
        chatterComment = '';

        getCurrentUserInfo();
        isAutoCloseEnabled = StarTrack_Constants.CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK;
        displayCustomFilters = false;
        displayAreaTasksFilters = false;

        taskStatus = new List<String>();
        runDock = new List<String>();
        bulkField = new List<String>();
        depotAreaList = new List<String>();
        consignment = '';

        // Get Task column fields
        for(Schema.FieldSetMember fsm : SObjectType.Task.FieldSets.getMap().get('Task_Search').getFields()){
            taskColumnFields.add(fsm.getFieldPath());
            System.debug('Task Search Field: ' + fsm.getFieldPath());
        }

        // Get Task detail fields
        for(Schema.FieldSetMember fsm : SObjectType.Task.FieldSets.getMap().get('Task_Detail').getFields()){
            taskDetailFields.add(fsm.getFieldPath());
        }
        Set<String> taskFieldFilter = new Set<String>();
        taskFieldFilter.addAll(taskColumnFields);
        taskFieldFilter.addAll(taskDetailFields);
        taskFieldFilter.add('Resolution_Code__c');
        taskFieldFilter.add('CaseObject__r.Status');
        taskFields.addAll(taskFieldFilter);

        // Run first search
        for(Task_Search_Settings__c tss : Task_Search_Settings__c.getAll().values()){
            if(tss.Default__c){
                filterType = tss.Name;
                break;
            }
        }
        if(filterType.equals('My Area Tasks')){
            displayAreaTasksFilters = true;
        }
        
        /*if (stSettings.OperationsTaskSearchQueryLimit__c != null || stSettings.OperationsTaskSearchQueryLimit__c > 0) {
            taskSearchLimit = Integer.valueOf(stSettings.OperationsTaskSearchQueryLimit__c);
        }*/
        
        searchTasks();
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that fetches the mapped Depot Area of the current user
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void getCurrentUserInfo(){
        thisUserDepotRole = new Set<Id>();

        for(Depot_Area_User__c dau : [SELECT Depot_Role__c, Name FROM Depot_Area_User__c WHERE User__c = :UserInfo.getUserId()]){
            thisUserDepotRole.add(dau.Depot_Role__c);
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that searches and sorts the Task according to different filters
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    September 30, 2015 - Patrick James Franco - Removed OwnerId filter on My Area Tasks
    August 4, 2016 - Jen Karen Tan - Updated pagination implementation
    December 21, 2016 - Davey Yu   - Updated to query size with a single field to avoid heap exception and improve perf
    ------------------------------------------------------------*/
    public void searchTasks(){
        funcErr = false;
        // Reset Task results
        resultTaskWrapper = new List<TaskWrapper>();
        resultTaskWrapperMap = new Map<Id, TaskWrapper>();

        // Reset selected Task detail
        selectedTaskWrapper = new TaskWrapper(null);
        selectedTaskId = '';
        selectedConsignmentId = '';
        showScanEventsNoConsign = false;
        limitExceeded = false;

        if(!taskColumnFields.isEmpty()){

            // Sorting logic
            if(String.isNotBlank(sortExpression)){
                // Change sort direction
                if(sortExpression.equals(sortExp)){
                    sortDir = (sortDir == 'ASC') ? 'DESC' : 'ASC';
                    offset = 0;
                }
                else{
                    sortExp = sortExpression;
                    sortDir = 'ASC';
                }
                sortExpression = '';
            }
            else{
                // Default sort
                if(String.isBlank(sortExp)){
                    sortExp = 'CreatedDate';
                    sortDir = 'DESC';
                }
            }

            // Default query
            String taskQuery = 'SELECT ' + String.join(taskFields, ',') + ' FROM Task ';

            // Filter Type selection
            if(filterType.equals('My Area Tasks')){
                taskQuery += 'WHERE (Status = \'' + String.escapeSingleQuotes(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED) + '\' OR Status = \'' + StarTrack_Constants.TASK_STATUS_WAITING + '\') AND Depot_Role__c IN :thisUserDepotRole ';
                // Run Dock
                if(!runDock.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Run_Dock__c IN :runDock ';
                    }
                    else{
                        taskQuery += 'WHERE Run_Dock__c IN :runDock ';
                    }
                }
                // Bulk
                if(!bulkField.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Bulk__c IN :bulkField ';
                    }
                    else{
                        taskQuery += 'WHERE Bulk__c IN :bulkField ';
                    }
                }
            }
            else if(filterType.equals('My Acknowledged')){
                taskQuery += 'WHERE Status = \'' + String.escapeSingleQuotes(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED) + '\' AND OwnerId = \'' + UserInfo.getUserId() + '\' ';
            }
            else if(filterType.equals('My Finished Tasks')){
                
                taskQuery += 'WHERE (Status = \'' + String.escapeSingleQuotes(StarTrack_Constants.TASK_STATUS_FINISHED) + '\' OR Status = \'' + String.escapeSingleQuotes(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED) + '\') AND OwnerId = \'' + UserInfo.getUserId() + '\' ';

                if(String.isBlank(String.valueOf(dummyTaskA.Case_Delivery_Collection_Date__c)) && String.isBlank(String.valueOf(dummyTaskB.Case_Delivery_Collection_Date__c))){
                    Date startDate = Date.today().addMonths(-1);
                    Date endDate = Date.today().addDays(1);
                    taskQuery += 'AND CreatedDate >= :startDate AND CreatedDate <= :endDate ';
                }
            }
            else if(filterType.equals('Custom')){

                // Depot
                if(String.isNotBlank(dummyTaskA.Network__c)){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Network__c = \'' + dummyTaskA.Network__c + '\' ';
                    }
                    else{
                        taskQuery += 'WHERE Network__c = \'' + dummyTaskA.Network__c + '\' ';
                    }
                }

                // Depot Area
                if(!depotAreaList.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Depot_Role__c IN :depotAreaList ';
                    }
                    else{
                        taskQuery += 'WHERE Depot_Role__c IN :depotAreaList ';
                    }
                }

                // Owner
                if(String.isNotBlank(dummyTaskA.OwnerId)){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND OwnerId = \'' + dummyTaskA.OwnerId + '\' ';
                    }
                    else{
                        taskQuery += 'WHERE OwnerId = \'' + dummyTaskA.OwnerId + '\' ';
                    }
                }

                // Legal Entity
                if(String.isNotBlank(dummyCase.AccountId)){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND CaseObject__r.AccountId = \'' + dummyCase.AccountId + '\' ';
                    }
                    else{
                        taskQuery += 'WHERE CaseObject__r.AccountId = \'' + dummyCase.AccountId + '\' ';
                    }
                }

                // Run Dock
                if(!runDock.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Run_Dock__c IN :runDock ';
                    }
                    else{
                        taskQuery += 'WHERE Run_Dock__c IN :runDock ';
                    }
                }

                // Bulk
                if(!bulkField.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Bulk__c IN :bulkField ';
                    }
                    else{
                        taskQuery += 'WHERE Bulk__c IN :bulkField ';
                    }
                }

                // Status
                if(!taskStatus.isEmpty()){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Status IN :taskStatus ';
                    }
                    else{
                        taskQuery += 'WHERE Status IN :taskStatus ';
                    }
                }
                
                // Consignment
                if(String.isNotBlank(consignment)){
                    if(taskQuery.contains(' WHERE ')){
                        taskQuery += 'AND Consignment__c =:consignment ';
                    }
                    else{
                        taskQuery += 'WHERE Consignment__c =:consignment ';
                    }
                }
            }
            
            // Start Date Range
            if(String.isNotBlank(String.valueOf(dummyTaskA.Case_Delivery_Collection_Date__c))){
                Date dateA = dummyTaskA.Case_Delivery_Collection_Date__c;
                if(taskQuery.contains(' WHERE ')){
                    taskQuery += 'AND CreatedDate >= :dateA ';
                } else {
                    taskQuery += 'WHERE CreatedDate >= :dateA ';
                }
            }
                
            // End Date Range
            if(String.isNotBlank(String.valueOf(dummyTaskB.Case_Delivery_Collection_Date__c))){
                Date dateB = dummyTaskB.Case_Delivery_Collection_Date__c;
                dateB = dateB.addDays(1);
                if(taskQuery.contains(' WHERE ')){
                    taskQuery += 'AND CreatedDate <= :dateB ';
                } else {
                    taskQuery += 'WHERE CreatedDate <= :dateB ';
                }
            }
            
         // Default StarTrack filter
           if(String.isNotBlank(filterType)){
                //Added by DYU Dec 2016 - Create a list of recordtype ids for startrack which will be used on where clause
                //Updated by David Catindoy Feb 2, 2017 - To make sure that only Task recordtype will be queried.
                List<RecordType> startTrackRecTypeIds = new List<RecordType>([SELECT Id FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName LIKE '%StarTrack%']);
                //startTrackRecTypeIds = [SELECT Id from RecordType where DeveloperName LIKE '%StarTrack%'];
                
                if(startTrackRecTypeIds.size() > 0) {
                    if(taskQuery.contains(' WHERE ')){
                        //Added by DYU Dec 2016 - Replace LIKE clause with IN clause to make query more efficient which query on the same object
                        //taskQuery += 'AND RecordType.DeveloperName LIKE \'%StarTrack%\' AND Type = \'Operations Task\' AND WhatId != NULL ORDER BY ' + sortExp + ' ' + sortDir + ' ';
                        taskQuery += 'AND RecordTypeId IN : startTrackRecTypeIds AND Type = \'Operations Task\' AND WhatId != NULL ORDER BY ' + sortExp + ' ' + sortDir + ' ';
                    }
                    else{
                        //Added by DYU Dec 2016 - Replace LIKE clause with IN clause to make query more efficient which query on the same object
                        //taskQuery += 'WHERE RecordType.DeveloperName LIKE \'%StarTrack%\' AND Type = \'Operations Task\' AND WhatId != NULL ORDER BY ' + sortExp + ' ' + sortDir + ' ';
                        taskQuery += 'WHERE RecordTypeId IN : startTrackRecTypeIds AND Type = \'Operations Task\' AND WhatId != NULL ORDER BY ' + sortExp + ' ' + sortDir + ' ';
                    }
                }
            }
            
            //Added by DYU Dec 2016 - Dynamic string to obtain the size of the result with only a single field to avoid heap exception
            String[] taskQueryArray = taskQuery.split('FROM');
            String taskQuerySize = String.valueOf('SELECT Id FROM '+taskQueryArray[1]+' LIMIT 1000');
            System.debug('~~ taskQuerySize : ' + taskQuerySize);
            List<Task> taskSize = database.query(taskQuerySize);
            
            //Removed by DYU Dec 2016 - Remove query here and validate first if its more than the specified max number of result
            //taskList = Database.query(taskQuery);
            System.debug('~~ taskQuery : ' + taskQuery);
            
            if (stSettings.OperationsTaskSearchQueryLimit__c != null && taskSize.size() > stSettings.OperationsTaskSearchQueryLimit__c) {
                String opsLimitErrMsg = stSettings.Operations_Tasks_Exceeded_Error__c.replace('<?>', String.valueOf(Integer.valueOf(stSettings.OperationsTaskSearchQueryLimit__c)));
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, opsLimitErrMsg));
                if (!funcErr) {
                    limitExceeded = true;
                }
                if (stSettings.OperationsTaskSearchQueryLimit__c != null && stSettings.OperationsTaskSearchQueryLimit__c > 0) {
                    taskQuery += 'LIMIT ' +  Integer.valueOf(stSettings.OperationsTaskSearchQueryLimit__c);
                }
                System.debug('~~ taskQuery : ' + taskQuery);
                taskList = Database.query(taskQuery);
            }else{//Added by DYU Dec 2016 - Query task without limit if its less than specified max number of result
                taskList = Database.query(taskQuery);
            }
            
            // Complete result size
            totalResultSize = taskSize.size(); //Updated by DYU Dec 2016 - Get size of result based on the new query to obtain actual result
            generateTasksResultData();
            taskJustAcknowledged = false;
        }
    }

    public void generateTasksResultData() {
        resultTaskWrapper = new List<TaskWrapper>();
        if (!taskList.isEmpty()) {
            for (Integer i = 0 ; i < limitBy ; i++) {
                Integer index = offset + i;
                if (index < taskList.size()) {
                    resultTaskWrapper.add(new TaskWrapper(taskList.get(index)));
                    if (taskList.get(index).CaseObject__c != null) {
                        taskIdByArticleId.put(String.valueOf(taskList.get(index).Id), taskList.get(index).CaseObject__r.ArticleTest__c);
                    }
                }
            }
        }

        // Build map for Task detail
        for(TaskWrapper tw : resultTaskWrapper){
            resultTaskWrapperMap.put(tw.twTask.Id, tw);
        }
                
        //page numbers
        Integer remainder = Math.mod(totalResultSize, (Integer) StarTrackDefaultValues__c.getValues('Task Search').LIMIT__c);            
        totalTaskResultPage = totalResultSize / (Integer) StarTrackDefaultValues__c.getValues('Task Search').LIMIT__c;
        if (remainder > 0) {
            totalTaskResultPage++;
        }

        currentTaskResultPage = (offset / (Integer) StarTrackDefaultValues__c.getValues('Task Search').LIMIT__c) + 1;

        pageResultText = 'Displaying results: Page ' + currentTaskResultPage + ' of ' + totalTaskResultPage;

    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that enables the acknowledgement of Tasks via search result or detail task view
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    February 23, 2016 - David Catindoy - Modified (Refactor to include additional logic)
    ------------------------------------------------------------*/
    public void acknowledgeTasks(){
        initChatterLoad = true;
        String previousId;
        List<Task> taskList = new List<Task>();
        // Detail Section
        Set<Id> taskIds = new Set<Id>();

        if(String.isNotBlank(selectedTaskId) && detailAcknowledge && resultTaskWrapperMap.containsKey(selectedTaskId)){
            previousId = selectedTaskId;
            Task thisTask = resultTaskWrapperMap.get(selectedTaskId).twTask;
            taskIds.add(thisTask.Id);
            if (validateTaskStatus(taskIds)) {
                thisTask.OwnerId = UserInfo.getUserId();
                thisTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
                taskList.add(thisTask);
            }            
        }
        // Search Result Section
        else{
            previousId = '';
            if (validateTaskStatus(resultTaskWrapper)) {
                for(TaskWrapper tw : resultTaskWrapper){
                    if(tw.isSelected){
                        tw.twTask.OwnerId = UserInfo.getUserId();
                        tw.twTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
                        taskList.add(tw.twTask);
                    }
                }
            }
            initChatterLoad = true;
        }

        if(!taskList.isEmpty()){
            UPDATE taskList;
            previousRecord = selectedTaskWrapper;    
            searchTasks();
            selectedTaskWrapper = previousRecord;
            if(previousId!=''){
                selectedTaskId = previousId;
            }
        }
        if (detailAcknowledge) {
            taskJustAcknowledged = true;
            initChatterLoad = false;
        }
        detailAcknowledge = false;
    }
    // MW0004540 modified to check for new Finished - Case Resolved status
    public boolean validateTaskStatus(Set<Id> taskIds) {
        List<Task> tasks = new List<Task>([SELECT Id, Status, Resolution_Code__c, LastModifiedBy.Name FROM Task WHERE Id IN: taskIds]);
        Integer taskAlreadyUpdatedCounter = 0;
        String errorMessage = '';
        for (Task t : tasks) {
            if (t.Status == StarTrack_Constants.TASK_STATUS_FINISHED || t.Status == StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED) {
                taskAlreadyUpdatedCounter++;
                errorMessage = 'Task has already been ' + t.Status + ' by ' + t.LastModifiedBy.Name;
            }
        }
        if (taskAlreadyUpdatedCounter > 0) {
            if (!detailAcknowledge) {
                errorMessage = 'One or more of the selected Task/s has already been updated to Acknowledged or Finished';
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            funcErr = true;
            return false;
        }
        return true;
    }

    public boolean validateTaskStatus(List<TaskWrapper> tasks) {
        Set<Id> taskIds = new Set<Id>();
        for (TaskWrapper t : tasks) {
            if (t.isSelected) {
                taskIds.add(t.twTask.Id);
            }
        }
        return validateTaskStatus(taskIds);
    }
    // MW0004540 - SJudd modified for new Status Finished - Case Resolved
    public boolean validateTask(Task taskObj) {
        funcErr = false;
        List<Task> tasks = new List<Task>([SELECT Id, Status, Resolution_Code__c, CaseObject__r.Enquiry_Type__c, Depot_Role__r.Area__c, LastModifiedBy.Name FROM Task WHERE Id =: taskObj.Id]);
        if (!tasks.isEmpty()) {
            String errorMessage = '';
            if (tasks[0].Status == StarTrack_Constants.TASK_STATUS_FINISHED || tasks[0].Status == StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED) {
                errorMessage = 'Task has already been ' + tasks[0].Status + ' by ' + tasks[0].LastModifiedBy.Name;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            } else if (!tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION) &&
                    !tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION) &&
                    !tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASEENTYPE_CHECKADDRESS) &&
                    StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(taskObj.Status )) {
                errorMessage = 'Task Status of ' + taskObj.Status + ' is not valid for a Case Type of <' + taskObj.CaseObject__r.Enquiry_Type__c + '>. Use Task Status of ' + StarTrack_Constants.TASK_STATUS_FINISHED + ' instead.';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            } else if (tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION) &&
                    StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(taskObj.Status ) &&
                    tasks[0].Depot_Role__r.Area__c != StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION) {
                errorMessage = 'Depot area ' + tasks[0].Depot_Role__r.Area__c + ' is not valid for a Case Type of ' + taskObj.CaseObject__r.Enquiry_Type__c ;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            } else if (tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION) &&
                    StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(taskObj.Status ) &&
                    tasks[0].Depot_Role__r.Area__c != StarTrack_Constants.CASE_ENQUIRY_REDIRECTION) {
                errorMessage = 'Depot area ' + tasks[0].Depot_Role__r.Area__c + ' is not valid for a Case Type of ' + taskObj.CaseObject__r.Enquiry_Type__c ;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            } else if (tasks[0].CaseObject__r.Enquiry_Type__c.equalsIgnoreCase(StarTrack_Constants.CASEENTYPE_CHECKADDRESS) &&
                    StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(taskObj.Status ) &&
                    tasks[0].Depot_Role__r.Area__c != StarTrack_Constants.CASE_ENQUIRY_REDIRECTION) {
                errorMessage = 'Depot area ' + tasks[0].Depot_Role__r.Area__c + ' is not valid for a Case Type of ' + taskObj.CaseObject__r.Enquiry_Type__c ;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            } else if (StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(taskObj.Status) && !isAutoCloseEnabled ){
                errorMessage = 'Task Status of ' + taskObj.Status + ' is not enabled. Use Task Status of ' + StarTrack_Constants.TASK_STATUS_FINISHED + ' instead.' ;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, +errorMessage));
                funcErr = true;
                return false;
            }
        }
        return true;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that commits the updated value of Task (Status, Operations Outcome) and Case (Status)
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    February 23, 2016 - David Catindoy - Modified (Refactor to include additional logic)
    ------------------------------------------------------------*/
    public void saveTaskDetails(){
        limitExceeded = false;
        Task thisTask = null;
        if (resultTaskWrapperMap.containsKey(selectedTaskId) && !taskJustAcknowledged){
            thisTask = resultTaskWrapperMap.get(selectedTaskId).twTask;
        } else {
            thisTask = previousRecord.twTask;
        }
        if (validateTask(thisTask)) {
            if(String.isNotBlank(thisTask.CaseObject__c)){
                Case thisCase = new Case();
                thisCase.Id = thisTask.CaseObject__c;
                if (StarTrack_Constants.WAITING_ON_INVESTIGATOR.equals(thisTask.TaskUpdate__c)) {
                    thisCase.Case_Update__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
                    thisCase.Case_Update_Time__c = System.now();
                    UPDATE thisCase;
                }
            }
            // Updated for MW0004540 to set Finished Date and Resolution Code
            if(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equalsIgnoreCase(thisTask.Status)){
                thisTask.Finished_Date__c = System.now();
                if(StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equalsIgnoreCase(thisTask.CaseObject__r.Enquiry_Type__c)){
                    thisTask.Resolution_Code__c = StarTrack_Constants.CASE_RESOLUTIONCODE_DEPOTCOLLECTION;
                } else if(StarTrack_Constants.CASE_ENQUIRY_REDIRECTION.equalsIgnoreCase(thisTask.CaseObject__r.Enquiry_Type__c)){
                    thisTask.Resolution_Code__c = StarTrack_Constants.CASE_RESOLUTIONCODE_REDIRECTED;
                } else if(StarTrack_Constants.CASEENTYPE_CHECKADDRESS.equalsIgnoreCase(thisTask.CaseObject__r.Enquiry_Type__c)){
                    thisTask.Resolution_Code__c = StarTrack_Constants.CASE_UPDATE_OPERATIONSRESP;
                }
            }
            UPDATE thisTask;
            searchTasks();
        }

        if (funcErr) {
            initChatterLoad = false;
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Wrapper class that contains the checkbox and Task object
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public class TaskWrapper{

        public Boolean isSelected {get; set;}
        public Task twTask {get; set;}
        
        public TaskWrapper(Task twTask){
            isSelected = false;
            this.twTask = twTask;
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that assigns the selected Task to be displayed in the detail section
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void getSelectedTaskDetails(){
        if(resultTaskWrapperMap.containsKey(selectedTaskId)){
            selectedTaskWrapper = resultTaskWrapperMap.get(selectedTaskId);
            selectedConsignmentId = taskIdByArticleId.get(selectedTaskId);
            if (selectedConsignmentId == null) {
                showScanEventsNoConsign = true;
            } else {
                showScanEventsNoConsign = false;
            }
            twSelectedCont = selectedTaskWrapper;
        }
        System.debug(resultTaskWrapperMap.get(selectedTaskId));
        System.debug(selectedTaskWrapper);
        initChatterLoad = true;
        chatterComment = '';
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that determines if the custom filters will be displayed in the layout
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void changeFilter(){
        setDefaultValues();
        if(filterType.equals('Custom')){
            displayCustomFilters = true;
            displayAreaTasksFilters = false;
            resetFilter();
        } else if(filterType.equals('My Area Tasks')){
            displayAreaTasksFilters = true;
            displayCustomFilters = false;
            resetFilter();
        } else {

            displayCustomFilters = false;
            displayAreaTasksFilters = false;
            
            //W-001277 - op task sorting
            resetFilter();

            searchTasks();
        }

        sortExpression = '';
        sortExp = '';
        chatterComment = '';
    }
    
    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method to reset custom filters
    Inputs:        None
    Returns:       None
    History:
    October 5, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void resetFilter(){
        setDefaultValues();

        // Reset custom filters
        dummyTaskA.Network__c = null;
        dummyCase.AccountId = null;
        dummyTaskA.Depot_Role__c = null;
        dummyTaskA.OwnerId = null;
        runDock.clear();
        bulkField.clear();
        depotAreaList.clear();
        consignment = '';
        taskStatus.clear();
        dummyTaskA.Case_Delivery_Collection_Date__c = null;
        dummyTaskB.Case_Delivery_Collection_Date__c = null;
        displayDepotAreaFilter = false;

        sortExpression = '';
        sortExp = '';
        showScanEventsNoConsign = false;
        if(filterType.equals('My Area Tasks')){
            searchTasks();
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that set the default values for certain containers
    Inputs:        None
    Returns:       None
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void setDefaultValues(){
        totalResultSize = 0;
        offset = (Integer) StarTrackDefaultValues__c.getValues('Task Search').OFFSET__c;
        limitBy = (Integer) StarTrackDefaultValues__c.getValues('Task Search').LIMIT__c;

        // Reset Task results
        resultTaskWrapper = new List<TaskWrapper>();
        resultTaskWrapperMap = new Map<Id, TaskWrapper>();

        // Reset selected Task detail
        selectedTaskWrapper = new TaskWrapper(null);
        selectedTaskId = '';
        selectedConsignmentId = '';

        // Reset sort field
        sortExpression = '';
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that populates the available search filters
    Inputs:        None
    Returns:       List<SelectOption>
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public List<SelectOption> getFilterTypes(){
        List<SelectOption> filterTypeMain = new List<SelectOption>();
        Set<SelectOption> filterTypeOthers = new Set<SelectOption>();

        for(Task_Search_Settings__c tss : Task_Search_Settings__c.getAll().values()){
            if(tss.Default__c){
                filterTypeMain.add(new SelectOption(tss.Name, tss.Name));
            }
            else{
                filterTypeOthers.add(new SelectOption(tss.Name, tss.Name));
            }
        }
        filterTypeMain.addAll(filterTypeOthers);
        return filterTypeMain;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that populates the available Task Status search filters
    Inputs:        None
    Returns:       List<SelectOption>
    History:
    September 10, 2015 - Patrick James Franco - Created
    October 5, 2015 - Patrick James Franco - Get Task status directly from constants
    September 17,  2021 - Steve Judd - Added new status to show if user has permission
    ------------------------------------------------------------*/
    public List<SelectOption> getTaskStatuses(){
        List<SelectOption> statusList = new List<SelectOption>{new SelectOption(StarTrack_Constants.TASK_STATUS_NOTSTARTED, StarTrack_Constants.TASK_STATUS_NOTSTARTED),
                                                               new SelectOption(StarTrack_Constants.TASK_STATUS_WAITING, StarTrack_Constants.TASK_STATUS_WAITING),
                                                               new SelectOption(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED),
                                                               new SelectOption(StarTrack_Constants.TASK_STATUS_FINISHED, StarTrack_Constants.TASK_STATUS_FINISHED)};

        if(isAutoCloseEnabled) {
            statusList.add(new SelectOption(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED, StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED));
        }

        return statusList;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that populates the available Task Run Dock search filters
    Inputs:        None
    Returns:       List<SelectOption>
    History:
    September 10, 2015 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public List<SelectOption> getRunDocks(){
        Set<PostcodeMapping__c> runDockSet = new Set<PostcodeMapping__c>([SELECT Run_Dock__c FROM PostcodeMapping__c WHERE Run_Dock__c != null ORDER BY Run_Dock__c ASC]);
        Set<String> runDockCounter = new Set<String>();
        List<SelectOption> runDockSelectList = new List<SelectOption>();
        for(PostcodeMapping__c runDock : runDockSet){
            if(String.isNotBlank(runDock.Run_Dock__c) && !runDockCounter.contains(runDock.Run_Dock__c)){
                runDockCounter.add(runDock.Run_Dock__c);
                runDockSelectList.add(new SelectOption(runDock.Run_Dock__c, runDock.Run_Dock__c));
            }
        }
        return runDockSelectList;
    }
    
    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Company:       Cloud Sherpas
    Description:   Method that populates the available Bulk search filters
    Inputs:        None
    Returns:       List<SelectOption>
    History:
    June 6, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public List<SelectOption> getBulkFields(){
        Set<PostcodeMapping__c> bulkSet = new Set<PostcodeMapping__c>([SELECT Bulk__c FROM PostcodeMapping__c WHERE Bulk__c != null ORDER BY Bulk__c ASC]);
        Set<String> bulkCounter = new Set<String>();
        List<SelectOption> bulkSelectList = new List<SelectOption>();
        for(PostcodeMapping__c bulkField : bulkSet){
            if(String.isNotBlank(bulkField.Bulk__c) && !bulkCounter.contains(bulkField.Bulk__c)){
                bulkCounter.add(bulkField.Bulk__c);
                bulkSelectList.add(new SelectOption(bulkField.Bulk__c, bulkField.Bulk__c));
            }
        }
        return bulkSelectList;
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Accenture
    Description:   Method that populates the available Task Depot Area search filters
    Inputs:        None
    Returns:       List<SelectOption>
    History:
    December 2, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public List<SelectOption> getDepotAreas(){
        //List<AggregateResult> aggregateDepotArea = new List<AggregateResult>([SELECT Depot_Role__c, Depot_Role__r.Name FROM Task WHERE Depot_Role__c != null AND Network__c != null AND Network__c = :dummyTaskA.Network__c GROUP BY Depot_Role__c, Depot_Role__r.Name]);
        List<Depot_Area__c> depotAreas = new List<Depot_Area__c>([SELECT Id, Name FROM Depot_Area__c WHERE Depot__c != null AND Depot__c = :dummyTaskA.Network__c ORDER BY Name]);
        List<SelectOption> depotAreaList = new List<SelectOption>();
        
        for(Depot_Area__c result : depotAreas){
            depotAreaList.add(new SelectOption(result.Id, result.Name));
        }
        
        return depotAreaList;
    }
    
    /*------------------------------------------------------------
    Author:        David Catindoy
    Company:       Accenture
    Description:   Method that determine visibility of depot area filter
    Inputs:        None
    Returns:       None
    History:
    December 2, 2016 - David Catindoy - Created
    ------------------------------------------------------------*/
    public void changeDepotAreaVisibility(){
        displayDepotAreaFilter = String.isNotBlank(dummyTaskA.Network__c) ? true : false;
    }

    /**********************************************************
     **Description: Performs navigation to the first page
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public PageReference first(){
        offset = 0;
        generateTasksResultData();
        return null;
    }

    /**********************************************************
     **Description: Performs navigation to the last page
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public PageReference last(){
        listCounter = totalResultSize;
        offset = listCounter - math.mod(listCounter, limitBy);
        if (listCounter == offset) {
            offset -= limitBy; 
        }
        generateTasksResultData();
        return null;
    }

    /**********************************************************
     **Description: Performs navigation to the next records
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public PageReference next(){
        // Append offset
        offset += limitBy;
        generateTasksResultData();
        return null;
    }


    /**********************************************************
     **Description: Performs navigation to the previous records
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public PageReference previous(){
        // Deduct from offset
        offset -= limitBy;
        generateTasksResultData();
        return null;
    }

    /**********************************************************
     **Description: Check if navigation to next page is allowed.
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public Boolean getDisableNext() {
        if (offset + limitBy < totalResultSize)
            return false;
        else
            return true;
    }

    /**********************************************************
     **Description: Check if navigation to previous page is allowed.
     **Parameters: N/A
     **Returns: NULL
     **Author: DAVID.CATINDOY(CloudSherpas)
     **Date Created: SEPT.15.2014
     **********************************************************/
    public Boolean getDisablePrevious() {
        if (offset > 0)
            return false;
        else
            return true;
    }

    /**********************************************************
     **Description: Method for rendering Tasks on PDF
     **Parameters: N/A
     **Returns: PageReference
     **Author: Jen Karen Tan
     **Date Created: JULY.21.2016
     **********************************************************/
    public PageReference renderTasksAsPDF() {
        idsForPDFPrinting = '';
        idForPDFPrinting = '';
        if(String.isNotBlank(selectedTaskId) && detailPrint && resultTaskWrapperMap.containsKey(selectedTaskId)){
            idForPDFPrinting = String.valueOf(selectedTaskId);
            detailPrint = false;
        } else {
            for(TaskWrapper tw : resultTaskWrapper){
                if(tw.isSelected){
                    idsForPDFPrinting += String.valueOf(tw.twTask.Id) + ',';
                }
            }
            if (idsForPDFPrinting.length() > 0) {
                idsForPDFPrinting = idsForPDFPrinting.subString(0, idsForPDFPrinting.length() - 1);
            } else {
                return null;
            }
        }
        initChatterLoad = false;
        return null;
    }

    /**********************************************************
     **Description: Method for posting comments to Feed
     **Parameters: N/A
     **Returns: void
     **Author: Jen Karen Tan
     **Date Created: AUG.31.2016
     **********************************************************/
    public void postToFeed() {
        funcErr = false;
        if (!String.isBlank(chatterComment)) {
            Task thisTask = [SELECT Id, TaskUpdate__c, Operations_Outcome__c, Status, LastModifiedBy.Name FROM Task WHERE Id =: selectedTaskId];
            FeedItem fi = new FeedItem(ParentId = selectedTaskId, Body = chatterComment);    
            insert fi;
            if (!StarTrack_Constants.TASK_STATUS_FINISHED.equals(thisTask.Status) && !StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED.equals(thisTask.Status)) {
                thisTask = resultTaskWrapperMap.get(selectedTaskId).twTask;
                thisTask.Operations_Outcome__c = chatterComment;
                thisTask.TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
                update thisTask;
            }
            initChatterLoad = false;
            chatterComment = '';
        }
    }
    
    /**********************************************************
     **Description: Method for assigning value to flag needed for 
     **              rendering chatter panel properly
     **Returns: void
     **Author: Jen Karen Tan
     **Date Created: DEC.7.2016
     **********************************************************/
    public void refresh() {
        initChatterLoad = true;
    }
    
    /**********************************************************
     **Description: Method for validating Tasks selected and displaying popup
     **Parameters: N/A
     **Returns: void
     **Author: Jen Karen Tan
     **Date Created: OCT.25.2016
     **********************************************************/
    public void showListPopUp() {
        funcErr = false;
        bulkTaskList = getSelectedTasks();
        if (bulkTaskList.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select Task/s.'));
            funcErr = true;
        } else {
            displayListPopUp = false;
            if (!validTasksDepot()) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select Tasks with the same Depot.'));
                funcErr = true;
            } else if (!validTaskStatus()) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Finished Tasks cannot be reassigned.'));
                funcErr = true;
//change started by Ramya                
            } else if (!validTaskLDC()) { 
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'LDC Tasks cannot be reassigned.'));
                funcErr = true;
//change ended by Ramya                
            } else if (!validCaseStatus()) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Tasks with Closed Case cannot be reassigned.'));
                funcErr = true;
            } else {
                displayListPopUp = true; 
            }
        }
        if (funcErr) {
            initChatterLoad = true;
        } else {
            initChatterLoad = false;
        }
    }
    
    public void closeListPopup() {        
        displayListPopUp = false;    
    }
    
    public void closeDetailPopup() {        
        displayDetailPopUp = false;    
    }     
    public void showDetailPopup() {
        List<TaskWrapper> twList = new List<TaskWrapper>();
        twList.add(resultTaskWrapperMap.get(selectedTaskId));
        bulkTaskList = twList;
        bulkTaskObj = resultTaskWrapperMap.get(selectedTaskId).twTask;
        if (!validCaseStatus()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Tasks with Closed Case cannot be reassigned.'));
            funcErr = true;
            initChatterLoad = true;
        } else {
            displayDetailPopUp = true;
            initChatterLoad = true;
        }
    }
    
    /**********************************************************
     **Description: Method for reassigning Depot Area of Task/s
     **Parameters: N/A
     **Returns: void
     **Author: Jen Karen Tan
     **Date Created: OCT.25.2016
     **********************************************************/    
    public void reassignTasks(){
        limitExceeded = false;
        String previousId;
        List<Task> taskList = new List<Task>();
        // Detail Section
        Set<Id> taskIds = new Set<Id>();
        if(String.isNotBlank(selectedTaskId) && detailReassign && resultTaskWrapperMap.containsKey(selectedTaskId)){
            previousId = selectedTaskId;
            Task thisTask = null;
            if (resultTaskWrapperMap.containsKey(selectedTaskId) && !taskJustAcknowledged){
                thisTask = resultTaskWrapperMap.get(selectedTaskId).twTask;
            } else {
                thisTask = previousRecord.twTask;
            }
            
            taskIds.add(thisTask.Id);
            thisTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
            thisTask.TaskUpdate__c = StarTrack_Constants.TASK_UPDATE_REASSIGN;
            thisTask.Depot_Role__c = depotAreaId;
            taskList.add(thisTask);
            displayDetailPopUp = false;
        } else {
            previousId = '';
            for(TaskWrapper tw : resultTaskWrapper){
                if(tw.isSelected){
                    tw.twTask.Depot_Role__c = depotAreaId;
                    tw.twTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
                    tw.twTask.TaskUpdate__c = StarTrack_Constants.TASK_UPDATE_REASSIGN;
                    taskList.add(tw.twTask);
                }
            }
            displayListPopUp = false;
                
        }

        if(!taskList.isEmpty()){
            UPDATE taskList;
            previousRecord = selectedTaskWrapper;    
            searchTasks();
            selectedTaskWrapper = previousRecord;
            if(previousId!=''){
                selectedTaskId = previousId;
            }
        }
        
        detailReassign = false;
        taskJustAcknowledged = false;
        initChatterLoad = false;
        
        if (!thisUserDepotRole.contains(depotAreaId)) {
            selectedTaskId = '';
        }
    }
    
    /**********************************************************
     **Description: Method for validating if Tasks selected are of the same Depot
     **Parameters: N/A
     **Returns: boolean
     **Author: Jen Karen Tan
     **Date Created: OCT.25.2016
     **********************************************************/    
    public boolean validTasksDepot() {
        Id depotId = bulkTaskList[0].twTask.Network__c;
        for(TaskWrapper tw : bulkTaskList){
            if (tw.twTask.Network__c != depotId) {
                return false;
            }
        }
        bulkTaskObj = bulkTaskList[0].twTask;
        bulkTaskNetworkId = depotId;
        return true;
    }
    
    /**********************************************************
     **Description: Method for validating if Tasks' status is not Finished
     **Parameters: N/A
     **Returns: boolean
     **Author: Jen Karen Tan
     **Date Created: OCT.28.2016
     **********************************************************/    
    public boolean validTaskStatus() {
        for(TaskWrapper tw : bulkTaskList){
            if (tw.twTask.Status.equals(StarTrack_Constants.TASK_STATUS_FINISHED) || tw.twTask.Status.equals(StarTrack_Constants.TASK_STATUS_FINISHED_RESOLVED)) {
                return false;
            }
        }
        return true;
    }    
    /**********************************************************
     **Description: Method for validating if Tasks case type is a LDC
     **Parameters: N/A
     **Returns: boolean
     **Author: Ramya Chintakula    
     **Date Created: AUG.17.2017
     **********************************************************/    
    public boolean validTaskLDC() {
        for(TaskWrapper tw : bulkTaskList){
            Task t1 = [SELECT CaseObject__r.Enquiry_Type__c FROM Task WHERE Id = :tw.twTask.Id];
            if (t1.CaseObject__r.Enquiry_Type__c == 'LDC'){
                    return false;
            }       
        }
        return true;
    }    
    /**********************************************************
     **Description: Method for validating if Case status is not Closed
     **Parameters: N/A
     **Returns: boolean
     **Author: Jen Karen Tan
     **Date Created: OCT.28.2016
     **********************************************************/    
    public boolean validCaseStatus() {
        List<Id> taskIds = new List<Id>();
        for(TaskWrapper tw : bulkTaskList){
            taskIds.add(tw.twTask.Id);
        }
        List<Task> tasks = new List<Task>([SELECT Id, CaseObject__r.Status FROM Task WHERE Id IN: taskIds]);
        for(Task t : tasks){
            if (t.CaseObject__r != null 
                && t.CaseObject__r.Status.equals(StarTrack_Constants.CASE_STAT_CLOSED)) {
                return false;
            }
        }
        return true;
    }       
    
    /**********************************************************
     **Description: Method for getting Tasks selected
     **Parameters: N/A
     **Returns: List<TaskWrapper>
     **Author: Jen Karen Tan
     **Date Created: OCT.25.2016
     **********************************************************/        
    public List<TaskWrapper> getSelectedTasks() {
        List<TaskWrapper> twList = new List<TaskWrapper>();
        for (TaskWrapper tw : resultTaskWrapper) {
            if (tw.isSelected) {
                twList.add(tw);
            }
        }
        return twList;
    }
    
    public List<SelectOption> getDepotAreaRecords() {
        depotAreaId = bulkTaskObj.Depot_Role__c;
        Boolean depotAreaIdValid = false;
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        List<Depot_Area__c> depotAreaList = [SELECT Id, Name FROM Depot_Area__c WHERE Depot__c =: bulkTaskObj.Network__c ORDER BY Name ASC];
        for(Depot_Area__c depotAreaRec : depotAreaList){
            options.add(new SelectOption(depotAreaRec.Id, depotAreaRec.Name));
        }
        return options;
    }
}