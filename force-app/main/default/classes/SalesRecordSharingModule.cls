/**
 * @description
 * Generic Domain Module to handle records with Sales Team.
 * @author Ken McGuire
 * @group Domain
 * @domain Account
 * @test SalesRecordSharingModule_Test
 * @changelog
 * 2022-11-28 - Ken McGuire - Created.
 * 2022-02-13 - Ranjeewa Silva - Refactored and added support to recalculate sharing when records are undeleted.
 */

public inherited sharing class SalesRecordSharingModule extends ApplicationDomain.Module {

	private static final String APP = 'Sales';

	public static SalesRecordSharingModule newInstance() {
		return (SalesRecordSharingModule)Application.Utilities.newInstance(SalesRecordSharingModule.class);
	}
 
	public SalesRecordSharingModule() {
		// Setup which trigger events this module should respond to
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableAfterUndelete();
	}
 

	// after insert trigger handler
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		
		// Share records using sharing service
		try {

			Map<Id, SObject> sharingScope = getSharingScope(records, new Map<Id, SObject>());
			if (!sharingScope.isEmpty()) {
				SalesRecordSharingService.getInstance().shareRecords(records.getSObjectType(), sharingScope, false, uow);
			}

		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), APP, SalesRecordSharingModule.class.getName(),
					'onAfterInsert', String.valueOf(records.getSObjectType()), ApplicationLogger.LoggingLevel.ERROR);
		}

	}
 
	// after update trigger handler
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
	
		try {

			Map<Id, SObject> sharingScope = getSharingScope(records, existingRecords);
			if (!sharingScope.isEmpty()) {
				SalesRecordSharingService.getInstance().shareRecords(records.getSObjectType(), sharingScope, true, uow);
			}

		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), APP, SalesRecordSharingModule.class.getName(),
					'onAfterUpdate', String.valueOf(records.getSObjectType()), ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	// after undelete trigger handler
	public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {

		// Share records using sharing service
		try {

			Map<Id, SObject> sharingScope = getSharingScope(records, new Map<Id, SObject>());
			if (!sharingScope.isEmpty()) {
				SalesRecordSharingService.getInstance().shareRecords(records.getSObjectType(), sharingScope, true, uow);
			}

		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), APP, SalesRecordSharingModule.class.getName(),
					'onAfterUndelete', String.valueOf(records.getSObjectType()), ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Returns sub-set of records that need to be submitted for sharing calculation.
	 *
	 * @param records new versions of records
	 * @param existingRecords old versions of records (only in updated scenario).
	 *
	 * @return records that need to be submitted for sharing calculation.
	 */
	private Map<Id, SObject> getSharingScope(List<SObject> records, Map<Id, SObject> existingRecords) {

		SObjectField lookupField = SalesRecordSharingService.getInstance().getSharingConfiguration(records.getSObjectType())?.lookupField;
		if (lookupField == null) {
			return new Map<Id,SObject>();
		}

		Map<Id, SObject> results = new Map<Id, SObject>();
		for (SObject record: records) {
			SObject existingRecord = existingRecords?.get(record.Id);
			// determine sharing scope based on below rules:
			// - newly inserted(or undeleted) records need to be submitted for sharing recalculation if the account lookup field is populated
			// - updated records need to be submitted for sharing only if the account lookup is updated
			if (record.get(lookupField) != null
					&& (existingRecord == null || (record.get(lookupField) != existingRecord.get(lookupField)))) {
				results.put(record.Id, record);
			}
		}
		return results;
	}
}