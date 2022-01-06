/* @author 
 * @date 2020-04-10
 * @group Opportunities
 * @tag Opportunity
 * @domain Core
 * @description test class for OpportunityCloseErrosController
 * @changelog
 * 2020-08-14 - Victor Chang - Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Modified to use mocking framework for dml operations
 */
global without sharing class OpportunityCloseErrorsController {
    /*
        Class is implemented using without sharing , since Component needs to perform dummy opportunity update
        to get all the possible validation errors and it needs to be done for all the user who are able to go to 
        opportunity detail page regardless they have read access or write access.
    */
    public final static String KEY_STATUS = 'status';
    public final static String KEY_ERRORS = 'errors';
    public final static String KEY_MESSAGE = 'message';
    public final static String OK = 'ok';
    public final static String ERROR = 'error';

    // the stage value of the opportunity
    public final static String CURRENT_STAGE = 'currentStage';
    public final static String NEXT_STAGE = 'nextStage';

    public Id oppId {get; set;}
    public string lexUrl{get;set;}
   
    public OpportunityCloseErrorsController(ApexPages.StandardController stdController) {
        oppId = (Id)stdController.getId();  
        String baseUrl = String.valueOf(System.Url.getOrgDomainUrl());
        String baseUrlStartTrim = baseUrl.replace('Url:[delegate=','');
        String baseUrlEndTrim = baseUrlStartTrim.replace(']','');
        lexUrl = baseUrlEndTrim.replace('my.salesforce.com','lightning.force.com'); 
    }
    @RemoteAction
    global static Map<String, Object> getCloseOpportunityErrors(String recordId){
        // return results as a map, which makes it extendable
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<Id, Opportunity> opportunityMap = OpportunitiesSelector.newInstance().selectById(new Set<Id>{recordId});
        list<Opportunity> updateList = new list<Opportunity>();
        if(opportunityMap != null) {
            updateList.add(opportunityMap.values());
        }
        System.debug('updateList>>>>>'+updateList);
        if(updateList.size() != 1)
        {
            // if the record is not found, return with an error
            mapResults.put(KEY_STATUS, ERROR);
            mapResults.put(KEY_MESSAGE, 'no opportunity for record Id:' + recordId);
            // early out
            return mapResults;
        }

        // get the update target
        Opportunity theOppty = updateList[0];
        mapResults.put(CURRENT_STAGE, theOppty.StageName);
        String nextStage = getNextStageName(theOppty.StageName);
        mapResults.put(NEXT_STAGE, nextStage);

        // set savepoint for rollback
        Savepoint sp = ApplicationDatabase.getInstance().dmlSetSavePoint();
        // set as the next stage
        theOppty.StageName = nextStage;
        Map<String, Object> mapTriggerValidationResults = new Map<String, Object>();
        try
        {
            mapTriggerValidationResults = updateOpportunity(updateList);
             // rollback regardless
            ApplicationDatabase.getInstance().dmlRollback(sp);
            list<string> errMsgList = new list<string>();
            if(mapTriggerValidationResults != null){
                // Disabling the trigger as needs to get all the possible validation messages
                SystemSettings__c.getInstance().Disable_Triggers__c = true;
                Map<String, Object> mapCustomValidationResults = updateOpportunity(updateList);                
                errMsgList =(list<String>) mapTriggerValidationResults.get(KEY_ERRORS);
                for(String mapVar: mapCustomValidationResults.keySet()){
                    if(mapTriggerValidationResults.containsKey(mapVar) && mapVar == KEY_ERRORS){                
                    Set<String> tmpFirstDMLErrMsg = New Set<String>(errMsgList);
                    list<String> errValidationMsgList =(list<String>) mapCustomValidationResults.get(mapVar); 
                        for(String errMsg: errValidationMsgList){
                            if(!tmpFirstDMLErrMsg.contains(errMsg)){
                                errMsgList.add(errMsg);
                            }
                        }
                    
                    }
                }
            }
            if(errMsgList != null){
                mapResults.put(KEY_ERRORS, errMsgList);
            }
            if(mapResults != null && mapResults.containsKey(KEY_ERRORS)){
                mapResults.put(KEY_STATUS, ERROR);
            }else{
                mapResults.put(KEY_STATUS, OK);
            }
        }
        catch(Exception e)
        {
            // return the exceptions
            mapResults.put(KEY_ERRORS, e.getMessage());
            // return status as error
            mapResults.put(KEY_STATUS, ERROR);
        }
        ApplicationDatabase.getInstance().dmlRollback(sp);
        System.debug('mapResults>>>>'+mapResults);
        return mapResults;
    }    
    /**
     * @description : Method is used for dummy update dml on Oppotunity to get the possible validation error messages
     */
    private static Map<String, Object> updateOpportunity(list<opportunity> updateList){
        Map<String, Object> mapResults = new Map<String, Object>();
        Set<String> ErrMsgSet = New Set<String>();
         // mimic the save
         List<String> saveErrors = new List<String>(); 
        list<Database.SaveResult> svResult = ApplicationDatabase.getInstance().dmlUpdate(updateList, false);
        System.debug('!@#$' + svResult);
        //List<Apexpages.Message> msgs = ApexPages.getMessages();  
        List<Apexpages.Message> msgs = ApexPageMessagesSelector.newInstance().getPageMessages();           
        System.debug('msgsvalidation>' + msgs);
        if(msgs != null){
            for(Apexpages.Message msg : msgs){
                string msgString = String.valueOf(msg);
                string msgStringStartTrim = msgString.remove('ApexPages.Message["');
                string msgStringStartEnd = msgStringStartTrim.removeEnd('"]');
                saveErrors.add(string.valueOf(msgStringStartEnd));
                ErrMsgSet.add(string.valueOf(msgStringStartEnd));
            }
        }
        for(Database.SaveResult res : svResult) {
            if (!res.isSuccess())
            {
                // loop through to collate error messages
                for (Database.Error err : res.getErrors())
                {   
                    String errMsg = String.valueOf(err.getMessage());
                    if(!ErrMsgSet.contains(errMsg)){
                        String errMsgReplaceSingleQuote = errMsg.replace('\'','"');
                        saveErrors.add(errMsgReplaceSingleQuote);
                        System.debug('OpptyCloseError msg:' + err.getMessage());
                    }
                }
            }
        }
        if(saveErrors.size() != 0)
        {
            // return it as a field
            mapResults.put(KEY_ERRORS, saveErrors);
        }
        return mapResults;
    }
    private static String getNextStageName(String currentStage)
    {

        if(currentStage.indexOf('Closed') == 0)
        {
            // nothing to progress or check
            return '';
        }

        // get all the picklist values
        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        // iterator
        for(Integer i = 0; i < ple.size(); i++)
        {
            //System.debug('label:' + stageName.getLabel());
            //System.debug('value:' + stageName.getValue());
            PicklistEntry stageName = ple[i];
            if(stageName.getValue() == currentStage)
            {
                return ple[i+1].getValue();
            }
        }
        return null;
    }

}