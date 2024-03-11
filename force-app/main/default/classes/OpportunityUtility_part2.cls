/**************************************************
Type:      Additional Utility Class for Opportunity Object - created so as not to void SFDC PS warranty
Purpose:    Oppty Utilities as used by triggers 
                         
History:
--------------------------------------------------
22.11.11    Carl Vescovi    Created and added insertSalesTeamMember Util plus test coverage
31.07.12    Michael McShane Edited the InsertSalesTeamMember to preset inserted role as 'Unknown'
10-12.12    Mat Isidro (Cloud Sherpas)  Added code logic to set the OpportunityAccessLevel of the old opportunity owner to Read/Write
06.06.13    Haider Raza (Auspost)       Added Condition to not over write the Roles of an existing Opportunity Team Member
09.07.15    Eric Shen (Auspost)   update    oppty.StageName = 'Closed Duplicate';
30.10.2015  nandan.narasappa@auspost.com.au  updated running user profile for testOpportunityUtilpart2 method
25.11.2019  RSolomon Commented an unused SOQL in the insertSalesTeamMember method
28/05/2020  Lija Jawahar           SOQL Error fix update
14/07/2020  arjun.singh@auspost.com.au STP-2148 - Add user’s team information as mandatory with an Opportunity Closure
2020-08-02 - Nathan Franklin - Updating registerOpptyOwner to add support for Employee Number
2020-10-02 - arjun.singh@auspost.com.au Added a method to update user role on related split record on opportunity closure
18-01-2021 - Suman Gunaganti   Updated registerOpptyOwner method to populate opportunity closed date/time
2021-02-22 - arjun.singh@auspost.com.au - Modified to update Direct Contribution details on closed opportunity owner change
2021-03-01 - Alvin Zhou   Updated registerOpptyOwner method to reference to the Current_Owner_Role__c in the user object
2021-03-04 - disha.kariya@auspost.com.au - Modified to use Current Owner Role field from User for rollup description for Opportunity Split closing owner.
2023-09-12 - Ranjeewa Silva - Updated to check current closing owner on Opportunity Splits before performing update operation.

**************************************************/

public class OpportunityUtility_part2 {

    public static final string STAGE_CLOSED_WON = 'Closed Won';

    // stores the queried user records as transactional cache when updating the opportunity with the owners employee number
    public static Map<Id, User> queriedOwnerUsers = new Map<Id, User>();

    public static void insertSalesTeamMember(List<Opportunity> newOppList, Map<Id,Opportunity> oldOpptyMap){
        // meets criteria to check if handover process has taken place
        List<OpportunityTeamMember> otm = new List<OpportunityTeamMember>();
        List <OpportunityTeamMember> team_membersList = new List <OpportunityTeamMember>();
        Set<Id> changedOwnerIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        List<OpportunityUserWrapper> opptyUserWrapperList = new List<OpportunityUserWrapper>();

        //28/05/2020  check owner has changed
        for(Opportunity opp : newOppList) {
            if(opp.OwnerId != oldOpptyMap.get(opp.Id).OwnerId ){
                changedOwnerIds.add(opp.OwnerId);
            }
            opptyIds.add(opp.Id);
        }

        //01/06/2020  LJ only need to proceed if the owner has changed
        if(changedOwnerIds.size()>0 ) {

            team_membersList = [
                    SELECT OpportunityId,TeamMemberRole,UserId
                    FROM OpportunityTeamMember
                    WHERE OpportunityId IN :opptyIds
                    AND UserId IN :changedOwnerIds
            ];


            // RSolomon 25Nov2019 Commenting out below query because it isn't being used anywhere. Attempting to refactor code to prevent SOQL101 errors
            /* Map<id,User> userMap = new Map<id,User>([Select id, UserRole.Name from User where id in:oldOwnerIds]); */
            // now build a list of new sales team member records to insert
            //28/05/2020  LJ removed SOQL ouside of for loop
            for (Opportunity opp : newOppList) {
                Id oldOwnerId = oldOpptyMap.get(opp.Id).OwnerId;
                if (opp.OwnerId != oldOwnerId) {
                    List <OpportunityTeamMember> team_member = new List <OpportunityTeamMember>();

                    for (OpportunityTeamMember otmItem : team_membersList) {
                        if (otmItem.OpportunityId == opp.Id && otmItem.UserId == oldOwnerId) {
                            team_member.add(otmItem);
                        }
                    }

                    if (team_member.size() < 1) {
                        OpportunityUserWrapper ouw = new OpportunityUserWrapper(opp.Id, oldOwnerId);
                        opptyUserWrapperList.add(ouw);

                        String userRole;
                        userRole = 'Unknown';
                        if (userRole == null) userRole = 'Unknown';
                        otm.add(new OpportunityTeamMember(UserId = oldOwnerId, OpportunityId = opp.Id, TeamMemberRole = userRole));
                    }
                }
            }

            // build a map of users and their profile, for Sales Team role population.

            // have list of opptys where owner has changed. Now we need to insert new Sales Team members
            if (otm.size() > 0) {
                Database.saveResult[] result = database.insert(otm, false); // provide for partial success if already a team member
                system.debug('*** result: ' + result);
            }

            // Change Opportunity Access Level of old Opportunity owner/s
            setOldOwnerOpportunityAccessLevel(opptyUserWrapperList);
        }
    }

