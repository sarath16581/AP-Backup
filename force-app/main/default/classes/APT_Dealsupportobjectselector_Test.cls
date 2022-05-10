/**
* @author nasir jawed
* @date 2022-04-27
* @group Tests
* @tag Selector
* @tag Deal_Support_Request__c SObject
* @domain Apttus 
* @description Deal_Support_Request__c to validate Data.
*/
@IsTest
private with sharing class APT_Dealsupportobjectselector_Test {
    
    //Test setupdata;
    @testSetup static void setup() { 
    
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;        
        
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.type = 'New Customer';
        insert opty;   
        
        Id bidDSRRecordTypeId = [Select Id from RecordType where Name='Bids Support Request' and sObjectType='Deal_Support_Request__c'].Id;
        
        Deal_Support_Request__c dsr= new Deal_Support_Request__c();
        dsr.Quote_Validity_End_Date__c=system.today();
        dsr.stage__c='New';
        dsr.Status__c='Draft';
        dsr.Start_Date__c = date.Today();
        dsr.Due_Date__c = date.Today().addDays(25); 
        dsr.Document_Type__c = 'RFP'; 
        dsr.Organisation__c=acc.id;
        dsr.Product__c='Courier';
        dsr.Work_Type__c='other';
        dsr.RecordTypeId = bidDSRRecordTypeId;
        dsr.Opportunity__c = opty.Id;
        insert dsr;
       
        
        
    }
    
    /**
* Test:
*  Ensures that the selectors method is returning the correct query result
*/
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult() {        
        
        MockUtility.disableTriggerExecution();
        
        Deal_Support_Request__c dsr=[select id from Deal_Support_Request__c limit 1];
        
        Test.startTest();
        
        APT_Dealsupportobjectselector selector = APT_Dealsupportobjectselector.newInstance(1);
        Map<Id, Deal_Support_Request__c > results = selector.selectByConfigId(new Set<ID>{dsr.id});
        System.assertEquals(system.today(), results.get(dsr.id).Quote_Validity_End_Date__c, 'Expected Quote validity end date is Today');
        
        Test.stopTest();
        
    }
    
}