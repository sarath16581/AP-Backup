/*** 
 * @description
 * Domain Module to update related child records for StarTrack cases. 
 * @author Dattaraj Deshmukh
 * @date 2023-01-17
 * @group Domain
 * @domain core 
 * @changelog
 * 2023-01-17 - Dattaraj Deshmukh - Created
 */

public inherited sharing class STCaseRelatedRecordsProcessingModule extends ApplicationDomain.Module  {
    
	

	/*
	* Creates a new instance of the utility to facilitate dependency injection for mocking
	* @return the new instance
	*/
	public static STCaseRelatedRecordsProcessingModule newInstance() {
		return (STCaseRelatedRecordsProcessingModule)Application.Utilities.newInstance(STCaseRelatedRecordsProcessingModule.class);
	}
    
	// Constructor
	public STCaseRelatedRecordsProcessingModule() {
		// Setup which triggers this module should respond to
		getTriggerEvents().enableAfterUpdate();
	}

	/**
	 * Called after a case is updated. 
	 * If startrack case is closed then all its related case investigations are also marked as closed.
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			STCaseInvestigationLifecycleModule.newInstance().updateAllCaseInvestigations(records, uow);
			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'STCaseRelatedRecordsProcessing', STCaseRelatedRecordsProcessingModule.class.getName(), 'onBeforeInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)STCaseRelatedRecordsProcessingModule.newInstance();
		}
	}
}
