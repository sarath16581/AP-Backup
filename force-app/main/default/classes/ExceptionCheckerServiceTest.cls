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
    private static void TestExceptionCheckerService_exceptionFound_001() {

        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        Map<String, List<ExceptionCheckerService.EventMessageDTO>> eventsByArticle = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();

        ExceptionCheckerService.EventMessageDTO event1dExceptionDTO = new ExceptionCheckerService.EventMessageDTO();
        event1dExceptionDTO.EventType = 'AFC-ER19';

        eventsByArticle.put(article.Id, new List<ExceptionCheckerService.EventMessageDTO> {event1dExceptionDTO});

        Test.startTest();
        Map<String,ExceptionCheckerService.ExceptionResultDTO> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);
        Test.stopTest();

        for(ExceptionCheckerService.ExceptionResultDTO res : result.values()) {
            System.assertEquals(true, res.isException, 'TestExceptionCheckerService_exceptionFound_001: Should marked as exception found');
        }

    }

    @IsTest
    private static void TestExceptionCheckerService_No_exceptionFound_001() {

        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        Map<String, List<ExceptionCheckerService.EventMessageDTO>> eventsByArticle = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();

        ExceptionCheckerService.EventMessageDTO event1dExceptionDTO = new ExceptionCheckerService.EventMessageDTO();
        event1dExceptionDTO.EventType = 'DD-ER13';

        eventsByArticle.put(article.Id, new List<ExceptionCheckerService.EventMessageDTO> {event1dExceptionDTO});

        Test.startTest();
        Map<String,ExceptionCheckerService.ExceptionResultDTO> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);
        Test.stopTest();

        for(ExceptionCheckerService.ExceptionResultDTO res : result.values()) {
            System.assertEquals(false, res.isException, 'TestExceptionCheckerService_No_exceptionFound_001: Should marked as NO exception found');
        }
    }

    @IsTest
    private static void TestExceptionCheckerService_recent_scan_exception_001() {

        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        Map<String, List<ExceptionCheckerService.EventMessageDTO>> eventsByArticle = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();

        ExceptionCheckerService.EventMessageDTO event1dExceptionDTO = new ExceptionCheckerService.EventMessageDTO();
        event1dExceptionDTO.EventType = 'DD-ER13';
        event1dExceptionDTO.ActualDateTime = Date.today().addDays(-3);

        eventsByArticle.put(article.Id, new List<ExceptionCheckerService.EventMessageDTO> {event1dExceptionDTO});

        Test.startTest();
        Map<String,ExceptionCheckerService.ExceptionResultDTO> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);
        Test.stopTest();

        for(ExceptionCheckerService.ExceptionResultDTO res : result.values()) {
            System.assertEquals(true, res.isException, 'TestExceptionCheckerService_recent_scan_exception_001: When event date is less than 5 days it should marked as exception found');
        }
    }

    @IsTest
    private static void TestExceptionCheckerService_recent_scan_exception_002() {

        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

        Map<String, List<ExceptionCheckerService.EventMessageDTO>> eventsByArticle = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();

        ExceptionCheckerService.EventMessageDTO event1dExceptionDTO = new ExceptionCheckerService.EventMessageDTO();
        event1dExceptionDTO.EventType = 'DD-ER13';
        event1dExceptionDTO.ActualDateTime = Date.today().addDays(-10);

        eventsByArticle.put(article.Id, new List<ExceptionCheckerService.EventMessageDTO> {event1dExceptionDTO});

        Test.startTest();
        Map<String,ExceptionCheckerService.ExceptionResultDTO> result = ExceptionCheckerService.isExceptionApplies(eventsByArticle);
        Test.stopTest();

        for(ExceptionCheckerService.ExceptionResultDTO res : result.values()) {
            System.assertEquals(false, res.isException, 'TestExceptionCheckerService_recent_scan_exception_002: When event date is more than 5 days it should marked as exception NOT found');
        }
    }
}