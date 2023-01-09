/*** 
 * @description
 * Domain Module to update Case fields that are used in Omni Skills Routing. Only SSSW Cases are processed.
 * a) Stamp CustomerQueueType__c field. In isBefore so it is available for OTB Omni Skills routing 
 * b) Assign Case to Preferred Agent. For Cases moving from a non-Omni to an Omni Queue, generate a PendingServiceRouting with a Preferred User if Case has existing AgentWork
 * 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-09-20
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-09-20 - Noel Lim - Created
 * 2022-12-06 - Noel Lim - added method assignToPreferredAgent
 */

public inherited sharing class CaseSkillBasedRoutingModule extends ApplicationDomain.Module  {
	
	private static Set<Id> validRecTypes;
	public static final String SERVICESLA_CONSUMER = 'Consumer';

	private Map<String, Integer> secondaryPriorityMappings = new Map<String, Integer> {
		'Low' => 5,
		'Critical' => 1,
		'Normal' => 2,
		'High' => 2,
		'Medium' => 4,
		'Regular' => 3,
		'Urgent' => 1
	};

	private String preferredAgentQueueId {
		get {
			if(preferredAgentQueueId == null) {
				preferredAgentQueueId = QM__c.getOrgDefaults().PreferredAgentQueueId__c;
			}
			return preferredAgentQueueId;
		}
		private set;
	}

	/*
	 * Creates a new instance of the utility to facilitate dependency injection for mocking
	 * @return the new instance
	 */
	public static CaseSkillBasedRoutingModule newInstance() {
		return (CaseSkillBasedRoutingModule)Application.Utilities.newInstance(CaseSkillBasedRoutingModule.class);
	}
	
	// Constructor
	public CaseSkillBasedRoutingModule() {
		// Setup which triggers this module should respond to
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();		
	}
	/**
	 * Called when a new Case is being inserted
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateCustomerQueueType(filterToOnlySSSWCases(records), null , uow);
			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CaseSkillRouting', CaseSkillBasedRoutingModule.class.getName(), 'onBeforeInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	/**
	 * Called when a Case is being updated.
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			populateCustomerQueueType(filterToOnlySSSWCases(records), existingRecords, uow);
			assignToPreferredAgent(filterToOnlySSSWCases(records), existingRecords, uow);
			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CaseSkillRouting', CaseSkillBasedRoutingModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method manually generates a PendingServiceRouting record to route a Case directly to an agent.
	 * It is done for Cases being routed to a Queue with a Routing Configuration (referred to as an Omni Queue), and the Case has an accepted AgentWork.
	 * Cases are moved to a Queue without a Routing Configuration to allow PendingServiceRouting to be inserted and not overridden by Salesforce.
	 * As part of manually generating a PendingServiceRouting record, existing ones for respective Cases are deleted. 
	 * 
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void assignToPreferredAgent(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		
		Map<Id,Id> caseIdsToAcceptedAgentWorkUserId = OmniChannelService.getInstance().getUserIdsFromLatestAcceptedAgentWork(existingRecords.keySet());

		Map<Id, Case> processable = new Map<Id, Case>(); 	

		for (Case csRec : (List<Case>) records) {

			Case oldCase = existingRecords != null ? (Case)existingRecords.get(csRec.Id) : null;	

			if(oldCase != null 
				&& String.isEmpty(preferredAgentQueueId) == false 
				&& Application.Cache.queuesWithRoutingConfig.containsKey(oldCase.OwnerId) == false 
				&& Application.Cache.queuesWithRoutingConfig.containsKey(csRec.OwnerId) == true 
				&& caseIdsToAcceptedAgentWorkUserId.containsKey(csRec.Id) //TODO add logic that checks the User in AgentWork is Active
			){
				processable.put(csRec.Id, csRec);
			}
		}

		if(processable.isEmpty() == false) {

			Map<Id, PendingServiceRouting> casePsrRecords = new Map<Id, PendingServiceRouting>();			
			List<PendingServiceRouting> deletablePsrRecords = new List<PendingServiceRouting>();
			Set<Id> excludedManualPsrCreation = new Set<Id>();

			List<PendingServiceRouting> psrRecords = PendingServiceRoutingSelector.newInstance().selectByWorkItemId(processable.keySet(), new Set<Object>());

			// check which psr records can actually deleted
			// we only want to do that if it hasn't already been pushed.
			// if it has been pushed then it's too late for us to do anything about and we need to let Omni do it's thing
			// we also exclude these from manual record creation
			for(PendingServiceRouting psrRecord : psrRecords) {
				if(psrRecord.IsPushed == false
					&& psrRecord.IsPushAttempted == false) {
					deletablePsrRecords.add(psrRecord);
				} else {
					excludedManualPsrCreation.add(psrRecord.WorkItemId);
				}
			}

			ServiceChannel sc = Application.Cache.serviceChannels.get('Case_Channel');

			for(Case csRec : processable.values()) {
				if(excludedManualPsrCreation.contains(csRec.Id) == false) {

					
					//use the routing configuration of the Omni queue the Case was being routed to
					QueueRoutingConfig routingConfiguration = Application.Cache.queuesWithRoutingConfig.get(csRec.OwnerId).routingConfiguration; 
					
					csRec.OwnerId = preferredAgentQueueId;

					//PushTimeout cannot be set when IsPreferredUserRequired is set
					casePsrRecords.put(csRec.Id, new PendingServiceRouting(
						PreferredUserId = caseIdsToAcceptedAgentWorkUserId.get(csRec.Id),
						IsPreferredUserRequired = true,
						CapacityPercentage = routingConfiguration.CapacityPercentage, 
						CapacityWeight = routingConfiguration.CapacityWeight, 
						DropAdditionalSkillsTimeout = routingConfiguration.DropAdditionalSkillsTimeout,
						RoutingModel = routingConfiguration.RoutingModel, 
						RoutingPriority = routingConfiguration.RoutingPriority, 
						CustomRequestedDateTime = csRec.CreatedDate, 
						WorkItemId = csRec.Id,
						IsReadyForRouting = true,
						RoutingType = 'SkillsBased', 
						ServiceChannelId = sc.Id,
						SecondaryRoutingPriority = secondaryPriorityMappings.get(csRec.Priority) //TODO:.... map from Service Channel config... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
					));
				}
			}

			// remove all existing psr records for the work items here since we are creating new ones
			if(!deletablePsrRecords.isEmpty()) {
				uow.registerDeleted(deletablePsrRecords);
			}

			if(casePsrRecords.isEmpty() == false) {
				uow.registerNew(casePsrRecords.values());
			}
		}

	}

	/*
	 * This method populates the Case field CustomerQueueType based on the Case Contact's Account.
	 * 
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void populateCustomerQueueType(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		
		Set<Id> contactIds = new Set<Id>();
		List<Case> caseToProcess = new List<Case>();
		

		for (Case cs : (List<Case>) records) {

			if(existingRecords == null || 
				(existingRecords.isEmpty() == false &&
					cs.ContactId != ((Case)existingRecords.get(cs.Id)).ContactId)
			){					
				
				caseToProcess.add(cs);	  
				if(cs.ContactId != null){
					contactIds.add(cs.ContactId);  
				}					 
			}			
		}

		if(caseToProcess.isEmpty() == false){
			
			Map<Id, Contact> contactsMap = new Map<Id, Contact>();
			if(contactIds.isEmpty() == false){
				contactsMap = ContactsSelector.newInstance().selectById(contactIds, new Set<Object>{ContactsSelector.Options.WITH_ACCOUNT});
			} 

			for(Case cs : caseToProcess){
				Contact contact = contactsMap.get(cs.ContactId);
				cs.CustomerQueueType__c = (contact != null && contact.Account != null && String.isEmpty(contact.Account.ServiceSLA__c) == false)  ? contact.Account.ServiceSLA__c : SERVICESLA_CONSUMER;				
			}
		}
	}

	/*
	 * This method returns a list of Case records that are related to SSSW
	 * 
	 * @param caseRecords the list of Cases to filter to SSSW only
	 */
	private List<SObject> filterToOnlySSSWCases(List<SObject> caseRecords){
		if(validRecTypes == null){
			validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		}
		
		List<SObject> ssswCases = new List<SObject>();
		
		for (Case c : (List<Case>) caseRecords) {
			if(Utility.isValidRecordType(validRecTypes,c.RecordTypeId)){
				ssswCases.add(c);				
			}				
		}

		return ssswCases;
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) CaseSkillBasedRoutingModule.newInstance();
		}
	}

}