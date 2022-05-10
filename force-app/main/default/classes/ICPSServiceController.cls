/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Controller
 * @tag Controller
 * @tag ICPS Service
 * @domain ICPS
 * @description Service Controller class for ICPS Object.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
public with sharing class ICPSServiceController {

	/**
	 * Record limit on search results
	 */
	private static final Integer SEARCH_LIMIT = 100;

	/**
	 * Field Overrides for ICPS Search Function
	 * In case of new fields required to be returned in the future update this field set
	 */
	private static final Set<SObjectField> ICPS_SEARCH_FIELD_OVERRIDES = new Set<SObjectField>{
			ICPS__c.Name,
			ICPS__c.MailCategory__c,
			ICPS__c.ItemType__c,
			ICPS__c.ReceiverName__c,
			ICPS__c.CountryofOrigin__c,
			ICPS__c.NumberofArticles__c
	};

	/**
	 * This method is used to get ICPS Cases given search parameters as a map and a match option
	 * note: This method only supports at most 9 search criteria as in searchParams
	 * @param searchParams Search Params passed in as Map<String, String> (e.g, Reference: '12818')
	 * @param matchAll Match options, true for 'AND', false for 'OR'
	 * @return list of ICPS meeting the search criteria
	 */
	@AuraEnabled
	public static List<ICPS__c> getICPSCases(Map<String, String> searchParams, Boolean matchAll) {
		try {
			return ICPSSelector.newInstance(SEARCH_LIMIT, ICPS_SEARCH_FIELD_OVERRIDES).search(searchParams, matchAll);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}

	}

	/**
	 * This method is used to clone an ICPS provided current ICPS Id
	 * @param icpsId Id of the ICPS to be cloned
	 * @return cloned ICPS__C record
	 */
	@AuraEnabled
	public static ICPS__c cloneICPS(String icpsId) {
		try {
			ICPS__c icps = ICPSSelector.newInstance(1).selectById(new Set<Id>{
					icpsId
			})[0];
			ICPS__c newICPS = new ICPS__c(
					RecordTypeId = icps.RecordTypeId,
					OwnerId = icps.OwnerId,
					CountryofOrigin__c = icps.CountryofOrigin__c,
					DemurrageStartDate__c = icps.DemurrageStartDate__c,
					Status__c = 'In Store',
					DutyStatus__c = icps.DutyStatus__c,
					ItemType__c = icps.ItemType__c,
					MailCategory__c = icps.MailCategory__c,
					OrderNumber__c = icps.OrderNumber__c,
					OtherStorageLocation__c = icps.OtherStorageLocation__c,
					StoredLocation__c = icps.StoredLocation__c
			);
			ApplicationDatabase.getInstance().dmlInsert(new List<ICPS__c>{newICPS});
			return newICPS;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}