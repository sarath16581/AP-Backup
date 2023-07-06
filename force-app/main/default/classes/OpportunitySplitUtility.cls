/*
 * @date 2020-10-01
 * @group Opportunities
 * @tag OpportunitySplit
 * @domain Core
 * @description Utility Class for OpportunitySplit trigger events
 * @changelog
 * 2020-10-01 - arjun.singh@auspost.com.au - Created
 * 2021-02-22 - arjun.singh@auspost.com.au - Modified to update Direct Contribution details on closed opportunity owner change
 * 2021-02-24 - dheeraj.mandavilli@auspost.com.au - Added method to Populate "Split Member Role at Opportunity Closure" Field when
 *												  when a split member is added on a Closed Opportunity.
 * 2023-05-17 - Ranjeewa Silva - Implemented opportunity splits automation on opportunity creation and transfer to a new owner.
 */
public with sharing class OpportunitySplitUtility {
	public static  Boolean RUN_TRIGGER_INSERT = false;
	public static final String DIRECT_CONTRIBUTION = 'Direct Contribution';
	public static final String DIRECT_CONTRIBUTION_MSG = 'DirectContribution';
	public static final String OVERLAY_CONTRIBUTION = 'Overlay Contribution';
	public static final String OVERLAY_CONTRIBUTION_MSG = 'OverlayContribution';
	public static final String CLOSED_OPPORTUNITY_MSG = 'ClosedOpportunity';
	public static final String TOTAL_PERCENT_MSG = 'TotalPercent';
	public static final String OPPORTUNITY_OWNER = 'Opportunity Owner';

	// split type developer name for 'Overlay Contribution' split type
	private static final String OVERLAY_SPLIT_TYPE_DEVELOPER_NAME = 'Opportunity_00N9000000EOb4X_Overlay';

	public static final Map<Id,OpportunitySplitType> SPLIT_TYPE_MAP{
		get{
		if(SPLIT_TYPE_MAP == null){
			SPLIT_TYPE_MAP = new Map<Id,OpportunitySplitType>([SELECT Id, DeveloperName, MasterLabel FROM OpportunitySplitType WHERE isActive = TRUE]);
		}
		return SPLIT_TYPE_MAP;
		}
		private set;
	}
	public static final Map<String,Boolean> BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED{
		get {
		if(BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED == null){ 
			List<PermissionSetAssignment> permissionSetAssigned = [Select Id From PermissionSetAssignment Where PermissionSet.Name = 'BG_Sales_Operations' AND AssigneeId =: userInfo.getUserID()];
			If(!permissionSetAssigned.isEmpty()){
				BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED = new Map<String,Boolean>{String.valueOf(userInfo.getUserID()) => true};
			}else{
				BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED = new Map<String,Boolean>{String.valueOf(userInfo.getUserID()) => false};
			}
		}
		return BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED;
		}
		private set;
	}

	// overlay type mappings configured in custom metadata. used by opportunity splits related automation on creation
	// and transfer of opportunities.
	@TestVisible private static Map<String, SalesOverlayTypeMapping__mdt> overlayTypesMetadata {
		get {
			if (overlayTypesMetadata == null) {

				Map<String, SalesOverlayTypeMapping__mdt> metadata = new Map<String, SalesOverlayTypeMapping__mdt>();

				for (SalesOverlayTypeMapping__mdt record: SalesOverlayTypeMapping__mdt.getAll().values()) {
					metadata.put(record.MasterLabel, record);
				}
				overlayTypesMetadata = metadata;
			}
			return overlayTypesMetadata;
		}
		set;
	}

	/**
	 * Creates a new instance. This allows use to use dependency injection for mocking
	 * @return the new instance
	 */
	public static OpportunitySplitUtility getInstance() {
		return (OpportunitySplitUtility) Application.Utilities.getInstance(OpportunitySplitUtility.class);
	}

	/**
		@Description: will populate the opportunity Onwer role as "Direct Contribution" on related split record at
					  the time of opportunity creation
	 */
	public void populateOpportunityOwnerRole(List<OpportunitySplit> opportunitySplits){
		Map<Id,List<OpportunitySplit>> opportunityWithSplits = new Map<Id,List<OpportunitySplit>>();
		Map<Id,Id> opportunityMap = new Map<Id,Id>();
		for(OpportunitySplit oSplit : opportunitySplits){
			if(SPLIT_TYPE_MAP.containsKey(oSplit.SplitTypeId) && SPLIT_TYPE_MAP.get(oSplit.SplitTypeId).MasterLabel == DIRECT_CONTRIBUTION){
				if(opportunityWithSplits.containsKey(oSplit.opportunityId)){
					List<OpportunitySplit> oSplitList = opportunityWithSplits.get(oSplit.opportunityId);
					oSplitList.add(oSplit);
				}else{
					opportunityWithSplits.put(oSplit.opportunityId, new List<OpportunitySplit>{oSplit});
				}
			}
		}
		Map<Id, Opportunity> opportunities = OpportunitiesSelector.newInstance().selectById(opportunityWithSplits.keySet());

		for(Opportunity oppRecord :opportunities.values()){
			opportunityMap.put(oppRecord.Id, oppRecord.OwnerId);
		}
		for(Id oppId : opportunityWithSplits.keySet()){
			if(opportunityMap.containsKey(oppId)){
				Id opportunityOwnerId = opportunityMap.get(oppId);
				for(OpportunitySplit oSplitVar : opportunityWithSplits.get(oppId)){
					if(oSplitVar.SplitOwnerId == opportunityOwnerId){
						oSplitVar.Overlay_Type__c = DIRECT_CONTRIBUTION ;
					}
				}
			}
		}
	}
	/**
		@Description: Validations check on Opportunity Split record insert or update.
					   1.Only Direct Contribution is allowed in the Overlay Type under this Split
					   2.Direct Contribution is not allowed in the Overlay Type under this Split
					   3.The Total Percent for each Overlay Type must not exceed 100%
					   4.The adding or editing of opportunity splits will be locked when the opportunity is closed
	 */
	public void opportunitySplitValidations(List<OpportunitySplit> opportunitySplits, Map<Id,OpportunitySplit> oldSplitsMap){
		try{
			if(oldSplitsMap == null){
				RUN_TRIGGER_INSERT = true;
			}
			if(!opportunitySplits.isEmpty()){
				Map<Id,Opportunity> opportunityMap = getSplitWithOpportunityDetail(OpportunitySplits);
				Map<Id,List<OpportunitySplit>> splitWithOpportunityMap = new Map<Id,List<OpportunitySplit>>();
				Set<Id> splitIdsFromTrigger = new Set<Id>();
				for(OpportunitySplit oppSplit : OpportunitySplits){
					String splitTypeId = String.valueOf(oppSplit.SplitTypeId) ;
						if(opportunityMap.get(oppSplit.OpportunityId).isClosed && !BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED.get(userInfo.getUserID())){
							//The adding or editing of opportunity splits will be locked when the opportunity is closed
							oppSplit.addError(Label.CLOSED_OPPORTUNITY_MSG);
						} else if(SPLIT_TYPE_MAP != null && SPLIT_TYPE_MAP.containsKey(SplitTypeId)){
							String splitTypeName = SPLIT_TYPE_MAP.get(SplitTypeId).MasterLabel;
							if(String.isBlank(String.valueOf(oppSplit.Overlay_Type__c))){
								//Overlay type should not be blank
								oppSplit.addError(Label.SPLIT_OVERLAY_TYPE_CHECK);
							}else if(splitTypeName  == DIRECT_CONTRIBUTION && oppSplit.Overlay_Type__c != DIRECT_CONTRIBUTION){
							//Only Direct Contribution is allowed in the Overlay Type under this Split
								oppSplit.addError(Label.DIRECT_CONTRIBUTION_MSG);
							} else if(splitTypeName  == OVERLAY_CONTRIBUTION && oppSplit.Overlay_Type__c == DIRECT_CONTRIBUTION){
								//Direct Contribution is not allowed in the Overlay Type under this Split
								oppSplit.addError(Label.OVERLAY_CONTRIBUTION_MSG);
							}else if(splitTypeName  == OVERLAY_CONTRIBUTION){
								if(splitWithOpportunityMap.containsKey(oppSplit.OpportunityId)){
									List<OpportunitySplit> splitListTemp = splitWithOpportunityMap.get(oppSplit.OpportunityId);
									splitListTemp.add(oppSplit);
								}else{
									splitWithOpportunityMap.put(oppSplit.OpportunityId, new List<OpportunitySplit>{oppSplit});
								}
								splitIdsFromTrigger.add(oppSplit.Id);
							}
						}
				}
				if(!splitWithOpportunityMap.isEmpty()){
					splitPercentValidationCheck(splitWithOpportunityMap, splitIdsFromTrigger);
				}
			}
		}catch(Exception ex){
			System.debug('Error>>>'+ex.getMessage());
		}
	}
	/**
		@Description: Calculates the total percent for each overlay type and throws a message in case total percent
					  is greater than 100 for a overlay type.
	 */
	private void splitPercentValidationCheck(Map<Id,List<OpportunitySplit>> splitWithOpportunityMap, Set<Id> splitIdsFromTrigger){
		Map<Id, Map<String,List<OpportunitySplit>>> splitsWithOpportunityMap = new Map<Id, Map<String,List<OpportunitySplit>>>();
		Decimal percentValue; 
		Map<Id, OpportunitySplit> splitsRecords = OpportunitiesSplitSelector.newInstance().selectByOpportunity(splitWithOpportunityMap.keySet());
		Map<Id, Map<String,Boolean>> oppWithExistingSplitsMap = new Map<Id, Map<String,Boolean>>();
		for(OpportunitySplit sp: splitsRecords.values()){
			if(SPLIT_TYPE_MAP.containsKey(sp.SplitTypeId) && SPLIT_TYPE_MAP.get(sp.SplitTypeId).MasterLabel == OVERLAY_CONTRIBUTION) {   
				  if(splitsWithOpportunityMap.containsKey(sp.OpportunityId)){
						Map<String,List<OpportunitySplit>> splitMapTemp = splitsWithOpportunityMap.get(sp.OpportunityId); 
						if(splitMapTemp.containsKey(sp.Overlay_Type__c)){
							List<OpportunitySplit> oList = splitMapTemp.get(sp.Overlay_Type__c);
							oList.add(sp);
						}else{
							splitMapTemp.put(sp.Overlay_Type__c, new List<OpportunitySplit>{sp});
						}
					} else{
							Map<String,List<OpportunitySplit>> splitMapTemp = new Map<String,List<OpportunitySplit>>();
							splitMapTemp.put(sp.Overlay_Type__c, new List<OpportunitySplit>{sp});
							splitsWithOpportunityMap.put(sp.OpportunityId, splitMapTemp);
					}
					if(!splitIdsFromTrigger.contains(sp.Id)){
						if(oppWithExistingSplitsMap.containsKey(sp.opportunityId)){
							Map<String,Boolean> existingMapTemp = oppWithExistingSplitsMap.get(sp.opportunityId);
							existingMapTemp.put(sp.Overlay_Type__c, true);
						} else{
							Map<String,Boolean> existingMapTemp = new Map<String,Boolean>();
							existingMapTemp.put(sp.Overlay_Type__c, true);
							oppWithExistingSplitsMap.put(sp.opportunityId, existingMapTemp);
						}   
					}
			 }
		}
		Set<String> overlaySet = new Set<String>();
		for(String overlayVar: LABEL.OVERLAY_SPECIFIC_VALIDATION.split(';')){
			overlaySet.add(overlayVar);
		} 

		for(Id oppId : splitsWithOpportunityMap.keySet()){
			Map<String,List<OpportunitySplit>> splitMapTemp = splitsWithOpportunityMap.get(oppId);
			for(String overLayType : splitMapTemp.keySet()){
			   // if(splitMapTemp.get(overLayType).size() > 1 && RUN_TRIGGER_INSERT){
				 if(oppWithExistingSplitsMap.containsKey(oppId)){
					Map<String,Boolean> existingRecTemp = oppWithExistingSplitsMap.get(oppId);
					if(existingRecTemp.containsKey(overLayType) && existingRecTemp.get(overLayType) && RUN_TRIGGER_INSERT){
						 //skip the validation as inder and Validadtion will happen on update
						continue;
					}
				 } 
				percentValue = 0;

				for(OpportunitySplit oSplit: splitMapTemp.get(overLayType)){
					percentValue += oSplit.SplitPercentage ;
				}
				if(overlaySet.contains(overLayType) && percentValue != 100){
					//The Total Percent for each Overlay Type must be 100%
					for(OpportunitySplit sRecord : splitWithOpportunityMap.get(oppId)){
						if(sRecord.Overlay_Type__c == overLayType){
							sRecord.addError(Label.OVERLAY_SPECIFIC_TOTAL_PERCENT_MSG);
							break;
						}
					}
				}else if(percentValue > 100){
						//The Total Percent for each Overlay Type must not exceed 100%
						for(OpportunitySplit sRecord : splitWithOpportunityMap.get(oppId)){
							if(sRecord.Overlay_Type__c == overLayType){
								sRecord.addError(Label.TOTAL_PERCENT_MSG);
								break;
							}
						}
				}
								
			}
		}

	}
	/**
		@Description: Returns Opportunity with status and used for validation in which an split record
					  should not be created or edited for closed opportunity
	 */
	private static Map<Id,Opportunity> getSplitWithOpportunityDetail(List<OpportunitySplit> opportunitySplits){
		set<Id> opportunityIdset = new set<Id>();
		for(OpportunitySplit splitRecord: opportunitySplits){
			opportunityIdset.add(splitRecord.OpportunityId);
		}
		Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
		Map<Id, Opportunity> opportunities = OpportunitiesSelector.newInstance().selectById(opportunityIdset);
		
		for(Opportunity opp:opportunities.values()){
			opportunityMap.put(opp.Id, opp);
		}
		return opportunityMap;
	}
	
	public void updateTeamMemberRole(List<OpportunitySplit> opportunitySplits, Map<Id,OpportunitySplit> oldSplitsMap){
		try{
			/* Loop through the list of split records at insert/Update to get the filtered list of split records
				for which related TeamMember record Role should be updated with split overlay type.
				1. At Insert of split record, TeamMember role should be updated to split overlay type.
				2. At Update, it should only update TeamMember Role if there is a change in split overlay type other update
				   of split record will be ignored for TeamMember Role update.
			*/
			List<OpportunitySplit> splitListToProcess = new List<OpportunitySplit>();
			if(oldSplitsMap == null){
				splitListToProcess = OpportunitySplits ;
			}else{
				for(OpportunitySplit oSplit :OpportunitySplits){
					OpportunitySplit oldSplit = oldSplitsMap.get(oSplit.Id);
					if(oSplit.Overlay_Type__c != oldSplit.Overlay_Type__c){
						splitListToProcess.add(oSplit);
					}
				}
			}
			if(!splitListToProcess.isEmpty()){
				Set<Id> userIdSet = new Set<Id>();
				Map<Id,Map<Id,OpportunitySplit>> opportunityWithSplits = new Map<Id,Map<Id,OpportunitySplit>>();
				List<OpportunityTeamMember> teamMemberList = new List<OpportunityTeamMember>();
				Map<Id,Opportunity> opportunityMap = getSplitWithOpportunityDetail(OpportunitySplits);
				for(OpportunitySplit oSplit : OpportunitySplits){
					userIdSet.add(oSplit.SplitOwnerId);
					if(opportunityWithSplits.containsKey(oSplit.OpportunityId)){
						Map<Id,OpportunitySplit> splitMapTemp = opportunityWithSplits.get(oSplit.OpportunityId);
						splitMapTemp.put(oSplit.SplitOwnerId, oSplit);
					}else{
						Map<Id,OpportunitySplit> splitMapTemp = new Map<Id,OpportunitySplit>();
						splitMapTemp.put(oSplit.SplitOwnerId, oSplit);
						opportunityWithSplits.put(oSplit.OpportunityId, splitMapTemp);
					}
				}
				if(!opportunityWithSplits.isEmpty()){
					Map<Id, OpportunityTeamMember> opportunityTeamMembers = OpportunityTeamMembersSelector.newInstance().selectByOpportunityAndUsers(opportunityWithSplits.keySet(), userIdSet);				
					for(OpportunityTeamMember oppTeam :opportunityTeamMembers.values()){
						if(opportunityWithSplits.containsKey(oppTeam.OpportunityId)){
							Map<Id,OpportunitySplit> splitRecordsMap = opportunityWithSplits.get(oppTeam.OpportunityId);
							if(opportunityMap.containsKey(oppTeam.OpportunityId) && opportunityMap.get(oppTeam.OpportunityId).ownerId == oppTeam.UserId){
								if(oppTeam.TeamMemberRole != OPPORTUNITY_OWNER){
									oppTeam.TeamMemberRole = OPPORTUNITY_OWNER ;
									teamMemberList.add(oppTeam);
								}
							}else if(splitRecordsMap.containsKey(oppTeam.UserId)){
								if(oppTeam.TeamMemberRole != splitRecordsMap.get(oppTeam.UserId).Overlay_Type__c){
									oppTeam.TeamMemberRole = splitRecordsMap.get(oppTeam.UserId).Overlay_Type__c;
									oppTeam.OpportunityAccessLevel = 'Edit';
									teamMemberList.add(oppTeam);
								}
							}
						}
					}
					if(!teamMemberList.isEmpty()){
					   // ApplicationDatabase.getInstance().dmlUpdate(teamMemberList);  
						OpportunitySplitRoleUpdate.updateTeamMemberRoleInSystemContext(teamMemberList);  
					}
				}   
			}	 
		}catch(Exception err){
			GlobalUtility.logMessage('ERROR', 'updateTeamMemberRole', 'opportunitySplit', '', '', err.getMessage(), '', null, 0);
		}
	}
	/**
	 * @Description: Create the History records on Split Deletion
	 */
	public void createOpportunitySplitHistoryOnDelete(List<OpportunitySplit> opportunitySplitLists ){
		try{
			List<Opportunity_Split_History__c> splitHistoryList = new List<Opportunity_Split_History__c>();
			String uniqueNumber ;
			uniqueNumber =  'Audit' + String.valueOf(System.now().getTime());
				
			for(OpportunitySplit oSplitVar : opportunitySplitLists){
				if(SPLIT_TYPE_MAP.containsKey(oSplitVar.SplitTypeId)){
					Opportunity_Split_History__c historyVar = new Opportunity_Split_History__c();
					historyVar.Overlay_Type__c = oSplitVar.Overlay_Type__c + ' (Deleted)';
					historyVar.Split_Percent__c = oSplitVar.SplitPercentage ;
					historyVar.Split_Type__c = String.valueOf(SPLIT_TYPE_MAP.get(oSplitVar.SplitTypeId).MasterLabel) ;
					historyVar.Team_Member__c = oSplitVar.splitOwnerId ;
					historyVar.Opportunity__c = oSplitVar.opportunityId;
					historyVar.Split_Record_Id__c = oSplitVar.Id;
					splitHistoryList.add(historyVar);
				}
			}
			if(!splitHistoryList.isEmpty()){
				ApplicationDatabase.getInstance().dmlInsert(splitHistoryList);
			}
		}catch(Exception err){
			GlobalUtility.logMessage('ERROR', 'createOpportunitySplitHistoryOnDelete', 'opportunitySplit', '', '', err.getMessage(), '', null, 0);
		}
	}	
	/**
	 * @Description: Creates Opportunity Split History records based on insert/updates in Splits records
	 */
	public void createOpportunitySplitHistory(List<OpportunitySplit> opportunitySplitLists ){
		try{
			List<Opportunity_Split_History__c> splitHistoryList = new List<Opportunity_Split_History__c>();
			for(OpportunitySplit oSplitVar : opportunitySplitLists){
				if(SPLIT_TYPE_MAP.containsKey(oSplitVar.SplitTypeId)){
					Opportunity_Split_History__c historyVar = new Opportunity_Split_History__c();
					historyVar.Overlay_Type__c = oSplitVar.Overlay_Type__c ;
					historyVar.Split_Percent__c = oSplitVar.SplitPercentage ;
					historyVar.Split_Type__c = String.valueOf(SPLIT_TYPE_MAP.get(oSplitVar.SplitTypeId).MasterLabel) ;
					historyVar.Team_Member__c = oSplitVar.splitOwnerId ;
					historyVar.Opportunity__c = oSplitVar.opportunityId;
					historyVar.Split_Record_Id__c = oSplitVar.Id;
					historyVar.Split_Amount__c = String.valueOf(oSplitVar.SplitAmount);
					splitHistoryList.add(historyVar);
				}
			}
			if(!splitHistoryList.isEmpty()){
				ApplicationDatabase.getInstance().dmlInsert(splitHistoryList);
			}
		}catch(Exception err){
			GlobalUtility.logMessage('ERROR', 'createOpportunitySplitHistoryOnDelete', 'opportunitySplit', '', '', err.getMessage(), '', null, 0);
		}
	}
	
	/**
	* @Description: Populate Split Member Role at Opportunity Closure field before inserting the Opportunity Split records on Closed 
	* 				 opportunities.
	*/
	public void populateSplitMemberRoleAtOpportunityClosure(List<OpportunitySplit> opportunitySplits){
		
		Map<Id,Opportunity> opportunityMap = getSplitWithOpportunityDetail(opportunitySplits); 
		
		for(OpportunitySplit splitRecord : opportunitySplits){
			if(opportunityMap.get(splitRecord.OpportunityId).isClosed && BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED.get(userInfo.getUserID())){
				splitRecord.Split_Member_Role_At_Opportunity_Closure__c = (splitRecord.Split_Member_Role_At_Opportunity_Closure__c != null ? splitRecord.Split_Member_Role_At_Opportunity_Closure__c : splitRecord.Split_Member_Current_Role__c);					   
			}
		}
	}

	public enum OverlayTypeFilters {
		SUPPORTS_AUTO_ASSIGNMENT, SUPPORTS_KEEP_SPLITS
	}

	/**
	 * Return eligible overlay types for specified set of users. Overlay types returned are also filtered based on the
	 * specified filters.
	 *
	 * Eligibility is dependent on:
	 * 1. Custom Metadata Type - SalesOverlayTypeMapping__mdt contains the mapping of each supported overlay type
	 *	in the system to the public group that is eligible for that overlay type.
	 * 2. Public groups referenced in custom metadata is then checked to see if specified users are members of those groups.
	 *	users who are group members become eligible for corresponding overlay type.
	 *
	 * @param userIds set of user ids to check
	 * @param filters filters to apply in checking overlay type eligibility.
	 *
	 * @return eligible overlay types for each user. Returns a map where key = user id and value = eligible overlay types.
	 *		 Note that only the eligible users are returned in the map.
	 */
	public Map<Id, Set<String>> getEligibleOverlayContributionTypes(Set<Id> userIds, Set<OverlayTypeFilters> filters) {

		Map<Id, Set<String>> results = new Map<Id, Set<String>>();

		// get the mapping of public group --> overlay types
		// key = group developer name, value = set of eligible overlay types.
		Map<String, Set<String>> mappings = getSpecialistUserGroupOverlayTypeMappings(filters);

		if (!mappings.isEmpty()) {

			// delegate to service class to expand membership of the public groups.
			Map<String, Set<Id>> groupMemberUsers = GroupMembershipService.getInstance().expandGroupMembership(mappings.keySet(), new Set<GroupMembershipService.MemberTypes>{
					GroupMembershipService.MemberTypes.USER,
					GroupMembershipService.MemberTypes.ROLE,
					GroupMembershipService.MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL
			});

			// work out the results to return based on group membership and overlay type mappings.
			for (String groupName: groupMemberUsers.keySet()) {
				Set<Id> eligibleUsers = groupMemberUsers.get(groupName).clone();
				eligibleUsers.retainAll(userIds);
				for (Id eligibleUserId: eligibleUsers) {
					Set<String> overlayTypes = results.get(eligibleUserId);
					if (overlayTypes == null) {
						overlayTypes = new Set<String>{};
						results.put(eligibleUserId, overlayTypes);
					}
					overlayTypes.addAll(mappings.get(groupName));
				}
			}
		}

		return results;
	}

	@TestVisible private Map<String, Set<String>> getSpecialistUserGroupOverlayTypeMappings(Set<OverlayTypeFilters> filters) {
		Map<String, Set<String>> mappings = new Map<String, Set<String>>();
		for (SalesOverlayTypeMapping__mdt metadata: overlayTypesMetadata.values()) {
			if (filters == null || filters.isEmpty()
					|| (filters.contains(OverlayTypeFilters.SUPPORTS_AUTO_ASSIGNMENT) && metadata.AutoAssignOnOpportunityCreation__c)
					|| (filters.contains(OverlayTypeFilters.SUPPORTS_KEEP_SPLITS) && metadata.KeepSplitsOnOpportunityTransfer__c)) {

				if (mappings.get(metadata.SalesSpecialistGroupName__c) == null) {
					mappings.put(metadata.SalesSpecialistGroupName__c, new Set<String>{});
				}
				mappings.get(metadata.SalesSpecialistGroupName__c).add(metadata.MasterLabel);
			}
		}
		return mappings;
	}

	/**
	 * Async worker implementation that creates opportunity splits based on the parameters supplied.
	 */
	public without sharing class AsyncAutoAssignOpportunitySplitsWorker extends ApplicationUnitOfWork.AsyncWorker {

		private List<AutoAssignOpportunitySplitsWorkerParam> params;

		public override void execute(ApplicationUnitOfWork uow) {

			if (this.params != null && !this.params.isEmpty()) {

				Id overlayContributionSplitTypeId = getSplitTypeId();

				List<OpportunitySplit> creatable = new List<OpportunitySplit>();
				for (AutoAssignOpportunitySplitsWorkerParam param: params) {
					for (String overlayType: param.overlayTypes) {
						creatable.add(new OpportunitySplit(OpportunityId = param.opportunityId, SplitTypeId = overlayContributionSplitTypeId, Overlay_Type__c = overlayType,
								SplitOwnerId = param.ownerId, SplitPercentage = overlayTypesMetadata.get(overlayType)?.DefaultPercentageAssignedOnCreation__c));
					}
				}

				if (!creatable.isEmpty()) {
					uow.registerNew(creatable, false, AsyncAutoAssignOpportunitySplitsWorker.class.getName());
				}
			}
		}

		public override Type getClassType() {
			return AsyncAutoAssignOpportunitySplitsWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return OpportunitySplit.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				this.params = (List<AutoAssignOpportunitySplitsWorkerParam>) JSON.deserialize(serialisedParams, List<AutoAssignOpportunitySplitsWorkerParam>.class);
			}
		}

		private Id getSplitTypeId() {
			for (OpportunitySplitType splitType: SPLIT_TYPE_MAP.values()) {
				if (splitType.DeveloperName.equalsIgnoreCase(OVERLAY_SPLIT_TYPE_DEVELOPER_NAME)) {
					return splitType.Id;
				}
			}
			return null;
		}
	}

	public class AutoAssignOpportunitySplitsWorkerParam {
		@TestVisible private Id opportunityId;
		@TestVisible private Id ownerId;
		@TestVisible private Set<String> overlayTypes = new Set<String>();

		public AutoAssignOpportunitySplitsWorkerParam(Id opportunityId, Id ownerId, Set<String> overlayTypes) {
			this.opportunityId = opportunityId;
			this.ownerId = ownerId;
			this.overlayTypes = overlayTypes;
		}
	}

	/**
	 * Async worker implementation that reconciles opportunity splits based on the parameters supplied.
	 */
	public without sharing class AsyncReconcileOpportunitySplitsWorker extends ApplicationUnitOfWork.AsyncWorker {

		private Map<Id, ReconcileOpportunitySplitsWorkerParam> params = new Map<Id, ReconcileOpportunitySplitsWorkerParam>();

		public override void execute(ApplicationUnitOfWork uow) {
			if (this.params != null && !this.params.isEmpty()) {
				// query opportunities with child overlay splits
				Map<Id, Opportunity> opportunitiesWithSplits = OpportunitiesSelector.newInstance().selectById(params.keySet(), new Set<Object>{
						OpportunitiesSelector.Options.WITH_OVERLAY_SPLITS
				});

				// retrieve eligible split owners based on custom metadata configuration and group membership
				Set<Id> eligibleOverlaySplitOwners = getEligibleOverlaySplitOwners();

				// identify opportunity splits to be created, updated and deleted as part of reconciliation process
				Map<Id, OpportunitySplit> deletable = new Map<Id, OpportunitySplit>();
				List<OpportunitySplit> creatable = new List<OpportunitySplit>();
				List<OpportunitySplit> updatable = new List<OpportunitySplit>();

				for (ReconcileOpportunitySplitsWorkerParam param: params.values()) {
					// check if previous owner is an eligible overlay type split owner. we only need to reconcile when
					// previous owner is eligible to own overlay contribution splits.
					// this check is done in async process as expanding public groups synchronously in update triggers
					// could be an expensive operation.
					if (eligibleOverlaySplitOwners.contains(param.previousOwnerId)) {
						Opportunity opportunityWithSplits = opportunitiesWithSplits.get(param.opportunityId);
						for (OpportunitySplitSnapshot snapshot: param.splitsOwnedByPreviousOpportunityOwner) {
							// platform restricts a given user can have only one split record per each split type.
							// when opportunity is transferred to a new owner, any overlay splits owned by prior owner will
							// also be moved to new opportunity owner.
							// in the unlikely event if new owner had an overlay contribution split assigned for another overlay type prior to the change,
							// platform will try and merge the 2 overlay contribution splits:
							//  - one overlay split already owned by new owner prior to the owner change
							//  - one overlay split owned by previous owner, now being moved to new owner
							OpportunitySplit currentSplit = findOverlaySplitAssignedToNewOpportunityOwner(opportunityWithSplits, snapshot);
							if (currentSplit != null) {
								creatable.add(snapshot.toCreatableOpportunitySplit(param.opportunityId));
								if (currentSplit.Overlay_Type__c != snapshot.overlayType && currentSplit.SplitPercentage > snapshot.splitPercentage) {
									// new owner had overlay split assigned to him before owner change.
									// it has resulted in splits being merged. reverse merge and restore any splits owned by new opp owner
									updatable.add(new OpportunitySplit(Id = currentSplit.Id, SplitPercentage = (currentSplit.SplitPercentage - snapshot.splitPercentage)));
								} else {
									deletable.put(currentSplit.Id, new OpportunitySplit(Id = currentSplit.Id));
								}
							}
						}
					}
				}

				if (!creatable.isEmpty()) {
					uow.registerNew(creatable, false, AsyncReconcileOpportunitySplitsWorker.class.getName());
				}

				if (!deletable.isEmpty()) {
					uow.registerDeleted(deletable.values(), false, AsyncReconcileOpportunitySplitsWorker.class.getName());
				}

				if (!updatable.isEmpty()) {
					uow.registerDirty(updatable, false, AsyncReconcileOpportunitySplitsWorker.class.getName());
				}
			}
		}

		public override Type getClassType() {
			return AsyncReconcileOpportunitySplitsWorker.class;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				try {
					this.params = (Map<Id, ReconcileOpportunitySplitsWorkerParam>) JSON.deserialize(serialisedParams, Map<Id, ReconcileOpportunitySplitsWorkerParam>.class);
				} catch (Exception e) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', OpportunitySplitUtility.class.getName(),
							'deserialiseParams', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
				}

			}
		}

		public override SObjectType getSObjectTypeGroup() {
			return OpportunitySplit.SObjectType;
		}

		private Set<Id> getEligibleOverlaySplitOwners() {
			Set<Id> previousOwnerIds = new Set<Id>();
			for (ReconcileOpportunitySplitsWorkerParam param: params.values()) {
				previousOwnerIds.add(param.previousOwnerId);
			}

			Map<Id, Set<String>> eligibleUsers = OpportunitySplitUtility.getInstance().getEligibleOverlayContributionTypes(previousOwnerIds, new Set<OverlayTypeFilters>{
					OverlayTypeFilters.SUPPORTS_KEEP_SPLITS
			});

			return eligibleUsers.keySet();
		}

		private OpportunitySplit findOverlaySplitAssignedToNewOpportunityOwner(Opportunity opportunity, OpportunitySplitSnapshot snapshot) {
			for (OpportunitySplit split: opportunity.OpportunitySplits) {
				//if (split.SplitOwnerId == opportunity.OwnerId && split.Overlay_Type__c == snapshot.overlayType && split.SplitPercentage == snapshot.splitPercentage) {
				if (split.SplitOwnerId == opportunity.OwnerId && split.SplitTypeId == snapshot.splitTypeId) {
					return split;
				}
			}
			return null;
		}
	}

	public class ReconcileOpportunitySplitsWorkerParam {
		@TestVisible private Id opportunityId;
		@TestVisible private Id previousOwnerId;
		@TestVisible private List<OpportunitySplitSnapshot> splitsOwnedByPreviousOpportunityOwner = new List<OpportunitySplitSnapshot>();

		public ReconcileOpportunitySplitsWorkerParam(Id opportunityId, Id previousOwnerId) {
			this.opportunityId = opportunityId;
			this.previousOwnerId = previousOwnerId;
		}

		public void addOpportunitySplitSnapshot(OpportunitySplitSnapshot snapshot) {
			this.splitsOwnedByPreviousOpportunityOwner.add(snapshot);
		}

		public Boolean hasSplitsOwnedByPreviousOwner() {
			return !this.splitsOwnedByPreviousOpportunityOwner.isEmpty();
		}
	}

	public class OpportunitySplitSnapshot {
		@TestVisible private Id splitId;
		@TestVisible private Id splitOwnerId;
		@TestVisible private Id splitTypeId;
		@TestVisible private Decimal splitPercentage;
		@TestVisible private String overlayType;
		public OpportunitySplitSnapshot(OpportunitySplit split) {
			this.splitId = split.Id;
			this.splitOwnerId = split.SplitOwnerId;
			this.splitTypeId = split.SplitTypeId;
			this.splitPercentage = split.SplitPercentage;
			this.overlayType = split.Overlay_Type__c;
		}

		private OpportunitySplit toCreatableOpportunitySplit(Id opportunityId) {
			return new OpportunitySplit(OpportunityId = opportunityId, SplitOwnerId = this.splitOwnerId,
					SplitTypeId = this.splitTypeId, SplitPercentage = this.splitPercentage, Overlay_Type__c = this.overlayType);
		}
	}
}