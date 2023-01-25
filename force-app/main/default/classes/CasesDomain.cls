/** 
* @description Domain class to handle common logic for all case types
* @author Ashapriya Gadi
* @date 2021-12-06
* @group Domains
* @changelog
* 2022-09-21 - Noel Lim - addition of CaseSkillBasedRoutingModule
*/

public inherited sharing class CasesDomain extends ApplicationDomain{
    public static CasesDomain newInstance(List<SObject> sObjectList) {
        return (CasesDomain)ApplicationDomain.newInstance(CasesDomain.class, sObjectList);
    }
    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        // each module will register their trigger entry points
        // additionally, each module will specify a list of fields that it monitors changes for.
        registerModule(CaseOwnerMetricsModule.class);

        // The case survey Invitation Module tests case data for entry criteria for sending
        // Survey Invitations. Those records which meet specified criteria are enqued and sent to 
        // the survey service and the last survey sent date on the case object is updated to reflect this.
        registerModule(CaseSurveyInvitationModule.class);

        // Logic relating to Omni Skills-based Routing
        // Populate Case attributes used in Skills routing rules
        // Related to SSSW Cases only, the module filters to SSSW Cases only
        // NOTE: must run after the legacy code in CaseTriggerHandler.cls. It has logic that depends on Case.AccountId
        // Refactor Guidance - the logic in this code needs to be positioned: i) in CaseTriggerUtility.beforeHandler() ii) when caseUtility.assignContactIDToCase() is called
        registerModule(CaseSkillBasedRoutingModule.class);

		// Logic relating to Omni Routing
		// Updates the value of OmniRoutingSecondaryPriority field for cases that are assigned or routed to an Omni queue.
		// This is related to SSSW and StarTrack cases, the module filters based on recordtype
        // NOTE: must run after the legacy code in CaseTriggerHandler.cls. It requires the Case to have gone through the routing logic in SSSW_Routing__c.assignCasesAndDescription()
        registerModule(CaseOmniRoutingModule.class);
    }
    /**
     * Trigger instantiation context
     */
    public virtual class Constructor implements ApplicationDomain.IConstructable {
        public ApplicationDomain construct(List<SObject> sObjectList) {
            return CasesDomain.newInstance(sObjectList);
        }
    }
}