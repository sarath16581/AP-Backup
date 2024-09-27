/***
 * @description Utility Class for EventMessage Triggers
 * @author
 * @date
 * @group
 * @domain
 * @changelog
 * 2019-05-30 - Gunith Devasurendra - Disable routing to event types CE-TR01, CE-TR02, CE-EN01, CE-EN02
 * 2019-09-19 - Gunith Devasurendra - Getting event codes from Custom settings
 * 2020-03-16 - Nathan Franklin - Added a utility method to retrieve a list of event messages
 * 2020-05-29 - arjun.singh@auspost.com.au - Added a method to populate machine detail  Name for MyNetwork Community
 * 2020-09-18 - Ranjeewa Silva - Updated to populate new fields in the retrieved list of event message types.
 * 2021-05-07 - Ranjeewa Silva - Added a new method to retrieve event message attachment type definitions configured.
 * 2021-06-18 - Ranjeewa Silva - Added new method to save event message image as an attachment.
 * 2021-10-01 - Nathan Franklin - get a getInstance method for mocking and a new method getEventMessageTypeDefinitions
 * 2021-10-05 - Nathan Franklin - Removed the AP Case signature attachment capability since it's no longer in use in light of new PDF delivery proof capability (StarTrack still remains)
 * 2021-09-27 - Hasantha Liyanage - Added CHAS_EventMessageTypeMapping__mdt related getters for consumer help and support
 * 2024-09-20 - Ranjeewa Silva - Excluded unified cases from the automation in 'updateCases' (invoked on event message insert).
 */
