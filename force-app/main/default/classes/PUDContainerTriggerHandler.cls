/**
 * @author Dattaraj Deshmukh
 * @date 2022-06-23
 * @group TriggerHandler
 * @tag Handler
 * @tag Container Types
 * @domain Booking
 * @description Trigger Handler class for PUD_Container__c object
 * @changelog
 * 2022-06-23 - Dattaraj Deshmukh - Created
 */

public with sharing class PUDContainerTriggerHandler extends ApplicationDomainTriggerHandler {
    public override SObjectType getSObjectType() {
		return PUD_Container__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			PUDContainersDomain.class
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
            PUD_Container__c.SObjectType,
			PUD_Booking__c.SObjectType,
			PUD_Job__c.SObjectType			
		};
	}
}
