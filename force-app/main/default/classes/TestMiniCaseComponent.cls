@isTest
private class TestMiniCaseComponent {
//    static testMethod void testContactId(){
//        // if you pass in a person account id it should return the contact id.
//        // or else it should be the contact id.
//
//        MiniCaseComponentController controller = new MiniCaseComponentController();
//        system.debug(controller.contactId == '');
//
//        controller.contactId = null;
//        system.debug(controller.contactId == '');
//
//        controller.contactId = 'Houdini-G';
//        system.debug(controller.contactId == '');
//
//        Account a = TestDataProvider.createAndSavePersonAccount('Bob the builder', Constants.RECORDTYPE_NAME_ACCOUNT_UNVERIFIED);
//        controller.contactId = a.id;
//        a = [select personContactId from account where id = :a.id limit 1];
//        system.assert(controller.contactId == a.personContactId);
//
//        Account bizAccount = TestDataProvider.createAndSaveBusinessAccount('Business Bob the builder', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
//        Contact nContact = TestDataProvider.createContact('Bob the builder', bizAccount.id, null);
//        insert nContact;
//        controller.contactId = nContact.Id;
//        system.assert(controller.contactId == nContact.id);
//    }
//
//    static testMethod void testLoadComponent() {
//        // Need to insert custom settings with key values set for a test component.
//        // assert if the right component is showing up.
//
//        string variableKeys = '{"HoudiniG_is_Bob_the_builder":"Yeah Baby!"}';
//        SSSWAssistancePanelFilter__c filter = SSSWAssistancePanelFilter__c.getValues('HoudiniG_is_Bob_the_builder');
//        if(filter == null){
//            filter = new SSSWAssistancePanelFilter__c();
//            filter.name = 'HoudiniG_is_Bob_the_builder';
//            insert filter;
//        }
//
//        filter.CommaSeparatedFields__c = variableKeys;
//        filter.ComponentName__c = 'HoudiniG_is_Bob_the_builder';
//        update filter;
//
//        MiniCaseComponentController controller = new MiniCaseComponentController();
//        controller.variableKeys = variableKeys;
//        controller.LoadRelatedData();
//        system.assert(controller.componentName == 'HoudiniG_is_Bob_the_builder');
//
//        filter.ComponentName__c = 'SAPFiltersComponent';
//        update filter;
//        controller.LoadRelatedData();
//        system.assert(controller.componentName == 'SAPFiltersComponent');
//
//        filter.ComponentName__c = 'MRSFiltersComponent';
//        update filter;
//        controller.LoadRelatedData();
//        system.assert(controller.componentName == 'MRSFiltersComponent');
//    }
//
//    static testMethod void testCreateCase() {
//        // if you passing a ref id that already exist in a case it should load up an existing case.
//        // or else it will create a new case.
//
//        // variations:
//        // 1. If it loads up an existing case then all the data entered on the MiniCase should be stored as comments.
//        // 2. If it created a new case, then all the values should be set to the newly created case.
//
//        test.startTest();
//        string variableKeys = '';
//        string caseID = MiniCaseComponentController.createCase(variableKeys, true, '');
//        system.assert(caseID == '');
//
//        variableKeys = '{"ReferenceID__c":"BobTheBuilder","Subject":"HoudiniGIsTheBest"}';
//        caseID = MiniCaseComponentController.createCase(variableKeys, false, '');
//        Case c;
//        for(Case theCase : [select ReferenceID__c from Case where ReferenceID__c = 'BobTheBuilder' limit 1]) {
//        	c = theCase;
//        }
//        if(c != null) {
//        	system.assert(c.id == caseID);
//        	List<CaseComment> comments = [select id from CaseComment where parentId =:c.id];
//        	system.assert(comments.size() == 0);
//        	caseID = MiniCaseComponentController.createCase(variableKeys, false, '');
//	        comments = [select id from CaseComment where parentId =:c.id];
//	        system.assert(comments.size() == 1);
//        }
//
//        variableKeys = '{"ReferenceID__c":"BobTheBuilderXXXXException"}';
//        caseID = MiniCaseComponentController.createCase(variableKeys, false, '');
//        system.assert(caseId.startsWith('Error:'));
//        test.stopTest();
//    }
    
    
}