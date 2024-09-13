/**
 * @description This is a test class for the ImpactedArticleTrigger_Test
 * @author Seth Heang
 * @changelog:
 * 2024-09-13 - Seth Heang - Created
**/
@IsTest
private class ImpactedArticleTrigger_Test {
    @IsTest
    static void testEnsureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        ImpactedArticleTriggerHandler mock = (ImpactedArticleTriggerHandler)MockUtility.mockUtility(ImpactedArticleTriggerHandler.class);

        Case caseTest = ApplicationTestDataFactoryCase.getCases(1, false)[0];
        insert caseTest;

        Article__c articleTest = ApplicationTestDataFactory.getArticles(1, false)[0];
        insert articleTest;

        ImpactedArticle__c impactedArticle = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, articleTest.Id, false)[0];
        insert impactedArticle;

        System.debug('SETH impactedArticle inserted: ' + impactedArticle);

        ((ImpactedArticleTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

        // PMD Warning
        System.assert(true);
    }
}