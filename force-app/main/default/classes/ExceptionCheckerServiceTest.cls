/**
* @description Test class for ExceptionCheckerService
* @author hasantha.liyanage@auspost.com.au
* @date 26/09/2022
* @group Articles
* @changelog
*/
@IsTest
public class ExceptionCheckerServiceTest {
    @IsTest
    private static void setup() {

    }

    @IsTest
    private static void TestExceptionCheckerService_exceptionFound_001() {
        Map<String, List<EventMessage__c>> eventsByArticle = new Map<String, List<EventMessage__c>>();
        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
        event1.EventType__c = 'AFC-ER19'; //
        event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

        eventsByArticle.put(article.Id, new List<EventMessage__c> {event1});
        Map<String,ExceptionCheckerService.ExceptionResult> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);

        for(ExceptionCheckerService.ExceptionResult res : result.values()) {
            System.assertEquals(true, res.isException, 'TestExceptionCheckerService_exceptionFound_001: Should marked as exception found');
        }

    }

    @IsTest
    private static void TestExceptionCheckerService_No_exceptionFound_001() {
        Map<String, List<EventMessage__c>> eventsByArticle = new Map<String, List<EventMessage__c>>();
        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
        event1.EventType__c = 'DD-ER13'; //
        event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

        eventsByArticle.put(article.Id, new List<EventMessage__c> {event1});
        Map<String,ExceptionCheckerService.ExceptionResult> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);

        for(ExceptionCheckerService.ExceptionResult res : result.values()) {
            System.assertEquals(false, res.isException, 'TestExceptionCheckerService_No_exceptionFound_001: Should marked as NO exception found');
        }
    }

}