/**
 * @description
 * Domain Module to handle Contact object functionality 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain Contact
 * @changelog
 * 2022-05-22 - George Nguyen - Created.
 * 
 */
public with sharing class ContactDomainFormattingModule extends ApplicationDomain.Module {
    
    public static ContactDomainFormattingModule newInstance() {
		return (ContactDomainFormattingModule)Application.Utilities.newInstance(ContactDomainFormattingModule.class);
	}

	// Setup which trigger events this module should respond to
	public ContactDomainFormattingModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        ContactService.getInstance().applyPhoneNumberFormatting ((List<Contact>)records, null);
    }

    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        ContactService.getInstance().applyPhoneNumberFormatting ((List<Contact>)records, (Map<Id, Contact>)existingRecords);
    }

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)ContactDomainFormattingModule.newInstance();
		}
	}
}
