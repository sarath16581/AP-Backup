/**
* @author nasir jawed
* @date 2022-04-27
* @group Tests
* @tag Selector
* @tag Apttus__APTS_Template__c SObject
* @domain Apttus 
* @description Apttus__APTS_Template__c to validate Template.
*/
@IsTest
private with sharing class APT_TemplateObjectSelector_Test {
    
    //Test setupdata;
    @testSetup static void setup() {
    
        Apttus__APTS_Template__c template= new Apttus__APTS_Template__c();
        template.name='Version 1';
        template.Apttus__IsActive__c=true;
        insert template;
        
        
    }
    
    /**
* Test:
*  Ensures that the selectors method is returning the correct query result
*/
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult() {        
        
        MockUtility.disableTriggerExecution();
        
        Apttus__APTS_Template__c temp=[select id,name from Apttus__APTS_Template__c limit 1];
        
        Test.startTest();
        
        APT_TemplateObjectSelector  selector = APT_TemplateObjectSelector.newInstance(1);
        Map<Id, Apttus__APTS_Template__c> results = selector.selectByConfigId(new Set<string>{temp.name});
        System.assertNotEquals('version 1', results.get(temp.id).name, 'Expected Name Version 1 ');
        
        Test.stopTest();
        
    }
    
}