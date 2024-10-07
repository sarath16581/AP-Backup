/*
 * @changelog
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
 * 2024-06-13	Parveen Kaushik Added default value for mapping model on test data. See CSLU-470 (JIRA) for details.
*/
@isTest(seealldata=true)
private class CTI_Test {
    
    static testMethod void testCTIScreenPopController() {
        Id profileId = [SELECT ID FROM PROFILE WHERE NAME = 'System Administrator'].ID;
        User u = [SELECT Id FROM User WHERE IsPortalEnabled = false and ProfileId = :profileId AND IsActive = true LIMIT 1];
        test.starttest();
        system.runas(u){
            CTIScreenPopController instance = new CTIScreenPopController();
            CTIScreenPopController.getToken(true);
        }
        test.stoptest();
    }
    
    static testMethod void testCTIScreenPopController_bak() {
        Id profileId = [SELECT ID FROM PROFILE WHERE NAME = 'System Administrator'].ID;
        User u = [SELECT Id FROM User WHERE IsPortalEnabled = false and ProfileId = :profileId AND IsActive = true LIMIT 1];
        test.starttest();
        system.runas(u){
            CTIScreenPopController_bak instance2 = new CTIScreenPopController_bak();
            CTIScreenPopController_bak.getToken(true);
        }
        test.stoptest();
    }
    
