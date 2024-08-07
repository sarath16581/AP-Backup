/******************************************************************************************************
 * @description 	Creates cases when there is no exisiting cases available or the current case closeddate is older than three days for the given social post.
 * 					Updates cases if the case closedDate is less than 3 days.
 * 					Updates socialPost with its respective case Id.
 * @author 			Raghav Ravipati
 * @test			ProcessSocialCaseActionTest
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
global with sharing class ProcessSocialCaseAction {
	private static final String STATUS_NEW = 'New';
	private static final String CASETYPE_GENERAL_ENQUIRY = 'General Enquiry';
	private static final String CASE_ORIGIN = 'Social Business';
	private static final String FACEBOOK = 'Facebook';
	private static final String TWITTER = 'Twitter';
	private static final String MESSAGETYPE_DIRECT = 'Direct';
	private static final String MESSAGETYPE_POST = 'Post';
	private static final String MESSAGETYPE_COMMENT = 'General Enquiry';
	private static final Id CASE_SOCIAL_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Record Type').getRecordTypeId();

	@InvocableMethod(label='Process Case' description='Each new post from social persona will create a case')
	public static void processCases(List<SocialBusinessCaseParams> caseParams) {
		if(caseParams != null && !caseParams.isEmpty()){
			processCases(caseParams[0].socialPosts, caseParams[0].socialPersonas);
		}
	}

	private static void processCases(List<SocialPost> socialPosts, List<socialPersona> socialPersonas) {
		Set<Id> caseIds = new Set<Id>();
		for (SocialPost post : socialPosts) {
			if (post.ReplyTo != null && post.ReplyTo.ParentId != null) {
				caseIds.add(post.ReplyTo.ParentId);
			}
		}
		// Case selector returns cases if the closed date is < 3 days
		CasesSelector caseSelector = CasesSelector.newInstance(new Set<SObjectField>{ Case.ClosedDate, Case.Id });
		Set<Id> caseIdsToUpdate = new Set<Id>();
		for (case parent : caseSelector.selectByIdsWithClosedDate(caseIds, new Set<Object>())) {
			caseIdsToUpdate.add(parent.Id);
		}
		// Repoens the case or creates a new case for the social posts that has no case.
		upsertCasesAndUpdateSocialPost(socialPosts, caseIdsToUpdate, new Map<Id, SocialPersona>(socialPersonas));
	}

	/**
	 * @description Reopens the case if the caseId is available in caseIdsToUpdate else creates a new case.
	 * @param socialPosts List of social post records.
	 * @param caseIdsToUpdate list of case Ids should be reopened.
	 */
	private static void upsertCasesAndUpdateSocialPost(List<SocialPost> socialPosts, Set<Id> caseIdsToUpdate,  Map<Id, SocialPersona> personaMap) {
		Map<Id, Case> socialPostIdCaseMap = new Map<Id, Case>();
		for (SocialPost post : socialPosts) {
			if (post.ReplyTo != null && post.ReplyTo.ParentId != null && caseIdsToUpdate.contains(post.ReplyTo.ParentId)) {
				Case existingCase = new Case();
				existingCase.Id = post.ReplyTo.ParentId;
				existingCase.Status = STATUS_NEW;
				existingCase.AllocateToQueue__c = true;
				existingCase.IsNewForRouting__c = true;
				existingCase.Type = CASETYPE_GENERAL_ENQUIRY;
				socialPostIdCaseMap.put(post.Id, existingCase);
			} else {
				socialPostIdCaseMap.put(post.Id, createCase(post, personaMap.get(post.PersonaId)));
			}
		}
		if (!socialPostIdCaseMap.Values().isEmpty()) {
			upsert socialPostIdCaseMap.Values();
			// Updates the social posts Parent Id with case Id
			updateSocialPosts(socialPostIdCaseMap);
		}
	}

	/**
	 * @description Creates a new case record using the list of social posts.
	 * @param socialPosts List of social post records.
	 */
	private static Case createCase(SocialPost post, SocialPersona persona) {
		Schema.SObjectType sojectType;
		Id personaParentId = persona.ParentId;
		if (persona != null &&  personaParentId != null) {
			sojectType = personaParentId.getSObjectType();
		}

		Case socialCase = new Case();
		socialCase.RecordtypeId = CASE_SOCIAL_RECORDTYPEID;
		socialCase.Origin = CASE_ORIGIN;
		socialCase.ContactId = sojectType == Contact.getSObjectType() ? personaParentId : null;
		socialCase.AccountId = sojectType == Account.getSObjectType() ? personaParentId : null;
		socialCase.AllocateToQueue__c = true;
		socialCase.SocialPostTags__c = post.PostTags;
		socialCase.Subject = getCaseSubject(post, persona);

		return socialCase;
	}

	/**
	 * @description Updates the socialPost record with Case ids
	 * @param socialPostIdCaseMap social post Id and its related case.
	 */
	private static void updateSocialPosts(Map<Id, Case> socialPostIdCaseMap) {
		List<SocialPost> updateSocialPost = new List<SocialPost>();
		for (Id socialPostId : socialPostIdCaseMap.keySet()) {
			Socialpost post = new SocialPost();
			post.Id = socialPostId;
			post.ParentId = socialPostIdCaseMap.get(socialPostId).Id;
			updateSocialPost.add(post);
		}
		if (!updateSocialPost.isEmpty()) {
			update updateSocialPost;
		}
	}
	
	/**
	 * @description Prepares case subject based on the Provider and Message type
	 * @param socialPost social post record
	 */
	private static String getCaseSubject(SocialPost socialPost, SocialPersona persona) {
		String subject;

		if (socialPost.Provider == FACEBOOK && socialPost.MessageType == MESSAGETYPE_DIRECT) {
			subject = 'Facebook PM from ' + persona.Name;
		} else if (socialPost.Provider == FACEBOOK && socialPost.MessageType == MESSAGETYPE_COMMENT && socialPost.ReplyToId != null) {
			subject = 'Facebook reply from ' + persona.Name;
		} else if (socialPost.Provider == FACEBOOK && socialPost.MessageType == MESSAGETYPE_COMMENT && socialPost.ReplyToId == null) {
			subject = 'Facebook comment from ' + persona.Name;
		} else if (socialPost.Provider == TWITTER && socialPost.MessageType == MESSAGETYPE_DIRECT) {
			subject = 'X [Twitter] DM from ' + persona.Name;
		} else if (socialPost.Provider == TWITTER && socialPost.MessageType == MESSAGETYPE_POST) {
			subject = 'X [Twitter] from ' + persona.Name;
		} else {
			subject = socialPost.Name;
		}

		return subject;
	}

	global class SocialBusinessCaseParams {
		@InvocableVariable
		global List<SocialPersona> socialPersonas;
		@InvocableVariable
		global List<SocialPost> socialPosts;
	}
}