    // This method will set the Opportunity Access Level of the old Opportunity owner/s to Read/Write or Edit
    public static void setOldOwnerOpportunityAccessLevel(List<OpportunityUserWrapper> opptyUserWrapperList) {
        List<OpportunityShare> osList = new List<OpportunityShare>();

        for (OpportunityUserWrapper ouw : opptyUserWrapperList) {
            OpportunityShare os = new OpportunityShare();
            os.OpportunityId = ouw.opptyId;
            os.UserOrGroupId = ouw.userId;
            os.OpportunityAccessLevel = 'Edit';
            //os.RowCause = Schema.OpportunityShare.RowCause.Team;
            osList.add(os);
        }

        if(osList.size() > 0) {
            Database.saveResult[] result = database.insert(osList, false); // provide for partial success
            system.debug('*** result: ' + result);
        }

    }

    /**
     * This updates various user attributes on the Opportunity record
     * 1. When an opp is closed, set the Closing_Owner_Role__c
     * 2. Whenever the owner changes, set the Owner_Employee_Number__c
     */
    public static void registerOpptyOwner(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunities) {
        List<Opportunity> opportunitiesToProcess = new List<Opportunity>();
        List<Opportunity> opportunitiesChangedToClosed = new List<Opportunity>();
        Set<Id> ownerIds = new Set<Id>();
        for(Opportunity o : opportunities) {
            if(oldOpportunities == null || oldOpportunities.get(o.Id) == null ||
                    o.OwnerId != oldOpportunities.get(o.Id).OwnerId ||
                    o.IsClosed != oldOpportunities.get(o.Id).IsClosed) {
                ownerIds.add(o.OwnerId);
                opportunitiesToProcess.add(o);
            }
        }

        if(!ownerIds.isEmpty()) {
            Map<Id, User> users = getRequestedUsers(ownerIds);
            
            for(Opportunity o : opportunitiesToProcess) {
                User opportunityOwnerUser = users.get(o.OwnerId);
                if(opportunityOwnerUser != null) {
                    Opportunity oldOpportunity = (oldOpportunities != null ? oldOpportunities.get(o.Id) : null);
                    Boolean ownerChanged = (oldOpportunity == null || o.OwnerId != oldOpportunity.OwnerId);
                    Boolean closedChanged = (oldOpportunity == null || o.IsClosed != oldOpportunity.IsClosed);

                    o.Owner_Employee_Number__c = opportunityOwnerUser.EmployeeNumber;
                    if (opportunityOwnerUser.UserRole != null) {
                        if (o.IsClosed && (closedChanged || ownerChanged)) {
                            // Update the owner to be the user role rollup description for LPO Users.
                            o.Closing_Owner_Role__c = opportunityOwnerUser.Current_Owner_Role__c;
                            
                            if(closedChanged){
                                o.Opportunity_Closed_Date_Time__c = system.now();
                            }
                            opportunitiesChangedToClosed.add(o);
                        }
                    }
                } else {
                    // the the owner is ever a queue we clear this
                    o.Owner_Employee_Number__c = null;
                }
            }
        }
        if(!opportunitiesChangedToClosed.isEmpty()){
            updateUserRoleOnOpportunitySplits(opportunitiesToProcess);
        }
    }

    /**
    @Description : Updates the User roles on related split records at the time of opportunity closure
     */
    public static void updateUserRoleOnOpportunitySplits(List<Opportunity> opportunitiesToProcess){
        try{
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>(opportunitiesToProcess);
            Set<Id> userIdSet = new Set<Id>();
            List<OpportunitySplit> OpportunitySplitList = new List<OpportunitySplit>();
            List<OpportunitySplit> OpportunitySplitToUpdate = new List<OpportunitySplit>();
            Map<Id, OpportunitySplit> opportunitySplitRecords = OpportunitiesSplitSelector.newInstance().selectByOpportunity(OpportunityMap.keySet());
            
            for(OpportunitySplit oSplit :opportunitySplitRecords.values()){
                userIdSet.add(oSplit.SplitOwnerId);
                OpportunitySplitList.add(oSplit);
            }
            Map<Id, User> userMap = getRequestedUsers(userIdSet);
            for(OpportunitySplit splitRecord : OpportunitySplitList){
                User userDetails = userMap.get(splitRecord.SplitOwnerId);
                if (userDetails.UserRole != null
                        && (splitRecord.Role_Name_at_Opportunity_Closure__c != userDetails.UserRole.Name
                            || splitRecord.Split_Member_Role_At_Opportunity_Closure__c != userDetails.Current_Owner_Role__c)) {

                    splitRecord.Split_Member_Role_At_Opportunity_Closure__c = userDetails.Current_Owner_Role__c;
                    splitRecord.Role_Name_at_Opportunity_Closure__c = userDetails.UserRole.Name;
                    OpportunitySplitToUpdate.add(splitRecord);
                }
            }
            if(!OpportunitySplitToUpdate.isEmpty()){
                ApplicationDatabase.getInstance().dmlUpdate(OpportunitySplitToUpdate);
            }
        }Catch(Exception err){
            GlobalUtility.logMessage('ERROR', 'OpportunityClosureRoleUpdate', 'updateOpportunitySplit', '', '', err.getMessage(), '', null, 0);
        }
    }

