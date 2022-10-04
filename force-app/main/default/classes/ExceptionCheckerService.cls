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

    /**
     * Check for the exceptions in the events for articles
     * @param eventsByArticle Map<String, List<EventMessage__c>>
     *
     * @return Map<String,ExceptionResult>
     */
    public static Map<String, ExceptionResultDTO> isExceptionApplies(Map<String, List<EventMessageDTO>> eventsByArticle) {
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
                else if(exceptionDTO.ActualDateTime >= Date.today().addDays(-5)){
                    result.isException = true;
                }
            }

            articleToExceptionResult.put(articleId,result);
        }

        return articleToExceptionResult;
    }

    /**
     * support for EventMessage__c for back end use
     * @param eventsByArticle Map<String, List<EventMessage__c>>
     *
     * @return Map<String, ExceptionResultDTO>
     */
    public static Map<String, ExceptionResultDTO> isExceptionApplies(Map<String, List<EventMessage__c>> eventsByArticle) {
        Map<String, List<EventMessageDTO>> eventDTOsByArticle = new  Map<String, List<EventMessageDTO>>();
        for(String articleId: eventsByArticle.keySet()){
            if(eventsByArticle.get(articleId) == null) {continue;}
            List<EventMessageDTO> eventMessageDTOS = new List<EventMessageDTO>();
            for(EventMessage__c event : eventsByArticle.get(articleId)) {
                ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
                eventMessageDTO.EventType = event.EventType__c;
                eventMessageDTO.ActualDateTime = event.ActualDateTime__c;
                eventMessageDTOS.add(eventMessageDTO);
            }
            eventDTOsByArticle.put(articleId, eventMessageDTOS);
        }
        return isExceptionApplies(eventDTOsByArticle);
    }

    // in case if we need to send more parameters we are using this DTO
    public class EventMessageDTO {
        public String EventType { get; set; }
        public DateTime ActualDateTime { get; set; }
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

}