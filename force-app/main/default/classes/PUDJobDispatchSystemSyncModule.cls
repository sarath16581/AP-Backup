/**
 * @description
 * Domain Module to handle dispatch system sync functionality on a PUD Job.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Ranjeewa Silva
 * @date 2021-08-12
 * @group Domain
 * @domain PUD
 * @changelog
 * 2021-08-12 - Ranjeewa Silva - Created.
 * 2021-10-12 - Ranjeewa Silva - Added Start Time to the list of fields monitored for changes.
 * 2022-02-09 - Seth Heang - REQ2742514 Added 'Revenue_Check__c' into the monitoring fields check where Job is in 'Schedule' and 'Accepted' Status and push the updates to Dispatch system 
 * 2022-03-08 - Seth Heang - Add 'Containers_Payload__c', 'Regular_Product__c', 'International_Product__c', 'Express_Product__c' into the monitoring fields 
 * 2022-09-05 - Dattaraj Deshmukh - Added 'PUD_Job__c.Dock_Number__c' to monitored fields.
 */

public inherited sharing class PUDJobDispatchSystemSyncModule extends ApplicationDomain.Module {

	// set of job fields monitored for changes. for jobs already synced to dispatch system ('Schedule' and 'Accepted'
	// status), changes to these fields should trigger an update into dispatch system.
	private static final Set<SObjectField> MONITORED_FIELDS_FOR_UPDATES {
		get {
			if (MONITORED_FIELDS_FOR_UPDATES == null) {
				MONITORED_FIELDS_FOR_UPDATES = new Set<SObjectField>{
						PUD_Job__c.Article_Count__c, PUD_Job__c.Bags_Quantity__c, PUD_Job__c.Blue_Bags__c, PUD_Job__c.Booking_Comments__c,
						PUD_Job__c.Comments__c, PUD_Job__c.Contact_Email__c, PUD_Job__c.Contact_Name__c, PUD_Job__c.Contact_Phone_Number__c,
						PUD_Job__c.Display_Start_Time__c, PUD_Job__c.Dwell_Time_Planned__c, PUD_Job__c.Earliest_Start_Time__c,
						PUD_Job__c.Express_Bags__c, PUD_Job__c.Hazards__c, PUD_Job__c.Job_Instructions__c, PUD_Job__c.Key_Number__c,
						PUD_Job__c.Large_Letter_Tubs__c, PUD_Job__c.Latest_End_Time__c, PUD_Job__c.Pallets_Quantity__c,
						PUD_Job__c.Red_Tubs__c, PUD_Job__c.Site_Instructions__c, PUD_Job__c.Small_Letter_Trays__c,
						PUD_Job__c.Start_Time__c, PUD_Job__c.Trays_Quantity__c, PUD_Job__c.Tubs_Quantity__c, PUD_Job__c.Volume_Cubic_Metre__c,
						PUD_Job__c.White_Bags__c, PUD_Job__c.Revenue_Check__c, PUD_Job__c.Containers_Payload__c, PUD_Job__c.Regular_Product__c,
						PUD_Job__c.International_Product__c,PUD_Job__c.Express_Product__c, PUD_Job__c.Dock_Number__c
				};
			}
			return MONITORED_FIELDS_FOR_UPDATES;
		}
		set;
	}

	public static PUDJobDispatchSystemSyncModule newInstance() {
		return (PUDJobDispatchSystemSyncModule) Application.Utilities.newInstance(PUDJobDispatchSystemSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public PUDJobDispatchSystemSyncModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {

		try {
			List<PUD_Job__c> jobsToSendToDispatchSystem = new List<PUD_Job__c>();

			// loop through our records to figure out what actions need to be taken
			for (PUD_Job__c job : (List<PUD_Job__c>) records) {

				// monitor for jobs that satisfy below conditions:
				//  - Date__c = today
				//  - Status = New
				if (job.Date__c == System.today() && job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
					jobsToSendToDispatchSystem.add(job);
				}
			}

			if (!jobsToSendToDispatchSystem.isEmpty()) {
				PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync(jobsToSendToDispatchSystem);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDJobDispatchSystemSyncModule.class.getName(), 'onBeforeInsert', 'PUDJobTrigger', LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

		try {
			List<PUD_Job__c> jobsToSendToDispatchSystem = new List<PUD_Job__c>();

			Set<SObjectField> monitoredFields = new Set<SObjectField>{PUD_Job__c.Status__c, PUD_Job__c.Last_Pushed_to_Dispatch_System__c};
			monitoredFields.addAll(MONITORED_FIELDS_FOR_UPDATES);

			Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, monitoredFields);

			// loop through our records to figure out what actions need to be taken
			for (PUD_Job__c job : (List<PUD_Job__c>) records) {

				Set<SObjectField> changed = changedRecords.get(job.Id);
				if (changed == null) changed = new Set<SObjectField>();

				// monitor for changes on current day jobs
				//  - job details changing where Status = Schedule, Accepted
				//  - status changing to Cancel
				// it is not necessary to trigger the send if 'Last_Pushed_to_Dispatch_System__c' has been updated in
				// current transaction. this indicates the job has been already pushed.
				if (job.Date__c == System.today()
						&& (((job.Status__c == PUDConstants.PUD_JOB_STATUS_SCHEDULE || job.Status__c == PUDConstants.PUD_JOB_STATUS_ACCEPTED) && hasJobDetailsUpdated(changed))
								|| (changed.contains(PUD_Job__c.Status__c) && job.Status__c == PUDConstants.PUD_JOB_STATUS_CANCEL))
						&& !changed.contains(PUD_Job__c.Last_Pushed_to_Dispatch_System__c)) {

					jobsToSendToDispatchSystem.add(job);
				}
			}

			if (!jobsToSendToDispatchSystem.isEmpty()) {
				PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync(jobsToSendToDispatchSystem);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDJobDispatchSystemSyncModule.class.getName(), 'onBeforeUpdate', 'PUDJobTrigger', LoggingLevel.ERROR);
		}
	}

	private Boolean hasJobDetailsUpdated(Set<SObjectField> changed){

		Set<SObjectField> changedFieldsClone = new Set<SObjectField>(changed);
		changedFieldsClone.retainAll(MONITORED_FIELDS_FOR_UPDATES);

		return !changedFieldsClone.isEmpty();
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PUDJobDispatchSystemSyncModule.newInstance();
		}
	}
}