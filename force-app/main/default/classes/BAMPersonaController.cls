/**************************************************
Description: Utility class the handle various processes for BAM (Business Access Management)
History:
--------------------------------------------------
2019-04-11  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class BAMPersonaController {
	
	@TestVisible
	public static Id currentNetworkId {
		get {
			if(currentNetworkId == null) {
				currentNetworkId = Network.getNetworkId();
			}

			return currentNetworkId;
		}
		private set;
	}

	/**
	 * Grab the user details of the logged in user
	 */
	@AuraEnabled(cacheable=true)
	public static User getUserDetails() {
		Id userId = UserInfo.getUserId();
		return [Select Id, Contact.OID_ID__c, Contact.Name, ContactId From User Where Id = :userId];
	}

	/**
	 * Returns a list of persona's for the currently logged in User
	 */
	@AuraEnabled(cacheable=true)
	public static List<BAMUserUtility.UserPersona> getCurrentUserPersonas() {
		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(Id.valueOf(UserInfo.getUserId()), currentNetworkId);
		return personaUtility.personas.values();
	}

	/**
	 * This user has requested to switch personas.
	 * This will prepare
	 */
	@AuraEnabled(cacheable=false)
	public static Boolean switchPersona(String userId) {
		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(Id.valueOf(UserInfo.getUserId()), currentNetworkId);
		return personaUtility.switchPersona(userId);
	}

	/**
	 * Grab the url to redirect the user to after they switch personas
	 */
	@AuraEnabled(cacheable=true)
	public static String getIdPInitUrl() {
		AusPostSettings__c setting = AusPostSettings__c.getValues('BAM-IdP-Init-Login');
		return setting.URL__c;
	}


}