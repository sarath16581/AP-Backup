/**
 * @description Domain class to handle common logic for all Case EmailMessages
 * @author Naveen Rajanna
 * @date 2022-02-12
 * @group Domains
 * @changelog
 * 2022-10-12	Naveen Rajanna - created - REQ2859152
 * 2023-05-29	Mahesh Parvathaneni - Added module TransportEnquiryEmailMessagesModule
 * 2024-04-05	Thang Nguyen - Added module BulkMailEmailMessagesModule
 */
public inherited sharing class EmailMessageCasesDomain extends ApplicationDomain {
	public static EmailMessageCasesDomain newInstance(List<SObject> sObjectList) {
		return (EmailMessageCasesDomain) ApplicationDomain.newInstance(EmailMessageCasesDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		
		// Normally for an object, a domain encapsulates common functionality of an application and a module is a capability specific to a domain. 
		// for a related object like Parent (Case) in EmailMessage, to avoid an additional SOQL in the domain's filter method 
		// we define a generic domain like EmailMessageCasesDomain for the related object having a filter on related object and
		// this generic related object domain comprises of a generic module and all the other specific modules.
		// Include domain specific modules (e.g. StarTrack) in this generic domain class

		// Generic Case modules
		registerModule(EmailMessageGenericCaseAutomationModule.class);

		// Transport Enquiry modules
		registerModule(TransportEnquiryEmailMessagesModule.class);

		// StarTrack modules
		registerModule(StarTrackEmailMessagesModule.class);

		// Service Advisor modules
		registerModule(ServiceAdvisorEmailMesAutomationModule.class);
		registerModule(ServiceAdvisorEmailMesEntitlementsModule.class);

		// Bulk Mail module
		registerModule(BulkMailEmailMessagesModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			if (!String.isBlank((Id) record.get('ParentId')) && ((Id) record.get('ParentId')).getSObjectType() == Case.sObjectType) {
				output.add(record);
			}
		}
		return output;
	}
}