/**************************************************
Description:    Test Class  for the QuickGuideMeController
History:
--------------------------------------------------
2019-10-01  shashwat.a.nath@accenture.com  Created
**************************************************/

@istest
public with sharing class QuickGuideMeControllerTest {
    public static testmethod void createOpportunityTest() {
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        PageReference pageRef = Page.QuickGuideMe;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', acc.id);
        ApexPages.currentPage().getParameters().put('pageParam', 'quickGuideMe');
        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            QuickGuideMeController QuickGuideMeControllerInst = new QuickGuideMeController(sc);
            QuickGuideMeControllerInst.createOpportunity();
        Test.StopTest();
        List<Opportunity> oppList = [Select id from Opportunity Limit 1];
        System.assertEquals(oppList.size(),1);
    }

    public static testmethod void createOpportunityTestForQuickProposal() {
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        PageReference pageRef = Page.QuickGuideMe;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', acc.id);
        ApexPages.currentPage().getParameters().put('pageParam', 'quickProposal');
        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            QuickGuideMeController QuickGuideMeControllerInst = new QuickGuideMeController(sc);
            QuickGuideMeControllerInst.createOpportunity();
        Test.StopTest();
        List<Opportunity> oppList = [Select id from Opportunity Limit 1];
        System.assertEquals(oppList.size(),1);
    }

}