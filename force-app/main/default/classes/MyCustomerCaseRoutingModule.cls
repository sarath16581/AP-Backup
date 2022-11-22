/**
 * @description
 * Handles some of the case routing capabilities for SSSW cases
 *
 * @author Nathan Franklin
 * @date 2022-10-30
 * @group Domain
 * @domain SSSW
 * @changelog
 *
 */
public inherited sharing class MyCustomerCaseRoutingModule extends ApplicationDomain.Module {

	public static MyCustomerCaseRoutingModule newInstance() {
		return (MyCustomerCaseRoutingModule)Application.Utilities.newInstance(MyCustomerCaseRoutingModule.class);
	}

	// Setup which triggers this module should respond to
	public MyCustomerCaseRoutingModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<Case> validCases = new List<Case>();
			for(Case c : (List<Case>)records) {
				if(omniQueues.containsKey(c.OwnerId) == true && String.isBlank(c.Priority) == false) {
					validCases.add(c);
				}
			}
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, true);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, MyCustomerCaseRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Map<Id, Case> oldCases = (Map<Id, Case>)existingRecords;
			List<Case> validCases = new List<Case>();
			for(Case c : (List<Case>)records) {
				// take only cases that have gone to an Omni Queue or have changed priority. 
				if(omniQueues.containsKey(c.OwnerId) == true && (c.OwnerId != oldCases.get(c.Id).OwnerId || c.Priority != oldCases.get(c.Id).Priority)) {
					validCases.add(c);
				}
			}		
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, false);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, MyCustomerCaseRoutingModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private Map<Id, Group> omniQueues {
        get {
            if(omniQueues == null) {
                omniQueues = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
            }
            return omniQueues;
        }
        set;
    }
}