/**
 * @description Module to handle automation specific to classic SSSW / Social cases on receiving event messages.
 *			  This automation was previously delivered using below workflow rules on Case object:
 *				  - SSSW - Email Awaiting Collection
 *				  - SSSW - Email Delivered
 *				  - SSSW - Email Onboard with Driver
 *				  - SSSW - Email Awaiting Collection [Contact without Email]
 *				  - SSSW - Email Awaiting Collection [Contact without Email] (Allocate To Queue)
 *				  - SSSW - Email Awaiting Collection [Contact without Email] HLC
 *				  - SSSW - Email Delivered in a Safe Place
 *				  - SSSW - Missing Item Delivery
 *				  - SSSW - Onboard with driver international
 *
 *			  IMPORTANT:
 *			  It was decided the new module based automation will only be triggered when event messages are inserted.
 *
 * @author Ranjeewa Silva
 * @date 2024-09-19
 * @test EventMsgMyCustomerCaseAutoModule_Test
 * @changelog
 */
public inherited sharing class EventMessageMyCustomerCaseAutoModule extends ApplicationModule {

	// event messages indicating the article is awaiting collection
	@TestVisible private static final Set<String> EVENT_TYPES_AWAITING_COLLECTION = new Set<String>{'DD-ER4', 'NT-ER4', 'TTP-ER4'};
	// event messages indicating the article is delivered
	@TestVisible private static final Set<String> EVENT_TYPES_DELIVERED = new Set<String>{
			'DD-ER13', 'DD-ER14', 'DD-ER37', 'DD-ER47', 'DDR-ER13', 'DDR-ER14', 'DOM-0001', 'DOM-0008', 'DOM-0009',
			'INT-0037', 'INT-2009', 'INT-2037', 'INT-2039', 'INT-2136', 'INT-2137', 'DD-ER39'
	};
	// event messages indicating the article is onboard with driver for delivery
	@TestVisible private static final Set<String> EVENT_TYPES_ONBOARD_WITH_DRIVER = new Set<String>{'AFP-ER13', 'AFP-ER15'};
	// event messages indicating the international article is onboard with driver for delivery
	@TestVisible private static final Set<String> EVENT_TYPES_ONBOARD_WITH_DRIVER_INTERNATIONAL = new Set<String>{'INT-0074'};
	// event messages indicating the article is delivered in a safe drop
	@TestVisible private static final Set<String> EVENT_TYPES_DELIVERED_IN_SAFE_PLACE = new Set<String>{'DD-ER15', 'DD-ER38', 'INT-2070'};

	// event messages indicating the missing article has been delivered as per the source workflow rule.
	// on receiving these event messages the case type will be updated to 'General Enquiry' and enquiry sub type
	// will be updated to 'Tracking'
	@TestVisible private static final Set<String> EVENT_TYPES_MISSING_ITEM_DELIVERY = new Set<String>{
			'AFP-ER15', 'AFP-ER13', 'DD-ER13', 'DD-ER14', 'DD-ER37', 'DD-ER47', 'DD-ER64', 'DDR-ER13', 'DDR-ER14',
			'DOM-0001', 'DOM-0008', 'DOM-0009', 'INT-0037', 'INT-2009', 'INT-2037', 'INT-2039', 'INT-2070', 'INT-2136',
			'INT-2137', 'DD-ER38', 'DD-ER39', 'DD-ER4', 'NT-ER4', 'TTP-ER4'
	};

	// event messages eligible for case closure
	private static final Set<String> CASE_CLOSURE_ELIGIBLE_EVENT_TYPES {
		get {
			if (CASE_CLOSURE_ELIGIBLE_EVENT_TYPES == null) {
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES = new Set<String>();
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.addAll(EVENT_TYPES_AWAITING_COLLECTION);
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.addAll(EVENT_TYPES_DELIVERED);
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.addAll(EVENT_TYPES_ONBOARD_WITH_DRIVER);
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.addAll(EVENT_TYPES_ONBOARD_WITH_DRIVER_INTERNATIONAL);
				CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.addAll(EVENT_TYPES_DELIVERED_IN_SAFE_PLACE);
			}
			return CASE_CLOSURE_ELIGIBLE_EVENT_TYPES;
		}
		set;
	}

	// event messages we monitor for case automation.
	private static final Set<String> MONITORED_EVENT_TYPES {
		get {
			if (MONITORED_EVENT_TYPES == null) {
				MONITORED_EVENT_TYPES = new Set<String>();
				MONITORED_EVENT_TYPES.addAll(CASE_CLOSURE_ELIGIBLE_EVENT_TYPES);
				MONITORED_EVENT_TYPES.addAll(EVENT_TYPES_MISSING_ITEM_DELIVERY);
			}
			return MONITORED_EVENT_TYPES;
		}
		set;
	}

	// case record types eligible for automation
	@TestVisible private static final Set<Id> AUTOMATION_ENABLED_CASE_RECORDTYPES {
		get {
			if (AUTOMATION_ENABLED_CASE_RECORDTYPES == null) {
				AUTOMATION_ENABLED_CASE_RECORDTYPES = RecordTypesSelector.newInstance().selectByDeveloperNamesLike('Case', new Set<String>{
						'SSSW', 'Social'
				}).keySet();
			}
			return AUTOMATION_ENABLED_CASE_RECORDTYPES;
		}
		set;
	}

	// case enquiry sub types eligible for automation on receiving closure eligible event messages
	@TestVisible private static final Set<String> CASE_CLOSURE_ELIGIBLE_ENQUIRY_SUBTYPES = new Set<String>{
			'Item transfer', 'Missing Item', 'Disputed delivery scan', 'Tracking', 'Delivery complaint', 'Inbound tracking',
			'Outbound tracking', 'Delayed delivery', 'Delivery request'
	};

	// case queues excluded from automation on receiving closure eligible event messages
	private static final Set<String> CASE_CLOSURE_EXCLUDED_CASE_QUEUE_NAMES = new Set<String>{'SSSW High Level Complaints'};

	// case product categories eligible for conversion into 'General Enquiry' type, on receiving eligible event messages
	private static final Set<String> CASE_TYPE_UPDATE_ELIGIBLE_PRODUCT_CATEGORIES = new Set<String>{
			'Domestic Parcels', 'International Parcels', 'Domestic Letters', 'International Letters'
	};

	public EventMessageMyCustomerCaseAutoModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			// from Event Messages getting inserted, collect event types eligible for case automation with parent
			// article mapping (key - article id; value - automation eligible event types).
			Map<Id, Set<String>> automationEligibleEventTypes = new Map<Id, Set<String>>();
			for (EventMessage__c eventMessage : (List<EventMessage__c>) records) {
				if (MONITORED_EVENT_TYPES.contains(eventMessage.EventType__c)) {
					// event message is eligible for case automation.
					Set<String> articleEventTypes = automationEligibleEventTypes.get(eventMessage.Article__c);
					if (articleEventTypes == null) {
						articleEventTypes = new Set<String>();
						automationEligibleEventTypes.put(eventMessage.Article__c, articleEventTypes);
					}
					articleEventTypes.add(eventMessage.EventType__c);
				}
			}

			if (!automationEligibleEventTypes.isEmpty()) {
				registerCaseAutomationAsyncWork(automationEligibleEventTypes, uow);
			}
		} catch (Exception e) {
			// log error in ExceptionLog__c object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), SSSWConstants.SSSW_APP, EventMessageMyCustomerCaseAutoModule.class.getName(), 'onAfterInsert', 'EventMessage__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private void registerCaseAutomationAsyncWork(Map<Id, Set<String>> automationEligibleEventTypes, ApplicationUnitOfWork uow) {
		// query open cases related to the articles for which we have received new automation eligible event messages
		List<Case> openCases = CasesSelector.newInstance(new Set<SObjectField>{Case.Id, Case.ArticleTest__c}).search(new Map<String, Object>{
				'relatedArticleIds' => automationEligibleEventTypes.keySet(),
				'recordTypeIds' => AUTOMATION_ENABLED_CASE_RECORDTYPES,
				'isClosed'  =>  false
		}, new Set<Object>{}, true);

		Map<Id, Set<String>> caseAutomationAsyncWorkerParams  = new Map<Id, Set<String>>();
		for (Case openCase: openCases) {
			// get automation eligible event types relevant for this case from the new event messages
			// for the case's related article.
			Set<String> caseEventTypes = automationEligibleEventTypes.get(openCase.ArticleTest__c);
			caseAutomationAsyncWorkerParams.put(openCase.Id, caseEventTypes);
		}

		if (!caseAutomationAsyncWorkerParams.isEmpty()) {
			// we have identified eligible cases for closure/reassignment automation based on newly inserted event messages
			// register async work to process these cases.
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncEventMessageMyCustomerCaseAutomationWorker.class, caseAutomationAsyncWorkerParams));
		}
	}

	@TestVisible private static String getCaseClosureCustomerNotificationEmailAlert(String eventType) {
		if (EVENT_TYPES_AWAITING_COLLECTION.contains(eventType)) {
			return 'SSSW_Awaiting_Collection';
		} else if (EVENT_TYPES_DELIVERED.contains(eventType)) {
			return 'SSSW_Email_Delivered';
		} else if (EVENT_TYPES_DELIVERED_IN_SAFE_PLACE.contains(eventType)) {
			return 'SSSW_Email_Delivered_in_a_Safe_Place';
		} else if (EVENT_TYPES_ONBOARD_WITH_DRIVER.contains(eventType)) {
			return 'SSSW_Onboard_with_Driver';
		} else if (EVENT_TYPES_ONBOARD_WITH_DRIVER_INTERNATIONAL.contains(eventType)) {
			return 'SSSW_Onboard_with_driver_international';
		}
		return null;
	}

	/**
	 * Async worker for processing cases identified for automation based on newly inserted event messages.
	 */
	public inherited sharing class AsyncEventMessageMyCustomerCaseAutomationWorker extends ApplicationUnitOfWork.AsyncWorker {

		private Map<Id, Set<String>> params = new Map<Id, Set<String>>();

		public override void execute(ApplicationUnitOfWork uow) {

			Map<Id, Case> casesMap = CasesSelector.newInstance(new Set<SObjectField>{
					Case.ArticleTest__c, Case.Id, Case.EnquirySubType__c, Case.ContactEmail, Case.ClosedBySystem__c,
					Case.IsHLC__c, Case.IsCR__c, Case.Calc_Owner_Name__c, Case.Origin, Case.CHASEnquiryType__c, Case.IsClosed,
					Case.ProductCategory__c, Case.ProductSubCategory__c, Case.EnquirySubType__c, Case.Type
			}).selectById(params.keySet());

			Map<Id, Case> updatableCases = new Map<Id, Case>();

			for (Case caseRecord: casesMap.values()) {
				Case updatableCase = updatableCases.get(caseRecord.Id) ?? new Case(Id=caseRecord.Id);
				// this is replicating the behaviour of current workflow rules when multiple event messages are received.
				for (String eventType: params.get(caseRecord.Id)) {
					if (CASE_CLOSURE_ELIGIBLE_EVENT_TYPES.contains(eventType)) {
						updatableCase.ResolutionCode__c = 'Network resolution';
						if (canCloseCase(eventType, caseRecord)) {
							// close case
							updatableCase.Status = SSSWConstants.CASE_STATUS_CLOSED;
							updatableCase.ClosedBySystem__c = true;
							updatableCase.Resolution_Status__c = 'Delivered as addressed';
							updatableCases.put(updatableCase.Id, updatableCase);
							uow.queueEmailNotification(updatableCase.Id, Case.SObjectType, getCaseClosureCustomerNotificationEmailAlert(eventType));
						} else if (canReassignCase(eventType, caseRecord)) {
							// reassign case
							updatableCase.AllocateToQueue__c = true;
							updatableCases.put(updatableCase.Id, updatableCase);
						} else if (canUpdateResolutionCodeOnCase(eventType, caseRecord)) {
							updatableCases.put(updatableCase.Id, updatableCase);
						}
					}

					if (canUpdateEnquirySubTypeOnCase(eventType, caseRecord)) {
						updatableCase.Type = 'General Enquiry';
						updatableCase.EnquirySubType__c = 'Tracking';
						updatableCases.put(updatableCase.Id, updatableCase);
					}
				}
			}

			if (!updatableCases.isEmpty()) {
				uow.registerDirty(updatableCases.values(), false, AsyncEventMessageMyCustomerCaseAutomationWorker.class.getName() + 'execute');
			}
		}

		public override Type getClassType() {
			return AsyncEventMessageMyCustomerCaseAutomationWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				try {
					this.params = (Map<Id, Set<String>>) JSON.deserialize(serialisedParams, Map<Id, Set<String>>.class);
				} catch (Exception e) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), SSSWConstants.SSSW_APP, AsyncEventMessageMyCustomerCaseAutomationWorker.class.getName(),
							'deserialiseParams', String.valueOf(EventMessage__c.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		}

		private Boolean canCloseCase(String eventType, Case caseRecord) {
			return (!caseRecord.IsClosed
					&& CASE_CLOSURE_ELIGIBLE_ENQUIRY_SUBTYPES.contains(caseRecord.EnquirySubType__c)
					&& String.isNotBlank(caseRecord.ContactEmail)
					&& !caseRecord.ClosedBySystem__c
					&& !caseRecord.IsHLC__c
					&& !caseRecord.IsCR__c
					&& !CASE_CLOSURE_EXCLUDED_CASE_QUEUE_NAMES.contains(caseRecord.Calc_Owner_Name__c)
					&& ((caseRecord.Origin != 'Web' && caseRecord.Origin != 'Portal')
						|| caseRecord.CHASEnquiryType__c == 'Missing or lost item'
						|| EVENT_TYPES_ONBOARD_WITH_DRIVER_INTERNATIONAL.contains(eventType)));
		}

		private Boolean canReassignCase(String eventType, Case caseRecord) {
			return (EVENT_TYPES_AWAITING_COLLECTION.contains(eventType)
					&& !caseRecord.IsClosed
					&& String.isBlank(caseRecord.ContactEmail)
					&& ((!caseRecord.IsHLC__c && !caseRecord.IsCR__c)
						|| (String.isNotBlank(caseRecord.ProductCategory__c)
							&& String.isNotBlank(caseRecord.ProductSubCategory__c)
							&& String.isNotBlank(caseRecord.EnquirySubType__c)
							&& String.isNotBlank(caseRecord.Type))));
		}

		private Boolean canUpdateResolutionCodeOnCase(String eventType, Case caseRecord) {
			return (EVENT_TYPES_AWAITING_COLLECTION.contains(eventType)
					&& !caseRecord.IsClosed
					&& String.isBlank(caseRecord.ContactEmail));
		}

		private Boolean canUpdateEnquirySubTypeOnCase(String eventType, Case caseRecord) {
			return (EVENT_TYPES_MISSING_ITEM_DELIVERY.contains(eventType)
					&& !caseRecord.IsClosed
					&& CASE_TYPE_UPDATE_ELIGIBLE_PRODUCT_CATEGORIES.contains(caseRecord.ProductCategory__c)
					&& 'Missing Item'.equalsIgnoreCase(caseRecord.EnquirySubType__c)
					&& new Set<String>{'Investigation', 'Feedback'}.contains(caseRecord.Type));
		}
	}
}