/**
 * @description Test Class covering ContactRequestTrigger
 * @changelog
 * 2024-08-21	George Nguyen	Created
 */
@IsTest
class ContactRequestTrigger_Test {
	@IsTest
	static void handler() {
		Contact con = TestDataProvider.createTestContact();
        insert con;
        
	    Case case1 = new Case(
        	RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id,
			Type = 'Feedback',
			Subject = 'Newsdd',
			Status = 'New',
			ProductCategory__c = 'Travel & ID',
			EnquirySubType__c = 'Product Support',
			ProductSubCategory__c = 'KeyPass',
			ContactId = con.Id,
			ReferenceID__c = '123'
		);
        insert case1;

		ContactRequest cr = new ContactRequest(
			WhoId = con.Id,
			WhatId = case1.id,
			RequestDescription = 'test call'
		);

		insert cr;

		cr = [SELECT Case__c FROM ContactRequest WHERE Id =: cr.Id LIMIT 1];
		System.assertEquals(case1.Id, cr.Case__c, 'Case look up Id should match');
	}
}