/**
 * @description
 * Domain Module to create/update task related to the account manager of the campaign
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Mathew Jose
 * @date 2022-01-15
 * @group Domain
 * @domain CampaignMembersDomain
 * @changelog
 */
public inherited sharing class CampaignMemberSurveysModule extends ApplicationDomain.Module {
	public static CampaignMemberSurveysModule newInstance() {
		return (CampaignMemberSurveysModule)Application.Utilities.newInstance(CampaignMemberSurveysModule.class);
	}
	
	// Setup which triggers this module should respond to
	public CampaignMemberSurveysModule() {
		getTriggerEvents().enableAfterUpdate().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			System.debug('CampaignMemberSurveysModule:onAfterInsert');
			removeCampaignContactAssignment(records, null, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), CampaignContactAssignmentConstants.APP_NAME, CampaignMemberSurveysModule.class.getName(), 'onAfterUpdate', CampaignContactAssignmentConstants.TRIGGER_NAME, LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			System.debug('CampaignMemberSurveysModule:onAfterUpdate');
			removeCampaignContactAssignment(records, (Map<Id, CampaignMember>)existingRecords, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), CampaignContactAssignmentConstants.APP_NAME, CampaignMemberSurveysModule.class.getName(), 'onAfterUpdate', CampaignContactAssignmentConstants.TRIGGER_NAME, LoggingLevel.ERROR);
		}
	} 

	/**
	 * Remove contact assignment if the campaign member status is updated to status cancelled / removed.
	 * This will allow another Contact to be assigned to the Campaign via the Campaign Contact Assignments object (through the lightning ui)
	 *
	 * @param records  list of new records.
	 * @param existingRecords  Trigger.oldMap.
	 */
	public void removeCampaignContactAssignment(List<CampaignMember> records, Map<Id, CampaignMember> existingRecords, ApplicationUnitOfWork uow) {        
        System.debug('Entered removeCampaignContactAssignment');

		Boolean isInsert = false;
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();
		if(existingRecords == null || existingRecords.isEmpty()) {
			isInsert = true;
		} else {
			// confirm whether or not the tracked fields have changed values fields
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{CampaignMember.Status});
		}

		Set<Id> campaignIds = new Set<Id>();
		Set<Id> contactIds = new Set<Id>();

        //get campaign contact assignments associated with the changed campaign members.
        for(CampaignMember campaignMemberRecord : records){
            Set<SObjectField> changed = changedRecords.get(campaignMemberRecord.Id);
            if(changed == null) changed = new Set<SObjectField>();

            // Check if status changed and campaign member is marked as Changed Contact.
	        // If so, then we need to grab the corresponding CampaignContactAssignment__c record to nullify the ContactId value on it
	        // This will allow another ContactId to be selected through the Campaign Contact Assignment UI
            if (campaignMemberRecord.ContactId != null && CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED.equalsIgnoreCase(campaignMemberRecord.Status) && (isInsert || changed.contains(CampaignMember.Status))) {

	            // get the campaign and contact ids in order to fetch the campaign contact assignments.
	            campaignIds.add(campaignMemberRecord.CampaignId);
	            contactIds.add(campaignMemberRecord.ContactId);

            }            
        }

		List<CampaignContactAssignment__c> campaignContactAssignments = new List<CampaignContactAssignment__c>();
		if(!campaignIds.isEmpty() && !contactIds.isEmpty()) {
			List<CampaignContactAssignment__c> updateable = new List<CampaignContactAssignment__c>();

			campaignContactAssignments = CampaignContactAssignmentsSelector.newInstance().selectByCampaignAndContact(campaignIds, contactIds, new Set<Object>{});

			if(!campaignContactAssignments.isEmpty()){
				for(CampaignContactAssignment__c contactAssignmentRecord : campaignContactAssignments){
					//Remove the contact assignment so the user can choose another contact for the respective organisation.
					updateable.add(new CampaignContactAssignment__c(Id = contactAssignmentRecord.Id, Contact__c = null));
				}

				//register the campaigncontactAssignment__c to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
				uow.registerDirty(updateable);
			}
		}
    }

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) CampaignMemberSurveysModule.newInstance();
		}
	}    

}