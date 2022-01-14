/**
 * @description
 * Domain Module to handle the service delivery case related functionality in email message
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Ashapriya Gadi
 * @date 2021-11-22
 * @group Domain
 * @domain EmailMessage
 * @changelog
 */

public inherited sharing class ServiceAdvisorEmailMesEntitlementsModule extends ApplicationDomain.Module {
	
	public static ServiceAdvisorEmailMesEntitlementsModule newInstance() {
		return (ServiceAdvisorEmailMesEntitlementsModule)Application.Utilities.newInstance(ServiceAdvisorEmailMesEntitlementsModule.class);
	}
	
	// Setup which triggers this module should respond to
	public ServiceAdvisorEmailMesEntitlementsModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate().enableAfterUpdate();
	}
	/**
	 * Called when a new Case is being inserted, calls createInitialCaller which will create related authorised contact
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			assignEntitlements(records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), BGSConstants.SERVICE_DELIVERY_NAME, ServiceAdvisorEmailMesEntitlementsModule.class.getName(), 'onAfterInsert', BGSConstants.EMAILMESSAGE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	// SMWD-312 - MW0004779 - Assign the correct entitlement process and business hours record to the case
	public static void assignEntitlements(List<SObject> newEmails,ApplicationUnitOfWork uow) {
		
		//Set to store emailmessage's parent id(case)
		Set<Id> casesSet = new Set<Id>();
		//Set to store emailmessage's id
		Set<Id> emailMessageIdSet = new Set<Id>();
		//Map to store relevant case id and ToAddress
		Map<String, String> caseIdToEmailMap = new Map<String, String>();
		//Map to store the custom metadata related to the filtered entitlements
		Map<String,Case_Entitlements__mdt> caseEntitlementsMap = new Map<String,Case_Entitlements__mdt>();
		//set to store the unique entitlements corresponding to the email address
		Set<String> entitlementNameSet = new Set<String>();
		//set to store the unique business hours corresponding to the email address
		Set<String> businessHoursNameSet = new Set<String>();
		//Map to store entitlment name to its Id
		Map<String,String> entitlementNameToIdMap = new Map<String,String>();
		//Map to store businesshour name to its Id
		Map<String,String> businessHoursNameToIdMap = new Map<String,String>();
		//final case list to update
		List<Case> casesToUpdate = new List<Case>();
		//Collect all the case Ids from the list of incoming email messages
		for (EmailMessage em :  (List<EmailMessage>)newEmails ) {
			if(em.Incoming && em.ParentId.getSObjectType() == Case.sObjectType){//first check is to make sure it is incoming email and second check is to make sure the parent is case
				casesSet.add(em.parentId);
				emailMessageIdSet.add(em.Id);
			}
		}
		if(!casesSet.isEmpty() && !emailMessageIdSet.isEmpty()) {
			// fetch Id of the System Support user from the Custom Setting
			ConfigSetting__c configSetting = ConfigSetting__c.getInstance();
			string systemSupportUserId = configSetting.AutomatedCaseUser__c;
			//query for service delivery cases createdby system support user(that means they are created from EmailtoCase) with no entitlement, along with child emailmessages ordered in ascending order as our focus is only on the first email attached to the case, not the subsequent ones
			for(case cs : ServiceAdvisorsCasesSelector.newInstance(0,new Set<SObjectField>{Case.Id, Case.EntitlementId, Case.BusinessHoursId}).selectByIdsAndEntitlementIdAndCreatedBy(casesSet, null, systemSupportUserId,new Set<Object>{CasesSelector.Options.WITH_SINGLE_EMAIL_MESSAGE_ASC_ORDER})){
				if(!cs.EmailMessages.isEmpty()){
					for(EmailMessage em : cs.EmailMessages){//here we will recieve multiple emails as limit 1 is removed from the subquery
						if(emailMessageIdSet.contains(em.id)){ // this is to facilitate where id in: emailMessageIdSet
							if(!caseIdToEmailMap.keySet().contains(cs.id))// if we get multiple incoming emails from the query, we are only concerned about the first one. So if first one is alredy put in the map, then ignore the rest of them
								caseIdToEmailMap.put(cs.id,em.ToAddress);
						}
					}
				}
			}
			if(!caseIdToEmailMap.isEmpty()) {
				//fetch all the Case Entitlements Metadata using getAll() method
				for (Case_Entitlements__mdt caseEntitlement : Case_Entitlements__mdt.getAll().values() ){
					//if the case entitlement metadata record's MasterLabel(toemailaddress) is present in all the email address values from caseIdToEmailMap
					if(caseIdToEmailMap.values().contains(caseEntitlement.MasterLabel)) {
						//then populate below map and sets accordingly
						caseEntitlementsMap.put(caseEntitlement.MasterLabel, caseEntitlement);
						entitlementNameSet.add(caseEntitlement.Entitlement_Process__c);
						businessHoursNameSet.add(caseEntitlement.Business_Hours__c);
					}
				}
				if (!caseEntitlementsMap.isEmpty()) {
					if (!entitlementNameSet.isEmpty()) {
						//fetch the entitlement Id(will be used to update entitlementid field on Case) based on entitlement names
						for (Entitlement e : EntitlementsSelector.newInstance().selectByName(entitlementNameSet)) {
							entitlementNameToIdMap.put(e.Name, e.Id);
						}
					}
					if (!businessHoursNameSet.isEmpty()) {
						//fetch the BusinessHours Id(will be used to update BusinessHoursId field on Case) based on BusinessHours names
						for (BusinessHours b : BusinessHoursSelector.newInstance().selectByName(businessHoursNameSet)) {
							businessHoursNameToIdMap.put(b.Name, b.Id);
						}
					}
					//assign entitlementid and businesshours to case records based on above maps
					if(!entitlementNameToIdMap.isEmpty()) {
						for (String csId : caseIdToEmailMap.keyset()) {
							case c = new case(id=csId);
							c.EntitlementId = entitlementNameToIdMap.get(caseEntitlementsMap.get(caseIdToEmailMap.get(csId)).Entitlement_Process__c);
							c.BusinessHoursId = businessHoursNameToIdMap.get(caseEntitlementsMap.get(caseIdToEmailMap.get(csId)).Business_Hours__c);
							casesToUpdate.add(c);
						}
					}
				
				}
			}
		
		}
		system.debug('casesToUpdate> ' + casesToUpdate);
		if(!casesToUpdate.isEmpty()){
			//register the cases to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
			uow.registerDirty(casesToUpdate);
		}
	
	}
	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ServiceAdvisorEmailMesEntitlementsModule.newInstance();
		}
	}
}