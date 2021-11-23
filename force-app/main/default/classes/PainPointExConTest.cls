/**
 * Test Class for PainPointExCon
 * @changelog
 * 30-09-2021 seth.heang@auspost.com.au	Migrate the testmode from the main class(PainPointExCon) to a new test class
 * */
@isTest
public class PainPointExConTest {

    static testMethod void unitTest() 
    {
        Opportunity opp = new Opportunity(name='oppTest',stageName='Identify',Closed_Reason__c='test opp',Probability = 10 ,closeDate= date.Today());
        insert opp;
        
        opp.stageName='Closed Duplicate';
        opp.Hidden_Restrict_Path_Closure__c =true;
        update opp;
        
        Pain_Point__c pp = new Pain_Point__c (name='ppTest',Opportunity__c=opp.id);
        insert pp;
        
        PageReference pageRef = Page.PainChainNewEdit;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opp.id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(pp);  
        PainPointExCon ppExcon = new PainPointExCon(sc);
        
        //set this to bad data
        ppExcon.PainPoint = new Pain_Point__c(name='badRecord'); 
        
        //test for list set controller extension
        List<Pain_Point__c> pList = new List<Pain_Point__c>([SELECT id from Pain_Point__c limit 1]);
    
        ApexPages.StandardSetController setSc = new ApexPages.standardSetController(pList);
        PainPointExCon ppSetExcon = new PainPointExCon(setSc);
        ppSetExcon.save();  
        
        try{ppExcon.save();} catch(System.DMLException e) {}        
    }
}