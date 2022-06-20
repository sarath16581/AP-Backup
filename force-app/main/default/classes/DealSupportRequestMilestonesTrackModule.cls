/**
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author: Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date: 2022-06-02
 * @domain: DealSupportRequestGenericDomain
 * @test DealSpprtReqsMilestonesTrackModule_Test
 * @description: Module class to process a business logic when Implementation stage is update on DSR record..
 * @change log:
 * 2022-06-02 - Dattaraj Deshmukh - created 
 */


public with sharing class DealSupportRequestMilestonesTrackModule extends ApplicationDomain.Module{

    public static DealSupportRequestMilestonesTrackModule newInstance() {
		return (DealSupportRequestMilestonesTrackModule)Application.Utilities.newInstance(DealSupportRequestMilestonesTrackModule.class);
	}
	
	// Setup which triggers this module should respond to
	public DealSupportRequestMilestonesTrackModule() {
		getTriggerEvents().enableAfterUpdate().enableBeforeInsert().enableBeforeUpdate();
	}

	/**
    * Called when a new deal support request is being inserted.
    * Checks if Implementation_Stage__c picklist is populated or not and if its populated   
    * then update LastImplementationStageUpdate__c timestamp.
    */
	public override void onBeforeInsert(List<SObject> records,  ApplicationUnitOfWork uow){
		try {
			updateImplementationStageTimestamp((List<Deal_Support_Request__c>)records, null);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(),'DealSupportRequestTriggerHandler2', 'DealSupportRequestMilestonesTrackModule', 'onBeforeInsert', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
		}
	}

	/**
    * Called when a deal support request is being updated.
    * Checks if Implementation_Stage__c picklist is updated or not and if its updated   
    * then update LastImplementationStageUpdate__c timestamp.
    */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		try {
			updateImplementationStageTimestamp((List<Deal_Support_Request__c>)records, (Map<Id,Deal_Support_Request__c>)existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(),'DealSupportRequestTriggerHandler2', 'DealSupportRequestMilestonesTrackModule', 'onBeforeUpdate', 'DealSupportRequestTrigger', LoggingLevel.ERROR);
		}
	}



	/**
	 * Called after deal support request record is updated.
	 * Performs below operations:
	 * 1. Creates new deal support request milestones record. AND/OR
	 * 2. Updates existing deal support milestones records.
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


	/**
    * Called from beforeInsert() and beforeUpdate(), updates LastImplementationStageUpdate__c timestamps/
    */
	private void updateImplementationStageTimestamp(List<Deal_Support_Request__c> newRecords, Map<Id, Deal_Support_Request__c> existingRecords){
		for(Deal_Support_Request__c dsr: newRecords){
			
			//check if method is called for before insert trigger.
			if(existingRecords == null){
				if(dsr.Implementation_Stage__c != null){
					dsr.LastImplementationStageUpdate__c = System.now();
				}
			}
			else{
				//if Implementation_Stage__c value is changed then record timestamp.
				//all other updates are bypassed.
				if(existingRecords.get(dsr.id).Implementation_Stage__c != dsr.Implementation_Stage__c){
					dsr.LastImplementationStageUpdate__c = System.now();
				}
			}
		}
	}

	/**
    * Called from afterUpdate(). Creates new deal support request milestone records or update existing 
	* records based on matching implementation_stage__c values to track 
	* time taken for deal support requests to move across implementation stages.
    */
	private void trackDealSupportRequestMilestones(List<Deal_Support_Request__c> newDSRList, Map<Id, Deal_Support_Request__c> oldDSRMap,
														ApplicationUnitOfWork uow){

		Map<Id,Deal_Support_Request__c> idVsDSRlistWithImplementationStageUpdated = new Map<Id,Deal_Support_Request__c>();

            for(Deal_Support_Request__c dsr: newDSRList){
                //checking if Implementation_Stage__c value is changed or not.
                //all other updates are bypassed.
                if(oldDSRMap.get(dsr.id).Implementation_Stage__c != dsr.Implementation_Stage__c){
                    idVsDSRlistWithImplementationStageUpdated.put(dsr.Id, dsr);
                }
            }

            if(idVsDSRlistWithImplementationStageUpdated.isEmpty()){
                return;
            }

            //storing DSR ID vs Existing milestones records
            Map<Id, List<DealSupportRequestMilestone__c>> dsrIdsVsDSRMilestones = new Map<Id, List<DealSupportRequestMilestone__c>>();
            
            //map to store dsr id vs set of strings (implementation stage values).
            //This map avoids looping through existing milestones to determine creation of new Milestone based on implementation stage.
            Map<Id, Set<String>> dsrIdsVsExistingMilestoneStages = new Map<Id, Set<String>>();


            //collection to update and create new DSR Milestone records
            List<DealSupportRequestMilestone__c> dsrMilestonesToUpdate = new List<DealSupportRequestMilestone__c>();
            List<DealSupportRequestMilestone__c> newMilestoneRecordsToCreate = new List<DealSupportRequestMilestone__c>();

            //get default business hours
			Id defaultBusinessHoursId = Utility.getDefaultBussinessHour();


            //setting list of milestones for each DSR record.
            for(Id dsrId : idVsDSRlistWithImplementationStageUpdated.keySet()){
                dsrIdsVsDSRMilestones.put(dsrId, new List<DealSupportRequestMilestone__c>());
                dsrIdsVsExistingMilestoneStages.put(dsrId, new Set<String>());
            } 

            for(DealSupportRequestMilestone__c dsrMilestones : DealSupportRequestMilestonesSelector.newInstance().
                                                    selectByDSRId(idVsDSRlistWithImplementationStageUpdated.keySet(), new Set<Object>{DealSupportRequestMilestonesSelector.Options.WITH_RECORDTYPE, DealSupportRequestMilestonesSelector.Options.WITH_DEAL_SUPPORT_REQUEST })){
				
                //populating existing dsr milestones for each DSR    
                if(dsrIdsVsDSRMilestones.containsKey(dsrMilestones.DealSupportRequest__c)){
                    dsrIdsVsDSRMilestones.get(dsrMilestones.DealSupportRequest__c).add(dsrMilestones);
                    dsrIdsVsExistingMilestoneStages.get(dsrMilestones.DealSupportRequest__c).add(dsrMilestones.Stage__c);
                }
            }


            for(Deal_Support_Request__c newDSR : idVsDSRlistWithImplementationStageUpdated.values()){

                //check if Milestone record exists for updated implementation stage.
                if(dsrIdsVsExistingMilestoneStages.get(newDSR.Id).contains(oldDSRMap.get(newDSR.Id).Implementation_Stage__c)){
                    for(DealSupportRequestMilestone__c dsrMilestones : dsrIdsVsDSRMilestones.get(newDSR.Id)){

                        if(dsrMilestones.Stage__c == oldDSRMap.get(dsrMilestones.DealSupportRequest__c).Implementation_Stage__c){
                            DateTime businessHrsStartDate = oldDSRMap.get(newDSR.Id).LastImplementationStageUpdate__c != null ? oldDSRMap.get(newDSR.Id).LastImplementationStageUpdate__c : oldDSRMap.get(newDSR.Id).CreatedDate;
                            DealSupportRequestMilestone__c dsrMilestoneRecordToUpdate = new DealSupportRequestMilestone__c();
							dsrMilestoneRecordToUpdate.Id = dsrMilestones.Id;
							dsrMilestoneRecordToUpdate.Timeinminutes__c = dsrMilestones.Timeinminutes__c + BusinessHours.diff(defaultBusinessHoursId, businessHrsStartDate , System.now())/(1000*60);
							
							dsrMilestonesToUpdate.add(dsrMilestoneRecordToUpdate);
                        }
                    }
                }
                else{
                    //create a new Milestone record.
                    DealSupportRequestMilestone__c newMilestoneRecord = new DealSupportRequestMilestone__c();
                    newMilestoneRecord.DealSupportRequest__c = newDSR.Id;

					//checking stage value as different record types may not have stage value populated for OLD records.
					//If null checks are not done then Deal Support Milestone will be created without stage value.
					if(oldDSRMap.get(newDSR.Id).Implementation_Stage__c != null){
						newMilestoneRecord.Stage__c = oldDSRMap.get(newDSR.Id).Implementation_Stage__c;
						DateTime businessHrsStartDate = oldDSRMap.get(newDSR.Id).LastImplementationStageUpdate__c != null ? oldDSRMap.get(newDSR.Id).LastImplementationStageUpdate__c : oldDSRMap.get(newDSR.Id).CreatedDate;
						newMilestoneRecord.Timeinminutes__c = BusinessHours.diff(defaultBusinessHoursId, businessHrsStartDate, System.now())/(1000*60);

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