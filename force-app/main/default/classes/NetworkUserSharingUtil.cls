/*******************************  History ************************************************
    Date                User                                        Comments
    09/09/2016          nandan.narasappa@auspost.com.au             updated deleteNetworkAndCaseShares method for INC0763511 fix  
    01/02/2019            Swati.mogadala@auspost.com.au             Changed the deleteNetworkAndCaseShares method for reduce looping and improve performance REQ1646877 
    
*******************************  History ************************************************/
public class NetworkUserSharingUtil { 

    public static void insertNetworkAndCaseShares(List<Facility_User__c> newNetworkUsers) {
        Map<Id, List<Id>> networkUsers = new Map<Id, List<Id>>();
        for (Facility_User__c nu : newNetworkUsers) {
            if (nu.Network__c != null && nu.User__c != null && nu.Is_MyNetwork_User__c) {  //Kalpi: Added check for mynetwork users Is_MyNetwork_User__c
                if (networkUsers.get(nu.Network__c) == null) {
                    networkUsers.put(nu.Network__c, new List<Id>());
                }
                networkUsers.get(nu.Network__c).add(nu.User__c);
            }
        }
        
        if (!networkUsers.isEmpty()) {        
            // Network Apex Managed Sharing
            List<Network__Share> networkShares = new List<Network__Share>();
            Set<Id> networkIds = networkUsers.keySet();
            for (Id netId : networkIds) {
                for (Id userId : networkUsers.get(netId)) {
                    networkShares.add(new Network__Share(
                        ParentId = netId,
                        UserOrGroupId = userId,
                        AccessLevel = 'edit',
                        RowCause = Schema.Network__Share.RowCause.Facility_Staff__c
                    ));
                }               
            }                       
            Database.SaveResult[] networkResult = Database.insert(networkShares,false);          
           
            // Case sharing using Case Teams
            List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
            for (Case cas : [Select Id, Network__c From Case Where Network__c in :networkUsers.keySet() 
                                AND Permanent_Close__c = FALSE]) {    // Added Filter for INC0584835 fix : Nandan N
                // each user has access to each case
                for (Id userId : networkUsers.get(cas.Network__c)) {
                    caseTeamMembers.add(new CaseTeamMember(
                        TeamRoleId = Id.valueOf(CaseSharingUtil.teamRoleId),
                        ParentId = cas.Id,                        
                        MemberId = userId
                    ));
                }
            }
            
            if (!caseTeamMembers.isEmpty()) {
                Database.SaveResult[] caseResult = Database.insert(caseTeamMembers, false); 
            }
        }                              
    }
    
    public static void updateNetworkAndCaseShares(List<Facility_User__c> newNetworkUsers, List<Facility_User__c> oldNetworkUsers) {
        List<Facility_User__c> newNwUsers = new List<Facility_User__c>();
        List<Facility_User__c> delNwUsers = new List<Facility_User__c>();
        
        Integer index = 0;
        for (Facility_User__c nwUser : newNetworkUsers) {                                            
            // Network has not changed
            if (nwUser.Network__c != null && nwUser.Network__c == oldNetworkUsers[index].Network__c  && 
                                            nwUser.Is_MyNetwork_User__c) {  //Kalpi: Added check for mynetwork users Is_MyNetwork_User__c 
                // either with new user or old user and new user is not the same as old user  
                if ((nwUser.User__c != null || oldNetworkUsers[index].User__c != null) && nwUser.User__c != oldNetworkUsers[index].User__c) {
                    if (nwUser.User__c == null && oldNetworkUsers[index].User__c != null) {
                        delNwUsers.add(oldNetworkUsers[index]);
                    } else if (nwUser.User__c != null && oldNetworkUsers[index].User__c == null) {
                        newNwUsers.add(nwUser);
                    } else {
                        newNwUsers.add(nwUser);
                        delNwUsers.add(oldNetworkUsers[index]);
                    }
                }
            } else { 
                // Network has changed
                if (nwUser.Network__c != null || oldNetworkUsers[index].Network__c != null && nwUser.Is_MyNetwork_User__c) {  //Kalpi: Added check for mynetwork users Is_MyNetwork_User__c
                    // no old facility and with new facility
                    if (nwUser.Network__c != null && oldNetworkUsers[index].Network__c == null) {
                        if (nwUser.User__c != null) {
                            newNwUsers.add(nwUser);
                        }
                    } else if (nwUser.Network__c == null && oldNetworkUsers[index].Network__c != null) {
                        if (oldNetworkUsers[index].User__c != null) {
                            delNwUsers.add(oldNetworkUsers[index]);
                        }
                    } else { //old facility not the same with new facility
                        // either with new user or old user and new user is not the same as old user  
                        if ((nwUser.User__c != null || oldNetworkUsers[index].User__c != null) && nwUser.User__c != oldNetworkUsers[index].User__c) {              
                            if (nwUser.User__c == null && oldNetworkUsers[index].User__c != null) {
                                delNwUsers.add(oldNetworkUsers[index]);
                            } else if (nwUser.User__c != null && oldNetworkUsers[index].User__c == null) {
                                newNwUsers.add(nwUser);
                            } else {
                                newNwUsers.add(nwUser);
                                delNwUsers.add(oldNetworkUsers[index]);
                            }
                        }
                    }
                }
            }                                                              
            index++;
        }
                
        // delete shares
        if (!delNwUsers.isEmpty()) {
            deleteNetworkAndCaseShares(delNwUsers);            
        }
        
        // insert new shares 
        if (!newNwUsers.isEmpty()) {
            insertNetworkAndCaseShares(newNwUsers);
        }
    }   

