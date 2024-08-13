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
	private static final String CASE_ORIGIN = 'Social';
	private static final String FACEBOOK = 'Facebook';
	private static final String TWITTER = 'Twitter';
	private static final String MESSAGETYPE_DIRECT = 'Direct';
	private static final String MESSAGETYPE_POST = 'Post';
	private static final String MESSAGETYPE_COMMENT = 'General Enquiry';
	private static final Id CASE_SOCIAL_RECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Record Type').getRecordTypeId();

	@InvocableMethod(label='Process Case' description='Each new post from social persona will create a case')
	public static void processCases(List<SocialBusinessCaseParams> socialBusinessCaseParams) {
		Set<Id> caseIds = new Set<Id>();
		for (SocialBusinessCaseParams param : socialBusinessCaseParams) {
			if (param.socialPost != null && param.socialPost.ReplyTo != null && param.socialPost.ReplyTo.ParentId != null) {
				caseIds.add(param.socialPost.ReplyTo.ParentId);
			}
		}
		Set<Id> caseIdsToUpdate = new Set<Id>();
		BusinessHoursService businessHoursService = BusinessHoursService.newInstance();	
		// Select cases by Id
		CasesSelector caseSelector = CasesSelector.newInstance(new Set<SObjectField>{ Case.ClosedDate, Case.Id, Case.IsClosed });
		Map<Id, Case> caseMap = caseSelector.selectById(caseIds);
		// Collects cases to reopen.
		for (Case socialCase : caseMap.values()) {
			// Add case to reopen list if case is open or closed date is less than 3 business days
			if(!socialCase.IsClosed || (socialCase.ClosedDate != null && socialCase.ClosedDate < businessHoursService.calculateNextBusinessDateTime(socialCase.ClosedDate, 3))){
				caseIdsToUpdate.add(socialCase.Id);
			}
		}
		// Repoens the case or creates a new case for the social posts that has no case.
		upsertCasesAndUpdateSocialPost(socialBusinessCaseParams, caseIdsToUpdate);
	}

	/**
	 * @description Reopens the case if the caseId is available in caseIdsToUpdate else creates a new case.
	 * @param socialPosts List of social post records.
	 * @param caseIdsToUpdate list of case Ids should be reopened.
	 */
	private static void upsertCasesAndUpdateSocialPost(List<SocialBusinessCaseParams> socialBusinessCaseParams, Set<Id> caseIdsToUpdate) {
		Map<Id, Case> socialPostIdCaseMap = new Map<Id, Case>();
		for (SocialBusinessCaseParams param : socialBusinessCaseParams) {
			SocialPost post = param.socialPost;
			if (post != null && post.ReplyTo != null && post.ReplyTo.ParentId != null && caseIdsToUpdate.contains(post.ReplyTo.ParentId)) {
				Case existingCase = new Case();
				existingCase.Id = post.ReplyTo.ParentId;
				existingCase.Status = STATUS_NEW;
				existingCase.AllocateToQueue__c = true;
				existingCase.IsNewForRouting__c = true;
				existingCase.Type = CASETYPE_GENERAL_ENQUIRY;
				socialPostIdCaseMap.put(post.Id, existingCase);
			} else {
				socialPostIdCaseMap.put(post.Id, createCase(param));
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
	private static Case createCase(SocialBusinessCaseParams params) {
		Schema.SObjectType sojectType;
		Id personaParentId;
		if (params.socialPersona != null &&  params.socialPersona.ParentId != null) {
			personaParentId = params.socialPersona.ParentId;
			sojectType = personaParentId.getSObjectType();
		}

		Case socialCase = new Case();
		socialCase.RecordtypeId = CASE_SOCIAL_RECORDTYPEID;
		socialCase.Origin = CASE_ORIGIN;
		socialCase.ContactId = sojectType == Contact.getSObjectType() ? personaParentId : null;
		socialCase.AccountId = sojectType == Account.getSObjectType() ? personaParentId : null;
		socialCase.AllocateToQueue__c = true;
		socialCase.SocialPostTags__c = params.socialPost.PostTags;
		socialCase.Subject = getCaseSubject(params);

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
	private static String getCaseSubject(SocialBusinessCaseParams params) {
		String subject;
		String provider = params.socialPost.Provider;
		String messageType = params.socialPost.MessageType;
		String personaName = params.socialPersona.Name;

		if (FACEBOOK.equalsIgnoreCase(provider) && MESSAGETYPE_DIRECT.equalsIgnoreCase(messageType)) {
			subject = 'Facebook PM from ' + personaName;
		} else if (FACEBOOK.equalsIgnoreCase(provider) && MESSAGETYPE_COMMENT.equalsIgnoreCase(messageType) && params.socialPost.ReplyToId != null) {
			subject = 'Facebook reply from ' + personaName;
		} else if (FACEBOOK.equalsIgnoreCase(provider) && MESSAGETYPE_COMMENT.equalsIgnoreCase(messageType) && params.socialPost.ReplyToId == null) {
			subject = 'Facebook comment from ' + personaName;
		} else if (TWITTER.equalsIgnoreCase(provider) && MESSAGETYPE_DIRECT.equalsIgnoreCase(messageType)) {
			subject = 'X [Twitter] DM from ' + personaName;
		} else if (TWITTER.equalsIgnoreCase(provider) && MESSAGETYPE_POST.equalsIgnoreCase(messageType)) {
			subject = 'X [Twitter] from ' + personaName;
		} else {
			subject = params.socialPost.Name;
		}

		return subject;
	}

	global class SocialBusinessCaseParams {
		@InvocableVariable
		global SocialPersona socialPersona;
		@InvocableVariable
		global SocialPost socialPost;
	}
}