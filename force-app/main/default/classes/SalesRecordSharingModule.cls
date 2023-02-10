/**
 * @description
 * Generic Domain Module to handle sharing of APT SAP Contracts
 * @author Ken McGuire
 * @group Domain
 * @domain Account
 * @test SalesRecordSharingModule_Test
 * @changelog
 * 2022-11-28 - Ken McGuire - Created.
 */

public inherited sharing class SalesRecordSharingModule extends ApplicationDomain.Module {
	private static final String APP = 'Sales';
	private static final String ACTION_INSERT = 'INSERT';
	private static final String ACTION_UPDATE = 'UPDATE';
	// new instance
	public static SalesRecordSharingModule newInstance() {
		return (SalesRecordSharingModule)Application.Utilities.newInstance(SalesRecordSharingModule.class);
	}
 
	// Constructor
	public SalesRecordSharingModule() {
		// Setup which trigger events this module should respond to
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}
 

	// after insert trigger handler
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		
		// retrive object type for sharing service
		Schema.sobjectType objectType = records[0].getSObjectType();
		
		
		// Share records using sharing service
		try {
			SalesRecordSharingService.getInstance().shareRecords(objectType, new Map <Id, SObject>(records), false, uow);
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP, 
													SalesRecordSharingModule.class.getName(), ACTION_INSERT, 
													String.valueOf(objectType), LoggingLevel.ERROR);
		}

	}
 
	// after update trigger handler
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
	
		// retrieve object type for sharing service
		Schema.sobjectType objectType = records[0].getSObjectType();
		
		
		try {
			// obtain sharing service instance
			SalesRecordSharingService sharingService = SalesRecordSharingService.getInstance();
	
			// obtain any records which has a changed lookup to the parent record.
			Map<Id,SObject> changedParentRecordMap = getChangedParentRecordMap(records,existingRecords, sharingService.getSharingConfiguration(objectType).lookupField);
			
			if (changedParentRecordMap.isEmpty()) {
				return;
			}
			
			// recalculate sharing rules for objects having changed parent lookup.
				sharingService.shareRecords(objectType, changedParentRecordMap, true, uow);
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP, 
													SalesRecordSharingModule.class.getName(), ACTION_UPDATE,
													String.valueOf(objectType), LoggingLevel.ERROR);
		}
	}

	/*
	* Filters updated records for changed values in a field.
	* @param records The specified SObject records
	* @param existingRecords The existing SObject record values
	* @return a Map of records for those records which have had a change to the specified field
	*/    
	private Map<Id,SObject> getChangedParentRecordMap(List<SObject> records, Map<Id, SObject> existingRecords, SObjectField field ) {

		Map<Id,SObject> changedParentRecordMap = new Map<Id,SObject>();

		for (SObject currentRecord : records) {
			String currentFieldValue = (String)currentRecord.get(field);
			String existingFieldValue = (String)(existingRecords.get(currentRecord.id)).get(field);
			if (currentFieldValue != existingFieldValue) {
				changedParentRecordMap.put(currentRecord.id,currentRecord);
			}
		}
									
		return changedParentRecordMap;
	}
}