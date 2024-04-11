@IsTest(SeeAllData=true)
public with sharing class AMLCTFActionStatementRedirectConExt_Test {
/*------------------------------------------------------------------------
Author:        Kenny Liew
Company:       Salesforce
Description:   A test class created to validate the AMLCTFActionStatementNewButtonOverride visualforce page
History
<Date>      	<Authors Name>     	<Brief Description of Change>
15.Sep.2016    	Kenny Liew	     	Initial Version
----------------------------------------------------------------------------*/

    public static testMethod void testMyController() {
        
        RecordType scheduledAuditRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'ACIC_Request' LIMIT 1];
		//REQ3448199 replace AMLCTF_Scheduled_Audit RT with ACIC_Request
        Network__c selectedLPO = [SELECT Id FROM Network__c WHERE Name LIKE '%LPO' LIMIT 1];
        Case testCaseRecord = new Case();
        testCaseRecord.RecordTypeId = scheduledAuditRecordTypeId.Id;
        testCaseRecord.Network__c = selectedLPO.Id;
        testCaseRecord.AMLCTF_Planned_Audit_Date__c = Date.today();
        testCaseRecord.Origin = 'Referral';
		insert testCaseRecord;
        
        AMLCTF_Audit_Action_Statement__c childRec = new AMLCTF_Audit_Action_Statement__c();
        childRec.AMLCTF_Audit_Case__c = testCaseRecord.Id;
        
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(childRec);
        AMLCTFActionStatementRedirectConExt cext = new AMLCTFActionStatementRedirectConExt(sc);
        PageReference pref = new PageReference('/apex/AMLCTFActionStatementNewButtonOverride');
        Test.setCurrentPage(pref);
        PageReference nextpref = cext.pageredir();
        System.assert(nextpref.getUrl().contains(cext.getActionStatementRecordId()));
        Test.stopTest();

    }

}