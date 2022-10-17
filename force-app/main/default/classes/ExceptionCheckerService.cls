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
 */
public inherited sharing class ExceptionCheckerService {
    private static Consumer_Help_and_Support__c CHAS_SETTINGS = Consumer_Help_and_Support__c.getOrgDefaults();
    private static String ORIGIN_SENDER = 'Sender';

    /**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static ExceptionCheckerService getInstance() {
		return (ExceptionCheckerService)Application.Utilities.getInstance(ExceptionCheckerService.class);
	}

    /**
     * Check for the exceptions in the events for articles
     * @param eventsByArticle Map<String, List<EventMessage__c>>
     *
     * @return Map<String,ExceptionResult>
     */
    public Map<String, ExceptionResultDTO> isExceptionAppliesOnEventType(List<ExceptionCheckDTO> exceptionCheckDTOS) {
        // retrieving stored exceptionDTO message config
        List<String> eventMessageString = EventMessageUtil.getCHASExceptionalEventMessageTypes();
        // storing the result to be returned per article
        Map<String, ExceptionResultDTO> articleToExceptionResult = new Map<String, ExceptionResultDTO>();
        for(ExceptionCheckDTO exceptionDTO : exceptionCheckDTOS) {
            ExceptionResultDTO result = new ExceptionResultDTO();
            // checking through events for exceptions
            for(EventMessageDTO eventMessageDTO : exceptionDTO.eventMessages) {
                // if there's an exception found set the value to true in the DTO
                if(eventMessageString.contains(eventMessageDTO.EventType)) {
                    result.isException = true;
                }
            }

            articleToExceptionResult.put(exceptionDTO.articleId,result);
        }

        return articleToExceptionResult;
    }

    /**
     * is the case has been raised recently and the number of dates variation are taken from custom setting
     * @param exceptionCheckDTOS
     *
     * @return
     */
    public Map<String, ExceptionResultDTO> isCaseRaisedRecently(List<ExceptionCheckDTO> exceptionCheckDTOS) {
        Integer recentScanDays = Integer.valueOf(CHAS_SETTINGS.RecentScanDays__c);
        // storing the result to be returned per article
        Map<String, ExceptionResultDTO> articleToExceptionResult = new Map<String, ExceptionResultDTO>();
        for(ExceptionCheckDTO exceptionDTO : exceptionCheckDTOS) {
            ExceptionResultDTO result = new ExceptionResultDTO();
            // checking through events for exceptions
            for(EventMessageDTO eventMessageDTO : exceptionDTO.eventMessages) {
                // if there was a recent scan we should get the agent to look at the case.
                if(eventMessageDTO.ActualDateTime >= Date.today().addDays(-recentScanDays)){
                    result.isException = true;
                }
            }

            articleToExceptionResult.put(exceptionDTO.articleId,result);
        }

        return articleToExceptionResult;
    }

    /**
     * is the case has been raised by the sender
     * @param exceptionCheckDTOS
     *
     * @return
     */
    public Map<String, ExceptionResultDTO> isCaseRaisedBySender(List<ExceptionCheckDTO> exceptionCheckDTOS) {
        // storing the result to be returned per article
        Map<String, ExceptionResultDTO> articleToExceptionResult = new Map<String, ExceptionResultDTO>();
        for(ExceptionCheckDTO exceptionDTO : exceptionCheckDTOS) {
            ExceptionResultDTO result = new ExceptionResultDTO();
            if(ORIGIN_SENDER.equalsIgnoreCase(exceptionDTO?.CaseToCheck?.CaseOriginator__c)) {
                result.isCaseRaiseBySender = true;
            }
            articleToExceptionResult.put(exceptionDTO.articleId,result);
        }

        return articleToExceptionResult;
    }

    // in case if we need to send more parameters we are using this DTO
    public class EventMessageDTO {
        public String eventType { get; set; }
        public DateTime actualDateTime { get; set; }
    }

    public class ExceptionCheckDTO {
        public Case CaseToCheck { get; set; }
        public String ArticleId { get; set; }
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

        public Boolean isCaseRaiseBySender{
            get{
                if(isCaseRaiseBySender == null) {
                    return false;
                }
                return isCaseRaiseBySender;
            }
            set;
        }
    }

    /**
     *  Close cases for lost in transit and 
     */
	public void closeCases(List<Case> casesToClose) {
		List<CaseComment> caseComments = new List<CaseComment>();
		for (Case c: casesToClose) {
			c.ClosedBySystem__c = true;
			c.ByPassWorkflowRulesOnCreation__c = true; //populate the filed to trigger the email
			//add comment
			CaseComment caseComment = new CaseComment();
			caseComment.IsPublished = true;
            caseComment.ParentId = c.Id;
            caseComment.CommentBody = 'Auto-LIT exception: Yes';
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
		List<CaseComment> caseComments = new List<CaseComment>();
		for (Case c: casesToAgentQueue) {
			c.AllocateToQueue__c = true;
			c.Case_Reopen_Date__c = null;
			c.Bypass_Data_enforcement__c = true;
			//add comment
			CaseComment caseComment = new CaseComment();
			caseComment.IsPublished = true;
            caseComment.ParentId = c.Id;
            caseComment.CommentBody = 'Auto-LIT exception: No';
            caseComments.add(caseComment);
		}
        //update cases
		List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToAgentQueue, false);
		UTIL_LoggingService.logDmlResults(vResult, null, casesToAgentQueue, 'Case Reopen',
            ExceptionCheckerService.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
		//insert case comments
		List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlInsert(caseComments, false);
		UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
            ExceptionCheckerService.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
	}

}