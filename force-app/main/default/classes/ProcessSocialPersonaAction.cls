/******************************************************************************************************
 * @description 	Create or Update Social persona records using Sprout's Social data events.
 * @author 			Raghav Ravipati
 * @test			ProcessSocialPersonaActionTest
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
global with sharing class ProcessSocialPersonaAction {
	private static final String PROVIDER_OTHER = 'Other';

	@InvocableMethod(
		label='Process Social Persona'
		description='Accepts a Sprout Social Data Event record and determines whether new SocialPersona records need to be created or if existing records need to be updated.'
	)
	public static List<SocialPersona> processSocialPersonas(List<SproutSocialApp__Sprout_Social_Data_Event__c> socialDataEvents) {
		Set<String> providers = new Set<String>();
		Set<String> externalIds = new Set<String>();
		Set<String> mediaProviders = new Set<String>();
		Set<String> personaNames = new Set<String>();
		Map<String, SproutSocialApp__Sprout_Social_Data_Event__c> socialDataEventMap = new Map<String, SproutSocialApp__Sprout_Social_Data_Event__c>();
		// Collect the required params to pass to the Selector class.
		for (SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent : socialDataEvents) {
			String key = prepareSocialDataEventKey(socialDataEvent);

			if (String.isNotBlank(socialDataEvent.SproutSocialApp__Persona_External_Id__c)) {
				externalIds.add(socialDataEvent.SproutSocialApp__Persona_External_Id__c);
			}

			if (String.isNotBlank(socialDataEvent.SproutSocialApp__Persona_Name__c)) {
				personaNames.add(socialDataEvent.SproutSocialApp__Persona_Name__c);
			}

			if (String.isNotBlank(socialDataEvent.SproutSocialApp__Media_Provider__c)) {
				mediaProviders.add(socialDataEvent.SproutSocialApp__Media_Provider__c);
			}

			if (String.isNotBlank(socialDataEvent.SproutSocialApp__Post_Provider__c) && !PROVIDER_OTHER.equalsIgnoreCase(socialDataEvent.SproutSocialApp__Post_Provider__c)) {
				providers.add(socialDataEvent.SproutSocialApp__Post_Provider__c);
			}

			socialDataEventMap.put(key, socialDataEvent);
		}

		List<SocialPersona> upsertPersona = new List<SocialPersona>();
		// Selector to find any existing social persona available.
		SocialPersonasSelector selector = SocialPersonasSelector.newInstance();
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', providers);
		searchParams.put('externalIds', externalIds);
		searchParams.put('mediaProviders', mediaProviders);
		searchParams.put('personaNames', personaNames);

		// Update the existing personas with the latest information from Social data event.
		for (SocialPersona persona : selector.search(searchParams, new Set<Object>())) {
			String key;
			if (externalIds.contains(persona.ExternalId) && providers.contains(persona.Provider)) {
				key = persona.ExternalId;
			} else if (externalIds.contains(persona.ExternalId) && PROVIDER_OTHER.equalsIgnoreCase(persona.Provider) && mediaProviders.contains(persona.MediaProvider)) {
				key = persona.ExternalId + persona.MediaProvider;
			} else if (personaNames.contains(persona.Name) && mediaProviders.contains(persona.MediaProvider) && PROVIDER_OTHER.equalsIgnoreCase(persona.provider)) {
				key = persona.Name + persona.MediaProvider;
			}

			SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = socialDataEventMap.get(key);
			if (socialDataEvent != null) {
				upsertPersona.add(createOrUpdatePersona(persona, socialDataEvent));
				socialDataEventMap.remove(key);
			}
		}
		// Create new social persona event, if there is no matching persona available
		if (!socialDataEventMap.values().IsEmpty()) {
			Map<String, SocialPost> socialPostMap = new Map<String, SocialPost>();

			for (String key : socialDataEventMap.keySet()) {
				SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = socialDataEventMap.get(key);
				socialPostMap.put(key, createDummySocialPost(socialDataEvent.SproutSocialApp__Persona_Real_Name__c));
			}

			insert socialPostMap.values();

			for (String key : socialDataEventMap.keySet()) {
				SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = socialDataEventMap.get(key);
				socialPost post = socialPostMap.get(key);

				if (socialDataEvent != null && post != null) {
					SocialPersona newPersona = new SocialPersona();
					newPersona.ParentId = post.Id;
					upsertPersona.add(createOrUpdatePersona(newPersona, socialDataEvent));
				}
			}
		}
		if (!upsertPersona.isEmpty()) {
			upsert upsertPersona;
		}

		return upsertPersona;
	}

	/**
	 * @description Performs field mappings to social persona records using the social data event.
	 * @param socialPersona Existing or new social persona object.
	 * @param socialDataEvent Social data event record.
	 * @return socialPersona social persona record.
	 */
	private static SocialPersona createOrUpdatePersona(SocialPersona socialPersona, SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent) {
		socialPersona.Name = socialDataEvent.SproutSocialApp__Persona_Name__c;
		socialPersona.RealName = socialDataEvent.SproutSocialApp__Persona_Real_Name__c;
		socialPersona.Provider = socialDataEvent.SproutSocialApp__Post_Provider__c;
		socialPersona.ExternalId = socialDataEvent.SproutSocialApp__Persona_External_Id__c;
		socialPersona.MediaProvider = socialDataEvent.SproutSocialApp__Media_Provider__c;
		socialPersona.ExternalPictureURL = socialDataEvent.SproutSocialApp__Persona_External_Picture_URL__c;
		socialPersona.ProfileUrl = socialDataEvent.SproutSocialApp__Persona_Profile_URL__c;
		socialPersona.Followers = Integer.valueOf(socialDataEvent.SproutSocialApp__Persona_Followers__c);
		socialPersona.AuthorLabels = socialDataEvent.SproutSocialApp__Persona_Author_Labels__c;

		return socialPersona;
	}

	/**
	 * @description Prepare a key that used to put and get values from the maps
	 * @param socialDataEvent Social data event record.
	 * @return String key.
	 */
	private static String prepareSocialDataEventKey(SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent) {
		String key;

		if (socialDataEvent.SproutSocialApp__Persona_External_Id__c != null && !PROVIDER_OTHER.equalsIgnoreCase(socialDataEvent.SproutSocialApp__Post_Provider__c)) {
			key = socialDataEvent.SproutSocialApp__Persona_External_Id__c;
		} else if (
			socialDataEvent.SproutSocialApp__Persona_External_Id__c != null &&
			socialDataEvent.SproutSocialApp__Media_Provider__c != null &&
			PROVIDER_OTHER.equalsIgnoreCase(socialDataEvent.SproutSocialApp__Post_Provider__c)
		) {
			key = socialDataEvent.SproutSocialApp__Persona_External_Id__c + socialDataEvent.SproutSocialApp__Media_Provider__c;
		} else if (
			socialDataEvent.SproutSocialApp__Persona_Name__c != null &&
			socialDataEvent.SproutSocialApp__Media_Provider__c != null &&
			PROVIDER_OTHER.equalsIgnoreCase(socialDataEvent.SproutSocialApp__Post_Provider__c)
		) {
			key = socialDataEvent.SproutSocialApp__Persona_Name__c + socialDataEvent.SproutSocialApp__Media_Provider__c;
		}

		return key;
	}

	/**
	 * @description Prepare a key that used to put and get values from the maps
	 * @param String Real name field from Social data event
	 * @return SocialPost object.
	 */
	private static SocialPost createDummySocialPost(String realName) {
		SocialPost post = new SocialPost();
		post.Name = 'Dummy';
		if(String.isNotBlank(realName)){
			post.Name += realName.replace(' ', '');
		} 
		post.Posted = Datetime.now();

		return post;
	}
}