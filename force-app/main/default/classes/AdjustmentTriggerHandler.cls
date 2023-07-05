/**
 * Date            Version          Owner               Desription
 * 28-Mar-17        1.0             Adrian A            Main Adjustment Trigger Handler Class
 * 2023-06-30       2.0             Pratyush Chalasani  Refactored into new framework
 */
public without sharing class AdjustmentTriggerHandler extends ApplicationTriggerHandler {
	public static Boolean adjustmentLink = false;

	public override SObjectType getSObjectType() {
		return Adjustment__c.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override void registerModules() {
		registerModule(AdjustmentModule.class);
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			Adjustment__c.SObjectType,
			Disputed_Item__c.SObjectType,
			Credit_Approval__c.SObjectType
		};
	}
}