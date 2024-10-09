/**
 * @description Apex Controller for `UnifiedCaseFeed` LWC component.
 * It retrieves related important objects that are associated with the provided case such as:
 * - Scheduled Contact Request (ContactRequest)
 * - Email Message (EmailMessage)
 * - Scan Event Message (EventMessage__c)
 * Then display on the LWC component embedded on the case page layout.
 * @test UnifiedCaseFeedControllerTest
 * @author Seth Heang
 * @changelog:
 * 2024-09-23 - Seth Heang - created
 * 2024-10-09 - Seth Heang - update query criteria to retrieve related scan event
 */
public with sharing class UnifiedCaseFeedController {
	@TestVisible
	private final static String FEED_HEADER_SCR = 'Scheduled Contact Request';
	@TestVisible
	private final static String FEED_HEADER_EMAIL = 'Email Received';
	@TestVisible
	private final static String FEED_HEADER_SCAN_EVENT = 'Scan Event Update';
	@TestVisible
	private final static String FEED_ICON_SCR = 'standard:contact_request';
	@TestVisible
	private final static String FEED_ICON_EMAIL = 'standard:email';
	@TestVisible
	private final static String FEED_ICON_SCAN_EVENT = 'custom:custom26';
	@TestVisible
	private static final String GENERIC_ERROR_MESSAGE = 'An unexpected error has occurred. Please check the data you\'ve entered and try again. If this error persists, please inform your manager.';


	/**
	 * @description retrieve all case related records such as SCR, Email and Scan Events and map to wrapper objects
	 * @param caseId passed from LWC case feed component
	 *
	 * @return List<UnifiedCaseFeedsResult> list of wrapper objects for display
	 */
	@AuraEnabled(Cacheable=true)
	public static List<UnifiedCaseFeedsResult> getLatestCaseFeedsResults(Id caseId){
		try {
			if(String.isBlank(String.valueOf(caseId))){
				AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
				ae.setMessage(GENERIC_ERROR_MESSAGE);
				throw ae;
			}
			// get all Case Feeds Records (e.g. SCRs, Emails, and Scan Events)
			List<SObject> allCaseFeedsRecords = getAllCaseFeedsRecords(caseId);
			return buildFeedResults(allCaseFeedsRecords);
		} catch (Exception ex){
			AuraHandledException ae = new AuraHandledException(ex.getMessage());
			ae.setMessage(ex.getMessage());
			throw ae;
		}
	}

	/**
	 * @description get latest case feeds related objects such as SCR, Email and Scan Events
	 * @param caseId case Id from LWC case feed component
	 *
	 * @return List<SObject> list of objects including SCR, Email and Scan Events
	 */
	@TestVisible
	private static List<SObject> getAllCaseFeedsRecords(Id caseId){
		List<SObject> allCaseFeedsRecords = new List<SObject>();
		allCaseFeedsRecords.addAll(getRelatedScheduledContactRequests(caseId));
		allCaseFeedsRecords.addAll(getRelatedEmailMessages(caseId));
		allCaseFeedsRecords.addAll(getRelatedEventMessages(caseId));
		return allCaseFeedsRecords;
	}

	/**
	 * @description get scheduled contact requests where status is not abandoned and is related to case
	 * @param caseId case Id from LWC case feed component
	 *
	 * @return List<SObject> list of SCRs of SObject type
	 */
	@TestVisible
	private static List<SObject> getRelatedScheduledContactRequests(Id caseId){
		Set<SObjectField> scrFields = new Set<SObjectField>{
				ContactRequest.Case__c, ContactRequest.PreferredChannel, ContactRequest.ScheduledDate__c
		};
		List<ContactRequest> scrList = ContactRequestsSelector.newInstance(0, scrFields).search(
				new Map<String, Object>{
					'whatIds' => new Set<Id> { caseId },
					'status' => null // need to explicitly set to null, to return proper data
				},
				new Set<Object> { ContactRequestsSelector.Options.FILTER_STATUS_NOT_ABANDONED },
				true
		);
		return scrList;
	}

	/**
	 * @description get 'incoming' email messages related to the case
	 * @param caseId case Id from LWC case feed component
	 *
	 * @return List<SObject> list of email message of SObject type
	 */
	@TestVisible
	private static List<SObject> getRelatedEmailMessages(Id caseId){
		Map<SObjectType, Set<SObjectField>> emailMessageFields = new Map<SObjectType, Set<SObjectField>>{
				EmailMessage.SObjectType => new Set<SObjectField>{
						EmailMessage.FromAddress,
						EmailMessage.CreatedDate
				}
		};
		List<EmailMessage> incomingEmailMessages = EmailMessagesSelector.newInstance(emailMessageFields)
				.selectByParentIds(
						new Set<Id>{ caseId },
						new Set<Object>{ EmailMessagesSelector.Options.FILTER_INCOMING }
				);
		return incomingEmailMessages;
	}

	/**
	 * @description get scan event message whose event type matches those in a mapping table(EventMessageTypeMapping__mdt) that has isFeatured flag set to TRUE
	 * @param caseId case Id from LWC case feed component
	 *
	 * @return List<SObject> list of scan event message of SObject type
	 */
	@TestVisible
	private static List<SObject> getRelatedEventMessages(Id caseId){
		// query and filter event type where `IsFeatured` is true
		Set<String> filteredEventTypesWithIsFeatured = new Set<String>();
		for (EventMessageTypeMapping__mdt eventMessageTypeMapping : EventMessageUtil.getEventMessageTypes().values()){
			if (eventMessageTypeMapping.IsFeatured__c == true){
				filteredEventTypesWithIsFeatured.add(eventMessageTypeMapping.Label);
			}
		}

		List<ImpactedArticle__c> impactedArticles = ImpactedArticlesSelector.newInstance(0,
				new Set<SObjectField> {
					ImpactedArticle__c.Article__c
				}).selectByCaseId(new Set<Id>{ caseId });
		Set<Id> articleIds = new Set<Id>();
		for(ImpactedArticle__c impactedArticle : impactedArticles){
			articleIds.add(impactedArticle.Article__c);
		}

		Map<SObjectType, Set<SObjectField>> eventMessageFields = new Map<SObjectType, Set<SObjectField>>{
			EventMessage__c.SObjectType => new Set<SObjectField>{
				EventMessage__c.Case__c,
				EventMessage__c.EventDescription__c,
				EventMessage__c.ActualDateTime__c,
				EventMessage__c.EventType__c
			},
			Article__c.SObjectType => new Set<SObjectField>{
				Article__c.Case__c
			}
		};
		List<EventMessage__c> filteredEventMessages = EventMessagesSelector.newInstance(eventMessageFields)
				.selectByArticleIdAndEventType(
						articleIds,
						filteredEventTypesWithIsFeatured
				);
		return filteredEventMessages;
	}

	/**
	 * @description build list of feed wrapper records including attribute mappings for different object type such as SCRs, email, scan event messages
	 * @param feedRecords list of SCRs, email, scan event messages
	 *
	 * @return List<UnifiedCaseFeedsResult> list of wrapper objects for display on LWC component
	 */
	@TestVisible
	private static List<UnifiedCaseFeedsResult> buildFeedResults(List<SObject> feedRecords){
		List<UnifiedCaseFeedsResult> feedResults = new List<UnifiedCaseFeedsResult>();
		for (SObject obj : feedRecords){
			UnifiedCaseFeedsResult feedResult = new UnifiedCaseFeedsResult();
			if (obj instanceof ContactRequest) {
				ContactRequest scr = (ContactRequest) obj;
				feedResult.feedHeader = FEED_HEADER_SCR;
				feedResult.feedBody = scr.PreferredChannel;
				feedResult.feedDateTime = scr.ScheduledDate__c;
				feedResult.feedCustomIcon = FEED_ICON_SCR;
				feedResult.feedRecordId = scr.Id;
			}
			else if (obj instanceof EmailMessage) {
				EmailMessage emailMessage = (EmailMessage) obj;
				feedResult.feedHeader = FEED_HEADER_EMAIL;
				feedResult.feedBody = emailMessage.FromAddress;
				feedResult.feedDateTime = emailMessage.CreatedDate;
				feedResult.feedCustomIcon = FEED_ICON_EMAIL;
			}
			else if (obj instanceof EventMessage__c) {
				EventMessage__c eventMessage = (EventMessage__c) obj;
				feedResult.feedHeader = FEED_HEADER_SCAN_EVENT;
				feedResult.feedBody = eventMessage.EventDescription__c;
				feedResult.feedDateTime = eventMessage.ActualDateTime__c;
				feedResult.feedCustomIcon = FEED_ICON_SCAN_EVENT;
			}
			feedResults.add(feedResult);
		}
		return feedResults;
	}

	/**
	 * Wrapper feed object used to display on the Case feed update LWC component
	 */
	public class UnifiedCaseFeedsResult {
		@AuraEnabled
		public String feedHeader;
		@AuraEnabled
		public String feedBody;
		@AuraEnabled
		public DateTime feedDateTime;
		@AuraEnabled
		public String feedCustomIcon;
		@AuraEnabled
		public String feedRecordId; // used for record page navigation on LWC component
	}
}