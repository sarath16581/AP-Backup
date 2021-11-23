/**************************************************
Type:       Test class for the RelatedListComponent class
Purpose:    Tests the Dynamic RelatedListComponent creation
       
History:
--------------------------------------------------
17.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestRelatedListComponent 
{

    static testMethod void testRelatedListCreation() 
    {
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        cs.ContactId = cont.Id;
        insert cs;
        
        InteractionViewRelatedListSettings__c setting = new InteractionViewRelatedListSettings__c();        
		setting.RelationshipName__c = 'Cases';
		setting.FieldList__c = 'Subject,CaseNumber';
		setting.ObjectName__c = 'Case';
		setting.ParentFieldName__c = 'ContactId';
		setting.Filters__c = 'Status != \'Closed – Expired\'';
		setting.LinkableField__c = 'CaseNumber';
		setting.HideButtons__c = true;
        
        Component.Apex.RelatedList rl = RelatedListComponent.getRelatedList(cont.Id, cont.Id, setting);
        System.assertEquals(setting.RelationshipName__c, rl.list);
        System.assertEquals(cont.Id, rl.subject);
        
        CaseContactSidePanelTabSettings__c setting2 = new CaseContactSidePanelTabSettings__c();        
		setting2.RelationshipName__c = 'Cases';
		setting2.FieldList__c = 'Subject,CaseNumber';
		setting2.ObjectName__c = 'Case';
		setting2.ParentFieldName__c = 'ContactId';
		setting2.Filters__c = 'Status != \'Closed – Expired\'';
		setting2.LinkableField__c = 'CaseNumber';
		setting2.HideButtons__c = true;
        
        Component.Apex.RelatedList rl2 = RelatedListComponent.getRelatedList(cont.Id, cont.Id, setting2);
        System.assertEquals(setting2.RelationshipName__c, rl2.list);
        System.assertEquals(cont.Id, rl2.subject);
    }
}