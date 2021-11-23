@isTest
private class APT_SendInstanceURL_Test{
    
    public static testMethod void testingData(){
        APT_SendInstanceURL sendURL = new APT_SendInstanceURL ();
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
        insert proposal;
        sendURL.ProposalId= Proposal.Id;
        sendURL.greaterThan25K =false;
        sendURL.multipleCreditAssessments=true;
        sendURL.proposalNotComplete= 'Yes';
        Test.startTest();
        sendURL.getDeclinedCreditAssessments();
        sendURL.getAssessmentNotComplete();
        sendURL.getGreaterThan25K();
        sendURL.getMultipleCreditAssessments();
        sendURL.getSingleCreditAssessments();
        
        Test.stopTest();
    }
    public static testMethod void testingData1(){
        APT_SendInstanceURL sendURL = new APT_SendInstanceURL ();
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        sendURL.ProposalId= tempacct.Id;
        Test.startTest();
        sendURL.getDeclinedCreditAssessments();
        Test.stopTest();
    }
}