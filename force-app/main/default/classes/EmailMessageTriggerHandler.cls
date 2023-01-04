/***
 * @description Domain wrapper class for EmailMessage
 * @author Ashapriya Gadi
 * @date 2021-11-22
 * @group Domain
 * @domain EmailMessage
 * @test 
 * @changelog
 * 2022-02-10	Naveen Rajanna	REQ2723199 - Added StarTrackEmailMessagesDomain class to the register
 * 2022-10-17	Naveen Rajanna REQ2859152 Removed ServiceAdvisorsEmailMessagesDomain, StarTrackEmailMessagesDomain and included EmailMessageCasesDomain 
 * 				which filters EmailMessages with Cases, changed api version to 55
 */

public inherited sharing class EmailMessageTriggerHandler extends ApplicationDomainTriggerHandler {
	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			// Normally for an object, a domain encapsulates common functionality of an application and a module is a capability specific to a domain. 
			// for a related object like Parent (Case) in EmailMessage, to avoid an additional SOQL in the domain's filter method 
			// we define a generic domain like EmailMessageCasesDomain for the related object having a filter on related object and
			// this generic related object domain comprises of a generic module and all the other specific modules.
			EmailMessageCasesDomain.class
		};
	}
	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ EmailMessage.SObjectType, Case.SObjectType, CaseMileStone.SObjectType, Task.SObjectType };
	}
}