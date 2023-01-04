/*********************************************************************
Description:    Utility Class for handling NPS Voice functions
History:
15-02-2019  disha.kariya@auspost.com.au Removed Case contact context
and passing Task's Contact details instead of Case's Contact details
13-05-2019 saisweth.pingali@auspost.com.au Fix for INC1330241 - Task created by field data is not available on Survey.
10-08-2020 Ranjeewa Silva - Optimised checkTaskNPSVoiceSurvey method to only query task details if there are tasks to process.
12-04-2022 Madhuri - DML Exception : Check tRec.Queue__C is not null in isTaskValid method
-----------------------------------------------------------------------
**********************************************************************/
public with sharing class NPSVoiceSurveyUtil {

    public static final String RECORDTYPE_SSSW_CALL = 'SSSW Call';
    public static final String CUSTOMER_TYPE_ENTERPRISE = 'Enterprise';
    public static final String CALLTYPE_OUTBOUND = 'Outbound';
    public static final String CALLTYPE_INBOUND = 'Inbound';
    public static final String QUEUE_15798 = '15798';
    public static final String QUEUE_0293150019 = '0293150019';
    public static final String QUEUE_15799 = '15799';
    public static final String QUEUE_0293150513 = '0293150513';
    public static final String QUEUE_1579999 = '1579999';
    public static final String CASE_ORIGIN_HLC = 'High Level Complaint';
    public static final String NPS_VOICE_CUST_SETTING = 'NPSVoiceSurvey';
    public static final String SSSW_APP = 'SSSW NPS Voice Survey';
    public static final String TRIGGER_NAME_TASK = 'TaskTrigger';
    public static final String MOCK_ENDPOINT = 'https://www.google.com';
    public static final Integer BATCH_SIZE = 20;

    public static Set<Id> taskRecTypeIds;
    private static Set<Id> validCaseRecTypes;

    static { // code executed to fetch details when class is invoked
        try{
            // get all valid record types for the SSSW functionality
            validCaseRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
            // get valid task record type for NPS Voice Survey
            taskRecTypeIds = Utility.getRecordTypeIds(String.valueOf(Task.SObjectType),RECORDTYPE_SSSW_CALL);
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    NPSVoiceSurveyUtil.class.getName(), SSSWConstants.STATIC_BLOCK,
                    SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    //INC1330241 - SOQL to get the user lookup data as task created by data is passed to TIBCO.
    public static Map<id,Task> getTasksByIds(Set<Id> TaskIds) {
        
        Map<Id, Task> tasks = new Map<Id, Task> ([
            SELECT 	id,CreatedDate,Contact__c,CreatedBy.Alias,Agent__c,CreatedBy.FirstName,
            		CreatedBy.LastName,Segment__c,CTIInteractionID__c 
            FROM 	Task 
        	WHERE 	Id IN: TaskIds]);
       	return tasks;
    }

    /**
      * Check to see whether a task is valid to send to tibco
      * for NPS Voice Survey or not
      */
    public static void checkTaskNPSVoiceSurvey(List<Task> taskList, Map<Id,Task> oldMap) {
        List<Task> filteredTaskList = new List<Task>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> taskIds = new Set<Id>(); 
        Map<Id,Task> taskMap = new Map<Id,Task>();
        Map<Id,Case> relatedCaseMap = new Map<Id,Case>();
        List<Contact> taskContact = new List<Contact>();
        Map<Id, Contact> taskContactMap = new Map<Id, Contact>();
        List<NPSVoiceSurveyWrapper> npsWrapList = new List<NPSVoiceSurveyWrapper>();

        try {
            for (Task tRec : taskList) {
                // Check that task is not updated more than once to avoid duplicate callout with the same informations
                // Validate if task is valid to process using business criteria
                Task oldTask = (oldMap != null && oldMap.containsKey(tRec.Id)) ? oldMap.get(tRec.Id) : null;
                if (((oldTask != null && oldTask.MH_Action__c != true && tRec.MH_Action__c == false) || (tRec.MH_Action__c == false && oldTask == null))
                        && isTaskValid(tRec)) {
                    caseIds.add(tRec.whatId);
                    contactIds.add(tRec.whoId);
                    taskIds.add(tRec.Id); 
                    filteredTaskList.add(tRec);
                }
            }

            if(!filteredTaskList.isEmpty() && !contactIds.isEmpty()) {
                //Get Contacts from task for email field
                taskContact = [SELECT id, FirstName, LastName, email, APCN__c from Contact where id in :contactIds];
                for (Contact con : taskContact) {
                    taskContactMap.put(con.Id, con);
                }
            }
           
            if (!filteredTaskList.isEmpty() && !caseIds.isEmpty()) {

                //Query task details only if there are tasks satisfying the filter criteria.
                taskMap = getTasksByIds(taskIds);

                // Get case and contact details using caseIds from whatId field in parent task record
                // Validate if the case is valid to process using business criteria
                for (Case cRec : getCaseDetails(caseIds)) {
                    if (isRelatedCaseValid(cRec)) {
                        relatedCaseMap.put(cRec.Id, cRec);
                    }
                }
                
                

                // Iterate on valid tasks then check if related case/contact details is valid and Task contact Email is not blank as well
                // Create a collection of all informations and set to NPSVoiceSurveyWrapper
                for (Task tRec : filteredTaskList) {
                    if (relatedCaseMap.containsKey(tRec.whatId) && !String.isEmpty(taskContactMap.get(tRec.WhoId).Email)) {
                        Case relCase = relatedCaseMap.get(tRec.whatId);
                        npsWrapList.add(new NPSVoiceSurveyWrapper(taskMap.get(tRec.Id),relCase, taskContactMap.get(tRec.WhoId)));  
                    }
                }
                System.debug('npsWrapList--->'+npsWrapList);
                if (!npsWrapList.isEmpty()) {
                    batchProcessFuture(npsWrapList);
                }
            }
        } catch (Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSW_APP,
                    NPSVoiceSurveyUtil.class.getName(), 'checkTaskNPSVoiceSurvvey', TRIGGER_NAME_TASK, LoggingLevel.ERROR);
        }
    }

    /**
      * Query referenced field on case
      */
    public static List<Case> getCaseDetails(Set<Id> caseIds) {
        return [SELECT Id, Customer_Type__c, Origin, IsCR__c, IsHLC__c, Contact.Email,
                CaseNumber, LastModifiedDate, ProductCategory__c, ProductSubCategory__c,
                Status, OwnerId, RecordtypeId, Closed_Date__c, Type,
                EnquirySubType__c, Product_Type__c, CaseOriginator__c, Root_cause__c,
                Contact.Id, CreatedDate, ReferenceID__c, ResolutionCode__c,
                Is_Complaint__c, Contact.APCN__c,
                Contact.FirstName, Contact.LastName
        FROM Case WHERE Id IN: caseIds AND RecordTypeId IN: validCaseRecTypes];
    }

    /*
        Query fields of related task list
     */
    public static List<Task> getTaskDetails(Set<Id> taskIds) {
        return [SELECT Id, MH_Action__c, SMSError__c FROM Task WHERE Id IN: taskIds];
    }

    /**
      * Validation to check if the inserted/updated task is valid to process
      * using some of the business criterias
      */
    public static Boolean isTaskValid(Task tRec) {
        Boolean isValid = false;
        // 15798 , 0293150513 , 0293150019 - Callback queue/routing point
        // 15799 , 1579999 - Transfer routing point
        if (Utility.isValidRecordType(taskRecTypeIds,tRec.RecordTypeId)
                && tRec.whatId !=null && tRec.whatId.getSObjectType() == Case.getSObjectType()
                && tRec.whoId !=null && tRec.whoId.getSObjectType() == Contact.getSObjectType()
                && tRec.Queue__c != null
                &&
                (
                        tRec.CallType == CALLTYPE_INBOUND
                                ||
                                (
                                        tRec.CallType == CALLTYPE_OUTBOUND
                                                &&
                                                (tRec.Queue__c.startsWith(QUEUE_15798) || tRec.Queue__c.startsWith(QUEUE_0293150019) || tRec.Queue__c.startsWith(QUEUE_15799) || tRec.Queue__c.startsWith(QUEUE_0293150513))
                                )
                )
                && tRec.Queue__c != QUEUE_1579999
                && tRec.CreatedDate.date() == Date.today()
           ) {
            isValid = true;
        }
        return isValid;
    }

    /**
      * Second validation to check if task is valid to process
      * using some of the business criterias on its related case
      */
    public static Boolean isRelatedCaseValid(Case cRec) {
        Boolean isValid = false;
        /* Removed the check to identify if the Case has a Contact Email */
        if (cRec.Customer_Type__c != CUSTOMER_TYPE_ENTERPRISE
                && cRec.Origin != CASE_ORIGIN_HLC
                && !cRec.IsCR__c && !cRec.IsHLC__c) {
            isValid = true;
        }
        return isValid;
    }

    /*
     *  Accept String data (json format) then deserialize to
     *  Transform informations to json format and send data to TIBCO
     */
    @future(callout=true)
    public static void sendDataNPSVoiceSurvey(String data) {
        try {
            Map<Id,NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse> resWrapMap = new Map<Id,NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse>();
            List<NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse> responseWrapperList = new List<NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse>();
            List<NPSVoiceSurveyWrapper> npsWrapList = (List<NPSVoiceSurveyWrapper>) JSON.deserialize(data,List<NPSVoiceSurveyWrapper>.class);
            for (NPSVoiceSurveyWrapper nps : npsWrapList) {
                if (nps.taskObj != null && nps.caseObj != null) {
                    System.debug('nps.taskContact--->'+nps.taskContact);
                    NPSVoiceSurveyWrapper.NPSVoiceSurveyRequest payload = new NPSVoiceSurveyWrapper.NPSVoiceSurveyRequest(nps.taskObj, nps.caseObj, nps.taskContact);
                    System.debug('payload--->'+payload);
                    String jsonPayload = JSON.serialize(payload);
                    HttpResponse response = sendRequest(jsonPayload,nps.taskObj.Id);
                    System.debug('response--->'+response);
                    //Make a collection of response with task Id and success and response
                    resWrapMap.put(nps.taskObj.Id,getResponse(nps.taskObj.Id,response));
                }
            }
            if (!resWrapMap.isEmpty()) {
                updateProcessFlagOnTask(resWrapMap);
            }
        } catch (Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSW_APP,
                    NPSVoiceSurveyUtil.class.getName(), 'sendDataNPSVoiceSurvey', TRIGGER_NAME_TASK, LoggingLevel.ERROR);
        }
    }

    /*
     *  Method to send request to TIBCO json web service
     */
    public static HTTPResponse sendRequest(String payload, String taskId) {
        //AusPostSettings__c setting = AusPostSettings__c.getValues('NPSVoiceSurvey');
        DateTime reqStampDate = System.now();
        String timeStamp = reqStampDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(setting.URL__c);
        //request.setClientCertificateName('auspostapicert');
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setHeader('business_reference_id', 'NPSVoiceSurvey'+taskId);
        request.setHeader('source_system_id','SFDC');
        request.setHeader('request_timestamp',timeStamp);
        request.setEndpoint('callout:NPSVoiceSurvey');
        if (Test.isRunningTest()) {
            request.setEndpoint(MOCK_ENDPOINT);
        }
        request.setBody(payload);
        HTTPResponse response = http.send(request);
        return response;
    }

    /*
     *  Convert response to NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse format
     */
    public static NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse getResponse(String taskId, HTTPResponse res) {
        Boolean success = (res.getStatusCode() == 200) ? true : false;
        String msg = String.valueOf(res.getStatusCode()) +'\n'+ String.valueOf(res.getStatus()) +'\n'+ String.valueOf(res.getBody());
        return new NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse(taskId,success,msg);
    }

    /*
     *  Method to set MH_Action__c flag to true on task
     *  Populate SMSError__c if there's any error from the callout response
     */
    public static void updateProcessFlagOnTask(Map<Id,NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse> taskIdResWrapMap) {
        List<Task> taskToUpdateList = new List<Task>();
        for (Task tRec : getTaskDetails(taskIdResWrapMap.keySet())) {
            NPSVoiceSurveyWrapper.NPSVoiceSurveyResponse res = taskIdResWrapMap.get(tRec.Id);
            tRec.MH_Action__c = true;
            if (res.success != null && !res.success) {
                tRec.SMSError__c = res.errMsg!=null?(res.errMsg.length()>255)?res.errMsg.substring(0,255):res.errMsg:'';
            }
            taskToUpdateList.add(tRec);
        }
        if (!taskToUpdateList.isEmpty()) {
            update taskToUpdateList;
        }
    }

    /*
     *  Method to split into 20 tasks records to process per future method
     */
    public static void batchProcessFuture(List<NPSVoiceSurveyWrapper> npsWrapList) {
        if (npsWrapList.size() <= BATCH_SIZE) {
            sendDataNPSVoiceSurvey(JSON.serialize(npsWrapList));
        } else {
            List<NPSVoiceSurveyWrapper> tempNPSWrapList = new List<NPSVoiceSurveyWrapper>();
            Integer counter = 1;
            for (NPSVoiceSurveyWrapper wrapRec : npsWrapList) {
                tempNPSWrapList.add(wrapRec);

                if (tempNPSWrapList.size() == BATCH_SIZE || counter == npsWrapList.size()) {
                    System.debug('batchProcessFutureMethod:' + tempNPSWrapList.size());
                    tempNPSWrapList.clear();
                }
                counter++;
            }
        }
    }
}