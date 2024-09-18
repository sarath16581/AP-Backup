/**
 * @description Application Module to handle the creation of CaseTeamMember.
 *	This is to ensure newly assigned as well as historical case owner will have sharing access of the case, even if it's passed on to another agent.
 *	The creation of CaseTeamMember happens on new creation of a unified case or case owner update of an existing unified case.
 * @author Seth Heang
 * @date 2024-09-02
 * @test CaseUnifiedTeamMemberModuleTest
 * @changelog
 * 2024-09-02 - Seth Heang - Created.
 */
public with sharing class CaseUnifiedTeamMemberModule extends ApplicationModule {
	@TestVisible
	private static final String UNIFIED_CASE_TEAM_ROLE = 'Unified Agent';

	public static CaseUnifiedTeamMemberModule newInstance() {
		return (CaseUnifiedTeamMemberModule) Application.Utilities.newInstance(CaseUnifiedTeamMemberModule.class);
	}

	public CaseUnifiedTeamMemberModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	/**
	 * @description Called a after Insert and Performs below operations:
	 * 1. Create CaseTeamMember from Case's owner Id
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			processCaseTeamMemberCreation((List<Case>) records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedTeamMemberModule.class.getName(), 'onAfterInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description Called a after Update and Performs below operations:
	 * 1. Create CaseTeamMember from Case's owner Id
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			processCaseTeamMemberCreation((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedTeamMemberModule.class.getName(), 'onAfterUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description process case team member creation for AfterInsert scenario
	 * @param records new cases from trigger
	 * @param uow
	 */
	private void processCaseTeamMemberCreation(List<Case> records, ApplicationUnitOfWork uow) {
		processCaseTeamMemberCreation(records, null, uow);
	}

	/**
	 * @description process case team member creation for AfterUpdate scenario
	 * @param records new cases from trigger
	 * @param existingRecords existing cases from trigger
	 * @param uow
	 */
	private void processCaseTeamMemberCreation(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		// for AfterInsert Scenario, not required to check for changed state
		if (existingRecords == null) {
			createCaseTeamMember(records, uow);
			return;
		}

		// for AfterUpdate Scenario, check for changed state
		String context = CaseUnifiedTeamMemberModule.class.getName();
		Set<SObjectField> monitoredFields = new Set<SObjectField>{ Case.OwnerId };
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields);
		List<Case> filteredCases = new List<Case>();

		String userPrefix = User.getSObjectType().getDescribe().getKeyPrefix();
		// Eligibility Check on changed state
		for (ApplicationRecursion.RecordState recordState : changedRecords) {
			Case updatedCase = (Case) recordState.record;
			Set<SObjectField> changed = recordState.changedFields;
			String caseOwnerPrefix = updatedCase.OwnerId.toString().substring(0, 3);
			// check for ownerId changes and new ownerId belongs to a user
			if (!changed.isEmpty() && changed.contains(Case.OwnerId) && caseOwnerPrefix == userPrefix) {
				filteredCases.add(updatedCase);
			}
		}

		if (!filteredCases.isEmpty()) {
			createCaseTeamMember(filteredCases, uow);
		}
	}

	/**
	 * @description create case team member after filtering for valid cases
	 * @param cases
	 * @param uow
	 */
	private void createCaseTeamMember(List<Case> cases, ApplicationUnitOfWork uow) {
		// unified agent case team role
		Id unifiedCaseTeamRoleId = Utility.getCaseTeamRole(UNIFIED_CASE_TEAM_ROLE);

		// filter out cases that has existing case team member, to prevent inserting duplicate
		List<Case> filteredCases = filterCasesWithoutExistingCaseTeamMember(cases, unifiedCaseTeamRoleId);
		// terminate if there is no filtered cases
		if (filteredCases.isEmpty()){
			return;
		}

		// Add Case Team Member record for each Case
		List<CaseTeamMember> insertCaseTeamMembers = new List<CaseTeamMember>();
		for (Case cs : filteredCases) {
			insertCaseTeamMembers.add(new CaseTeamMember(ParentId = cs.Id, MemberId = cs.OwnerId, TeamRoleId = unifiedCaseTeamRoleId));
		}

		if (!insertCaseTeamMembers.isEmpty()) {
			uow.registerNew(insertCaseTeamMembers, false, CaseUnifiedTeamMemberModule.class.getName() + '.createCaseTeamMember');
		}
	}

	/**
	 * @description retrieve a filtered list of cases that do not have any existing team member by filtering a unique configuration of case Id, case owner and team role.
	 *  		This is done to prevent duplicate creation of case team member.
	 * @param cases new cases from trigger
	 * @param unifiedCaseTeamRoleId
	 * 
	 * @return List<Case> Cases which need Case Team Member to be created
	 */
	private static List<Case> filterCasesWithoutExistingCaseTeamMember(List<Case> cases, Id unifiedCaseTeamRoleId) {
		Set<Id> caseOwnerIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		for (Case parentCase : cases) {
			caseIds.add(parentCase.Id);
			caseOwnerIds.add(parentCase.OwnerId);
		}
		// fetch existing team members for the given cases and members and unified team role
		List<CaseTeamMember> existingCaseTeamMembers = CaseTeamMembersSelector.newInstance().selectByCaseIdAndMemberIdAndTeamRoleId(caseIds, caseOwnerIds, new Set<Id>{ unifiedCaseTeamRoleId });
		if (existingCaseTeamMembers.isEmpty()){
			return cases;
		}
		// build key for unique combination of case Id and member Id
		Set<String> uniqueKeyForExistingCaseAndMemberId = new Set<String>();
		for (CaseTeamMember teamMember : existingCaseTeamMembers) {
			uniqueKeyForExistingCaseAndMemberId.add(teamMember.ParentId + ':' + teamMember.MemberId);
		}
		// build filter cases list using unique key
		List<Case> filteredCases = new List<Case>();
		for (Case cs : cases) {
			String uniqueKeyForCaseIdOwnerId = cs.Id + ':' + cs.OwnerId;
			if(!uniqueKeyForExistingCaseAndMemberId.contains(uniqueKeyForCaseIdOwnerId)){
				filteredCases.add(cs);
			}
		}
		return filteredCases;
	}
}