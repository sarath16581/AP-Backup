/**************************************************
Type:       Test class for the ContactInteractionViewComponentCont class
Purpose:    Tests interaction view controller logic
       
History:
--------------------------------------------------
23.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestContactInteractionViewCompCont 
{

    static testMethod void testWithContact() 
    {
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        cs.ContactId = cont.Id;
        insert cs;
        
        setupCustSetting();
        
        Test.startTest();
        
        ContactInteractionViewComponentCont contr = new ContactInteractionViewComponentCont();
        contr.recId = cont.Id;
        
        System.assertEquals(cont.Id, contr.contId);
        System.assert(!contr.isPersonAccount); 
        
        Component.Apex.OutputPanel op = contr.getRelatedLists();
        System.assert(!op.childComponents.isEmpty());
        
        Test.stopTest();
    }
    
    static testMethod void testWithPersonAccount() 
    {
    	Account acc = TestDataProvider.createAndSavePersonAccount('PersAcc', Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        Id personContId = [SELECT PersonContactId FROM Account WHERE Id = :acc.Id].PersonContactId;
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        cs.ContactId = personContId;
        insert cs;
        
        setupCustSetting();
        
        Test.startTest();
        
        ContactInteractionViewComponentCont contr = new ContactInteractionViewComponentCont();
        contr.recId = acc.Id;
        
        System.assertEquals(personContId, contr.contId);
        System.assert(contr.isPersonAccount); 
        
        Component.Apex.OutputPanel op = contr.getRelatedLists();
        System.assert(!op.childComponents.isEmpty());
        
        Test.stopTest();
    }
    
    static void setupCustSetting()
    {
    	InteractionViewRelatedListSettings__c setting = new InteractionViewRelatedListSettings__c();  
        setting.Name = 'test123';      
		setting.RelationshipName__c = 'Cases';
		setting.FieldList__c = 'Subject,CaseNumber';
		setting.ObjectName__c = 'Case';
		setting.ParentFieldName__c = 'ContactId';
		setting.Filters__c = 'Status != \'Closed – Expired\'';
		setting.LinkableField__c = 'CaseNumber';
		setting.HideButtons__c = true;
		setting.DisplayOrder__c = 0;
		insert setting;
    }
}