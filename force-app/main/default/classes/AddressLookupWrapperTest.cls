/**
 * @author alexvolkov
 * @date 5/2/20
 * @description Test class for AddressLookupWrapperController
 */

/**
--------------------------------------- History --------------------------------------------------
2020-02-05	alex.volkov@auspost.com.au	Initial creation
2024-06-14 - Ranjeewa Silva - Refactored and added test to cover field mapping for person address fields on account.
**/

@IsTest
private with sharing class AddressLookupWrapperTest {

	/**
	 * Test to ensure address field mapping is returned when mapped to a standard compound address field.
	 */
	@IsTest
	static void testGetSettingsStandardAddressFields() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		injectMockAddressMetadataConfiguration();

		Account organisation = ApplicationTestDataFactory.getAccounts(1, false)[0];
		organisation.BillingStreet = '100 abc street';
		organisation.BillingCity = 'Melbourne';
		organisation.BillingState = 'VIC';
		organisation.BillingPostalCode = '3000';
		organisation.BillingCountry = 'AU';

		Database.insert(organisation);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
			AddressLookupWrapperController.FieldMapping result = AddressLookupWrapperController.getSettings(organisation.Id);
			Assert.isNotNull(result, 'Expected a valid field mapping but got null.');
			Assert.areEqual('Account', result.objectApiName, 'Expected the object API name of the supplied record id (Account) to be returned, bur received ' + result.objectApiName);
			Assert.areEqual(organisation.Id, result.currentRecord.Id, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(organisation.BillingStreet, ((Account)result.currentRecord).BillingStreet, 'Address field not populated on the returned record.');
			Assert.areEqual(organisation.BillingCity, ((Account)result.currentRecord).BillingCity, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(organisation.BillingState, ((Account)result.currentRecord).BillingState, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(organisation.BillingPostalCode, ((Account)result.currentRecord).BillingPostalCode, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(organisation.BillingCountry, ((Account)result.currentRecord).BillingCountry, 'Record with the specified id must be returned in the result.');
			Assert.isFalse(result.settings.isEmpty(), 'Address field mapping is not returned in the result.');
		Test.stopTest();
	}

	/**
	 * Test to ensure address field mapping is returned when mapped to individual custom fields.
	 */
	@IsTest
	static void testGetSettingsAddressCustomFields() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		injectMockAddressMetadataConfiguration();

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;

		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert contact;

		Case caseRecord = ApplicationTestDataFactory.getCases(3, new List<Id>{contact.Id, contact.Id, contact.Id}, false)[0];
		caseRecord.ReferenceID__c = '12345';
		caseRecord.Type = 'General Enquiry';
		caseRecord.Address1Line1__c = '100 abc street';
		caseRecord.Address1Suburb__c = 'Melbourne';
		caseRecord.Address1State__c = 'VIC';
		caseRecord.Address1Postcode__c = '3000';
		caseRecord.Address1Country__c = 'AU';
		insert caseRecord;

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
			AddressLookupWrapperController.FieldMapping result = AddressLookupWrapperController.getSettings(caseRecord.Id);
			Assert.isNotNull(result, 'Expected a valid field mapping but got null.');
			Assert.areEqual('Case', result.objectApiName, 'Expected the object API name of the supplied record id (Account) to be returned, bur received ' + result.objectApiName);
			Assert.areEqual(caseRecord.Id, result.currentRecord.Id, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(caseRecord.Address1Line1__c, ((Case)result.currentRecord).Address1Line1__c, 'Address field not populated on the returned record.');
			Assert.areEqual(caseRecord.Address1Suburb__c, ((Case)result.currentRecord).Address1Suburb__c, 'Address field not populated on the returned record.');
			Assert.areEqual(caseRecord.Address1State__c, ((Case)result.currentRecord).Address1State__c, 'Address field not populated on the returned record.');
			Assert.areEqual(caseRecord.Address1Postcode__c, ((Case)result.currentRecord).Address1Postcode__c, 'Address field not populated on the returned record.');
			Assert.isFalse(result.settings.isEmpty(), 'Address field mapping is not returned in the result.');
		Test.stopTest();
	}

	/**
	 * Test to ensure address field mapping is returned when mapped to a person account standard compound address field.
	 */
	@IsTest
	static void testGetSettingsPersonAccountStandardAddressFields() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		injectMockAddressMetadataConfiguration();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, false)[0];
		personAccount.PersonMailingStreet = '999 test street';
		personAccount.PersonMailingCity = 'Melbourne';
		personAccount.PersonMailingState = 'VIC';
		personAccount.PersonMailingPostalCode = '3000';
		personAccount.PersonMailingCountry = 'AU';

		Database.insert(personAccount);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
			AddressLookupWrapperController.FieldMapping result = AddressLookupWrapperController.getSettings(personAccount.Id);
			Assert.isNotNull(result, 'Expected a valid field mapping but got null.');
			Assert.areEqual('Account', result.objectApiName, 'Expected the object API name of the supplied record id (Account) to be returned, bur received ' + result.objectApiName);
			Assert.areEqual(personAccount.Id, result.currentRecord.Id, 'Record with the specified id must be returned in the result.');
			Assert.areEqual(personAccount.PersonMailingStreet, ((Account)result.currentRecord).PersonMailingStreet, 'Address field not populated on the returned record.');
			Assert.areEqual(personAccount.PersonMailingCity, ((Account)result.currentRecord).PersonMailingCity, 'Address field not populated on the returned record.');
			Assert.areEqual(personAccount.PersonMailingState, ((Account)result.currentRecord).PersonMailingState, 'Address field not populated on the returned record.');
			Assert.areEqual(personAccount.PersonMailingPostalCode, ((Account)result.currentRecord).PersonMailingPostalCode, 'Address field not populated on the returned record.');
			Assert.areEqual(personAccount.PersonMailingCountry, ((Account)result.currentRecord).PersonMailingCountry, 'Address field not populated on the returned record.');
			Assert.isFalse(result.settings.isEmpty(), 'Address field mapping is not returned in the result.');
		Test.stopTest();
	}

	/**
	 * Simple test to ensure address metadata is loaded in controller. Note that bulk of the logic is tested in other tests.
	 */
	@IsTest
	static void testLoadCustomMetadata() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		Map<String, List<Address_Fields_Mapping__mdt>> metadata = AddressLookupWrapperController.addressFieldMappingsMetadata;
		Assert.isNotNull(metadata, 'Expected a valid field mapping but got null.');
		Assert.isFalse(metadata.isEmpty(), 'Expected a valid field mapping but got no records.');
		Test.stopTest();
	}

	/**
	 * Setup mock metadata records in controller. Allows to test all scenarios independent of current metadata
	 * configuration in org.
	 */
	private static void injectMockAddressMetadataConfiguration() {

		// construct JSON interpretation of an Address_Fields_Mapping__mdt record for address custom fields
		// this approach is used so we can instantiate FieldDefinition instances.
		Map<String, Object> caseSenderAddressFieldMapping = new Map<String, Object>{
				'attributes' => new Map<String, Object>{'type' => 'Address_Fields_Mapping__mdt'},
				'Postcode_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'Address1Postcode__c'
				},
				'Street_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'Address1Line1__c'
				},
				'City_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'Address1Suburb__c'
				},
				'State_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'Address1State__c'
				},
				'DPID_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'Address1DPID__c'
				},
				'DPID_Field__c' => 'Address1DPID__c',
				'DeveloperName' => 'CaseSenderAddress'
		};

		// construct JSON interpretation of an Address_Fields_Mapping__mdt record for standard address fields on Account.
		// this approach is used so we can instantiate FieldDefinition instances.
		Map<String, Object> accountBillingAddressFieldMapping = new Map<String, Object>{
				'attributes' => new Map<String, Object>{'type' => 'Address_Fields_Mapping__mdt'},
				'Standard_Address_Field__r' => new Map<String, Object>{
						'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},
						'QualifiedApiName' => 'BillingAddress'
				},
				'Standard_Address_Field__c' => 'BillingAddress',
				'DeveloperName' => 'AccountBillingAddress'
		};

		// construct JSON interpretation of an Address_Fields_Mapping__mdt record for standard address fields on Account.
		Map<String, Object> accountPersonMailingAddressFieldMapping = new Map<String, Object>{
				'attributes' => new Map<String, Object>{'type' => 'Address_Fields_Mapping__mdt'},
				'PersonAccountStandardAddressField__c' => 'PersonMailingAddress',
				'DeveloperName' => 'AccountPersonMailingAddress'
		};

		AddressLookupWrapperController.addressFieldMappingsMetadata = new Map<String, List<Address_Fields_Mapping__mdt>>{
				'Account' => new List<Address_Fields_Mapping__mdt>{
						(Address_Fields_Mapping__mdt) JSON.deserialize(JSON.serialize(accountBillingAddressFieldMapping), Address_Fields_Mapping__mdt.class),
						(Address_Fields_Mapping__mdt) JSON.deserialize(JSON.serialize(accountPersonMailingAddressFieldMapping), Address_Fields_Mapping__mdt.class)
				},
				'Case' => new List<Address_Fields_Mapping__mdt>{
						(Address_Fields_Mapping__mdt) JSON.deserialize(JSON.serialize(caseSenderAddressFieldMapping), Address_Fields_Mapping__mdt.class)
				}
		};
	}
}