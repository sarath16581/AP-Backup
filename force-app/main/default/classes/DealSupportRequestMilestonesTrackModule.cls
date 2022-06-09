/**
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author: Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date: 2022-06-02
 * @domain: DealSupportRequestGenericDomain
 * @description: Module class to process a business logic when Implementation stage is update on DSR record..
 * @change log:
 * 2022-06-02 - Dattaraj Deshmukh - created 
 */


public with sharing class DealSupportRequestMilestonesTrackModule extends ApplicationDomain.Module{
	static final String BUSINESS_HOURS_NAME = 'Service Delivery VIC';

    public static DealSupportRequestMilestonesTrackModule newInstance() {
		return (DealSupportRequestMilestonesTrackModule)Application.Utilities.newInstance(DealSupportRequestMilestonesTrackModule.class);
	}
	
	// Setup which triggers this module should respond to
	public DealSupportRequestMilestonesTrackModule() {
		getTriggerEvents().enableAfterUpdate().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records,  ApplicationUnitOfWork uow){
		try {
			updateImplementationStageTimestamp((List<Deal_Support_Request__c>)records, null);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(),'DealSupportRequestTriggerHandler2', 'DealSupportRequestMilestonesTrackModule', 'onBeforeInsert', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
		}
	}
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		try {
			updateImplementationStageTimestamp((List<Deal_Support_Request__c>)records, (Map<Id,Deal_Support_Request__c>)existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(),'DealSupportRequestTriggerHandler2', 'DealSupportRequestMilestonesTrackModule', 'onBeforeUpdate', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
		}
	}
	/**
	 * called after DSR record is updated.
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
            trackDealSupportRequestMilestones((List<Deal_Support_Request__c>)records, (Map<Id,Deal_Support_Request__c>)existingRecords, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(),'DealSupportRequestTriggerHandler2', 'DealSupportRequestMilestonesTrackModule', 'onAfterUpdate', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
		}
	}

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) DealSupportRequestMilestonesTrackModule.newInstance();
		}
	}


	@testVisible
	private void updateImplementationStageTimestamp(List<Deal_Support_Request__c> newRecords, Map<Id, Deal_Support_Request__c> existingRecords){
		for(Deal_Support_Request__c dsr: newRecords){
			
			//check if method is called for before insert trigger.
			if(existingRecords == null){
				if(dsr.Implementation_Stage__c != null){
					dsr.Last_Implementation_Stage_Update__c = System.now();
				}
			}
			else{
				//if Implementation_Stage__c value is changed then record timestamp.
				//all other updates are bypassed.
				if(existingRecords.get(dsr.id).Implementation_Stage__c != dsr.Implementation_Stage__c){
					dsr.Last_Implementation_Stage_Update__c = System.now();
				}
			}
		}
	}

	@testVisible
	private void trackDealSupportRequestMilestones(List<Deal_Support_Request__c> newDSRList, Map<Id, Deal_Support_Request__c> oldDSRMap,
														ApplicationUnitOfWork uow){
		Map<Id,Deal_Support_Request__c> IdVsDSRlistWithImplementationStageUpdated = new Map<Id,Deal_Support_Request__c>();

            for(Deal_Support_Request__c dsr: newDSRList){
                //checking if Implementation_Stage__c value is changed or not.
                //all other updates are bypassed.
                if(oldDSRMap.get(dsr.id).Implementation_Stage__c != dsr.Implementation_Stage__c){
                    IdVsDSRlistWithImplementationStageUpdated.put(dsr.Id, dsr);
                }
            }

            if(IdVsDSRlistWithImplementationStageUpdated.isEmpty()){
                return;
            }

            //storing DSR ID vs Existing milestones records
            Map<Id, List<DealSupportRequestMilestones__c>> DSRIdsVsDSRMilestones = new Map<Id, List<DealSupportRequestMilestones__c>>();
            
            //map to store dsr id vs set of strings (implementation stage values).
            //This map avoids looping through existing milestones to determine creation of new Milestone based on implementation stage.
            Map<Id, Set<String>> DSRIdsVsExistingMilestoneStages = new Map<Id, Set<String>>();


            //collection to update and create new DSR Milestone records
            List<DealSupportRequestMilestones__c> dsrMilestonesToUpdate = new List<DealSupportRequestMilestones__c>();
            List<DealSupportRequestMilestones__c> newMilestoneRecordsToCreate = new List<DealSupportRequestMilestones__c>();

            //Business Hours
            List<BusinessHours> businessHrs = BusinessHoursSelector.newInstance().selectByName(new Set<String>{BUSINESS_HOURS_NAME});

            //setting list of milestones for each DSR record.
            for(Id DSRId : IdVsDSRlistWithImplementationStageUpdated.keySet()){
                DSRIdsVsDSRMilestones.put(dsrId, new List<DealSupportRequestMilestones__c>());
                DSRIdsVsExistingMilestoneStages.put(dsrId, new Set<String>());
            }

            for(DealSupportRequestMilestones__c dsrMilestones : DealSupportRequestMilestonesSelector.newInstance().
                                                    selectByDSRId(IdVsDSRlistWithImplementationStageUpdated.keySet(), new Set<Object>{DealSupportRequestMilestonesSelector.Options.WITH_RECORDTYPE, DealSupportRequestMilestonesSelector.Options.WITH_DEAL_SUPPORT_REQUEST }).values()){
				
                //populating existing dsr milestones for each DSR    
                if(DSRIdsVsDSRMilestones.containsKey(dsrMilestones.Deal_Support_Request__c)){
                    DSRIdsVsDSRMilestones.get(dsrMilestones.Deal_Support_Request__c).add(dsrMilestones);
                    DSRIdsVsExistingMilestoneStages.get(dsrMilestones.Deal_Support_Request__c).add(dsrMilestones.Stage__c);
                }
            }


            for(Deal_Support_Request__c newDSR : IdVsDSRlistWithImplementationStageUpdated.values()){

                //check if Milestone record exists for updated implementation stage.
                if(DSRIdsVsExistingMilestoneStages.get(newDSR.Id).contains(oldDSRMap.get(newDSR.Id).Implementation_Stage__c)){
                    for(DealSupportRequestMilestones__c dsrMilestones : DSRIdsVsDSRMilestones.get(newDSR.Id)){

                        if(dsrMilestones.Stage__c == oldDSRMap.get(dsrMilestones.Deal_Support_Request__c).Implementation_Stage__c){
                            DateTime businessHrsStartDate = oldDSRMap.get(newDSR.Id).Last_Implementation_Stage_Update__c != null ? oldDSRMap.get(newDSR.Id).Last_Implementation_Stage_Update__c : oldDSRMap.get(newDSR.Id).CreatedDate;
                            DealSupportRequestMilestones__c dsrMilestoneRecordToUpdate = new DealSupportRequestMilestones__c();
							dsrMilestoneRecordToUpdate.Id = dsrMilestones.Id;
							dsrMilestoneRecordToUpdate.Time_in_minutes__c = dsrMilestones.Time_in_minutes__c + BusinessHours.diff(businessHrs[0].Id, businessHrsStartDate , System.now())/(1000*60);
							
							dsrMilestonesToUpdate.add(dsrMilestoneRecordToUpdate);
                        }
                    }
                }
                else{
                    //create a new Milestone record.
                    DealSupportRequestMilestones__c newMilestoneRecord = new DealSupportRequestMilestones__c();
                    newMilestoneRecord.Deal_Support_Request__c = newDSR.Id;

					//checking stage value as different record types may not have stage value populated for OLD records.
					//If null checks are not done then Deal Support Milestone will be created without stage value.
					if(oldDSRMap.get(newDSR.Id).Implementation_Stage__c != null){
						newMilestoneRecord.Stage__c = oldDSRMap.get(newDSR.Id).Implementation_Stage__c;
						DateTime businessHrsStartDate = oldDSRMap.get(newDSR.Id).Last_Implementation_Stage_Update__c != null ? oldDSRMap.get(newDSR.Id).Last_Implementation_Stage_Update__c : oldDSRMap.get(newDSR.Id).CreatedDate;
						newMilestoneRecord.Time_in_minutes__c = BusinessHours.diff(businessHrs[0].Id, businessHrsStartDate, System.now())/(1000*60);

						newMilestoneRecordsToCreate.add(newMilestoneRecord);
					}
                    
                }
            }

            if(!dsrMilestonesToUpdate.isEmpty()){
				uow.registerDirty(dsrMilestonesToUpdate, true, 'DealSupportRequestMilestonesTrackModule');
            }
            if(!newMilestoneRecordsToCreate.isEmpty()){
				uow.registerNew(newMilestoneRecordsToCreate);
            }
	}

	

}