/**
* @description Test class covering CaseRecordPopulationModule
* @changelog
* 2024-08-23	George Nguyen	Created 
*/
@IsTest
class CaseRecordPopulationModule_Test {
    
	@IsTest
	static void mappedFields() {
		System.assertEquals(ContactRequest.WhatId, CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(ContactRequest.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(VoiceCall.RelatedRecordId, CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(VoiceCall.SobjectType), 'It should return the correct field mapping');

		System.assertEquals(ContactRequest.Case__c, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(ContactRequest.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(VoiceCall.Case__c, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(VoiceCall.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(LiveChatTranscript.CaseId, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(LiveChatTranscript.SobjectType), 'It should return the correct field mapping');
	}
}