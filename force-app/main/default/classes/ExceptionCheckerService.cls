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
public with sharing class ExceptionCheckerService {

    /**
     * Check for the exceptions in the events for articles
     * @param eventsByArticle Map<String, List<EventMessage__c>>
     *
     * @return Map<String,ExceptionResult>
     */
    public static Map<String,ExceptionResult> isExceptionApplies(Map<String, List<EventMessage__c>> eventsByArticle) {
        // retrieving stored event message config
        List<String> eventMessageString = EventMessageUtil.getCHASExceptionalEventMessageTypes();
        // storing the result to be returned per article
        Map<String,ExceptionResult> articleToExceptionResult = new Map<String,ExceptionResult>();
        for(String articleId : eventsByArticle.keySet()) {
            List<EventMessage__c> events = eventsByArticle.get(articleId);
            ExceptionResult result = new ExceptionResult();
            // checking through events for exceptions
            for(EventMessage__c event : events) {
                // if there's an exception found set the value to true in the DTO
                if(eventMessageString.contains(event.EventType__c)) {
                    result.isException = true;
                } // if there was a recent scan we should get the agent to look at the case.
                else if(event.ActualDateTime__c >= Date.today().addDays(-5)){
                    result.isException = true;
                }
            }

            articleToExceptionResult.put(articleId,result);
        }

        return articleToExceptionResult;
    }

    // in case if we need to send more parameters we are using this DTO
    public class ExceptionResult {
        public boolean isException{
            get{
                if(isException == null) {
                    return false;
                }
                return isException;
            }
            set;
        }
    }

}