    public static void deleteNetworkAndCaseShares(List<Facility_User__c> delNetworkUsers) {        
        Map<Id, Set<Id>> networkUsers = new Map<Id, Set<Id>>();
        set<id> userId = new set<id>(); //spingali
        for (Facility_User__c delNwUser : delNetworkUsers) {
            if (delNwUser.Network__c != null && delNwUser.User__c != null && delNwUser.Is_MyNetwork_User__c) {  //Kalpi: Added check for mynetwork users Is_MyNetwork_User__c
                if (networkUsers.get(delNwUser.Network__c) == null) {
                    networkUsers.put(delNwUser.Network__c, new Set<Id>());
                    userid.add(delNwUser.User__c); //spingali
                }
                networkUsers.get(delNwUser.Network__c).add(delNwUser.User__c);
            }
        }
        
        if (!networkUsers.isEmpty()) {              
            // Remove Network Apex Managed Sharing 
            List<Network__Share> nwShareToDelete = new List<Network__Share>();      
            for (Network__Share nwShare : [Select Id, ParentId, UserOrGroupId From Network__Share Where ParentId in :networkUsers.keySet()]) {
                if (networkUsers.get(nwShare.ParentId).contains(nwShare.UserOrGroupId)) {
                    nwShareToDelete.add(nwShare);
                }
            }
            
            if (!nwShareToDelete.isEmpty()) {
                Database.DeleteResult[] nwResult = Database.delete(nwShareToDelete, false);
            }
        
            // Remove Case User Managed Sharing -- get all the caseteammember records using soql 
            List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>([Select Id, ParentId,MemberId from CaseTeamMember Where ParentId in (select id From Case Where Network__c  in :networkUsers.keySet()
                                                      AND Permanent_Close__c = false) and memberId in :userId]); 
           /* 
           Map<Id, Case> cases = new Map<Id, Case>([Select Id, Network__c From Case Where Network__c in :networkUsers.keySet() 
                                                        AND Permanent_Close__c = false]);  // Added Filter for INC0763511 fix : Nandan N                                                    
 
            for (CaseTeamMember ctm : [Select Id, ParentId, MemberId From CaseTeamMember Where ParentId in :cases.keySet()]) {  
 
                if (networkUsers.get(cases.get(ctm.ParentId).Network__c).contains(ctm.MemberId)) {
                    caseTeamMembers.add(ctm);
                }
            }
     */
            
            system.debug('caseTeamMembers '+caseTeamMembers);
                      
            if (!caseTeamMembers.isEmpty()) {
                Database.DeleteResult[] caseResult = Database.delete(caseTeamMembers, false);                  
            }
        }        
    }
}