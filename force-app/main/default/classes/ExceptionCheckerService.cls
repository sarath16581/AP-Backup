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
 */
public inherited sharing class ExceptionCheckerService {
    private static Consumer_Help_and_Support__c CHAS_SETTINGS = Consumer_Help_and_Support__c.getOrgDefaults();
    private List<String> exceptionEventMessageString = EventMessageUtil.getCHASExceptionalEventMessageTypes();
    private List<String> notificationEventMessageString = EventMessageUtil.getCHASNotificationEventMessageTypes();

    @TestVisible private static String ORIGIN_ADDRESSEE = 'Addressee';

    /**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static ExceptionCheckerService getInstance() {
		return (ExceptionCheckerService)Application.Utilities.getInstance(ExceptionCheckerService.class);
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
        if(!CHAS_SETTINGS.EnableExceptionChecker__c) {
            return true;
        }
        if (isExceptionAppliesOnEventType(exceptionDTO)) {
            return true;
        }
        if (isCaseRaisedRecently(exceptionDTO)) {
            return true;
        }
        if (!isCaseRaisedByReceiver(exceptionDTO)) {
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

}