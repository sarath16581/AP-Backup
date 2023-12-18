/**
 * @description Module that contains business logic for checking the Lead Seeker checkbox on Opportunities created by MyCommunity users eligible for the Lead Seeker program
 * 
 * @test 
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 */
public inherited sharing class OpportunityLeadSeekerModule extends ApplicationModule {
	// Make testing mocks easier
	@TestVisible 
	private Id currentUserId = System.UserInfo.getUserId();
	private User currentUser;
	@TestVisible
	private static final String LEAD_SEEKER_OPPORTUNITY_LEAD_SOURCE = 'MyCommunity';
	private static final String APP = 'Sales';

	// Setup which triggers this module should respond to
	public OpportunityLeadSeekerModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	// Get the Facility record type id, used to determine whether an accout is a CPO
	private Id facilityRTId {
		get {
			if (facilityRTId == null) {
				facilityRTId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set <String>{ 'Facility' }).values()[0].Id;
			}

			return facilityRTId;
		}

		private set;
	}

	/*
	 * Called when a new Opportunity is being inserted
	 * 
	 * @param records the list of new records from the trigger.
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	public override void onBeforeInsert(List <SObject> records, ApplicationUnitOfWork uow) {	
		try {
			if (!records.IsEmpty()) {
				populateLocalBusinessPartnerLeadSeeker((List <Opportunity>)records);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), APP, OpportunityLeadSeekerModule.class.getName(), 'onBeforeInsert', 'Opportunity', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method sets the Lead Source and the Lead Seeker on the Opportunity record, when created by My Community users eligible for the Lead Seeker program
	 * 
	 * @param records the list of new records from the trigger.
	 */
	private void populateLocalBusinessPartnerLeadSeeker(List <Opportunity> records) {
		if (isUserEligibleForLeadSeekerPoints()) {
			for (Opportunity opptyRecord : records) {
				opptyRecord.LeadSource = LEAD_SEEKER_OPPORTUNITY_LEAD_SOURCE;
				opptyRecord.Lead_Seeker__c = true;

				// Populate additional user info on the opportunity - used for reporting purposes
				opptyRecord.Hidden_Lead_Creator_Name__c = currentUser.Name;
				opptyRecord.Hidden_Lead_Seeker_Lead_Owner__c = currentUser.Email;
				opptyRecord.APS_Number__c = currentUser.APSNumber__c;
			}
		}
	}

	/*
	 * This method determines whether a user is eligible for the Lead Seeker program 
	 * Used for Local Business Partners in MyCommunity - when the users create new Opportunities, they're automatically 
	 * enrolled into the Lead Seeker program through which they earn points and rewards.
	 * The criteria is: APS number on the user record and the account record they're associated with is of record type "Facility"
	 */
	private boolean isUserEligibleForLeadSeekerPoints() {
		currentUser = UsersSelector.newInstance(0, new Map<SObjectType, Set <SObjectField>>{
													User.SObjectType => new Set <SObjectField>{ User.APSNumber__c, User.Name, User.Email },
													Account.SObjectType => new Set <SObjectField>{ Account.RecordTypeId }})
										.selectById(new Set <Id> { currentUserId }, 
													new Set <Object> { UsersSelector.Options.WITH_COMMUNITY_ACCOUNT })
										.get(currentUserId);
		
		Boolean userHasAPSNumber = String.IsNotBlank(currentUser?.APSNumber__c);
		Boolean userNetworkIsCPO = currentUser?.Contact?.Account?.RecordTypeId == facilityRTId;

		return userHasAPSNumber && userNetworkIsCPO;
	}
}