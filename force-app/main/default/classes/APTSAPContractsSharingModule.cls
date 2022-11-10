/**
 * @description
 * Domain Module to handle sharing of APT SAP Contracts
 * @author Ken McGuire
 * @group Domain
 * @domain Account
 * @changelog
 * 2022-11-11 - Ken McGuire - Created.
 * 
 */
public inherited sharing class APTSAPContractsSharingModule extends ApplicationDomain.Module {
    
    public static APTSAPContractsSharingModule newInstance() {
		return (APTSAPContractsSharingModule)Application.Utilities.newInstance(APTSAPContractsSharingModule.class);
	}

	// Setup which trigger events this module should respond to
	public APTSAPContractsSharingModule() {
		getTriggerEvents().enableAfterUpdate();
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)APTSAPContractsSharingModule.newInstance();
		}
	}

}