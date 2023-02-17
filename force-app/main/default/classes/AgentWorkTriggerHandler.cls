/***
 * @description Domain wrapper class for ContactPointPhone
 * @author George Nguyen
 * @group Domain
 * @tag AgentWorkDomain
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - updated. This class was created a while back but does not follow the framework. I have updated to use our framework
 */
public class AgentWorkTriggerHandler extends ApplicationDomainTriggerHandler {

	public static AgentWorkTriggerHandler newInstance() {
		return (AgentWorkTriggerHandler) Application.Utilities.newInstance(AgentWorkTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return AgentWork.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ 
			APAgentWorkDomain.class 
		};
	}

	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 *
	 * @return unit or work instance
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ AgentWork.SObjectType };
	}

}