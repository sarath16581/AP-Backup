/**
* @author Nathan Franklin
* @date 2020-07-22
* @group Selector
* @domain SSSW
* @description A very simple selector class that sits in the SSSW domain
* @changelog
* 13.06.2024 Parveen Kaushik Added MappingModel__c in the field list. See CSLU-470 (JIRA) for details.
*/
public inherited sharing class EnquiryMappingsSelector extends ApplicationSelector {

	public static EnquiryMappingsSelector newInstance() {
		return (EnquiryMappingsSelector)Application.Selectors.newInstance(EnquiryMappingsSelector.class);
	}

	public override SObjectType getSObjectType() {
		return MiniCaseFieldMapping__c.getSObjectType();
	}

	public override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				MiniCaseFieldMapping__c.CaseRecordTypeId__c, MiniCaseFieldMapping__c.CTICustomerSegment__c, MiniCaseFieldMapping__c.CTIKey__c, MiniCaseFieldMapping__c.CTIServiceType__c, MiniCaseFieldMapping__c.Id,
				MiniCaseFieldMapping__c.Name, MiniCaseFieldMapping__c.ProductCategory__c, MiniCaseFieldMapping__c.ProductSubcategory__c, MiniCaseFieldMapping__c.SAPKey__c, MiniCaseFieldMapping__c.SAPProductCategory__c,
				MiniCaseFieldMapping__c.SAPProductSubcategory__c, MiniCaseFieldMapping__c.Type__c, MiniCaseFieldMapping__c.MappingModel__c
		};
	}

	public Map<Id, MiniCaseFieldMapping__c> selectBySAPKey(Set<String> sapKeys) {
		// convert all the sap keys to uppercase
		Set<String> upperCaseSapKeys = new Set<String>();
		for(String key : sapKeys) {
			upperCaseSapKeys.add(key.toUpperCase());
		}

		Map<Id, MiniCaseFieldMapping__c> mappings = getAllMappings();
		Map<Id, MiniCaseFieldMapping__c> output = new Map<Id, MiniCaseFieldMapping__c>();
		for(MiniCaseFieldMapping__c mapping : mappings.values()) {
			if(!String.isEmpty(mapping.SAPKey__c)) {
				if (upperCaseSapKeys.contains(mapping.SAPKey__c.toUpperCase())) {
					output.put(mapping.Id, mapping);
				}
			}
		}
		return output;
	}

	/**
	 * Grab mappings from cache if they exist
	 */
	private Map<Id, MiniCaseFieldMapping__c> getAllMappings() {
		Map<Id, MiniCaseFieldMapping__c> output = (Map<Id, MiniCaseFieldMapping__c>)CacheManager.get('MINICASE_MAPPINGS');
		if (output != null) {
			return output;
		} else {
			String soql = newQueryBuilder().toSoqlString();
			output = new Map<Id, MiniCaseFieldMapping__c>((List<MiniCaseFieldMapping__c>)Database.query(soql));

			CacheManager.put('MINICASE_MAPPINGS', output);
		}

		return output;
	}

}