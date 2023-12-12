/**
 * @description
 * Manages the functions for notification preferences for APCN, Email and/or contact number
 *
 * @author Disha Kariya
 * @date 2021-05-05
 * @group Tracking
 * @changelog
 * 2023-11-22 - Mahesh Parvathaneni - Changed the authentication mechanism from Authz to Auth0
 */
public with sharing class NotificationPreferencesService {

	//constants
	private static final String NOTIFICATION_PREFERENCE = 'NotificationPreference';

	private static apsecrets.Auth0AccessManager.Auth0Token AUTH0_TOKEN {
		get {
			if (AUTH0_TOKEN == null) {
				AUTH0_TOKEN = apsecrets.Auth0AccessManager.getAccessToken(NOTIFICATION_PREFERENCE);
			}
			return AUTH0_TOKEN;
		}
		private set;
	}
	Map<String, Set<String>> searchStringMap;
	
	/**
	 * Creates a new instance of the service. This allows use to use dependency injection for mocking
	 */
	public static NotificationPreferencesService getInstance() {
		return (NotificationPreferencesService) Application.Utilities.getInstance(NotificationPreferencesService.class);
	}
	
	/**
	 * Retrieve the current Notification Status
	 * This is a single article either standalone or a part of a consignment
	 */
	public NotificationPreferencesResponse getNotificationPreferences(Map<String, List<String>> preferenceStrings) {
		searchStringMap = new Map<String, Set<String>>();
		for(String searchString : preferenceStrings.keySet()){
			Set<String> searchSet = new Set<String>();
			searchSet.addAll(preferenceStrings.get(searchString));
			searchStringMap.put(searchString, searchSet);
		}
//		searchStringMap = preferenceStrings;
		NotificationPreferencesResponse output = new NotificationPreferencesResponse();
		System.debug('preferenceStrings--->'+searchStringMap);
		if(searchStringMap.keySet().contains('apcn')){
			List<String> searchStrings = new List<String>();
			searchStrings.addAll(searchStringMap.get('apcn'));
			output = getPreferencesByAPCN(searchStrings[0]);
		}
		if(searchStringMap.keySet().contains('email') || searchStringMap.keySet().contains('phone')) {
			//Use other api to get preferences
			Set<String> searchStrings = new Set<String>();
			if(searchStringMap.containsKey('email')) {
				searchStrings.addAll(searchStringMap.get('email'));
			}
			if (searchStringMap.containsKey('phone')) {
				List<String> phoneList = new List<String>();
				for(String phoneString : searchStringMap.get('phone')){
					phoneList.add(phoneString.replaceAll('\\D',''));
				}
				searchStrings.addAll(phoneList);
			}
			System.debug('output--->'+output);
			if(output.preferences!=null && output.preferences.size() > 0) {
				NotificationPreferencesResponse newOutput = new NotificationPreferencesResponse();
				List<Preferences> prefList = new List<Preferences>(output.preferences);
				List<Preferences> foundByAPCNPreferences = new List<Preferences>();
				Map<String, Boolean> prefMap = new Map<String, Boolean>();
				for(Preferences pref : prefList){
					pref.foundByAPCN = true;
					foundByAPCNPreferences.add(pref);
					prefMap.put(String.isNotBlank(pref.email) ? pref.email : pref.mobile, pref.optedOut);
					searchStrings.remove(String.isNotBlank(pref.email) ? pref.email : pref.mobile);
				}
				output.preferences = foundByAPCNPreferences;
				if(searchStrings.size() > 0) {
					newOutput = getPreferencesByEmailMobile(searchStrings);
					if (newOutput.preferences != null && newOutput.preferences.size() > 0) {
						for (Preferences pref : newOutput.preferences) {
							System.debug('pref--->' + pref);
							if (!prefMap.containsKey(String.isNotBlank(pref.email) ? pref.email : pref.mobile)) {
								prefList.add(pref);
							}
						}
						System.debug('after prefList--->' + prefList);
						output.preferences = prefList;
					}
				}
			}else {
				output = getPreferencesByEmailMobile(searchStrings);
			}
		}
		return output;
	}

	/**
	* @description Method performing a callout to NCCC API to set notification preferences by email or mobile
 	* @param preferenceString email/mobile
 	* @param setValue opt in/out flag
 	* @return String
	 */
	public String setNotificationPreferences(String preferenceString, Boolean setValue)
	{
		try {
			Http vHTTP = new Http();
			HttpRequest req = new HttpRequest();
			req.setMethod('PUT');
			req.setHeader('Content-Type', 'application/json');
			req.setEndpoint('callout:NotificationPreferences/consumer/preferences/groups/track');
			req.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
			req.setHeader('staffId', UserInfo.getUserId());
			JSONGenerator gen = JSON.createGenerator(true);
			gen.writeStartObject();
			gen.writeStringField(preferenceString.contains('@') ? 'email' : 'mobile', preferenceString);
			gen.writeBooleanField('optedOut', setValue);
			gen.writeEndObject();
			System.debug(gen.getAsString());
			req.setBody(gen.getAsString());
			HttpResponse vRes = vHTTP.send(req);
			/** If 401 Unauthorized, force token regeneration*/
			if (vRes.getStatusCode() == 401) {
				AUTH0_TOKEN = apsecrets.Auth0AccessManager.getAccessToken(apsecrets.Auth0AccessManager.RunMode.FORCE_GENERATE, NOTIFICATION_PREFERENCE);
				req.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
				vRes = vHTTP.send(req);
			}
			if (vRes.getStatusCode() == 204) {
				return 'Notification preference' + (!setValue ? ' ON ' : ' OFF ') + 'for ' + preferenceString;
			} else {
				return 'Error: ' + ((NotificationPreferencesError) JSON.deserialize(vRes.getBody(), NotificationPreferencesError.class)).detail;
			}
		}catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
 	* @description Method performing a callout to NCCC API to get notification preferences by APCN
 	* @param pAPCN APCN
 	* @return NotificationPreferencesResponse
 	*/
	private NotificationPreferencesResponse getPreferencesByAPCN(String pAPCN)
	{
		try {
			NotificationPreferencesResponse vNotificationPreferencesResponse = new NotificationPreferencesResponse();
			Http vHTTP = new Http();
			HttpRequest vReq = new HttpRequest();
			vReq.setEndpoint('callout:NotificationPreferences/' + pAPCN + '/preferences/groups/track');
			vReq.setMethod('GET');
			vReq.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
			vReq.setHeader('staffId', UserInfo.getUserId());
			HttpResponse vRes = vHTTP.send(vReq);
			/** If 401 Unauthorized, force token regeneration*/
			if (vRes.getStatusCode() == 401) {
				AUTH0_TOKEN = apsecrets.Auth0AccessManager.getAccessToken(apsecrets.Auth0AccessManager.RunMode.FORCE_GENERATE, NOTIFICATION_PREFERENCE);
				vReq.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
				vRes = vHTTP.send(vReq);
			}
			if (vRes.getStatusCode() == 200) {
				vNotificationPreferencesResponse.preferences = (List<Preferences>) JSON.deserialize(vRes.getBody(), List<Preferences>.class);
				vNotificationPreferencesResponse.foundBasedOnAPCN = true;
			}
			else {
				vNotificationPreferencesResponse.error = ((NotificationPreferencesError) JSON.deserialize(vRes.getBody(), NotificationPreferencesError.class)).detail;
			}
			return vNotificationPreferencesResponse;
		}catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
 	* @description Method performing a callout to NCCC API to get notification preferences by email or mobile
 	* @param pSearchStringSet email/mobile set
 	* @return NotificationPreferencesResponse
 	*/
	private NotificationPreferencesResponse getPreferencesByEmailMobile(Set<String> pSearchStringSet)
	{
		try {
			NotificationPreferencesResponse vNotificationPreferencesResponse = new NotificationPreferencesResponse();
			Http vHTTP = new Http();
			HttpRequest vReq = new HttpRequest();
			vReq.setEndpoint('callout:NotificationPreferences/preferences/groups/track/get');
			vReq.setMethod('POST');
			vReq.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
			vReq.setHeader('staffId', UserInfo.getUserId());
			vReq.setHeader('Content-Type', 'application/json');
			JSONGenerator vJSON = JSON.createGenerator(true);
			vJSON.writeStartArray();
			for (String searchString : pSearchStringSet) {
				vJSON.writeStartObject();
				vJSON.writeStringField(searchString.contains('@') ? 'email' : 'mobile', searchString);
				vJSON.writeEndObject();
			}
			vJSON.writeEndArray();
			vReq.setBody(vJSON.getAsString());
			HttpResponse vRes = vHTTP.send(vReq);
			/** If 401 Unauthorized, force token regeneration*/
			if (vRes.getStatusCode() == 401) {
				AUTH0_TOKEN = apsecrets.Auth0AccessManager.getAccessToken(apsecrets.Auth0AccessManager.RunMode.FORCE_GENERATE, NOTIFICATION_PREFERENCE);
				vReq.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
				vRes = vHTTP.send(vReq);
			}
			if (vRes.getStatusCode() == 200) {
				vNotificationPreferencesResponse.preferences = (List<Preferences>) JSON.deserialize(vRes.getBody(), List<Preferences>.class);
			} else {
				vNotificationPreferencesResponse.error = ((NotificationPreferencesError) JSON.deserialize(vRes.getBody(), NotificationPreferencesError.class)).detail;
			}
			return vNotificationPreferencesResponse;
		}catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class Preferences {
		@AuraEnabled public String email;
		@AuraEnabled public String mobile;
		@AuraEnabled public Boolean optedOut;
		@AuraEnabled public Boolean foundByAPCN = false;
		
		public Preferences(String email, String mobile, Boolean optedOut){
			this.email = email;
			this.mobile = mobile;
			this.optedOut = optedOut;
		}
	}
	
	public class NotificationPreferencesResponse {
//		@AuraEnabled public Boolean success;
		@AuraEnabled public String error;
		@AuraEnabled public Boolean foundBasedOnAPCN = false;
		@AuraEnabled public List<Preferences> preferences;
	}

	private class NotificationPreferencesError
	{
		String status;
		String code;
		String detail;
	}
}