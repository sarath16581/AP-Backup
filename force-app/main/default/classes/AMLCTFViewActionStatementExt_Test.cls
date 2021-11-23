@isTest
private class AMLCTFViewActionStatementExt_Test {
/*------------------------------------------------------------------------
Author:        Deepu Chacko
Company:       Salesforce
Description:   A test class created to validate the AMLCTFViewActionStatement visualforce page
               Tests executed:
               1 - list()
               List Actions for an Action Statement
               2 - update()
               Update Actions of an Action Statement
               3 - delete()
               Delete Actions of an Action Statement
History
<Date>          <Authors Name>      <Brief Description of Change>
15.Sep.2016     Deepu Chacko        Initial Version
----------------------------------------------------------------------------*/
    
    @testSetup static void setupActions() {
        // Get recordtype definitions
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap    = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> networkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
        
        // A network is required to create a case
        Network__c nw = TestUtility.createNetwork('SFDC',
                                                  networkRecTypeMap.get('Retail').getRecordTypeId(),
                                                  'bruce@wayne.com');
        Database.insert(nw);
        // Create the case using the above network
        Case csRec = TestUtility.createCase('Test Audit Subject',
                                            'In Progress',
                                            'General Enquiry',
                                            null,
                                            null,
                                            caseRecTypeMap.get('Scheduled Audit').getRecordTypeId());
        csRec.Origin        = 'Referral';
        csRec.AMLCTF_Planned_Audit_Date__c = Date.today();
        csRec.Network__c    = nw.id;
        Database.insert(csRec);
        
        // Now create the action statement
        AMLCTF_Audit_Action_Statement__c stmt = new AMLCTF_Audit_Action_Statement__c(AMLCTF_Audit_Case__c = csRec.Id);
        Database.insert(stmt);
        
        // Create actions for this audit statement
        AMLCTF_Audit_Action__c act1 = new AMLCTF_Audit_Action__c(
                                        AMLCTF_Audit_Action_Statement__c = stmt.id,
                                        Name = 'Action 1',
                                        AMLCTF_Item_Number__c = 1,
                                        AMLCTF_Audit_Task_Num__c = '1.1.1',
                                        AMLCTF_Task_Name__c = 'Cash in the box');
        insert act1;

        AMLCTF_Audit_Action__c act2 = new AMLCTF_Audit_Action__c(
                                        AMLCTF_Audit_Action_Statement__c = stmt.id,
                                        Name = 'Action 2',
                                        AMLCTF_Item_Number__c = 2,
                                        AMLCTF_Audit_Task_Num__c = '1.1.2',
                                        AMLCTF_Task_Name__c = 'Cash in the box');
        insert act2;
        
        // Create standard responses
        Audit_Action_Standard_Response__c std1 = new Audit_Action_Standard_Response__c(Name = 'Std Resp 1', Audit_Task_Num__c = '1.1.1'); insert std1;
        Audit_Action_Standard_Response__c std2 = new Audit_Action_Standard_Response__c(Name = 'Std Resp 2', Audit_Task_Num__c = '1.1.1'); insert std2;
        Audit_Action_Standard_Response__c std3 = new Audit_Action_Standard_Response__c(Name = 'Std Resp 3', Audit_Task_Num__c = '1.1.2'); insert std3;
    }
    
    @isTest static void runFetchActions(){
        // there is only one action statement created from test setup
        AMLCTF_Audit_Action_Statement__c stmt = [SELECT Id 
                                                 FROM AMLCTF_Audit_Action_Statement__c 
                                                 LIMIT 1];
        
        // define the page to test
        PageReference pg = Page.AMLCTFViewActionStatement;
        pg.getParameters().put('id', stmt.id);
        
        // start the test execution context
        Test.startTest();
        // set the test's page to our VF page
        Test.setCurrentPage(pg);
        // call the constructor
        AMLCTFViewActionStatementExt ext    = new AMLCTFViewActionStatementExt(new ApexPages.StandardController(stmt));
        // stop the test
        Test.stopTest();
        
        System.assertEquals(2, ext.actions.size(), 'Actions should be 2 but it is ' + ext.actions.size());
        System.assertEquals(2, ext.actions[0].stdResponses.size(), 'Standard responses should be 2 but it is ' + ext.actions[0].stdResponses.size());
    }
    @isTest static void runSaveActions(){
        // there is only one action statement created from test setup
        AMLCTF_Audit_Action_Statement__c stmt = [SELECT Id 
                                                 FROM AMLCTF_Audit_Action_Statement__c 
                                                 LIMIT 1];
        
        // define the page to test
        PageReference pg = Page.AMLCTFViewActionStatement;
        pg.getParameters().put('id', stmt.id);
        
        // start the test execution context
        Test.startTest();
        // set the test's page to our VF page
        Test.setCurrentPage(pg);
        // call the constructor
        AMLCTFViewActionStatementExt ext    = new AMLCTFViewActionStatementExt(new ApexPages.StandardController(stmt));
        // make updates and mark record for deletion
        for(AMLCTFViewActionStatementExt.ActionWrapper action : ext.actions){
            if(action.record.AMLCTF_Audit_Task_Num__c == '1.1.1')
                action.markedForDelete = true;
            else
                action.isUpdated = true;
        }
        ext.saveActions();
        // stop the test
        Test.stopTest();
        
        System.assertEquals(1, ext.actions.size(), 'Actions should be 1 but it is ' + ext.actions.size());
        System.assertEquals(1, ext.actions[0].stdResponses.size(), 'Standard responses should be 1 but it is ' + ext.actions[0].stdResponses.size());
    }
    @isTest static void runSaveActionsWithException(){
        // there is only one action statement created from test setup
        AMLCTF_Audit_Action_Statement__c stmt = [SELECT Id 
                                                 FROM AMLCTF_Audit_Action_Statement__c 
                                                 LIMIT 1];
        
        // define the page to test
        PageReference pg = Page.AMLCTFViewActionStatement;
        pg.getParameters().put('id', stmt.id);
        
        // start the test execution context
        Test.startTest();
        // set the test's page to our VF page
        Test.setCurrentPage(pg);
        // call the constructor
        AMLCTFViewActionStatementExt ext    = new AMLCTFViewActionStatementExt(new ApexPages.StandardController(stmt));
        // make updates and mark record for deletion
        Id delRecordId;
        for(AMLCTFViewActionStatementExt.ActionWrapper action : ext.actions){
            if(action.record.AMLCTF_Audit_Task_Num__c == '1.1.1'){
                delRecordId = action.record.id;
                action.markedForDelete = true;
            }
        }
        // Now explicitly delete the action record
        AMLCTF_Audit_Action__c act = [SELECT Id FROM AMLCTF_Audit_Action__c WHERE Id =: delRecordId];
        delete act;
        // Now attempt to delete through the extension class to invoke the exception
        ext.saveActions();
        // stop the test
        Test.stopTest();
        
        // Because of the rollback, actions size should remain intact
        System.assertEquals(2, ext.actions.size(), 'Actions should be 2 but it is ' + ext.actions.size());
    }    
}