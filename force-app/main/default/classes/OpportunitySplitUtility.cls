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
 *                                                  when a split member is added on a Closed Opportunity.
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

    public static final Map<Id,OpportunitySplitType> SPLIT_TYPE_MAP{
        get{
		if(SPLIT_TYPE_MAP == null){                    
			SPLIT_TYPE_MAP = new Map<Id,OpportunitySplitType>([Select Id, MasterLabel From OpportunitySplitType Where isActive = true]);                  
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
            System.debug('BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED>>>'+BG_SALES_OPERATION_PERMISSIONSET_ASSIGNED);
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
        System.debug('overlaySet>>>>>'+overlaySet);
        System.debug('splitsWithOpportunityMap>>>>>'+splitsWithOpportunityMap);
        System.debug('oppWithExistingSplitsMap>>>>>'+oppWithExistingSplitsMap);
        for(Id oppId : splitsWithOpportunityMap.keySet()){
            Map<String,List<OpportunitySplit>> splitMapTemp = splitsWithOpportunityMap.get(oppId);     
            for(String overLayType : splitMapTemp.keySet()){
               // if(splitMapTemp.get(overLayType).size() > 1 && RUN_TRIGGER_INSERT){
                 if(oppWithExistingSplitsMap.containsKey(oppId)){
                     System.debug('Here>>>>>1');
                    Map<String,Boolean> existingRecTemp = oppWithExistingSplitsMap.get(oppId);
                    if(existingRecTemp.containsKey(overLayType) && existingRecTemp.get(overLayType) && RUN_TRIGGER_INSERT){
                        System.debug('Here>>>>>2');
                         //skip the validation as inder and Validadtion will happen on update
                        continue;
                    }
                 } 
                percentValue = 0;               

                for(OpportunitySplit oSplit: splitMapTemp.get(overLayType)){
                    percentValue += oSplit.SplitPercentage ;
                }
                System.debug('percentValue>>>>'+percentValue);
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
            System.debug('splitListToProcess>>>>'+splitListToProcess);
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
                System.debug('opportunityWithSplits>>>>'+opportunityWithSplits);
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
                    System.debug('teamMemberList>>>>>'+teamMemberList);
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
}