/**
 * Test Class for RelationshipPowerMapExCon
 * @changelog
 * 30-09-2021 seth.heang@auspost.com.au	Migrate the testmode from the main class(RelationshipPowerMapExCon) to a new test class
 * */
@isTest
public class RelationshipPowerMapExConTest {

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
    }
}