/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Application Domain Trigger Handler for Membership Contact Data Object
* @test : MembershipContactTriggerHandler_Test
* @changelog :
*/

public  inherited sharing  class MembershipContactTriggerHandler extends ApplicationDomainTriggerHandler {
	
	public override SObjectType getSObjectType() {

		return MembershipContact__c.SObjectType;
	
	}
	
	public override List<Type> registerDomains() {

		return new List<Type>{
			AustracMembershipContactDomain.class
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
			MembershipContact__c.SObjectType,
			Task.SObjectType
		};
	
	}
}