/**
 * @description Application Module to handle creating CaseTeamMember for new or updated Case for Unified Case Automation
 *
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

		// check for existing case team member then terminate, to prevent inserting duplicate
		if (hasExistingCaseTeamMember(cases, unifiedCaseTeamRoleId)) {
			return;
		}

		// Add Case Team Member record for each Case
		List<CaseTeamMember> insertCaseTeamMembers = new List<CaseTeamMember>();
		for (Case cs : cases) {
			insertCaseTeamMembers.add(new CaseTeamMember(ParentId = cs.Id, MemberId = cs.OwnerId, TeamRoleId = unifiedCaseTeamRoleId));
		}

		if (!insertCaseTeamMembers.isEmpty()) {
			uow.registerNew(insertCaseTeamMembers, false, CaseUnifiedTeamMemberModule.class.getName() + '.createCaseTeamMember');
		}
	}

	/**
	 * @description check for existing case team member based on caseId, memberId and teamRoleId in order to prevent duplicate creation
	 * @param cases new cases from trigger
	 * @param unifiedCaseTeamRoleId
	 *
	 * @return Boolean
	 */
	private static Boolean hasExistingCaseTeamMember(List<Case> cases, Id unifiedCaseTeamRoleId) {
		Set<Id> caseOwnerIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		for (Case parentCase : cases) {
			caseIds.add(parentCase.Id);
			caseOwnerIds.add(parentCase.OwnerId);
		}
		List<CaseTeamMember> existingCaseTeamMember = CaseTeamMembersSelector.newInstance().selectByCaseIdAndMemberIdAndTeamRoleId(caseIds, caseOwnerIds, new Set<Id>{ unifiedCaseTeamRoleId });
		// Check for existing CaseTeamMember and prevent duplicate creation of CaseTeamMember
		if (!existingCaseTeamMember.isEmpty()) {
			return true;
		}
		return false;
	}
}