/***
 * @description
 * Another take at a framework with domainless architecture. Domains can be controlled by naming conventions with ApplicationModule
 * 
 * @author Nathan Franklin
 * @date 2023-06-12
 * @group Core
 * @domain Core
 * @changelog
 */
public inherited sharing abstract class ApplicationModule {

	@TestVisible
	private TriggerEvent triggerEvents;

	public virtual TriggerEvent getTriggerEvents() {
		if (triggerEvents == null) {
			triggerEvents = new TriggerEvent().disableAll();
		}
		return triggerEvents;
	}

	public virtual void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {}

	public virtual void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {}
	public virtual void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {}

	public virtual void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {}
	public virtual void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {}

	public virtual void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {}

	// returns an empty string
	protected String nullToString(String nullString) {
		String emptyString = nullString == null ? '' : nullString;
		return emptyString;
	}

	public class TriggerEvent {
		public Boolean beforeInsertEnabled { get; private set; }
		public Boolean beforeUpdateEnabled { get; private set; }
		public Boolean beforeDeleteEnabled { get; private set; }

		public Boolean afterInsertEnabled { get; private set; }
		public Boolean afterUpdateEnabled { get; private set; }
		public Boolean afterDeleteEnabled { get; private set; }
		public Boolean afterUndeleteEnabled { get; private set; }

		public TriggerEvent() {
			this.disableAll();
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

		public TriggerEvent disableBeforeInsert() {
			beforeInsertEnabled = false;
			return this;
		}
		public TriggerEvent disableBeforeUpdate() {
			beforeUpdateEnabled = false;
			return this;
		}
		public TriggerEvent disableBeforeDelete() {
			beforeDeleteEnabled = false;
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

		public TriggerEvent disableAfterInsert() {
			afterInsertEnabled = false;
			return this;
		}
		public TriggerEvent disableAfterUpdate() {
			afterUpdateEnabled = false;
			return this;
		}
		public TriggerEvent disableAfterDelete() {
			afterDeleteEnabled = false;
			return this;
		}
		public TriggerEvent disableAfterUndelete() {
			afterUndeleteEnabled = false;
			return this;
		}

		public TriggerEvent enableAll() {
			return this.enableAllBefore().enableAllAfter();
		}

		public TriggerEvent disableAll() {
			return this.disableAllBefore().disableAllAfter();
		}

		public TriggerEvent enableAllBefore() {
			return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
		}

		public TriggerEvent disableAllBefore() {
			return this.disableBeforeInsert().disableBeforeUpdate().disableBeforeDelete();
		}

		public TriggerEvent enableAllAfter() {
			return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
		}

		public TriggerEvent disableAllAfter() {
			return this.disableAfterInsert().disableAfterUpdate().disableAfterDelete().disableAfterUndelete();
		}
	}
}