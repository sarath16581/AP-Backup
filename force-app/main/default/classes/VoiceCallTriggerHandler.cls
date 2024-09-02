/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2024-07-31
 * @changelog
 */
public inherited sharing class VoiceCallTriggerHandler extends ApplicationTriggerHandler {

	public override SObjectType getSObjectType() {
		return VoiceCall.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override void registerModules() {

		// populate the case id on both the relevant agent work records and the contactrequest records themselves
		// This provides an easy to reference lookup to the case the record is associated with
		registerModule(CaseRecordPopulationModule.class);

	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			AgentWork.SObjectType
		};
	}


}