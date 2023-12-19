/**
 * @auth: Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date: 2022-06-02
 * @desc: Generic Domain class created to perform logic as per trigger framework.
 * @test DealSupportRequestGenericDomain_Test
 * @change log:
 * Dattaraj Deshmukh - 2022-06-02  - Created
 * Ken McGuire - 2022-08-08 registered survey invitation module
 * Pratyush Chalasani - 2023-07-12 - Added SurchargeExemptionRequestModule
 */
public with sharing class DealSupportRequestGenericDomain  extends ApplicationDomain{
    public static DealSupportRequestGenericDomain newInstance(List<SObject> sObjectList) {
		return (DealSupportRequestGenericDomain)ApplicationDomain.newInstance(DealSupportRequestGenericDomain.class, sObjectList);
	}
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(DealSupportRequestMilestonesTrackModule.class);
		// The Deal Support survey Invitation Module tests case data for entry criteria for sending
		// Survey Invitations. Those records which meet specified criteria are enqued and sent to 
		// the survey service and the last survey sent date on the deal support request object is updated to reflect this.
		registerModule(DealSupportSurveyInvitationModule.class);
		// The sales record sharing module shares deal support request records based on parent records
		registerModule(SalesRecordSharingModule.class);
		// Module for processing surchage exemption approvals
		registerModule(SurchargeExemptionRequestModule.class);
	}
	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return DealSupportRequestGenericDomain.newInstance(sObjectList);
		}
	}
}