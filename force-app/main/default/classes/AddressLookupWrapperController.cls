/**
 * @author alexvolkov
 * @date 30/1/20
 * @description Controller for Address Lookup generic wrapper component
 */

/**
--------------------------------------- History --------------------------------------------------
30.01.2020    alex.volkov@auspost.com.au    Initial creation
25.02.2020    alex.volkov@auspost.com.au    Removed address type filtering
19.08.2020    suman.gunaganti@auspost.com.au  Added Country and Address validation fields
26.03.2021    dheeraj.mandavilli@auspost.com.au Updated the Config query to support custom object by changing Object__c
                                                to Object__r.QualifiedApiName
**/

public with sharing class AddressLookupWrapperController
{

	/**
 	* @description Singleton returning configuration metadata for the object
 	* Placed in a separate variable and populated by an explicit call for test coverage purposes (need to set the config from tests)
 	*/
	@TestVisible
	private static List<Address_Fields_Mapping__mdt> CONFIG{get; private set;}

	private static void getConfig(String pObjectApiName)
	{
		if (CONFIG == null)
		{
			CONFIG = [SELECT DeveloperName, 
							Standard_Address_Field__c, 
							Standard_Address_Field__r.QualifiedApiName, 
							Street_Field__c, 
							Street_Field__r.QualifiedApiName, 
							State_Field__c, 
							State_Field__r.QualifiedApiName, 
							Postcode_Field__c, 
							Postcode_Field__r.QualifiedApiName, 
							City_Field__c, 
							City_Field__r.QualifiedApiName, 
							DPID_Field__c, 
							DPID_Field__r.QualifiedApiName, 
							Geolocation_Field__c, 
							Geolocation_Field__r.QualifiedApiName,
							Address_Validated_Field__c,
							Address_Validated_Field__r.QualifiedApiName
					 FROM Address_Fields_Mapping__mdt WHERE Object__r.QualifiedApiName = :pObjectApiName];
		}
		system.debug('Object at Top:::'+pObjectApiName);
		system.debug('CONFIG at Top:::'+CONFIG);
	}


	/**
	 * @description Get initial settings and record field values on load
	 * @param pRecordId ID of the target record
	 * @return FieldMapping
	 */
	@AuraEnabled
	public static FieldMapping getSettings(Id pRecordId)
	{
		FieldMapping vRes = new FieldMapping();
		if (pRecordId != null)
		{
			/** Get Object Type and API Name from Record ID */
			Schema.SObjectType vType = pRecordId.getSobjectType();
			vRes.objectApiName = String.valueOf(vType);
			vRes.settings = new Map<String, AddressComponents>();
			/** Set of fields to include in SOQL query when retrieving the record */
			Set<String> vFieldSet = new Set<String>();
			system.debug('VfieldSet at Top:::'+vFieldSet);
			/** Get the object fields definitions */
			Map<String, SObjectField> vFieldMap = vType.getDescribe().fields.getMap();
			system.debug('vFieldMap at Top:::'+ vType.getDescribe().fields.getMap());
			/** Retrieve object config. If several addresses are required on one page, Address Type can be dropped and return all address configs - the component will need to loop through*/
			getConfig(vRes.objectApiName);
			system.debug('Object Name:::'+vRes.objectApiName);
			/** Loop through address configurations*/
			for (Address_Fields_Mapping__mdt setting: CONFIG)
			{
				/** Fields making up the address */
				AddressComponents lComp = new AddressComponents();
				/** If mapping to a standard compound field, find all the components and get their names */
				system.debug('Standard Address field'+setting.Standard_Address_Field__c);
				if (setting.Standard_Address_Field__c != null)
				{
					/** Find all fields belonging to the select compound field */
					for (String s : vFieldMap.keySet())
					{
						DescribeFieldResult lFieldDesc = vFieldMap.get(s).getDescribe();
						/** Check that the field belongs to the compound field mapped */
						if (lFieldDesc.compoundFieldName == setting.Standard_Address_Field__r.QualifiedApiName)
						{
							vFieldSet.add(lFieldDesc.getName());
							if (lFieldDesc.getName().endsWith('City'))
							{
								lComp.City = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('PostalCode'))
							{
								lComp.PostCode = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('State'))
							{
								lComp.State = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('Street'))
							{
								lComp.Street = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('Latitude'))
							{
								lComp.Latitude = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('Longitude'))
							{
								lComp.Longitude = lFieldDesc.getName();
							}
							else if (lFieldDesc.getName().endsWith('Country'))
							{
								lComp.Country = lFieldDesc.getName();
							}
						}
					}
				}
				/** If mapping to several custom fields, we know the names of all fields already */
				else
				{
					system.debug('vFieldSet'+vFieldSet);
					lComp.PostCode = setting.Postcode_Field__r.QualifiedApiName;
					system.debug('Post Code in Setting'+setting.Postcode_Field__r.QualifiedApiName);
					vFieldSet.add(lComp.PostCode);
					lComp.Street = setting.Street_Field__r.QualifiedApiName;
					system.debug('Street in Setting'+setting.Street_Field__r.QualifiedApiName);
					vFieldSet.add(lComp.Street);
					lComp.City = setting.City_Field__r.QualifiedApiName;
					system.debug('City in Setting'+setting.Street_Field__r.QualifiedApiName);
					vFieldSet.add(lComp.City);
					lComp.State = setting.State_Field__r.QualifiedApiName;
					system.debug('state in Setting'+setting.State_Field__r.QualifiedApiName);
					vFieldSet.add(lComp.State);
					/** If a Geolocation field mapped, get the components */
					if (setting.Geolocation_Field__c != null)
					{
						String lGeoFieldName = setting.Geolocation_Field__r.QualifiedApiName.substring(0, setting.Geolocation_Field__r.QualifiedApiName.length() - 3);
						lComp.Latitude =  lGeoFieldName + '__Latitude__s';
						vFieldSet.add(lComp.Latitude);
						lComp.Longitude = lGeoFieldName + '__Longitude__s';
						vFieldSet.add(lComp.Longitude);
					}
				}
				/** If a custom DPID field mapped, add it */
				if (setting.DPID_Field__c != null)
				{
					lComp.DPID = setting.DPID_Field__r.QualifiedApiName;
					vFieldSet.add(lComp.DPID);
				}
				/* added if address validated field is mapped*/
				if (setting.Address_Validated_Field__c != null){
					lComp.AddressValidated = setting.Address_Validated_Field__r.QualifiedApiName;
					vFieldSet.add(lComp.AddressValidated);
				}
				vRes.settings.put(setting.DeveloperName, lComp);
			}

			/** Now we know all the fields, get their values to show the current address on the record */
			system.debug('vFieldSet:::'+vFieldSet);
			if (!vFieldSet.isEmpty())
			{
				vRes.currentRecord = Database.query('SELECT ' + String.join(new List<String>(vFieldSet), ',') + ' FROM ' + vRes.objectApiName + ' WHERE Id = :pRecordId');
				//system.debug('Current Record in apex'+vRes.currentRecord);
			}
			/*else{
				vRes.currentRecord = Database.query('SELECT Address__c,Suburb__c,State__c,Postcode__c,DPID__c FROM '+ vRes.objectApiName + ' WHERE Id = :pRecordId' );
				system.debug('Current Record in apex'+vRes.currentRecord);
			}*/
		}
		return vRes;
	}

	/**
	* The return object - all field mappings and current record values
	*/
	public class FieldMapping
	{
		@AuraEnabled
		public String objectApiName{get; set;}
		@AuraEnabled
		public SObject currentRecord{get; set;}
		@AuraEnabled
		public Map<String, AddressComponents> settings{get; set;}
	}

	/**
	* Components making up the address
	* */
	public class AddressComponents
	{
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
	}
}