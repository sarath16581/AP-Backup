/*** 
 * @description
 * Domain Module to update Case fields that are used in Omni Skills Routing. Only SSSW Cases are processed.
 * a) Stamp CustomerQueueType__c field. In isBefore so it is available for OTB Omni Skills routing 
 * 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-09-20
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-09-20 - Noel Lim		Created
 * 2022-12-06	Noel Lim		Added method populateAgentType
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

	private static Set<Id> allValidRecordTypes{
		get {
			if(allValidRecordTypes == null){
				allValidRecordTypes = new Set<Id>();
				allValidRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet());
			}
			return allValidRecordTypes;
		}
		private set;
	}
	
	/*
	 * This method returns a list of Case records that are related to SSSW
	 * NOTE: Ideally this should be in MyCustomerCasesDomain where it gets filtered. However, we need to do it here because MyCustomerCasesDomain is in the CaseTriggerHandler2. 
	 * Order of execution: CaseTriggerHandler2 >> CaseTriggerHandler (legacy code) >> CaseTriggerHandler3
	 * 
	 * @param caseRecords the list of Cases to filter to SSSW only
	 */
	private List<Case> filterToApplicableCases(List<Case> caseRecords){
		List<Case> filteredCases = new List<Case>();		
		
		for (Case c : caseRecords) {
			if(allValidRecordTypes.contains(c.RecordTypeId)){
				filteredCases.add(c);		
			}				
		}

		return filteredCases;
	}

	/**
	 * Called when a new Case is being inserted
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<Case> ssswCasesOnly = filterToApplicableCases((List<Case>)records);
			populateCustomerQueueType(ssswCasesOnly, null , uow);
			populateAgentType(ssswCasesOnly, null , uow);
			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseSkillBasedRoutingModule.class.getName(), 'onBeforeInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Called when a Case is being updated.
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<Case> ssswCasesOnly = filterToApplicableCases((List<Case>)records);
			populateCustomerQueueType(ssswCasesOnly, (Map<Id, Case>)existingRecords, uow);			
			populateAgentType(ssswCasesOnly, (Map<Id, Case>)existingRecords , uow);

		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseSkillBasedRoutingModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method populates the Case field CustomerQueueType based on the Case Contact's Account.
	 * 
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void populateCustomerQueueType(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
		
		Set<Id> contactIds = new Set<Id>();
		List<Case> caseToProcess = new List<Case>();
		

		for (Case cs : records) {

			if(existingRecords == null || 
				(existingRecords.isEmpty() == false &&
					cs.ContactId != existingRecords.get(cs.Id).ContactId)
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
				Map<SObjectType,Set<SObjectField>> fieldOverrides = new Map<SObjectType,Set<SObjectField>> {
					Contact.SObjectType => new Set<SObjectField> {
						Contact.Id
					},
					Account.SObjectType => new Set<SObjectField> {
						Account.ServiceSLA__c
					}
				};
				contactsMap = ContactsSelector.newInstance(0, fieldOverrides).selectById(contactIds, new Set<Object>{ContactsSelector.Options.WITH_ACCOUNT});
			} 

			for(Case cs : caseToProcess){
				Contact contact = contactsMap.get(cs.ContactId);
				cs.CustomerQueueType__c = (contact != null && contact.Account != null && String.isEmpty(contact.Account.ServiceSLA__c) == false)  ? contact.Account.ServiceSLA__c : SERVICESLA_CONSUMER;				
			}
		}
	}

	/*
	 * This method populates the Case field AgentType based on a custom metadata mapping Queues
	 * 
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void populateAgentType(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){		
		
		for (Case cs : (List<Case>) records) {
			if(existingRecords == null || 
				(existingRecords != null && 
				 cs.OwnerId != existingRecords.get(cs.Id).OwnerId)){
				
				if(OmniChannelService.Cache.queuesToAgentType.containsKey(cs.OwnerId) == true){
					cs.AgentType__c = OmniChannelService.Cache.queuesToAgentType.get(cs.OwnerId);
				} else if(String.isBlank(cs.AgentType__c) == false){
					cs.AgentType__c = null;
				}
				
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