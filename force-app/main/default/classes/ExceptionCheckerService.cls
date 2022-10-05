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
    /**
     * Check for the exceptions in the events for articles
     * @param eventsByArticle Map<String, List<EventMessage__c>>
     *
     * @return Map<String,ExceptionResult>
     */
    public static Map<String, ExceptionResultDTO> isExceptionApplies(Map<String, List<EventMessageDTO>> eventsByArticle) {
        Integer recentScanDays = Integer.valueOf(CHAS_SETTINGS.RecentScanDays__c);
        // retrieving stored exceptionDTO message config
        List<String> eventMessageString = EventMessageUtil.getCHASExceptionalEventMessageTypes();
        // storing the result to be returned per article
        Map<String, ExceptionResultDTO> articleToExceptionResult = new Map<String, ExceptionResultDTO>();
        for(String articleId : eventsByArticle.keySet()) {
            List<EventMessageDTO> exceptionDTOS = eventsByArticle.get(articleId);
            ExceptionResultDTO result = new ExceptionResultDTO();
            // checking through events for exceptions
            for(EventMessageDTO exceptionDTO : exceptionDTOS) {
                // if there's an exception found set the value to true in the DTO
                if(eventMessageString.contains(exceptionDTO.EventType)) {
                    result.isException = true;
                } // if there was a recent scan we should get the agent to look at the case.
                else if(exceptionDTO.ActualDateTime >= Date.today().addDays(-recentScanDays)){
                    result.isException = true;
                }
            }

            articleToExceptionResult.put(articleId,result);
        }

        return articleToExceptionResult;
    }

    // in case if we need to send more parameters we are using this DTO
    public class EventMessageDTO {
        public String eventType { get; set; }
        public DateTime actualDateTime { get; set; }
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
    }

    /**
     *  Close cases for lost in transit and 
     */
	public static void closeCases(List<Case> casesToClose) {
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
		List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToClose, false);
		UTIL_LoggingService.logDmlResults(vResult, null, casesToClose, 'Case Reopen',
				ExceptionCheckerService.class.getName(), 'closeCases',null, LoggingLevel.ERROR);
		//update case comments
		List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlInsert(caseComments, false);
		UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
                ExceptionCheckerService.class.getName(), 'closeCases',null, LoggingLevel.ERROR);
	}

    /**
     * Assign cases to agent queue
     */
	public static void assignCasesToAgentQueue(List<Case> casesToAgentQueue) {
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
				CaseReopenBatch.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
		//update case comments
		List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlUpdate(caseComments, false);
		UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
	}

}