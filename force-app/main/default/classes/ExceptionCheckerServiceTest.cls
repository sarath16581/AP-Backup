/**
* @description Test class for ExceptionCheckerService
* @author hasantha.liyanage@auspost.com.au
* @date 26/09/2022
* @group Articles
* @changelog
*/
@IsTest
public class ExceptionCheckerServiceTest {

    @TestSetup
    private static void setup() {
        Consumer_Help_and_Support__c hs = new Consumer_Help_and_Support__c();
        hs.RecentScanDays__c = 5;
        insert hs;
    }

    @IsTest
    private static void testExceptionCheckerService_exceptionFound_001() {

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();

        ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
        exceptionCheckDTO.CaseToCheck = cases[0];
        ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
        eventMessageDTO.EventType = 'AFC-ER19';

        exceptionCheckDTO.eventMessages =  new List<ExceptionCheckerService.EventMessageDTO> {eventMessageDTO};

        exceptionCheckDTOS.add(exceptionCheckDTO);

        System.assertEquals(true, ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS)[0].isException, 'TestExceptionCheckerService_exceptionFound_001: Should marked as exception found');
    }

    @IsTest
    private static void testExceptionCheckerService_No_exceptionFound_001() {

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].CaseOriginator__c = ExceptionCheckerService.ORIGIN_ADDRESSEE;
        List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();

        ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
        exceptionCheckDTO.CaseToCheck = cases[0];
        ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
        eventMessageDTO.EventType = 'DD-ER13';

        exceptionCheckDTO.eventMessages =  new List<ExceptionCheckerService.EventMessageDTO> {eventMessageDTO};

        exceptionCheckDTOS.add(exceptionCheckDTO);

        System.assertEquals(false, ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS)[0].isException, 'TestExceptionCheckerService_No_exceptionFound_001: Should marked as NO exception found');

    }

    @IsTest
    private static void testExceptionCheckerService_recent_scan_exception_001() {

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();

        ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
        exceptionCheckDTO.CaseToCheck = cases[0];
        ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
        eventMessageDTO.EventType = 'DD-ER13';
        eventMessageDTO.ActualDateTime = Date.today().addDays(-3);

        exceptionCheckDTO.eventMessages =  new List<ExceptionCheckerService.EventMessageDTO> {eventMessageDTO};

        exceptionCheckDTOS.add(exceptionCheckDTO);

        System.assertEquals(true, ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS)[0].isException, 'TestExceptionCheckerService_recent_scan_exception_001: When event date is less than 5 days it should marked as exception found');

    }

    @IsTest
    private static void testExceptionCheckerService_recent_scan_exception_002() {

        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].CaseOriginator__c = ExceptionCheckerService.ORIGIN_ADDRESSEE;
        List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();

        ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
        exceptionCheckDTO.CaseToCheck = cases[0];
        ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
        eventMessageDTO.EventType = 'DD-ER13';
        eventMessageDTO.ActualDateTime = Date.today().addDays(-10);

        exceptionCheckDTO.eventMessages =  new List<ExceptionCheckerService.EventMessageDTO> {eventMessageDTO};

        exceptionCheckDTOS.add(exceptionCheckDTO);

        System.assertEquals(false, ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS)[0].isException, 'TestExceptionCheckerService_recent_scan_exception_002: When event date is more than 5 days it should marked as exception NOT found');

    }

    @IsTest
    private static void testExceptionCheckerService_Is_Recipient_001() {
        
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        cases[0].CaseOriginator__c = ExceptionCheckerService.ORIGIN_ADDRESSEE;
        List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();

        ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
        exceptionCheckDTO.CaseToCheck = cases[0];
        ExceptionCheckerService.EventMessageDTO eventMessageDTO = new ExceptionCheckerService.EventMessageDTO();
        eventMessageDTO.EventType = 'DD-ER13';
        eventMessageDTO.ActualDateTime = Date.today().addDays(-10);

        exceptionCheckDTO.eventMessages =  new List<ExceptionCheckerService.EventMessageDTO> {eventMessageDTO};

        exceptionCheckDTOS.add(exceptionCheckDTO);

        System.assertEquals(false, ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS)[0].isException, 'testExceptionCheckerService_Is_Recipient_001: When case raised by recipient it should marked as exception NOT found');

    }

    @IsTest
    private static void testCloseCases() {
        // =====================================
        // Data Preparation
        // =====================================
		List<Case> vCases = ApplicationTestDataFactory.getCases(100, true);

        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        MockUtility.Mocks.when(vMockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
		Test.startTest();
		ExceptionCheckerService service = ExceptionCheckerService.getInstance();
        service.closeCases(vCases);
		Test.stopTest();

        // PMD by-pass
		System.assert(true, 'PMD by-pass');
        // should have attempted to update and insert the request
        ((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false));
        ((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false));
    }

    @IsTest
    private static void testAssignCasesToAgentQueue() {
        // =====================================
        // Data Preparation
        // =====================================
		List<Case> vCases = ApplicationTestDataFactory.getCases(100, true);

        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        MockUtility.Mocks.when(vMockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
		Test.startTest();
		ExceptionCheckerService service = ExceptionCheckerService.getInstance();
        service.assignCasesToAgentQueue(vCases);
		Test.stopTest();

        // PMD by-pass
		System.assert(true, 'PMD by-pass');
        // should have attempted to update and insert the request
        ((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false));
        ((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false));
    }
}