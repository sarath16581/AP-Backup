/**
 * @author alexvolkov
 * @date 5/2/20
 * @description Test class for AddressLookupWrapperController
 */

/**
--------------------------------------- History --------------------------------------------------
05.02.2020    alex.volkov@auspost.com.au    Initial creation
**/

@IsTest
private with sharing class AddressLookupWrapperTest
{
	/**
	* @description Test data setup
	*/
	@TestSetup
	static void setupData()
	{
		/** Create a person account record */
		TestDataProvider.createAndSavePersonAccount();
	}

	/**
	* @description Test getSettings method
	*/
	@IsTest
	static void testGetSettings()
	{
		/**
		* Construct a JSON interpretation of an Address_Fields_Mapping__mdt record for a standard address field
		* Need to do it this way as can't instantiate relationship fields (not writeable)
		* */
		Map<String, Object> vStandardFieldMapping = new Map<String, Object>
		{
				'attributes' => new Map<String, Object>
				{
						'type' => 'Address_Fields_Mapping__mdt'
				},
				'Standard_Address_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'BillingAddress'
				},
				'Standard_Address_Field__c' => 'BillingAddress'
		};

		/**
		* Construct a JSON interpretation of an Address_Fields_Mapping__mdt record for custom address fields
		* Need to do it this way as can't instantiate relationship fields (not writeable)
		* */
		Map<String, Object> vCustomFieldMapping = new Map<String, Object>
		{
				'attributes' => new Map<String, Object>
				{
						'type' => 'Address_Fields_Mapping__mdt'
				},
				'Postcode_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'BillingPostalCode'
				},
				'Street_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'BillingStreet'
				},
				'City_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'BillingCity'
				},
				'State_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'BillingState'
				},
				'DPID_Field__r' => new Map<String, Object>
				{
						'attributes' => new Map<String, Object>
						{
								'type' => 'FieldDefinition'
						},
						'QualifiedApiName' => 'Name'
				},
				'DPID_Field__c' => 'Name'
		};

		/**
		* Instantiate the configuration from JSON format of records
		* */
		AddressLookupWrapperController.CONFIG = new List<Address_Fields_Mapping__mdt>
		{
				(Address_Fields_Mapping__mdt)JSON.deserialize(JSON.serialize(vStandardFieldMapping), Address_Fields_Mapping__mdt.class),
				(Address_Fields_Mapping__mdt)JSON.deserialize(JSON.serialize(vCustomFieldMapping), Address_Fields_Mapping__mdt.class)
		};
		/** Get the test account */
		Account vAcc = [SELECT Id FROM Account LIMIT 1];
		Test.startTest();
		/** Assert the method result */
		System.assertEquals(vAcc.Id, AddressLookupWrapperController.getSettings(vAcc.Id).currentRecord.Id);
		Test.stopTest();
	}
}