public without sharing class EventMessageUtil {

	public static Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitionsCache = new Map<String, EventMessageTypeMapping__mdt>();
	public static Map<String, CHAS_EventMessageTypeMapping__mdt> chasEventTypeDefinitionsCache = new Map<String, CHAS_EventMessageTypeMapping__mdt>();

	// transactional cache of attachment type definitions
	public static Map<String, EventMessageAttachmentTypeMapping__mdt> attachmentTypeDefinitionsCache = new Map<String, EventMessageAttachmentTypeMapping__mdt>();

	public static Boolean caseSignatureAttachmentsCreated = false;

	// attachment file name prefix for event message attachments
	public static final String EVENT_MESSAGE_ATTACHMENT_PREFIX = 'em-attachment';

	/**
	 * These event codes will not change a Case by re-routing it by making SystemUpdate__c ='Tracking Update'.
	 * Instead of calling it directly, get it via getter nonRoutingEventCodes which will load values from the Custom Setting SSSWNonRoutingEventCodes__c
	 */
	private static Set<String> nonRoutingEventCodesInstance = new Set<String>();

	/**
	 * Get comma separated event codes from the Custom Setting SSSWNonRoutingEventCodes__c.
	 * These will be split from comma and loaded to nonRoutingEventCodesInstance.
	 * These event codes will not change a Case by re-routing it by making SystemUpdate__c ='Tracking Update'
	 */
	private static Set<String> nonRoutingEventCodes {
		get {
			if (nonRoutingEventCodesInstance.isEmpty()) {
				SSSWNonRoutingEventCodes__c eventCodeSetting = SSSWNonRoutingEventCodes__c.getInstance();
				String[] codesSplit = eventCodeSetting.Codes__c.split(',');

				for (String codeSplit : codesSplit) {
					nonRoutingEventCodesInstance.add(codeSplit.trim());
				}

				System.debug('Non Routing Event Codes loaded: ' + codesSplit);
			}
			return nonRoutingEventCodesInstance;
		}
	}

	private static Set<Id> unifiedCaseRecordTypeIds {
		get {
			if (unifiedCaseRecordTypeIds == null) {
				unifiedCaseRecordTypeIds = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'Unified').keySet();
			}
			return unifiedCaseRecordTypeIds;
		}
		set;
	}

	public static EventMessageUtil getInstance() {
		return (EventMessageUtil) Application.Utilities.getInstance(EventMessageUtil.class);
	}

	public Map<String, EventMessageTypeMapping__mdt> getEventMessageTypeDefinitions() {
		return EventMessageUtil.getEventMessageTypes();
	}

	//update cases when event messages are created
	public static void updateCases(list<EventMessage__c> events) {

		map<Id, Case> casesToUpdate = new map<Id, Case>();
		set<id> articleIDs = new set<id>();
		for (EventMessage__c e : events) {
			articleIDs.add(e.Article__c);
		}

		Map<string, List<Case>> lodgementPointUpdates = new Map<string, List<Case>>();
		Map<string, EventMessage__c> eventCodes = new Map<string, EventMessage__c>();
		list<Case> cases = [select Article_Event_Codes__c,Network__c,Lodgement_Network__c,ArticleTest__c,status, CreatedDate, IsClosed from Case where ArticleTest__c in:articleIDs AND RecordTypeId NOT IN :unifiedCaseRecordTypeIds];
		for (Case c : cases) {
			for (EventMessage__c e : events) {
				if (e.ActualDateTime__c != null) {
					if (e.Article__c == c.ArticleTest__c && e.SenderID__c <> 'SF' && (e.ActualDateTime__c > c.CreatedDate && e.ActualDateTime__c.addHours(48) > Datetime.now()) && !c.IsClosed) {
						c.Article_Event_Codes__c = e.EventType__c; //added by Kalpita 25.10.17 - for SMS Automation for having latest article event code.

						// Gunith 2019-05-30: If a Case belongs to a shortlist of EventCodes, then it shouldn't route. Otherwise it will.
						// SystemUpdate__c ='Tracking Update' will make a Case Route
						if (!nonRoutingEventCodes.contains(e.EventType__c)) {
							c.SystemUpdate__c = 'Tracking Update';
						}

						c.Bypass_Data_enforcement__c = true;
						casesToUpdate.put(c.Id, c);

					}
				}

				if (e.Article__c == c.ArticleTest__c && !c.IsClosed) {
					if (c.Lodgement_Network__c == null && !string.isBlank(e.EventType__c)) {
						if (!lodgementPointUpdates.containsKey(e.EventType__c)) {
							lodgementPointUpdates.put(e.EventType__c, new List<Case>());
						}
						lodgementPointUpdates.get(e.EventType__c).add(c);

						if (!eventCodes.containsKey(e.EventType__c)) {
							eventCodes.put(e.EventType__c, e);
						}
					}
				}
			}
		}

		if (!lodgementPointUpdates.isEmpty()) {
			for (LodgementPointMapping__c m : [select SAPEMEventCode__c from LodgementPointMapping__c where SAPEMEventCode__c in:lodgementPointUpdates.keySet()]) {
				for (Case c : lodgementPointUpdates.get(m.SAPEMEventCode__c)) {
					c.Lodgement_Network__c = eventCodes.get(m.SAPEMEventCode__c).Facility__c;
					if (!casesToUpdate.containsKey(c.id)) {
						c.Bypass_Data_enforcement__c = true;
						casesToUpdate.put(c.id, c);
					}
				}
			}
		}

		if (casesToUpdate.size() > 0) {
			//ISSUE WITH VALIDATION RULES - NEW CODE ADDED - 16/06/2014
			update casesToUpdate.values();
		}
	}

	//creates signture attachments when event messages are created
	// NOTE: This attachment is used when generating proof of delivery PDF's, in POD_SafeDrop and MyCustomerDeliveryProofPdfWrapper
	// TODO: this probably shouldn't be doing this blindly whenever there is a signature available.... this should be rewritten at some point
	// NOTE: For StarTrack use cases, this method is sporadically invoked... See execution logic in EventMessageTrigger for more details (specifically, StarTrackConsignmentSearchUtil.isFromWebservice)
	public static void createSignatureAttachments(List<EventMessage__c> events) {
		List<Attachment> attachments = new List<Attachment>();

		List<EventMessage__c> eventMsgsWithSignature = new List<EventMessage__c>();
		Set<Id> articleIds = new Set<Id>();

		for (EventMessage__c e : events) {
			if (e.SignatureXString__c != null) {
				attachments.add(
						Util.createAttachment('Signature-' + (e.EventDescription__c == null ? '' : e.EventDescription__c) + + '-' + (e.SignatoryName__c == null ? '' : e.SignatoryName__c) +'.png', e.SignatureXString__c, 'image/png', e.Id));

				if (e.Article__c != null) {
					articleIds.add(e.Article__c);
				}
				eventMsgsWithSignature.add(e);
			}
		}

		// This no longer creates signature attachments for AP cases, just StarTrack cases
		if (articleIds.size() > 0 && eventMsgsWithSignature.size() > 0) {
			Map<Id, List<Case>> articleToCases = new Map<Id, List<Case>>();
			for (Case c : [SELECT Id, ArticleTest__c FROM Case WHERE ArticleTest__c IN :articleIds AND StarTrack_RecordType__c = TRUE]) {
				List<Case> clist = articleToCases.get(c.ArticleTest__c);
				if (clist == null) {
					clist = new List<Case>();
				}
				clist.add(c);
				articleToCases.put(c.ArticleTest__c, clist);
			}

			attachments.addAll(createSignatureAttachments(eventMsgsWithSignature, articleToCases));
		}

		if (attachments.size() > 0) {
			insert attachments;
		}
	}

	public static List<Attachment> createSignatureAttachments(List<EventMessage__c> eventMsgsWithSignature, Map<Id, List<Case>> articleToCases) {
		List<Attachment> attachments = new List<Attachment>();
		Map<String, EventMessageTypes__c> eventMessageTypes = EventMessageTypes__c.getAll();
		if (!caseSignatureAttachmentsCreated) {
			for (EventMessage__c em: eventMsgsWithSignature) {
				EventMessageTypes__c et = eventMessageTypes.get(em.EventType__c);
				if (et != null && et.SignatureAttachmentOnCase__c && em.Article__c != null && articleToCases.containsKey(em.Article__c)) {
					for (Case c : articleToCases.get(em.Article__c)) {
						attachments.add(Util.createAttachment('Signature-' + (em.EventDescription__c == null ? '' : em.EventDescription__c) + '-' + (em.SignatoryName__c == null ? '' : em.SignatoryName__c) + '.png', em.SignatureXString__c, 'image/png', c.Id));
						caseSignatureAttachmentsCreated = true;
					}
				}
			}
		}
		return attachments;
	}

	/**
	 * Create an attachment linked to an event message with the contents passed in
	 * @param parentId Id of the event message
	 * @param imageBody Image contents
	 * @param guid attachment guid.
	 * @param isSafeDrop flag indicating if this is a safedrop picture
	 *
	 * @return the new attachment created
	 */
	public static Attachment attachArticleImage(Id parentId, Blob imageBody, String guid, Boolean isSafeDrop) {

		if (isSafeDrop) {
			return SafeDropUtility.attachSafeDropImage(parentId, imageBody);
		}

		String attachmentName = EVENT_MESSAGE_ATTACHMENT_PREFIX + (guid != null ? ('-' + guid) : '') + '.jpg';
		Attachment attachment = new Attachment(ParentId = parentId, Body = imageBody, ContentType = 'image/jpg', Name = attachmentName, IsPrivate = false);
		insert attachment;

		return attachment;
	}

	//links an Event Message to a Network, based on a matching Org ID. 
	public static void linkToNetworkFacility(List<EventMessage__c> events) {

		Map<String, Id> networkOrgs = new Map<String, Id>();

		//Process all ORGs from the incomming events. 
		for (EventMessage__c e : events) {
			if (e.FacilityOrganisationID__c <> null) {
				networkOrgs.put(e.FacilityOrganisationID__c, null);
			}
		}

		if (networkOrgs.size() > 0) {
			//Retreive the IDs for all ORGs from the incomming events.
			for (Network__c nOrg : [SELECT Id, Name, Org_ID__c from Network__c where Org_ID__c in :networkOrgs.keyset()]) {
				networkOrgs.put(nOrg.Org_ID__c, nOrg.Id);
			}

			for (EventMessage__c e : events) {
				//Set the ORG on the Event, if it is blank and found.
				if (e.Facility__c == null && networkOrgs.containsKey(e.FacilityOrganisationID__c)) {
					e.Facility__c = networkOrgs.get(e.FacilityOrganisationID__c);
				}
			}
		}
	}

	public static void updateArticles(List<EventMessage__c> events) {
		Set<Id> artIds = new Set<Id>();
		for (EventMessage__c em : events) {
			if (em.EventType__c == 'CE-EN01' ||
					em.EventType__c == 'CE-EN02' ||
					(em.EventType__c == 'AFP-ER37' && (em.SenderID__c == 'PAA' || em.SenderID__c == 'PAAM'))) {
				artIds.add(em.Article__c);
			}
		}

		Map<Id, Article__c> articles = new Map<Id, Article__c>([SELECT Notification__c, AdditionalServicesPayload__c FROM Article__c WHERE Id IN :artIds]);

		Map<Id, Article__c> articleToUpdate = new Map<Id, Article__c>();

		for (EventMessage__c em : events) {
			if (em.EventType__c == 'CE-EN01' || em.EventType__c == 'CE-EN02') {
				Article__c a = articles.get(em.Article__c);
				if (a != null && !a.Notification__c) {
					a.Notification__c = true;
					articleToUpdate.put(em.Article__c, a);
				}
			}

			if (em.EventType__c == 'AFP-ER37' && (em.SenderID__c == 'PAA' || em.SenderID__c == 'PAAM')) {
				Article__c a = articles.get(em.Article__c);
				if (a != null && a.AdditionalServicesPayload__c != null) {
					ArticleUtil.setAdditionalServices(a, new List<TIBCOEventMessageWrapper>{
							new TIBCOEventMessageWrapper(em)
					});
					articleToUpdate.put(em.Article__c, a);
				}
			}
		}

		if (articleToUpdate.size() > 0) {
			update articleToUpdate.values();
		}
	}

	/**
	 * Grab the specific details about a single event message type and their attributes. This is used for a range of automation and ui capabilities in Salesforce
	 */
	public static EventMessageTypeMapping__mdt getEventMessageType(String eventType) {
		return getEventMessageTypes().get(eventType);
	}

	/**
	 * Grab the specific details about a category of message types and their attributes. This is used for a range of automation and ui capabilities in Salesforce
	 */
	public static List<EventMessageTypeMapping__mdt> getEventMessageTypesByCategory(String category) {
		return getEventMessageTypesByCategory().get(category);
	}

	/**
	 * Get all event message types and their attributes by category. This is used for a range of automation and ui capabilities in Salesforce
	 */
	public static Map<String, List<EventMessageTypeMapping__mdt>> getEventMessageTypesByCategory() {
		Map<String, List<EventMessageTypeMapping__mdt>> eventTypes = new Map<String, List<EventMessageTypeMapping__mdt>>();
		for (EventMessageTypeMapping__mdt eventType : getEventMessageTypes().values()) {
			if (eventTypes.get(eventType.Category__c) == null) {
				eventTypes.put(eventType.Category__c, new List<EventMessageTypeMapping__mdt>());
			}

			eventTypes.get(eventType.Category__c).add(eventType);
		}
		return eventTypes;
	}

	/**
	 * Grab the details about all the event message types and their attributes used in various forms of automation and ui presentation in Salesforce.
	 * TODO: Does this need platform cache?
	 */
	public static Map<String, EventMessageTypeMapping__mdt> getEventMessageTypes() {
		// see if this data was already requested in this transaction
		if (!eventTypeDefinitionsCache.isEmpty()) {
			return eventTypeDefinitionsCache;
		}

		Map<String, EventMessageTypeMapping__mdt> output = new Map<String, EventMessageTypeMapping__mdt>();
		for (EventMessageTypeMapping__mdt record : [
				Select Label, Category__c, DeveloperName, IsEnquiryLodged__c, IsSafeDrop__c, IsSignatureOnDelivery__c, IsFeatured__c,
						ColourCode__c
				From EventMessageTypeMapping__mdt
		]) {
			output.put(record.Label, record);
		}

		// add to transaction cache
		eventTypeDefinitionsCache = output;

		return output;
	}

	/**
	 * Grab the details about all the event message types used in Help and support community related functionalities.
	 * TODO: Does this need platform cache?
	 */
	public static Map<String, CHAS_EventMessageTypeMapping__mdt> getChasEventMessageTypes() {
		// see if this data was already requested in this transaction
		if (!chasEventTypeDefinitionsCache.isEmpty()) {
			return chasEventTypeDefinitionsCache;
		}

		Map<String, CHAS_EventMessageTypeMapping__mdt> output = new Map<String, CHAS_EventMessageTypeMapping__mdt>();
		for (CHAS_EventMessageTypeMapping__mdt record : [
				Select Label, DeveloperName, IsException__c, Description__c
				From CHAS_EventMessageTypeMapping__mdt
		]) {
			output.put(record.Label, record);
		}

		// add to transaction cache
		chasEventTypeDefinitionsCache = output;

		return output;
	}

	/** get the exceptional event messages
	 * @return list of event's
	 */
	public static List<String> getCHASExceptionalEventMessageTypes() {
		List<String> eventMessageString = new List<String>();
		for (CHAS_EventMessageTypeMapping__mdt eventType : getChasEventMessageTypes().values()) {
			if (eventType.IsException__c) {
				eventMessageString.add(eventType.Label);
			}
		}
		return eventMessageString;
	}

	/** get the notification event messages
	 * @return list of event's
	 */
	public static List<String> getCHASNotificationEventMessageTypes() {
		List<String> eventMessageString = new List<String>();
		for (CHAS_EventMessageTypeMapping__mdt eventType : getChasEventMessageTypes().values()) {
			if (!eventType.IsException__c) {
				eventMessageString.add(eventType.Label);
			}
		}
		return eventMessageString;
	}

	/**
	 * Retrieve details about all event message attachment types and their attributes used in ui presentation in Salesforce.
	 * @return event message attachment types
	 */
	public static Map<String, EventMessageAttachmentTypeMapping__mdt> getEventMessageAttachmentTypes() {
		// see if this data was already requested in this transaction
		if (!attachmentTypeDefinitionsCache.isEmpty()) {
			return attachmentTypeDefinitionsCache;
		}

		Map<String, EventMessageAttachmentTypeMapping__mdt> output = new Map<String, EventMessageAttachmentTypeMapping__mdt>();
		for (EventMessageAttachmentTypeMapping__mdt record : [
				Select Label, DeveloperName, IsIncludedOnCasePrintOut__c
				From EventMessageAttachmentTypeMapping__mdt
		]) {
			output.put(record.DeveloperName, record);
		}

		// add to transaction cache
		attachmentTypeDefinitionsCache = output;

		return output;
	}

	/**
	 * Description : Get the Sorting Ids Name from the Machine Detail table and populate the respective attrtibute on Event Message
	 */
	public static void populateMachineDetails(List<EventMessage__c> events) {
		Set<String> machineIds = new Set<String>();
		Map<String, String> DeviceWithNameMap = new Map<String, String>();
		for (EventMessage__c ev : events) {
			if (ev.DeviceID__c != null) {
				machineIds.add(ev.DeviceID__c);
			}if (ev.SortDest__c != null) {
				machineIds.add(ev.SortDest__c);
			}if (ev.SortOutputComp__c != null) {
				machineIds.add(ev.SortOutputComp__c);
			}
		}
		System.debug('machineIds>>>' + machineIds);
		for (Machine_Details__c machineRecord : [Select Component_ID__c, Name From Machine_Details__c Where Component_ID__c IN :machineIds]) {
			DeviceWithNameMap.put(machineRecord.Component_ID__c, machineRecord.Name);
		}
		System.debug('DeviceWithNameMap>>>' + DeviceWithNameMap);
		if (DeviceWithNameMap != null) {
			for (EventMessage__c ev : events) {
				if (ev.DeviceID__c != null && DeviceWithNameMap.containsKey(ev.DeviceID__c)) {
					ev.Machine_Device_Name__c = DeviceWithNameMap.get(ev.DeviceID__c);
				}if (ev.SortDest__c != null && DeviceWithNameMap.containsKey(ev.SortDest__c)) {
					ev.Logical_Destination_Name__c = DeviceWithNameMap.get(ev.SortDest__c);
				}if (ev.SortOutputComp__c != null && DeviceWithNameMap.containsKey(ev.SortOutputComp__c)) {
					ev.Actual_Destination_Name__c = DeviceWithNameMap.get(ev.SortOutputComp__c);
				}
			}
		}
	}
}