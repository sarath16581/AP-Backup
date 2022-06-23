/**
 * @description
 * Domain Module to handle sync when container types on Bookings/Jobs are added/updated.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Dattaraj Deshmukh
 * @date 2022-06-23
 * @group Domain
 * @domain PUD
 * @changelog
 * 2021-08-12 - Dattaraj Deshmukh - Created.
 */
public with sharing class PUBContainerTypeSyncModule extends ApplicationDomain.Module{
    public static PUBContainerTypeSyncModule newInstance() {
		return (PUBContainerTypeSyncModule) Application.Utilities.newInstance(PUBContainerTypeSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public PUBContainerTypeSyncModule() {
		getTriggerEvents().enableAfterUpdate().enableAfterInsert();
	}

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PUBContainerTypeSyncModule.newInstance();
		}
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){

    }
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow){

    }
}
