/*
  Written By  : Ji Zhang (CoreTec Solutions)
  Date        : 07/10/2011
  Email       : jzhang@coretec.com.au

  Description : This extension is used to overwrite the new and edit button 
                of Relationship Power Map Object

  History     : Version 1.0 07/10/2011
                Ji Zhang    13/10/2011 Test Method Added   
                C.McIntyre  28/05/2015 Added 'with sharing' as part of security audit. 
                
                
 09.07 Eric Shen (Auspost) Update stageName='Closed Duplicate'    
 02.06.2020   shashwat.a.nath@accenture.com updated the method unitTest to set the stage name to identify and then updated it to Closed Duplicate to bypass the validation NewRecord_Stage_Validation           
 30.09.2021   seth.heang@auspost.com.au	Uplift SF API Version to 52
*/

public with sharing class RelationshipPowerMapExCon 
{
    private Id opportunityId;
    public Relationship_Power_Map__c RPM{get;set;}
    
    public RelationshipPowerMapExCon(ApexPages.StandardController controller) 
    {
        RPM = (Relationship_Power_Map__c)controller.getRecord();
    }
    
    public RelationshipPowerMapExCon(ApexPages.StandardSetController controller) 
    {     
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        RPM = new Relationship_Power_Map__c();
        RPM.Opportunity__c = opportunityId;     
    }
    
    public PageReference save()
    {
        try {
            upsert(RPM);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        return (new ApexPages.StandardController(RPM)).view();
    }
    
    /*
     * API v28 onward, disallow the inclusion of testmethod in apex classes
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     * Therefore, Migrate below test code a new test class 'RelationshipPowerMapExConTest'
     * ****************************************************************
    * Test Class
    *****************************************************************
    static testMethod void unitTest() 
    {
        Opportunity opp = new Opportunity(name='oppTest',stageName='Identify',Probability = 10 ,closeDate= date.Today(), Closed_Reason__c='test opp');
        insert opp;
        
        opp.stageName='Closed Duplicate';
        opp.Hidden_Restrict_Path_Closure__c  = true;
        update opp;
        
        Relationship_Power_Map__c pp = new Relationship_Power_Map__c (name='ppTest',Opportunity__c=opp.id);
        insert pp;
        
        PageReference pageRef = Page.RelationshipPowerMapNewEdit;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opp.id); 
        
        ApexPages.StandardController sc = new ApexPages.standardController(pp);  
        RelationshipPowerMapExCon ppExcon = new RelationshipPowerMapExCon(sc);
        
        //set this to bad data
        ppExcon.RPM = new Relationship_Power_Map__c(name='badRecord'); 
        
        //test for list set controller extension
        List<Relationship_Power_Map__c> pList = new List<Relationship_Power_Map__c>([SELECT id from Relationship_Power_Map__c limit 1]);
    
        ApexPages.StandardSetController setSc = new ApexPages.standardSetController(pList);
        RelationshipPowerMapExCon ppSetExcon = new RelationshipPowerMapExCon (setSc);
        ppSetExcon.save();  
        
        try{ppExcon.save();} catch(System.DMLException e) {}        
    }*/
}