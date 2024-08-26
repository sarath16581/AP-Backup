/**
 * @description Test Class covering VoiceCallTrigger
 * @changelog
 * 2024-08-21	George Nguyen	Created
 */
@IsTest
class VoiceCallTrigger_Test {
    
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

		insert new VoiceCall(
			initiationMethod = 'Inbound',
			RelatedRecordId = case1.id,
			FromPhoneNumber = '23432423423',
			Description = 'test call',
			VendorCallKey = '8f441452-eb7d-4142-8ae6-5b3f4a44f7d0',
			VendorType = '', 
			callCenterApiName = 'MyContactCenter'
		);
	}
}