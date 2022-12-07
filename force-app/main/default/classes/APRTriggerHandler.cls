/***
 * @description Domain wrapper class for APR__c
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Domain
 * @domain APR__c
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 * 2022-12-05  Ken McGuire - Added Sharing
 */

public inherited sharing class APRTriggerHandler extends ApplicationDomainTriggerHandler {
	public override SObjectType getSObjectType() {
	  return APR__c.SObjectType;
	}
  
	public override List<Type> registerDomains() {
	  return new List<Type> { 
		  APRDomain.class,
		  StarTrackAPRDomain.class
		};
	}
  
	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
	  return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
  
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
	  return new List<SObjectType> { 
		  APR__c.SObjectType,
		  APR__Share.SObjectType    
	  };
	}
  }