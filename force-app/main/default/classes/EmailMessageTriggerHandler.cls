/***
 * @description Domain wrapper class for EmailMessage
 * @author Ashapriya Gadi
 * @date 2021-11-22
 * @group Domain
 * @domain EmailMessage
 * @changelog
 * 2022-02-10	Naveen Rajanna	REQ2723199 - Added StarTrackEmailMessagesDomain class to the register
 */

public inherited sharing class EmailMessageTriggerHandler extends ApplicationDomainTriggerHandler {
	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}
	
	public override List<Type> registerDomains() {
		return new List<Type>{
			ServiceAdvisorsEmailMessagesDomain.class,			
			StarTrackEmailMessagesDomain.class
		};
	}
	/**
	* Unit of work that encapsulates all the required objects for each domain within this SObject
	*/
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				EmailMessage.SObjectType,
				Case.SObjectType,
				CaseMileStone.SObjectType
		};
	}
}