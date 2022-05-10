/**
 * @description
 * Domain Module to handle the service delivery case related functionality in email message
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * TODO: Eventually we should try and refactor this into a module non specific to Service Advisors so we can make better use of the Case_Entitlements__mdt metadata
 *
 * @author Ashapriya Gadi
 * @date 2021-11-22
 * @group Domain
 * @domain EmailMessage
 * @changelog
 * 2022-02-04 Ashapriya Gadi To fix prod issue -If some sends an email to one of the email-to-case email addresses, but puts multiple recipients on the email (From Email Address), the entitlement does not get assigned to the case
 * 2022-02-16 - Nathan Franklin - Small refactor and fixed bugs
 */
public inherited sharing class ServiceAdvisorEmailMesEntitlementsModule extends ApplicationDomain.Module {
	
	public static ServiceAdvisorEmailMesEntitlementsModule newInstance() {
		return (ServiceAdvisorEmailMesEntitlementsModule)Application.Utilities.newInstance(ServiceAdvisorEmailMesEntitlementsModule.class);
	}
	
	// Setup which triggers this module should respond to
	public ServiceAdvisorEmailMesEntitlementsModule() {
		getTriggerEvents().enableAfterInsert();
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

		//Map to store relevant case id and a list of corresponding ToAddress, CcAddress and BccAddress
		Map<String, List<String>> caseIdToAllEmailIdsMap = new Map<String, List<String>>();

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

		//collection of case to its metadata
		Map<Id,Case_Entitlements__mdt> caseToEntitlementMap = new Map<Id,Case_Entitlements__mdt>();
		
		//Collect all the case Ids from the list of incoming email messages
		for (EmailMessage em :  (List<EmailMessage>)newEmails ) {
			if(em.Incoming && em.ParentId.getSobjectType() == Case.SObjectType){//first check is to make sure it is incoming email and second check is to make sure the parent is case
				casesSet.add(em.ParentId);
				emailMessageIdSet.add(em.Id);
			}
		}
		
		if(!casesSet.isEmpty() && !emailMessageIdSet.isEmpty()) {
			// fetch Id of the System Support user from the Custom Setting
			ConfigSetting__c configSetting = ConfigSetting__c.getInstance();
			String systemSupportUserId = configSetting.AutomatedCaseUser__c;
			
			// Grab the cases and their associated first incoming email message to check whether the incoming email messages are the first one attached to the case
			//  If it is, then we treat this as a new case and therefore the entitlement needs to be added
			for(Case cs : ServiceAdvisorsCasesSelector.newInstance(0,new Set<SObjectField>{Case.Id, Case.EntitlementId, Case.BusinessHoursId})
								.selectByIdsAndEntitlementIdAndCreatedBy(casesSet, null, systemSupportUserId,new Set<Object>{CasesSelector.Options.WITH_SINGLE_EMAIL_MESSAGES_ASC_ORDER, EmailMessagesSelector.Options.FILTER_INCOMING})){

				if(!cs.EmailMessages.isEmpty()) {
					if(emailMessageIdSet.contains(cs.EmailMessages[0].Id)) {
						//to fix cc/bcc multiple emailaddresses in a single incoming email issue
						caseIdToAllEmailIdsMap.put(cs.Id, processEmailIds(cs.EmailMessages[0].ToAddress,cs.EmailMessages[0].CcAddress,cs.EmailMessages[0].BccAddress));
					}
				}
			}
			
			if(!caseIdToAllEmailIdsMap.isEmpty()) {
				//fetch all the Case Entitlements Metadata using getAll() method
				// These hold the information relating to which entitlement to assign
				for (Case_Entitlements__mdt caseEntitlement : Case_Entitlements__mdt.getAll().values()) {
					caseEntitlementsMap.put(caseEntitlement.MasterLabel, caseEntitlement);
				}

				if (!caseEntitlementsMap.isEmpty()) {
					//iterate through all cases and its list of emails(to,cc) to see if any of the emails is email-to-case(it has to be in the custommetadata) and if its present, then store the mdt record with case id as key
					for (Id caseId : caseIdToAllEmailIdsMap.keySet()) {
						for (String email : caseIdToAllEmailIdsMap.get(caseId)) {
							if (caseEntitlementsMap.keySet().contains(email.trim())) { //if the email is present in the custom metadata
								//then populate below map and sets accordingly
								entitlementNameSet.add(caseEntitlementsMap.get(email.trim()).Entitlement_Process__c);
								businessHoursNameSet.add(caseEntitlementsMap.get(email.trim()).Business_Hours__c);
								caseToEntitlementMap.put(caseId, caseEntitlementsMap.get(email.trim()));//on a case,if there are to,cc emails as the email-to-case emails, only one emailtocase email's related entitlements will be stored in this map; we cant assign multiple entitlement or business hrs to a single case anyway

								// once we find a match in the entitlement metadata mappings, then we don't need to continue any further
								break;
							} else {
								// the email is not present in the custom metadata and since all service delivery email-to-case emails are present in the custom
								//metadata and not finding one would mean that the email must have come in BCC. So for Bcc, default entitlement to VIC

								//set default entitlement and business hours
								entitlementNameSet.add(BGSConstants.BGS_ENTITLEMENT_VIC);
								businessHoursNameSet.add(BGSConstants.BGS_BUSINESSHOUR_VIC);
								//put null in the map across the case id, to assign defaults later on
								caseToEntitlementMap.put(caseId, null);
							}
						}
					}
				}
			}

			if (!caseToEntitlementMap.isEmpty()) {

				//fetch the entitlement Id(will be used to update entitlementid field on Case) based on entitlement names
				//
				if (!entitlementNameSet.isEmpty()) {
					for (Entitlement e : EntitlementsSelector.newInstance().selectByNameAndAccountName(entitlementNameSet, new Set<String>{BGSConstants.BGS_ENTITLEMENT_STANDARD})) {
						entitlementNameToIdMap.put(e.Name, e.Id);
					}
				}

				//fetch the BusinessHours Id(will be used to update BusinessHoursId field on Case) based on BusinessHours names
				if (!businessHoursNameSet.isEmpty()) {
					for (BusinessHours b : BusinessHoursSelector.newInstance().selectByName(businessHoursNameSet)) {
						businessHoursNameToIdMap.put(b.Name, b.Id);
					}
				}

				//assign entitlementid and businesshours to case records based on above maps
				if(!entitlementNameToIdMap.isEmpty()) {
					for (String caseId : caseIdToAllEmailIdsMap.keySet()) {
						Case c = new Case(Id=caseId);
						if(caseToEntitlementMap.get(caseId) != null) {
							//if the caseentitlement mdt record is not null, then assign its respective values
							c.EntitlementId = entitlementNameToIdMap.get(caseToEntitlementMap.get(caseId).Entitlement_Process__c);
							c.BusinessHoursId = businessHoursNameToIdMap.get(caseToEntitlementMap.get(caseId).Business_Hours__c);
						} else {
							// if the caseentitlement mdt record is null, then assign default to VIC
							c.EntitlementId = entitlementNameToIdMap.get(BGSConstants.BGS_ENTITLEMENT_VIC);
							c.BusinessHoursId = businessHoursNameToIdMap.get(BGSConstants.BGS_BUSINESSHOUR_VIC);
						}
						casesToUpdate.add(c);
					}
				}
			}
		}

		if(!casesToUpdate.isEmpty()){
			//register the cases to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
			uow.registerDirty(casesToUpdate, false, 'ServiceAdvisorEmailMesEntitlementsModule.assignEntitlements');
		}
	
	}

	//This method is used to split the incoming To, cc and bcc email addresses and add them to one list
	private static List<String> processEmailIds(String toAdd, String ccAdd, String bccAdd){
		List<String> allEmailList = new List<String>();
		if(String.isNotBlank(toAdd)){
			allEmailList.addAll(toAdd.split(';'));
		}
		if(String.isNotBlank(ccAdd)){
			allEmailList.addAll(ccAdd.split(';'));
		}
		if(String.isNotBlank(bccAdd)){
			allEmailList.addAll(bccAdd.split(';'));
		}
		return allEmailList;
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