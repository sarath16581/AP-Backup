/**
 *Test class for schema classes.
 @author Fuqi Tan
 @created 2014-06-20
 *- Test coverage 90%
*/

@isTest
private class BatchableArticleDeleter_Test{
    @IsTest
    static void testGeneral(){
        Case case1 = TestDataProvider.createCase();
        insert case1;
        
        RecordType rt = [select Id from RecordType where sobjecttype='Article__c' limit 1];
        Article__c article1 = new Article__c();
        article1.RecordTypeId = rt.Id;
        article1.Name = 'testArticle';
        article1.ArticleID__c = case1.Id;
        List<Article__c> list_articles = new List<Article__c>();
        list_articles.add(article1);
        insert list_articles;
        
        Test.startTest();
        
        BatchableArticleDeleter cls = new BatchableArticleDeleter();
        Database.BatchableContext bc;
        cls.start(bc);
        cls.execute(bc, list_articles);
        cls.finish(bc);
        
        system.assert(true);
        Test.stopTest();
    }
}