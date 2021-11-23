/**
 *Test class for bspRewriter
 @author Louis Wang (Bluewolf)
 @created 2014-09-10
 *- Test coverage 100%
*/

@isTest
private class bspRewriter_Test 
{
    static testMethod void requestURLTest() 
    {
        // test 1st class method 
        bspRewriter rew = new bspRewriter();

        // setup a test case
        Case c = new Case();
        c.Type='Test';
        insert c;
        c = [SELECT Id, CaseNumber FROM Case WHERE Id = : c.Id];
        
        // test with correct path
        string testUrl = rew.CASEDETAIL_PAGE + c.CaseNumber;
        system.debug('xxx testUrl = ' + testUrl);
        PageReference pageRef = new PageReference(testUrl); 
        rew.mapRequestUrl(pageRef);

        // test with incorrect case number
        string testUrlBad = rew.CASEDETAIL_PAGE + '123';
        PageReference pageRefBad = new PageReference(testURLBad);
        rew.mapRequestUrl(pageRefBad);
        
        // test with incorrect format
        string testUrlBadFormat = '/aaa/';
        PageReference pageRefBadFormat = new PageReference(testURLBadFormat);
        rew.mapRequestUrl(pageRefBadFormat);
    }

    static testMethod void generateURLTest() 
    {
        // test 2nd class method
        bspRewriter rew = new bspRewriter();

        // setup a test case
        Case c = new Case();
        c.Type='Test';
        insert c;
        c = [SELECT Id, CaseNumber FROM Case WHERE Id = : c.Id];

        list<PageReference> refList = new list<PageReference>();

        // test data with correct path
        string testUrl = rew.CASEDETAIL_VISUALFORCE_PAGE + c.Id; 
        PageReference pageRef = new PageReference(testUrl);
        refList.add(pageRef);
        
        // test data with incorrect format
        string testUrlBadFormat = '/aaa/';
        PageReference pageRefBadFormat = new PageReference(testURLBadFormat);
        refList.add(pageRefBadFormat);

        // generate URL conversion                 
        rew.generateUrlFor(refList);    
    }
}