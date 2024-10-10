/**
 * @description Constant definitions for Genesys related logic
 * NOTE: Contains Field Mappings for synchronising SF VoiceCall => Genesys Call Interaction
 * @author Paul Perry
 * @date 2024-08-28
 * @group SCV/Unified
 * @changelog
 * 2024-08-28 - Paul Perry - created
 */
public with sharing class GenesysConstants {
	public static final String VOICE_CALL_OUTBOUND_CALL_TYPE = 'Outbound';
	public static final String VOICE_CALL_INBOUND_CALL_TYPE = 'Inbound';
	public static final String VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY = 'General Enquiry';
	public static final String VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION = 'Investigation';
	/**
	 * Mappings from Salesforce VoiceCall fields => Genesys Custom Attribute names
	 */
	public final static Map<SObjectField,String> genesysFieldMappings {
		get {
			if (genesysFieldMappings == null) {
				genesysFieldMappings = new Map<SObjectField,String>{
					VoiceCall.TrackingNumber__c => 'Tracking_Number',
					VoiceCall.ProductCategory__c => 'Product_Category',
					VoiceCall.ProductSubCategory__c => 'Product_Sub_Category',
					VoiceCall.EnquiryType__c => 'Enquiry_Type',
					VoiceCall.EnquirySubType__c => 'Enquiry_Sub_Type',
					VoiceCall.Case__c => 'CaseId',
					VoiceCall.Contact__c => 'ContactId',
					VoiceCall.RootCause__c => 'Root_Cause',
					VoiceCall.Outcome__c => 'Outcome'
				};
			}

			return genesysFieldMappings;
		}
		set;
	}
	/**
	 * Mappings from Salesforce VoiceCall fields => related VoiceCall fields
	 */
	public final static Map<SObjectField,String> voiceCallFieldMappings {
		get {
			if (voiceCallFieldMappings == null) {
				voiceCallFieldMappings = new Map<SObjectField,String>{
						VoiceCall.TrackingNumber__c => 'Tracking_Number',
						VoiceCall.ProductCategory__c => 'Product_Category',
						VoiceCall.ProductSubCategory__c => 'Product_Sub_Category',
						VoiceCall.EnquiryType__c => 'Unified_Enquiry_Type',
						VoiceCall.EnquirySubType__c => 'Unified_Enquiry_Sub_Type',
						VoiceCall.RelatedRecordId => 'RelatedRecordId',
						VoiceCall.Contact__c => 'ContactId',
						VoiceCall.Consignment__c => 'Tracking_Number',
						VoiceCall.Case__c => 'CaseId',
						VoiceCall.RootCause__c => 'Root_Cause',
						VoiceCall.Outcome__c => 'Outcome',
						VoiceCall.CustomerParticipantId__c => 'CustomerParticipantId'
				};
			}

			return voiceCallFieldMappings;
		}
		set;
	}

	/**
	 * Mappings from Salesforce VoiceCall fields => related Case fields
	 */
	public final static Map<SObjectField,SObjectField> voiceCallCaseFieldMappings {
		get {
			if (voiceCallCaseFieldMappings == null) {
				voiceCallCaseFieldMappings = new Map<SObjectField,SObjectField>{
						Case.ProductCategory__c => VoiceCall.ProductCategory__c,
						Case.ProductSubCategory__c => VoiceCall.ProductSubCategory__c,
						Case.EnquirySubType__c => VoiceCall.EnquirySubType__c,
						Case.Type => VoiceCall.EnquiryType__c
				};
			}

			return voiceCallCaseFieldMappings;
		}
		set;
	}
}