    /**
     * Query the user records to get the employee numbers. Only query if the record was not already queried in this transaction
     */
  public static Map<Id, User> getRequestedUsers(Set<Id> requestedUserIds) {
        Set<Id> usersToQuery = requestedUserIds.clone();
        usersToQuery.removeAll(queriedOwnerUsers.keySet());

        if(!usersToQuery.isEmpty()) {
            // replacing the select query with Domain Selector class
            /*List<User> users = [
                Select Id, EmployeeNumber, UserRole.RollupDescription, UserRole.Name
                From User
                Where Id In : usersToQuery
            ];*/            
            Map<Id, User> usrMap = UsersSelector.newInstance().selectById(usersToQuery,  new Set<Object>{UsersSelector.Options.WITH_ROLE});
            List<User> users = new List<User>();
            
            for(User uRecord : usrMap.values()){
                users.add(uRecord);
            }
            queriedOwnerUsers.putAll(users);
        }

        Map<Id, User> output = new Map<Id, User>();
        for(Id userId : queriedOwnerUsers.keySet()) {
            if(requestedUserIds.contains(userId)) {
                output.put(userId, queriedOwnerUsers.get(userId));
            }
        }
        return output;
    }
  /**
   * @Description: Update Direct Contribution records on closed opportunity with correct percent value
   */
  public static void validateAndUpdateDirectContribution(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunities) {
    Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
    for(Opportunity opp: opportunities){
      Opportunity oldOpportunity = oldOpportunities.get(opp.Id);
      if(opp.OwnerId != oldOpportunity.OwnerId && opp.isClosed){
        opportunityMap.put(oldOpportunity.OwnerId, opp);
      }
    }
    if(!opportunityMap.isEmpty()){
            System.enqueueJob(new OpportunitySplitQueueableUtil(opportunityMap));
        }
  }


     /**
    @Description : Set the Primary Proposal's field(s) value, only on Opportunity's respected field value change
     */
    public static void setOpportunityPrimaryProposalFieldValues(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunities){
        //Ref from :createGroupedRevenueSchedules(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunities)
        try{
            Set<Id> fieldUpdatedOpportunityIds = new Set<Id>();
            Opportunity updatedOpportunity;
            for(Opportunity opp: opportunities){
                Opportunity oldOpportunity = oldOpportunities.get(opp.Id);
                if(opp.IsStartrackProposal__c != oldOpportunity.IsStartrackProposal__c
                    || opp.APTPostcodeSuburb__c != oldOpportunity.APTPostcodeSuburb__c
                    || opp.APTMinimumMonthlySpend__c != oldOpportunity.APTMinimumMonthlySpend__c){
                    fieldUpdatedOpportunityIds.add(opp.id);
                    updatedOpportunity = opp;
                }
            }

            if(!fieldUpdatedOpportunityIds.isEmpty()) {
                Boolean isFirstPrimary = false;
                List<Apttus_Proposal__Proposal__c> proposalToUpdate = new List<Apttus_Proposal__Proposal__c>();
                //get proposal(s) of opp
                List<Apttus_Proposal__Proposal__c> existingProposalList = APT_ProposalObjectsSelector.newInstance().selectByOpportunityId(fieldUpdatedOpportunityIds);
                for (Apttus_Proposal__Proposal__c proposal : existingProposalList) {
                    //as per business need only update & check for latest primary proposal
                    if(proposal.Apttus_Proposal__Primary__c && isFirstPrimary == false) {
                        isFirstPrimary = true;
                        proposal.Is_Startrack_Proposal__c = updatedOpportunity.IsStartrackProposal__c;
                        proposal.APT_Postcode_Suburb__c = updatedOpportunity.APTPostcodeSuburb__c;
                        proposal.APT_Minimum_Monthly_Spend__c = updatedOpportunity.APTMinimumMonthlySpend__c;

                        proposalToUpdate.add(proposal);
                    }
                }

                if(!proposalToUpdate.isEmpty()){
                    ApplicationDatabase.getInstance().dmlUpdate(proposalToUpdate);
                }
            }

        }Catch(Exception err){
            GlobalUtility.logMessage('ERROR', 'OpportunityClosureRoleUpdate', 'setOpportunityPrimaryProposalFieldValues', '', '', err.getMessage(), '', null, 0);
        }
    }
}