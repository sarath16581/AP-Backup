/***
 * @description Domain wrapper class for EmailMessage
 * @author Ashapriya Gadi
 * @date 2021-11-22
 * @group Domain
 * @domain EmailMessage
 * @test 
 * @changelog
 * 2022-02-10	Naveen Rajanna	REQ2723199 - Added StarTrackEmailMessagesDomain class to the register
 * 2022-10-17	Naveen Rajanna REQ2859152 Removed ServiceAdvisorsEmailMessagesDomain, StarTrackEmailMessagesDomain and included EmailMessageCasesDomain 
 * 				which filters EmailMessages with Cases, changed api version to 55
 * 2024-08-07 - Ranjeewa Silva - Uplifted to new domain-less ApplicationModule framework
 */

public inherited sharing class EmailMessageTriggerHandler extends ApplicationTriggerHandler {
	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
	@TestVisible private static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ EmailMessage.SObjectType, Case.SObjectType, CaseMileStone.SObjectType, Task.SObjectType };
	}

	public override void registerModules() {

		// module is a capability specific to an object and could apply ony to a subset of records meeting a specific
		// filter criteria defined at module registration time. for EmailMessage object we have set of modules we need
		// to execute when EmailMessage.ParentId is a Case. more refined filtering is applied in these modules to target
		// specific records that the module is monitoring for. this allows us to avoid additional SOQL during module registration.

		// Generic Case modules
		registerModule(EmailMessageGenericCaseAutomationModule.class, 'filterCaseEmails');
		// Transport Enquiry modules
		registerModule(TransportEnquiryEmailMessagesModule.class, 'filterCaseEmails');
		// StarTrack modules
		registerModule(StarTrackEmailMessagesModule.class, 'filterCaseEmails');
		// Service Advisor modules
		registerModule(ServiceAdvisorEmailMesAutomationModule.class, 'filterCaseEmails');
		registerModule(ServiceAdvisorEmailMesEntitlementsModule.class, 'filterCaseEmails');
		// Bulk Mail module
		registerModule(BulkMailEmailMessagesModule.class, 'filterCaseEmails');
		// Unified Cases module
		registerModule(UnifiedCaseEmailMessagesModule.class, 'filterCaseEmails');
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules.
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered.
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 *
	 * @param records
	 *
	 * @return
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterCaseEmails' => new List<SObject>()
		};

		for(SObject record : records) {
			Id parentId = (Id)record.get('ParentId');
			if (parentId != null && parentId.getSobjectType() == Case.SObjectType) {
				filteredRecords.get('filterCaseEmails').add(record);
			}
		}
		return filteredRecords;
	}
}