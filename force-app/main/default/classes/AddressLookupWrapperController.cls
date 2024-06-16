/**
 * @author alexvolkov
 * @date 30/1/20
 * @description Controller for Address Lookup generic wrapper component
 */

/**
--------------------------------------- History --------------------------------------------------
30.01.2020	alex.volkov@auspost.com.au	Initial creation
25.02.2020	alex.volkov@auspost.com.au	Removed address type filtering
19.08.2020	suman.gunaganti@auspost.com.au  Added Country and Address validation fields
26.03.2021	dheeraj.mandavilli@auspost.com.au Updated the Config query to support custom object by changing Object__c
												to Object__r.QualifiedApiName
2024-06-14 - Ranjeewa Silva - Updated to support person account standard address fields. Refactored code and leveraged
							  platform cache for metadata mappings.
**/

public with sharing class AddressLookupWrapperController {

	// cache key setting names for accessing platform cache
	private static final String CACHE_KEY_ADDRESS_MAPPING_CONFIGURATION = 'ADDRESS_FIELD_MAPPING_CONFIGURATION';

	// address field mapping custom metadata. arranged into a map where SObject API name is the key for ease of access.
	// field mapping metadata is stored in platform cache for reuse later.
	@TestVisible
	private static Map<String, List<Address_Fields_Mapping__mdt>> addressFieldMappingsMetadata {
		get {
			if (addressFieldMappingsMetadata == null) {
				// check platform cache first.
				if (CacheManager.get(CACHE_KEY_ADDRESS_MAPPING_CONFIGURATION) != null) {
					// use metadata available in platform cache.
					addressFieldMappingsMetadata = (Map<String, List<Address_Fields_Mapping__mdt>>) CacheManager.get(CACHE_KEY_ADDRESS_MAPPING_CONFIGURATION);
				} else {
					// field mapping metadata not available in platform cache.
					// query metadata including fields from EntityDefinition and FieldDefinition types. once queried store
					// in platform cache for reuse.
					Map<String, List<Address_Fields_Mapping__mdt>> metadata = new Map<String, List<Address_Fields_Mapping__mdt>>();
					for (Address_Fields_Mapping__mdt record : [
							SELECT DeveloperName, Standard_Address_Field__c, Standard_Address_Field__r.QualifiedApiName,
									Street_Field__c, Street_Field__r.QualifiedApiName, State_Field__c, State_Field__r.QualifiedApiName,
									Postcode_Field__c, Postcode_Field__r.QualifiedApiName, City_Field__c, City_Field__r.QualifiedApiName,
									DPID_Field__c, DPID_Field__r.QualifiedApiName, Geolocation_Field__c, Geolocation_Field__r.QualifiedApiName,
									Address_Validated_Field__c, Address_Validated_Field__r.QualifiedApiName, Object__r.QualifiedApiName,
									PersonAccountStandardAddressField__c
							FROM Address_Fields_Mapping__mdt
					]) {
						List<Address_Fields_Mapping__mdt> addressMetadataForSobject = metadata.get(record.Object__r.QualifiedApiName);
						if (addressMetadataForSobject == null) {
							addressMetadataForSobject = new List<Address_Fields_Mapping__mdt>();
							metadata.put(record.Object__r.QualifiedApiName, addressMetadataForSobject);
						}
						addressMetadataForSobject.add(record);
					}
					addressFieldMappingsMetadata = metadata;
					// also populate platform cache so it is available later
					CacheManager.put(CACHE_KEY_ADDRESS_MAPPING_CONFIGURATION, metadata);
				}
			}
			return addressFieldMappingsMetadata;
		}
		set;
	}

	/**
	 * @description Get initial settings and record field values on load
	 * @param pRecordId ID of the target record
	 * @return FieldMapping
	 */
	@AuraEnabled
	public static FieldMapping getSettings(Id pRecordId) {
		FieldMapping result = new FieldMapping();
		if (pRecordId != null) {
			SObjectType sObjectType = pRecordId.getSobjectType();
			result.objectApiName = String.valueOf(sObjectType);

			// get field definitions map for SObjectType. we use this to derive constituent fields of the compound address
			Map<String, SObjectField> sObjectFieldsMap = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();

			// iterate through address configuration for the sobject type
			for (Address_Fields_Mapping__mdt setting: addressFieldMappingsMetadata.get(result.objectApiName)) {
				AddressComponents addressComponents = new AddressComponents();
				// if mapped to a compound address field, find relevant constituent address fields.
				// compound address fields on person account (PersonMailingAddress && PersonOtherAddress) are not selectable
				// in custom metadata setup ui (Metadata Relationship(FieldDefinition)). hence using a dedicated field 'PersonAccountStandardAddressField__c'.
				if (setting.Standard_Address_Field__c != null || setting.PersonAccountStandardAddressField__c != null) {
					String compoundAddressFieldName = (setting.Standard_Address_Field__c != null ? setting.Standard_Address_Field__r.QualifiedApiName : setting.PersonAccountStandardAddressField__c);
					// currently only support standard compound address fields only. custom compound address fields are
					// not enabled in the org yet (https://developer.salesforce.com/docs/atlas.en-us.250.0.caf_dev_guide.meta/caf_dev_guide/caf_dev_guide.htm).
					// to be extended in future to support custom address fields when the feature is enabled.
					if (compoundAddressFieldName.endsWithIgnoreCase('Address')) {
						// this is a standard address field. standard address fields follow the naming as documented here:
						// https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/compound_fields_address.htm
						// we rely on this to identify constituent fields.
						String compoundAddressFieldPrefix = compoundAddressFieldName.removeEndIgnoreCase('Address');
						addressComponents.Street = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'Street')?.toString();
						addressComponents.City = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'City')?.toString();
						addressComponents.PostCode = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'PostalCode')?.toString();
						addressComponents.State = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'State')?.toString();
						addressComponents.Latitude = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'Latitude')?.toString();
						addressComponents.Longitude = getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'Longitude')?.toString();
						addressComponents.Country =  getConstituentCompoundAddressField(sObjectFieldsMap, compoundAddressFieldName, compoundAddressFieldPrefix + 'Country')?.toString();
					}
				} else {
					// each component is mapped to individual custom fields (street, state etc).
					addressComponents.PostCode = setting.Postcode_Field__r.QualifiedApiName;
					addressComponents.Street = setting.Street_Field__r.QualifiedApiName;
					addressComponents.City = setting.City_Field__r.QualifiedApiName;
					addressComponents.State = setting.State_Field__r.QualifiedApiName;
					// if a Geolocation field mapped, get the components
					if (setting.Geolocation_Field__c != null) {
						String lGeoFieldName = setting.Geolocation_Field__r.QualifiedApiName.substring(0, setting.Geolocation_Field__r.QualifiedApiName.length() - 3);
						addressComponents.Latitude =  lGeoFieldName + '__Latitude__s';
						addressComponents.Longitude = lGeoFieldName + '__Longitude__s';
					}
				}

				// include any mapped DPID fields
				if (setting.DPID_Field__c != null) {
					addressComponents.DPID = setting.DPID_Field__r.QualifiedApiName;
				}

				// added if address validated field is mapped
				if (setting.Address_Validated_Field__c != null) {
					addressComponents.AddressValidated = setting.Address_Validated_Field__r.QualifiedApiName;
				}
				result.settings.put(setting.DeveloperName, addressComponents);
			}

			if (!result.settings.isEmpty()) {
				// query record including all relevant address fields
				result.currentRecord = selectAddressFieldsOnRecord(pRecordId, result.objectApiName, result.settings.values());
			}
		}
		return result;
	}

	/**
	 * Get the specified constituent field of the compound address field. SObjectField is returned to ensure the validity
	 * of the specified constituent field.
	 *
	 * @param sobjectFieldsMap SObjectFields for this SObject
	 * @param compoundAddressFieldName Name of compound address field
	 * @param constituentFieldName Name of constituent field
	 *
	 * @return SObjectField
	 */
	private static SObjectField getConstituentCompoundAddressField(Map<String, SObjectField> sobjectFieldsMap, String compoundAddressFieldName, String constituentFieldName) {
		if (sobjectFieldsMap.containsKey(compoundAddressFieldName)) {
			return sobjectFieldsMap.get(constituentFieldName);
		}
		return null;
	}

	/**
	 * Query specified record selecting all relevant address fields
	 *
	 * @param recordId Id of the record to query
	 * @param sObjectApiName SObject to query
	 * @param addressComponents list of address components
	 *
	 * @return Queried record.
	 */
	private static SObject selectAddressFieldsOnRecord(Id recordId, String sObjectApiName, List<AddressComponents> addressComponents) {
		Set<String> addressFields = new Set<String>();
		for (AddressComponents addressComponent: addressComponents) {
			addressFields.addAll(addressComponent.getFieldNames());
		}

		return Database.query('SELECT Id,' + String.join(new List<String>(addressFields), ',') + ' FROM ' + sObjectApiName + ' WHERE Id = :recordId');
	}

	/**
	* The return object - all field mappings and current record values
	*/
	public class FieldMapping {
		@AuraEnabled
		public String objectApiName{get; set;}
		@AuraEnabled
		public SObject currentRecord{get; set;}
		@AuraEnabled
		public Map<String, AddressComponents> settings{get; set;}

		public FieldMapping() {
			this.settings = new Map<String, AddressComponents>();
		}
	}

	/**
	* Components making up the address
	* */
	public class AddressComponents {
		@AuraEnabled
		public String Street;
		@AuraEnabled
		public String City;
		@AuraEnabled
		public String PostCode;
		@AuraEnabled
		public String State;
		@AuraEnabled
		public String Latitude;
		@AuraEnabled
		public String Longitude;
		@AuraEnabled
		public String DPID;
		@AuraEnabled
		public String Country;
		@AuraEnabled
		public String AddressValidated;

		private Set<String> getFieldNames() {
			Set<String> result = new Set<String>{this.Street, this.City, this.PostCode, this.State, this.Latitude, this.Longitude, this.DPID, this.Country, this.AddressValidated};
			result.remove(null);
			return result;
		}
	}
}