/*** 
 * @description
 * Domain Module to reassign Closed Cases from Omnichannel Queues to a Closed Cases Omni queue
 * This function removes Closed cases in Omni Queues, and therefore prevents such cases being routed to an Agent.
 * Only Cases in Queues with a Routing Configuration are reassigned.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-11-22 - Noel Lim - Created
 */

public inherited sharing class CaseClosedRoutingModule extends ApplicationDomain.Module  {
    
    static Set<Id> validRecTypes {
		get {
			if(validRecTypes == null) {
				validRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			}
			return validRecTypes;
		}
		private set;
	}
	
	static String omniClosedCaseQueueId {
		get {
			if(omniClosedCaseQueueId == null) {
				omniClosedCaseQueueId = QM__c.getOrgDefaults().ClosedQueueId__c;
			}
			return omniClosedCaseQueueId;
		}
		private set;
	}

	static Map<Id, Group> omniGroups {
		get {
			if(omniGroups == null) {
				omniGroups = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
			}
			return omniGroups;
		}
		private set;
	}

    /*
     * Creates a new instance of the utility to facilitate dependency injection for mocking
     * @return the new instance
     */
    public static CaseClosedRoutingModule newInstance() {
        return (CaseClosedRoutingModule)Application.Utilities.newInstance(CaseClosedRoutingModule.class);
    }
    
	// Setup which triggers this module should respond to
    public CaseClosedRoutingModule() {
        // Setup which triggers this module should respond to
        getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();        
    }
    
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            reassignClosedCases(filterToClosedCases(records, null), uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ClosedCase', CaseClosedRoutingModule.class.getName(), 'onBeforeInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
        }       
    }

    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            reassignClosedCases(filterToClosedCases(records, existingRecords), uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ClosedCase', CaseClosedRoutingModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
        }       
    }

    /**
     * Filter based on the following:
     * a) Closed Cases
     * b) Case Status changed or Case Owner changed
     * c) Case is assigned to a queue with a routing configuration
     */
    private Map<Id,Case> filterToClosedCases(List<SObject> records, Map<Id, SObject> existingRecords) {

        Map<Id, Case> closedCases = new Map<Id, Case>();
        Case oldCase;

		for(Case csRec: (List<Case>)records) {
            if(existingRecords != null){
                oldCase = (Case)existingRecords.get(csRec.Id);
            }

			if ((oldCase?.Status != csRec.Status || oldCase?.OwnerId != csRec.OwnerId) 
					&& String.isEmpty(omniClosedCaseQueueId) == false 
					&& Utility.getCaseClosedStatus().contains(csRec.Status) 
					&& omniGroups.containsKey(csRec.OwnerId) 			
			){	
				closedCases.put(csRec.Id,csRec);
			}
		}
						

        return closedCases;
    }

    /**
     * Assign the Case to the Closed Omnichannel Queue
     */
    private void reassignClosedCases(Map<Id, Case> closedCases, ApplicationUnitOfWork uow) {        

        
		if(closedCases.isEmpty() == false && String.isEmpty(omniClosedCaseQueueId) == false ) {
			for(Case csRec: closedCases.values()) {
				csRec.OwnerId = omniClosedCaseQueueId;
			}
		}
    }

}