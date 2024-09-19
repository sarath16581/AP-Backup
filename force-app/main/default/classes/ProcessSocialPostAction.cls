/******************************************************************************************************
 * @description 	Creates cases when there is no exisiting cases available or the current case closeddate is older than three days for the given social post.
 * 					Updates cases if the case closedDate is less than 3 days.
 * 					Updates socialPost with its respective case Id.
 * @author 			Raghav Ravipati
 * @test			ProcessSocialPostActionTest
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
global with sharing class ProcessSocialPostAction {
	@InvocableMethod(
		label='Process Social Post'
		description='Accepts a Sprout Social Data Event and Social Persona records and determines whether new Social Post records need to be created or need to update the existing records.'
	)
	public static List<SocialPost> processSocialPosts(List<SocialPostParams> params) {
		List<SocialPost> upsertSocialPosts;
		Set<String> providers = new Set<String>();
		Set<String> externalIds = new Set<String>();
		Set<String> responseContextExternalIds = new Set<String>();
		Map<String, SocialPostParams> socialPostParamsMap = new Map<String, SocialPostParams>();
		if (params != null && !params.isEmpty()) {
			for(SocialPostParams param : params){
				SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = param.socialDataEvent;
				if(socialDataEvent != null){			
					providers.add(socialDataEvent.SproutSocialApp__Post_Provider__c);
					externalIds.add(socialDataEvent.SproutSocialApp__Post_External_ID__c);
					responseContextExternalIds.add(socialDataEvent.SproutSocialApp__Response_Context_External_Id__c);
					socialPostParamsMap.put(socialDataEvent.SproutSocialApp__Post_External_ID__c, param);
				}
			}
			// Prepares list of social Post records to upsert
			upsertSocialPosts = processSocialPosts(providers, externalIds, responseContextExternalIds, socialPostParamsMap);
		}
		if (upsertSocialPosts != null && !upsertSocialPosts.isEmpty()) {
			upsert upsertSocialPosts;
		}

		return upsertSocialPosts;
	}

	/**
	 * @description Finds existing post using responseContextExternalIds to map to replyTo field of socialPost.
	 * 				Maps existing posts with latest information.
	 * 				Creates new socialPost instances using social data event information.
	 * @param providers Providers from social data event like Facebook, Twitter.
	 * @param externalIds post externalIds from  SocialDataEvent.
	 * @param responseContextExternalIds response Context ExternalIds from social data event.
	 * @param socialPostParamsMap Map that holds externalPostId as key and socialDataEvents as values
	 * @return List<SocialPost> socialPost records.
	 */
	private static List<SocialPost> processSocialPosts(
		Set<String> providers,
		Set<String> externalIds,
		Set<String> responseContextExternalIds,
		Map<String, SocialPostParams> socialPostParamsMap
	) {
		List<SocialPost> upsertSocialPosts = new List<SocialPost>();
		Map<String, SocialPost> existingPostMap = new Map<String, SocialPost>();
		// searches for the most recent SocialPost record with matching ResponseContextExternalId.
		for (SocialPost existingPost : getExistingSocialPost(responseContextExternalIds)) {
			existingPostMap.put(existingPost.ResponseContextExternalId, existingPost);
		}
		System.debug(existingPostMap);
		// Maps latest information to existing socialPost and removes existing records from the sociel data event map
		for (SocialPost post : getSocialPostWithProvidersAndExternalIds(providers, externalIds)) {
			if(socialPostParamsMap.containsKey(post.ExternalPostId)){				
				upsertSocialPosts.add(mapSocialPostFields(post, socialPostParamsMap.get(post.ExternalPostId).socialDataEvent));
				socialPostParamsMap.remove(post.externalPostId);
			}
		}
		// Creates new socialPost record instance.
		for (SocialPostParams param : socialPostParamsMap.values()) {
			SocialPost post = new SocialPost();
			//Mapping the parent of the first socialPost.
			if(existingPostMap.containsKey(param.socialDataEvent.SproutSocialApp__Response_Context_External_Id__c)){				
				post.ReplyToId = existingPostMap.get(param.socialDataEvent.SproutSocialApp__Response_Context_External_Id__c).Id;
				post.ReplyTo = existingPostMap.get(param.socialDataEvent.SproutSocialApp__Response_Context_External_Id__c);
			}
			if (param.socialPersona != null) {
				post.PersonaId = param.socialPersona.Id;
			}
			upsertSocialPosts.add(mapSocialPostFields(post, param.socialDataEvent));
		}

		return upsertSocialPosts;
	}

	/**
	 * @description Queries social post records based on response Context ExternalIds.
	 * @param responseContextExternalIds response Context ExternalIds from social data event.
	 * @return List<SocialPost> List of social post records.
	 */
	private static List<SocialPost> getExistingSocialPost(Set<String> responseContextExternalIds) {
		SocialPostsSelector selector = SocialPostsSelector.newInstance();
		return selector.selectByResponseContextExternalIds(responseContextExternalIds);
	}

	/**
	 * @description Queries social post records based on the providers and externalIds.
	 * @param providers Providers from social data event like Facebook, Twitter.
	 * @param externalIds post externalIds from  SocialDataEvent.
	 * @return List<SocialPost> List of social post records.
	 */
	private static List<SocialPost> getSocialPostWithProvidersAndExternalIds(Set<String> providers, Set<String> externalIds) {
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', providers);
		searchParams.put('externalPostIds', externalIds);
		SocialPostsSelector selector = SocialPostsSelector.newInstance();
		return selector.search(searchParams, new Set<Object>());
	}

	/**
	 * @description Creates SocialPost instance by mapping social data event information.
	 * @param post Existing Social post record or new social post record instance.
	 * @param socialDataEvent social data event record.
	 * @return socialPost updated socialPost record.
	 */
	private static SocialPost mapSocialPostFields(SocialPost post, SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent) {
		post.Name = socialDataEvent.SproutSocialApp__Post_Name__c;
		post.MessageType = socialDataEvent.SproutSocialApp__Message_Type__c;
		post.ExternalPostId = socialDataEvent.SproutSocialApp__Post_External_ID__c;
		post.Content = socialDataEvent.SproutSocialApp__Post_Content__c;
		post.PostTags = socialDataEvent.SproutSocialApp__Post_Tags__c;
		post.Posted = socialDataEvent.SproutSocialApp__Posted_At__c;
		post.Recipient = socialDataEvent.SproutSocialApp__Post_Recipient__c;
		post.R6TopicId = socialDataEvent.SproutSocialApp__Parent_GUID__c;
		post.TopicProfileName = socialDataEvent.SproutSocialApp__Sprout_Message_Type__c;
		post.R6SourceId = socialDataEvent.SproutSocialApp__Customer_Profile_Id__c;
		post.PostUrl = socialDataEvent.SproutSocialApp__Post_URL__c;
		post.MediaProvider = socialDataEvent.SproutSocialApp__Persona_Provider__c;
		post.Sentiment = socialDataEvent.SproutSocialApp__Post_Sentiment__c;
		post.Language = socialDataEvent.SproutSocialApp__Post_Language__c;
		post.ResponseContextExternalId = socialDataEvent.SproutSocialApp__Response_Context_External_Id__c;
		// These fields are not writeable on update operation.
		if(String.isBlank(post.Id)){
			post.Provider = socialDataEvent.SproutSocialApp__Post_Provider__c;
			post.IsOutbound = socialDataEvent.SproutSocialApp__Is_Outbound__c;
		}
		return post;
	}

	global class SocialPostParams {
		@InvocableVariable
		global SocialPersona socialPersona;
		@InvocableVariable
		global SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent;
	}
}