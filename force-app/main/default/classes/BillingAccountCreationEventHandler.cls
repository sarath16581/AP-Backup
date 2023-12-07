/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description This is the Handler class for BillingAccountCreationEvent__e Trigger.
 * @Test BillingAccountCreationEventHandler_Test
 * @changelog
 * 2020-11-18 - shashwat.nath@auspost.com.au - Created
 * 2022-08-04 - Seth Heang - Updated to handle Rating Plan platform event
 * 2023-11-24 - Ranjeewa Silva - Refactored to use new domain less ApplicationTriggerHandler framework.
*/
public inherited sharing class BillingAccountCreationEventHandler extends ApplicationTriggerHandler {

	public override void registerModules() {
		registerModule(CreateAPBillingAccountEventHandlerModule.class, 'filterNewAusPostBillingAccounts');
		registerModule(ActivateAPRatingPlanEventHandlerModule.class, 'filterNewAusPostRatingPlans');
		registerModule(CreateSTBillingAccountEventHandlerModule.class, 'filterNewStarTrackBillingAccounts');
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override SObjectType getSObjectType() {
		return BillingAccountCreationEvent__e.getSObjectType();
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 * @param records list of records to filter
	 * @return filtered records indexed by filter keys.
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterNewAusPostBillingAccounts' => new List<SObject>(),
				'filterNewAusPostRatingPlans' => new List<SObject>(),
				'filterNewStarTrackBillingAccounts' => new List<SObject>()
		};
		for(BillingAccountCreationEvent__e event: (List<BillingAccountCreationEvent__e>)records) {
			if ('SAP'.equalsIgnoreCase(event.Source_System__c)) {
				// below filtering logic is inherited from legacy trigger handler.
				if(event.Additional_Info__c == APT_Constants.RATING_PLAN_ACTIVATION_LABEL || event.Additional_Info__c == APT_Constants.RATING_CARD_ACTIVATION_LABEL){
					filteredRecords.get('filterNewAusPostRatingPlans').add(event);
				} else {
					filteredRecords.get('filterNewAusPostBillingAccounts').add(event);
				}
			} else if('TEAM'.equalsIgnoreCase(event.Source_System__c)) {
				filteredRecords.get('filterNewStarTrackBillingAccounts').add(event);
			}
		}

		return filteredRecords;
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 * @return the list of sobject types
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Billing_Account__c.SObjectType,
				BAMExternalOnboardingRequest__c.SObjectType,
				Deal_Support_Request__c.SObjectType,
				Apttus__APTS_Agreement__c.SObjectType,
				APT_Charge_Account__c.SObjectType,
				APT_Sub_Account__c.SObjectType,
				Organisation_Role__c.SObjectType,
				Account.SObjectType
		};
	}
}