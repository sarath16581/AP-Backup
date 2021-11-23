/*
  Written By  : Ji Zhang (CoreTec Solutions)
  Date        : 12/10/2011
  Email       : jzhang@coretec.com.au

  Description : This extension is used to overwrite the new and edit button of Pain Chains Object

  History     : Version 1.0 12/10/2011
                Ji Zhang    13/10/2011 Test Method Added  
                C.McIntyre  28/5/2015 - Added 'with sharing' as part of security audit.   
                
                
 09.07.2015   Eric Shen(Auspost)    Update  stageName='Closed Duplicate'   
 02.06.2020   shashwat.a.nath@accenture.com updated the method unitTest to set the stage name to identify and then updated it to Closed Duplicate to bypass the validation NewRecord_Stage_Validation            
 30.09.2021   seth.heang@auspost.com.au	Uplift SF API Version to 52
*/ 
public with sharing class PainPointExCon {
    
    private Id opportunityId;
    public Pain_Point__c PainPoint{ get;set; }
    
    //Standard Controller Constructor
    public PainPointExCon(ApexPages.StandardController controller) {
        PainPoint = (Pain_Point__c) controller.getRecord();
    }
    
    //Standard List Controller Constructor
    public PainPointExCon(ApexPages.StandardSetController controller) {
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        PainPoint = new Pain_Point__c();
        PainPoint.Opportunity__c = opportunityId;
    }
    
    public PageReference save()
    {
        try {
            upsert(PainPoint);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        return (new ApexPages.StandardController(PainPoint)).view();
    }
    
    /* 
     * API v28 onward, disallow the inclusion of testmethod in apex classes
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     * Therefore, Migrate below test code a new test class 'PainPointExConTest'
     * ****************************************************************
    * Test Class
    *****************************************************************
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
    }*/
}