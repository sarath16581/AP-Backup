/**
 * @description Module that wraps all of the Aus Post Rating Plan legacy code which hasn't been uplifted to the latest ApplicationModule
 *			  framework.
 *
 * @author Ranjeewa Silva
 * @date 2023-11-24
 * @test BillingAccountCreationEventHelperTest
 * @changelog
 * 2023-11-24 - Ranjeewa Silva - Created
 */
public inherited sharing class ActivateAPRatingPlanEventHandlerModule extends ApplicationModule {

	public ActivateAPRatingPlanEventHandlerModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		if (!records.isEmpty()) {
			BillingAccountCreationEventTriggerHelper.activateRatingPlan(records);
		}
	}
}