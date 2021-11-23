/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 
  * @description  : UTIL Test Class 
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    05/09/2016          eric.shen@auspost.com.au             add test code for parsetext method
    2021-08-24          Seth Heang                           Uplift SF API Version to 52
*******************************  History ************************************************/  
@isTest
private class Util_Test {

    static testMethod void testcleanPhoneString() {
        Util.cleanPhoneString('12ajh3sg4sd5');
        Util.cleanPhoneString('12ajh3sg4sd5678901231312121');
    }
    
    static testMethod void testsearchablePhoneString() {
        system.assert('%1%2%3%4%5' == Util.searchablePhoneString('12ajh3sg4sd5'));
    }
    
    static testMethod void testcontactIDForNameAndEmail() {
        Contact contact1 = new Contact();
        contact1.LastName = 'test last name';
        contact1.FirstName = 'test first name';
        contact1.MailingAddress__c = 'test address';
        contact1.MailingCity = 'test city';
        contact1.Email = 'TestUniqueEmail@test.com';
        insert contact1;
        Util.contactIDForNameAndEmail('name', 'TestUniqueEmail@test.com');
    } 
    
    static testMethod void testCommon() {
        Contact contact1 = new Contact();
        contact1.LastName = 'test last name';
        contact1.FirstName = 'test first name';
        contact1.MailingAddress__c = 'test address';
        contact1.MailingCity = 'test city';
        contact1.Email = 'TestUniqueEmail@test.com';
        insert contact1;
        Util.createAttachment('test attachment', 'ajgskdjgausgdhagsud', 'image', contact1.Id);
        util.replacePlaceholders(contact1, 'test');
        util.getRecordTypesNameById('Account');
        util.getRecordTypesDevNameById('Account');
        util.getRecordTypesByDeveloperName('Account');
        util.getCreatableFieldsSOQL('Account', ' Id != null');
        util.replaceMergeFields(contact1, '{!Contact.LastName}');
        Network__c x = new Network__c();
        insert x;
        util.getBodyFromEmailTemplate('PushEDM', contact1.Id, x.Id);
    }
}