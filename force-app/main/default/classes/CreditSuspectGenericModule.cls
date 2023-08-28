/**
 * @description
 * @group Domain
 * @domain CreditSuspect generic
 */
public inherited sharing class CreditSuspectGenericModule extends ApplicationDomain.Module {
	public static CreditSuspectGenericModule newInstance() {
		return (CreditSuspectGenericModule) Application.Utilities.newInstance(CreditSuspectGenericModule.class);
	}

	// Setup which trigger events this module should respond to
	public CreditSuspectGenericModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			formatDoB((List<CreditSuspect__c>)records, new Map<Id,CreditSuspect__c>(), uow);			
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CreditSuspectGenericModule.class.getName(), 'onBeforeInsert', 'CreditSuspect__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id,SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			formatDoB((List<CreditSuspect__c>) records, (Map<Id,CreditSuspect__c>) existingRecords, uow);	
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CreditSuspectGenericModule.class.getName(), 'onBeforeUpdate', 'CreditSuspect__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Syncing Date field to String field for accurate duplicate detection (Suspect Registry Matching)
	 * 
	 * @param records the list of updated or new records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 **/
	private void formatDoB(List<CreditSuspect__c> records, Map<Id,CreditSuspect__c> existingRecords, ApplicationUnitOfWork uow){
		for(CreditSuspect__c cs: records) {
			if (cs.Birthdate__c == null || isChanged(cs, existingRecords, new Set<SObjectField>{ CreditSuspect__c.Date_of_Birth__c })) {
				String value;

				if (cs.Date_of_Birth__c != null) {
					// Format the Date value as YYYY-MM-DD text value
					value = DateTime.newInstanceGmt(cs.Date_of_Birth__c, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
				}

				// No need to flag in uow as we don't need to commit updates in before trigger context
				cs.Birthdate__c = value;
			}
		}
	}

	/**
	 * Returns if any of the provided fields have been updated
	 * @param record the record to verify
	 * @param existingRecords Map for prior values
	 * @param fields to be verified
	 * @return  `Boolean`
	 */
	private static Boolean isChanged(SObject record, Map<Id,SObject> existingRecords, Set<SObjectField> fields) {
		Boolean result = false;

		for (SObjectField field :fields) {
			Object value = record.get(field);
			
			if (value != existingRecords.get(record.Id)?.get(field)) {
				result = true;
				break;
			}
		}

		return result;
	}
}