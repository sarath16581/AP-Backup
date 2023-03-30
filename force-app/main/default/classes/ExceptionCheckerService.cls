/**
 * Created by hasan on 28/09/2022.
 */
/**
 * @description DDS-12733 Check for the exceptions for the articles which have certain event codes
 * @author hasantha.liyanage@auspost.com.au
 * @date 26/09/2022
 * @group Articles
 * @domain CHAS
 * @changelog
 * 2022-11-14 - Thang Nguyen - DDS-13602 update case comments
 * 2022-11-21 - Thang Nguyen - DDS-13756 Added isWithComment parameter of assignCasesToAgentQueue
 * 2023-03-27 - StephenL - DDS-15372 & DDS-15373 added exception logic to check if the Case's Article is of record type Consignment
 * 2023-03-30 - StephenL - Introduced ExceptionRule class and evaluateExceptionRule method for developers to definite Exception Rules dynamically
 */
public inherited sharing class ExceptionCheckerService {
    private static Consumer_Help_and_Support__c CHAS_SETTINGS = Consumer_Help_and_Support__c.getOrgDefaults();
    @TestVisible private static Id consignmentArticleRTId = SObjectType.Article__c.getRecordTypeInfosByName().get(SSSWConstants.RECTYPE_ARTICLE_CONSIGNMENT).getRecordTypeId();
    private List<String> exceptionEventMessageString = EventMessageUtil.getCHASExceptionalEventMessageTypes();
    private List<String> notificationEventMessageString = EventMessageUtil.getCHASNotificationEventMessageTypes();
    private Map<String,ExceptionRule> exceptionRules = getExceptionRules();

    @TestVisible private static String ORIGIN_ADDRESSEE = 'Addressee';

    /**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
    public static ExceptionCheckerService getInstance() {
        return (ExceptionCheckerService)Application.Utilities.getInstance(ExceptionCheckerService.class);
    }

    /**
     * @description define that constitutes an exception. This can be transformed into CMD for more configurability
     * @return all the exception rules
     */
    private Map<String,ExceptionRule> getExceptionRules() {
        Map<String,ExceptionRule> ret = new Map<String,ExceptionRule>();
        ExceptionRule isConsignment= new ExceptionRule();
        isConsignment.sourceField = 'RecordTypeId';
        isConsignment.operator = '=';
        isConsignment.compareToValue = consignmentArticleRTId; // if the article is of RT consignment, we flag exception
        ret.put('isConsignment', isConsignment);

        ExceptionRule isExceptionCheckerNotEnabled = new ExceptionRule();
        isExceptionCheckerNotEnabled.sourceField = 'EnableExceptionChecker__c';
        isExceptionCheckerNotEnabled.operator = '!=';
        isExceptionCheckerNotEnabled.compareToValue = 'true';
        ret.put('isExceptionCheckerNotEnabled', isExceptionCheckerNotEnabled);

        ExceptionRule isCaseNotRaisedByReceiver = new ExceptionRule();
        isCaseNotRaisedByReceiver.sourceField = 'CaseOriginator__c';
        isCaseNotRaisedByReceiver.operator = '!=';
        isCaseNotRaisedByReceiver.compareToValue = ORIGIN_ADDRESSEE;
        ret.put('isCaseNotRaisedByReceiver', isCaseNotRaisedByReceiver);

        ExceptionRule isExceptionAppliesOnEventType = new ExceptionRule();
        isExceptionAppliesOnEventType.sourceField = 'eventType';
        isExceptionAppliesOnEventType.operator = 'contains';
        isExceptionAppliesOnEventType.compareToList = exceptionEventMessageString;
        ret.put('isExceptionAppliesOnEventType', isExceptionAppliesOnEventType);

        ExceptionRule isCaseRaisedRecently = new ExceptionRule();
        isCaseRaisedRecently.sourceField = 'ActualDateTime';
        isCaseRaisedRecently.operator = '>=';
        isCaseRaisedRecently.compareToValue = String.valueOf(Date.today().addDays(-Integer.valueOf(CHAS_SETTINGS.RecentScanDays__c)));
        ret.put('isCaseRaisedRecently', isCaseRaisedRecently);

        return ret;
    }

    /**
     * Is exception check main method, this will return the final results after calling individual exception checks
     * @param exceptionCheckDTOS
     *
     * @return list of results can be identified by the case id or the article id
     */
    public List<ExceptionResultDTO> isExceptionApplies(List<ExceptionCheckDTO> exceptionCheckDTOS) {
        List<ExceptionResultDTO> exceptionResultDTOS = new List<ExceptionResultDTO>();
        try {
            // storing the result to be returned per article
            for (ExceptionCheckDTO exceptionDTO : exceptionCheckDTOS) {
                ExceptionResultDTO result = new ExceptionResultDTO();
                // checking through for exceptions
                result.CaseToCheck = exceptionDTO?.CaseToCheck;
                result.isException = checkForExceptions(exceptionDTO);
                exceptionResultDTOS.add(result);
            }
        } catch(Exception ex) {
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Exception Checker Service', ExceptionCheckerService.class.getName(), 'call', null, LoggingLevel.ERROR);
        }
        return exceptionResultDTOS;
    }

    /**
     * Calling individual checks
     * @param exceptionDTO
     *
     * @return returns a boolean based on the result
     */
    private Boolean checkForExceptions(ExceptionCheckDTO exceptionDTO) {
        // if the exception checker is turned off return true will allow to create the case
        if(evaluateExceptionRule(exceptionRules.get('isExceptionCheckerNotEnabled'), CHAS_SETTINGS)) {
            return true;
        }
        if (evaluateExceptionRule(exceptionRules.get('isExceptionAppliesOnEventType'), exceptionDTO.eventMessages)) {
            return true;
        }
        if (isCaseRaisedRecently(exceptionDTO)) { // isCaseRaisedRecently is not current using evaluateExceptionRule due to the additional logic of: !notificationEventMessageString.contains(eventMessageDTO.EventType)
            return true;
        }
        if (evaluateExceptionRule(exceptionRules.get('isCaseNotRaisedByReceiver'), exceptionDTO?.CaseToCheck)) {
            return true;
        }
        if (evaluateExceptionRule(exceptionRules.get('isConsignment'), exceptionDTO?.CaseToCheck?.ArticleTest__r)) {
            return true;
        }
        return false;
    }

    /**
     * Check for exceptions on the event type
     * @param exceptionDTO
     *
     * @return boolean
     */
    public Boolean isExceptionAppliesOnEventType(ExceptionCheckDTO exceptionDTO) {
        ExceptionResultDTO result = new ExceptionResultDTO();
        // checking through events for exceptions
        for(EventMessageDTO eventMessageDTO : exceptionDTO.eventMessages) {
            // if there's an exception found set the value to true in the DTO
            if(exceptionEventMessageString.contains(eventMessageDTO.EventType)) {
                return true;
            }
        }
        return false;
    }

    /**
     * is the case has been raised recently and the number of dates variation are taken from custom setting
     * @param exceptionDTO
     *
     * @return boolean
     */
    public Boolean isCaseRaisedRecently(ExceptionCheckDTO exceptionDTO) {
        Integer recentScanDays = Integer.valueOf(CHAS_SETTINGS.RecentScanDays__c);
        // checking through events for exceptions
        for(EventMessageDTO eventMessageDTO : exceptionDTO.eventMessages) {
            // if there was a recent scan we should get the agent to look at the case.
            if((!notificationEventMessageString.contains(eventMessageDTO.EventType)) &&
                    (eventMessageDTO?.ActualDateTime >= Date.today().addDays(-recentScanDays))){
                return true;
            }
        }
        return false;
    }

    /**
     * is the case has been raised by the receiver
     * @param exceptionDTO
     *
     * @return boolean
     */
    public Boolean isCaseRaisedByReceiver(ExceptionCheckDTO exceptionDTO) {
        if(ORIGIN_ADDRESSEE.equalsIgnoreCase(exceptionDTO?.CaseToCheck?.CaseOriginator__c)) {
            return true;
        }
        return false;
    }

    /**
     * is the case's article part of a consignment
     * @param exceptionDTO
     *
     * @return boolean
     */
    public Boolean isConsignment(ExceptionCheckDTO exceptionDTO) {
        return exceptionDTO?.CaseToCheck?.ArticleTest__r?.RecordTypeId == consignmentArticleRTId;
    }

    // in case if we need to send more parameters we are using this DTO
    public class EventMessageDTO {
        public String eventType {
            get{
                if(eventType == null) {
                    return '';
                }
                return eventType;
            }
            set;
        }
        public DateTime actualDateTime { get; set; }
    }

    public class ExceptionCheckDTO {
        public Case CaseToCheck { get; set; }
        public List<EventMessageDTO> eventMessages { get; set; }
    }

    public class ExceptionResultDTO {
        public Boolean isException{
            get{
                if(isException == null) {
                    return false;
                }
                return isException;
            }
            set;
        }

        public Case CaseToCheck{
            get;
            set;
        }
    }

    public class ExceptionRule {
        public String sourceField {get; set;}
        public String operator {get; set;}
        public String compareToValue {get; set;}
        public List<String> compareToList {get; set;}
    }

    /**
     *  Close cases for lost in transit and 
     */
    public void closeCases(List<Case> casesToClose) {
        List<CaseComment> caseComments = new List<CaseComment>();
        for (Case c: casesToClose) {
            c.Status = 'Closed';
            c.ClosedBySystem__c = true;
            c.ByPassWorkflowRulesOnCreation__c = true; //populate the filed to trigger the email
            //add comment
            CaseComment caseComment = new CaseComment();
            caseComment.ParentId = c.Id;
            caseComment.CommentBody = Label.AutoLITExceptionNo;
            caseComments.add(caseComment);
        }
        //update cases
        List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToClose, false);
        UTIL_LoggingService.logDmlResults(vResult, null, casesToClose, 'Case Reopen',
                ExceptionCheckerService.class.getName(), 'closeCases',null, LoggingLevel.ERROR);
        //insert case comments
        List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlInsert(caseComments, false);
        UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
                ExceptionCheckerService.class.getName(), 'closeCases',null, LoggingLevel.ERROR);
    }

    /**
     * Assign cases to agent queue
     */
    public void assignCasesToAgentQueue(List<Case> casesToAgentQueue) {
        this.assignCasesToAgentQueue(casesToAgentQueue, true);
    }

    public void assignCasesToAgentQueue(List<Case> casesToAgentQueue, Boolean isWithComment) {
        List<CaseComment> caseComments = new List<CaseComment>();
        for (Case c: casesToAgentQueue) {
            c.AllocateToQueue__c = true;
            c.Case_Reopen_Date__c = null;
            c.Bypass_Data_enforcement__c = true;
            //add comment
            if (isWithComment){
                CaseComment caseComment = new CaseComment();
                caseComment.ParentId = c.Id;
                caseComment.CommentBody = Label.AutoLITExceptionYes;
                caseComments.add(caseComment);
            }
        }
        //update cases
        List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToAgentQueue, false);
        UTIL_LoggingService.logDmlResults(vResult, null, casesToAgentQueue, 'Case Reopen',
                ExceptionCheckerService.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
        if (isWithComment){
            //insert case comments
            List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlInsert(caseComments, false);
            UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
                    ExceptionCheckerService.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
        }
    }

    /**
     * @param rule ExceptionRule
     * @param sourceObject the Object that will be used for evaluation
     *
     * @return evaluate if an exception exists according to rule being passed
     */
    private Boolean evaluateExceptionRule(ExceptionRule rule, Object sourceObject) { // has to use Object rather than SObject, due to the lack of get(FIELD_NAME_AS_STRING_VALUE) method for non-SObject types
        return evaluateExceptionRule(rule, new List<Object>{sourceObject});
    }

    private Boolean evaluateExceptionRule(ExceptionRule rule, List<Object> sourceObjects) {
        Boolean exceptionFound = false;

        for (Object sourceObject : sourceObjects) {
            if (sourceObject == null) {
                return false;
            }

            Object sourceFieldValue = ((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(sourceObject))).get(rule.sourceField); // using JSON serialize and deserializeUntyped round trip to get the value from a given field, due to the lack of get(FIELD_NAME_AS_STRING_VALUE) method for non-SObject types
            switch on rule.operator {
                when '=','==' {
                    if (String.valueOf(sourceFieldValue).equalsIgnoreCase(String.valueOf(rule.compareToValue))) {
                        return true;
                    } else {
                        continue;
                    }
                }
                when '!=','<>' {
                    if (!String.valueOf(sourceFieldValue).equalsIgnoreCase(String.valueOf(rule.compareToValue))) {
                        return true;
                    } else {
                        continue;
                    }
                }
                when '>=' {
                    if (Double.valueOf(sourceFieldValue) >= Double.valueOf(rule.compareToValue)) {
                        return true;
                    } else {
                        continue;
                    }
                }
                when 'contains' {
                    if (rule.compareToList.contains(String.valueOf(sourceFieldValue))) {
                        return true;
                    } else {
                        continue;
                    }
                }
            }
        }

        return exceptionFound;
    }

}