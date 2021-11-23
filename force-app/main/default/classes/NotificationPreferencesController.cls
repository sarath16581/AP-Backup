/**
 * @description
 * Controller for handling notification preferences in consumer details
 *
 * @author Disha Kariya
 * @date 2021-05-18
 * @group Tracking
 * @changelog
 */

public with sharing class NotificationPreferencesController {
	
	public Map<String, Set<String>> searchString;
	
	public String attributes {
		get {
			// attributes to pass into notification preferences component
			Map<String, Object> componentAttributes = new Map<String, Object> {
					'searchString' => searchString
			};
			return JSON.serialize(componentAttributes);
		}
		private set;
	}
	
	public NotificationPreferencesController(ApexPages.StandardController controller){
		searchString = new Map<String, Set<String>>();
		Id aid = controller.getRecord().Id;
		System.debug('aid--->'+aid);
		if (aid != null) {
			Account accountFound = SSSWAccountsSelector.newInstance().selectById(new Set<Id>{aid}, new Set<Object>{SSSWAccountsSelector.Options.FILTER_PERSON_ACCOUNT_ONLY}).values()[0];
			if (accountFound!=null) {
				if(String.isNotEmpty(accountFound.APCN__pc)){
					addToMap('apcn',accountFound.APCN__pc);
				}
				if(accountFound.PersonEmail != null){
					addToMap('email',accountFound.PersonEmail);
				}
				if(accountFound.Phone != null){
					addToMap('phone',accountFound.Phone);
				}
				if(accountFound.VerifiedMobile__pc != null){
					addToMap('phone',accountFound.VerifiedMobile__pc);
				}
				if(accountFound.PersonMobilePhone != null){
					addToMap('phone',accountFound.PersonMobilePhone);
				}
			}
		}
		System.debug('searchString--->'+searchString);
	}
	
	
	@TestVisible private void addToMap(String key, String value){
		Set<String> searchSet = new Set<String>();
		if(searchString.containsKey(key)) {
			searchSet = searchString.get(key);
		}
		searchSet.add(value);
		searchString.put(key,searchSet);
	}
}