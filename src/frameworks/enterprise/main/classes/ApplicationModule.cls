/***
 * @description
 * Another take at a framework with domainless architecture. Domains can be controlled by naming conventions with ApplicationModule
 * 
 * @test ApplicationTriggerHandler_Test
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 * 2020-11-21 - Nathan Franklin - No Change
 */
public inherited sharing abstract class ApplicationModule {

	@TestVisible
	private TriggerEvent triggerEvents;

	public virtual TriggerEvent getTriggerEvents() {
		if (triggerEvents == null) {
			triggerEvents = new TriggerEvent();
		}
		return triggerEvents;
	}

	protected String nullToString(String nullString) {
		String emptyString = nullString == null ? '' : nullString;
		return emptyString;
	}

	/**
	 * Grabs a list of record ids where the values in the monitored fields have changed. This is just a bulkified helper method.
	 * @deprecated
	 */
	protected Map<Id, Set<SObjectField>> getIsChanged(List<SObject> records, Map<Id, SObject> oldRecords, Set<SObjectField> comparisonFields) {
		Map<Id, Set<SObjectField>> output = new Map<Id, Set<SObjectField>>();
		for (SObject record : records) {
			for (SObjectField field : comparisonFields) {
				if (record.get(field) != oldRecords.get(record.Id).get(field)) {
					if (output.get(record.Id) == null) {
						output.put(record.Id, new Set<SObjectField>());
					}
					output.get(record.Id).add(field);
				}
			}
		}
		return output;
	}

	public virtual void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {}
	public virtual void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {}
	public virtual void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {}

	public class TriggerEvent {
		public Boolean beforeInsertEnabled { get; private set; }
		public Boolean beforeUpdateEnabled { get; private set; }
		public Boolean beforeDeleteEnabled { get; private set; }

		public Boolean afterInsertEnabled { get; private set; }
		public Boolean afterUpdateEnabled { get; private set; }
		public Boolean afterDeleteEnabled { get; private set; }
		public Boolean afterUndeleteEnabled { get; private set; }

		public TriggerEvent() {
			beforeInsertEnabled = false;
			beforeUpdateEnabled = false;
			beforeDeleteEnabled = false;
			afterInsertEnabled = false;
			afterUpdateEnabled = false;
			afterDeleteEnabled = false;
			afterUndeleteEnabled = false;
		}

		// befores
		public TriggerEvent enableBeforeInsert() {
			beforeInsertEnabled = true;
			return this;
		}
		public TriggerEvent enableBeforeUpdate() {
			beforeUpdateEnabled = true;
			return this;
		}
		public TriggerEvent enableBeforeDelete() {
			beforeDeleteEnabled = true;
			return this;
		}

		// afters
		public TriggerEvent enableAfterInsert() {
			afterInsertEnabled = true;
			return this;
		}
		public TriggerEvent enableAfterUpdate() {
			afterUpdateEnabled = true;
			return this;
		}
		public TriggerEvent enableAfterDelete() {
			afterDeleteEnabled = true;
			return this;
		}
		public TriggerEvent enableAfterUndelete() {
			afterUndeleteEnabled = true;
			return this;
		}

		public TriggerEvent enableAll() {
			return this.enableAllBefore().enableAllAfter();
		}

		public TriggerEvent enableAllBefore() {
			return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
		}

		public TriggerEvent enableAllAfter() {
			return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
		}
	}
}