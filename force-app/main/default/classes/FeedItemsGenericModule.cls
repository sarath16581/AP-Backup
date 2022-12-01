/**
 * @description
 * Domain Module to handle functionality on a FeedItem.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Dattaraj Deshmukh
 * @date 23/11/2022
 * @group Domain
 * @domain PUD
 * @changelog
 * 23/11/2022 - Dattaraj Deshmukh - Created.
 */

public inherited sharing class FeedItemsGenericModule extends ApplicationDomain.Module  {
    public static FeedItemsGenericModule newInstance() {
		return (FeedItemsGenericModule) Application.Utilities.newInstance(FeedItemsGenericModule.class);
	}

	// Setup which trigger events this module should respond to
	public FeedItemsGenericModule() {
		getTriggerEvents().enableAfterInsert();
	}

    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
			FeedItemTriggerHelper.updateCaseInvestigations(records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'MyNetwork', FeedItemsGenericModule.class.getName(), 'onAfterInsert', 'FeedItemTrigger', LoggingLevel.ERROR);
		}
    }

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)FeedItemsGenericModule.newInstance();
		}
	}
}