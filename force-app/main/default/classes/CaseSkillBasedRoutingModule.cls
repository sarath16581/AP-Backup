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
 * 2022-02-01 - Noel Lim - update assignToPreferredAgent, remove criteria that checks if case is from an omni queue
 */

public inherited sharing class CaseSkillBasedRoutingModule extends ApplicationDomain.Module  {
	
	public static final String SERVICESLA_CONSUMER = 'Consumer';

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
	
	private Set<Id> ssswRecordTypeIds {
		get {
			if(ssswRecordTypeIds == null){
				ssswRecordTypeIds =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			}
			return ssswRecordTypeIds;
		}
		private set;
	}

	/*
	 * This method returns a list of Case records that are related to SSSW
	 * 
	 * NOTE: 
	 * 
	 * Ideally this should be in MyCustomerCasesDomain where it gets filtered. However, we need to do it here because MyCustomerCasesDomain is in the CaseTriggerHandler2. 
	 * Order of execution: CaseTriggerHandler2 >> CaseTriggerHandler (legacy code) >> CaseTriggerHandler3
	 * 
	 * @param caseRecords the list of Cases to filter to SSSW only
	 */
	private List<Case> getSSSWCasesOnly(List<Case> records){
		List<Case> result = new List<Case>();
		
		for (Case c : records) {
			if(ssswRecordTypeIds.contains(c.RecordTypeId) == true){
				result.add(c);				
			}				
		}

		return result;
	}

	/**
	 * Called when a new Case is being inserted
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<Case> ssswCasesOnly = getSSSWCasesOnly((List<Case>)records);
			populateCustomerQueueType(ssswCasesOnly, null , uow);
			
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
			List<Case> ssswCasesOnly = getSSSWCasesOnly((List<Case>)records);
			populateCustomerQueueType(ssswCasesOnly, (Map<Id, Case>)existingRecords, uow);
			assignToPreferredAgent(ssswCasesOnly, (Map<Id, Case>)existingRecords, uow);
			
			resetBypassPreferredAgentFlag((List<Case>)records, (Map<Id, Case>)existingRecords, uow);

		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CaseSkillRouting', CaseSkillBasedRoutingModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method resets the Bypass Preferred Agent flag on the case if the owner on the case changed from a Queue to a User. 
	 */
	private void resetBypassPreferredAgentFlag(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
		for(Case c: records) {
			if(c.OwnerId.getSobjectType() == User.getSObjectType() && existingRecords.get(c.Id).OwnerId.getSobjectType() == Group.getSobjectType()) {
				c.BypassPreferredAgent__c = false;
			}
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
	private void assignToPreferredAgent(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
		
		Id preferredAgentQueueId = OmniChannelService.getInstance().preferredAgentQueueId;
		if(String.isEmpty(preferredAgentQueueId) == false ) {

			Map<Id, Case> validCases = new Map<Id, Case>(); 	

			for (Case c : records) {

				Case oldCase = existingRecords?.get(c.Id);	

				if(c.BypassPreferredAgent__c == false 
					&& oldCase != null 
					&& c.OwnerId != oldCase.OwnerId
					&& c.PreferredAgentExpiry__c != null // this is set by the routing engine
					&& OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(c.OwnerId) == true // omni queue check
				){
					validCases.put(c.Id, c);
				}
			}

			if(validCases.isEmpty() == false) {
				
				Map<Id, AgentWork> caseIdsVsAgentWorks = OmniChannelService.getInstance().getLatestAcceptedAgentWorkWithActiveUser(validCases.keySet());

				if(caseIdsVsAgentWorks.isEmpty() == false) {

					ServiceChannel sc = OmniChannelService.Cache.serviceChannels.get('Case_Channel');
					List<PendingServiceRouting> newPSRs = new List<PendingServiceRouting>();			

					for(Case csRec : validCases.values()) {
						if(caseIdsVsAgentWorks.containsKey(csRec.Id) == true) {
							
							//use the routing configuration of the Omni queue the Case was being routed to
							QueueRoutingConfig routingConfiguration = OmniChannelService.Cache.queuesWithRoutingConfig.get(csRec.OwnerId).routingConfiguration; 
							
							csRec.OwnerId = preferredAgentQueueId;

							//PushTimeout cannot be set when IsPreferredUserRequired is set
							newPSRs.add(new PendingServiceRouting(
								PreferredUserId = caseIdsVsAgentWorks.get(csRec.Id).UserId,
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
								SecondaryRoutingPriority = OmniChannelService.getInstance().priorityMappingToSecondaryPriorityRange.get(csRec.Priority) //TODO:.... map from Service Channel config... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
							));
						}
					}

					if(newPSRs.isEmpty() == false) {
						uow.registerNew(newPSRs);
					}
				}
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

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) CaseSkillBasedRoutingModule.newInstance();
		}
	}

}