    static testMethod void testCTIScreenPopController2() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.ContactId = contact.Id;
        c.ReferenceID__c = 'testId';
        insert c;
        test.startTest();
        CTIScreenPopController.getContactByPhone('718273672');
        CTIScreenPopController.getCaseByArticleId('testId');
        CTIScreenPopController.getCaseOrContact(null, '718273672');
        test.stopTest();
    }
    
    static testMethod void testCTIScreenPopController_bak2() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.ContactId = contact.Id;
        c.ReferenceID__c = 'testId';
        insert c;
        test.startTest();
        CTIScreenPopController_bak.getContactByPhone('718273672');
        CTIScreenPopController_bak.getCaseByArticleId('testId');
        CTIScreenPopController_bak.getCaseOrContact(null, '718273672');
        test.stopTest();
        
    }
    
    static testMethod void testCTIScreenPopController3() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com', 
                                  MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.AccountId = acc.Id;
        c.ContactId = contact.Id;
        insert c;
        
        CTIScreenPopController.createActivity(c.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
        CTIScreenPopController.createActivity(contact.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
        CTIScreenPopController.createActivity(acc.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
    }
    
    static testMethod void testCTIScreenPopController_bak3() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com', 
                                  MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.AccountId = acc.Id;
        c.ContactId = contact.Id;
        insert c;
        
        CTIScreenPopController_bak.createActivity(c.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
        CTIScreenPopController_bak.createActivity(contact.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
        CTIScreenPopController_bak.createActivity(acc.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', '718273672');
    }

    static testMethod void testCTIListnerController() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com', 
                                  MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.AccountId = acc.Id;
        c.ContactId = contact.Id;
        insert c;
        
        c = [select id, casenumber from case where id =: c.Id];
        
        MiniCaseFieldMapping__c mcfm = new MiniCaseFieldMapping__c();
        mcfm.ProductCategory__c = 'test pc';
        mcfm.ProductSubcategory__c = 'test psc';
        mcfm.Type__c = 'Feedback';
		mcfm.MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL;
        insert mcfm;
        
        CTIListenerController instance = new CTIListenerController();
        CTIListenerController.CTIDefaultValue testdv = new CTIListenerController.CTIDefaultValue();
        CTIListenerController.CTIDefaultValue testdv2 = new CTIListenerController.CTIDefaultValue(mcfm);
        
        String fieldSet = instance.CTIFieldSetFieldPaths;
        
        CTIListenerController.getRecordTypeId('{"Subject": "test subject"}');
        
        CTIListenerController.defaultValues('test', 'cti');
        CTIListenerController.createCustomActivity(null,c.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','test','test','test','test','test','test');
        CTIListenerController.createCustomActivity(acc.Id,contact.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','test','test','test','test','test','test');
        CTIListenerController.createCustomActivity(c.Id,acc.Id, 'subject', 'description', 'outcome', 'duration', 1000, acc.Id, '718273672', null, 'serviceType', 'test', null,'Inbound','test','test','test','test','test','test');
        
        CTIListenerController.loadCaseOrContact(c.CaseNumber, '718273672');
        CTIListenerController.setWorkspaceConnectorInfo(c.Id, null);
        CTIListenerController.retrieveWorkspaceConnectorInfo(null);
        CTIListenerController.findCaseFromNumber(c.CaseNumber);
        CTIListenerController.findObjectFromANI('718273672');
        CTIListenerController.findContactFromANI('718273672');
        CTIListenerController.findContactFromEmailAddress('test@test.com');
        CTIListenerController.findContactFromChatAddress('test');
        CTIListenerController.findContactFromWorkItemAddress('test');
        CTIListenerController.findContactFromOpenMediaAddress('test');
        
        Test.startTest();
            CTIListenerController.lookupByPhone('718273672');
        Test.stopTest();
        
    }
    
    
    static testMethod void testCTIListnerController2() {
        Contact contact = new Contact(FirstName = 'test', LastName = 'test', Phone = '718273672', Email = 'test@test.com', MailingCity = 'test city');
        insert contact;
        
        Account acc = new Account(FirstName = 'test acc', LastName = 'test acc', Phone = '718273672', Email__c = 'test@test.com', 
                                  MailingAddress__pc = 'add', PersonEmail = 'test@test.com');
        insert acc;
        
        Case c = new Case(subject = 'test subject', type = 'Fax', referenceId__c = 'SSSWCase', Phone__c = '718273672');
        c.AccountId = acc.Id;
        c.ContactId = contact.Id;
        insert c;
        
        c = [select id, casenumber from case where id =: c.Id];
        
        MiniCaseFieldMapping__c mcfm = new MiniCaseFieldMapping__c();
        mcfm.ProductCategory__c = 'test pc';
        mcfm.ProductSubcategory__c = 'test psc';
        mcfm.Type__c = 'Feedback';
		mcfm.MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL;
        insert mcfm;
        
        CTIListenerController instance = new CTIListenerController();
        CTIListenerController.CTIDefaultValue testdv = new CTIListenerController.CTIDefaultValue();
        CTIListenerController.CTIDefaultValue testdv2 = new CTIListenerController.CTIDefaultValue(mcfm);
        
        String fieldSet = instance.CTIFieldSetFieldPaths;
        
       
        
        Map<String,String> activityMap = new Map<String,String>();
        activityMap.put('ANI', 'ANI');
        activityMap.put('LOOKUP', 'LOOKUP');
        activityMap.put('Call Duration', '12020591728');
        activityMap.put('IXN Type', 'Email');
        activityMap.put('Media Type', 'Media Type');
        activityMap.put('Comments', 'Comments');
        activityMap.put('Disposition', 'Disposition');
        activityMap.put('GenesysId', 'GenesysId');
        activityMap.put('DATE', '2014-06-12');
        activityMap.put('SFDC1field', 'Subject');
        activityMap.put('SFDC1value', 'test');
        activityMap.put('SFDC2field', 'type');
        activityMap.put('SFDC2value', 'call');
        activityMap.put('SFDC3field', 'Status');
        activityMap.put('SFDC3value', 'Completed');
        activityMap.put('SFDC4field', 'Description');
        activityMap.put('SFDC4value', 'Comments');
        activityMap.put('SFDC5field', 'CallDisposition');
        activityMap.put('SFDC5value', 'Disposition');
        CTIListenerController.createActivity(activityMap);
        
        activityMap.put('IXN Type', 'Chat');
        CTIListenerController.createActivity(activityMap);
        
        activityMap.put('IXN Type', 'InteractionWorkItem');
        CTIListenerController.createActivity(activityMap);
        
        activityMap.put('IXN Type', 'OpenMedia');
        CTIListenerController.createActivity(activityMap);
        
        activityMap.put('sfdc Object Id', contact.Id);
        Test.startTest();
            CTIListenerController.createActivity(activityMap);
        Test.stopTest();
        
    }
}