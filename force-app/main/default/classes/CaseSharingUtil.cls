/**
  * @description  : Sharing class for controlling case sharing based on network users
  */
/*******************************  History ************************************************
    Date                User                                       Comments
20.09.2016      kaplita.talwadekar@auspost.com.au        updated to get the dependant values based on product category
                                                           to accomodate clearview code change.  
                                                           
*******************************  History ************************************************/                                                         
public class CaseSharingUtil {    

    //getter setter for case team role retreival
    public static String teamRoleId {
        get {
            if(teamRoleId == null) {
                teamRoleId = [  Select Id 
                                from 
                                    CaseTeamRole 
                                where 
                                    Name = 'SSSW PON' 
                                limit 1].Id;
            }
            return teamRoleId;
        } set;
    }
    
    /**
      * @description       method to insert case team members based on facility users under the network
      * @param             List<Case> newCases
      * @return            NA
      * @throws            NA
      */
    public static void insertCaseTeamMembers(List<Case> newCases) {
        Map<Id, List<Case>> facilityCases = new Map<Id, List<Case>>();
        //looping through all triggered cases
        for (Case c : newCases) {
            //if network is attached to the case
            if (c.Network__c != null) {
                //map all cases under same network
                if (facilityCases.get(c.Network__c) == null) {
                    facilityCases.put(c.Network__c, new List<Case>());
                }
                facilityCases.get(c.Network__c).add(c);
            }
        }        
        
        //if cases are available for updation
        if (!facilityCases.isEmpty()) { 
            // get all facility users
            List<CaseTeamMember> caseShares = new List<CaseTeamMember>();
            //check mynetwork users under relevant network and with Is_MyNetwork_User__c flag
            for (Facility_User__c facUser : [   Select User__c, Network__c 
                                                From 
                                                    Facility_User__c 
                                                Where 
                                                    Network__c in :facilityCases.keySet() 
                                                and 
                                                    User__c != null
                                                and  Is_MyNetwork_User__c = true]) {  
            //get all cases under each network
            for (Case cas : facilityCases.get(facUser.Network__c)) {                           
                    System.debug('User : ' + facUser.User__c + ' : ' + cas.Id);
                    //check if the facility user is not the case owner to add him as case team member
                    if (facUser.User__c != cas.OwnerId) {
                        caseShares.add(new CaseTeamMember(
                            TeamRoleId = Id.valueOf(teamRoleId),
                            ParentId = cas.Id,                        
                            MemberId = facUser.User__c
                        )); 
                    }
                }           
            }
            //if there are records for case sharing available based on above logic
            if (!caseShares.isEmpty()) {
                Database.SaveResult[] caseResult = Database.insert(caseShares,false);
            }
            
        }
    }
    /*** - Logic removed as part of fixing 425 QC defect
    public static void insertCaseShares(List<Case> newCases) {
        Map<Id, List<Case>> facilityCases = new Map<Id, List<Case>>();
        for (Case c : newCases) {
            if (c.Network__c != null) {
                if (facilityCases.get(c.Network__c) == null) {
                    facilityCases.put(c.Network__c, new List<Case>());
                }
                facilityCases.get(c.Network__c).add(c);
            }
        }        
                
        if (!facilityCases.isEmpty()) { 
            // get all facility users
            List<CaseShare> caseShares = new List<CaseShare>();
            for (Facility_User__c facUser : [Select User__c, Network__c From Facility_User__c Where Network__c in :facilityCases.keySet() and User__c != null]) {             
                for (Case cas : facilityCases.get(facUser.Network__c)) {                           
                    System.debug('User : ' + facUser.User__c + ' : ' + cas.Id);
                    if (facUser.User__c != cas.OwnerId) {
                        caseShares.add(new CaseShare(
                            CaseAccessLevel = 'Edit',
                            CaseId = cas.Id,                        
                            UserOrGroupId = facUser.User__c
                        )); 
                    }
                }           
            }
            
            if (!caseShares.isEmpty()) {
                Database.SaveResult[] caseResult = Database.insert(caseShares,false);
            }
        }
    }
    **/
    
    /**
      * @description       method to update case team members based on facility users under the network
      * @param             List<Case> newCases, List<Case> oldCases
      * @return            NA
      * @throws            NA
      */
    public static void updateCaseShares(List<Case> newCases, List<Case> oldCases) {
        
        List<Case> addCases = new List<Case>();
        List<Case> delCases = new List<Case>();
        Integer index = 0;
        //loop through the new updated case details
        for (Case c : newCases) {
            //check if there is a change in the network
            if ((c.Network__c != null || oldCases[index].Network__c != null) && c.Network__c != oldCases[index].Network__c) {
                // with new facility & no previous facility
                if (c.Network__c != null && oldCases[index].Network__c == null) {
                    addCases.add(c);
                } else if (c.Network__c == null && oldCases[index].Network__c != null) {
                    delCases.add(oldCases[index]);
                } else {
                    addCases.add(c);
                    delCases.add(oldCases[index]);
                }
            } else {
                // owner change
                if (c.OwnerId != oldCases[index].OwnerId) {
                    addCases.add(c);
                }
            }
            index++;
        }
       
       
        System.debug('addCases : ' + addCases);
        System.debug('delCases : ' + delCases);
                            
        // delete sharing on cases
        if (!delCases.isEmpty()) {                                                   
            Set<Id> facilityIds = new Set<Id>();  
            Map<Id, Case> cases = new Map<Id, Case>(delCases);                  
            //if network is removed from case then loop through those cases
            for (Case c : delCases) {               
                facilityIds.add(c.Network__c);              
            }   
            System.debug('facilityIds : ' + facilityIds);
            
            Map<Id, Set<Id>> delFacilityUsers = new Map<Id, Set<Id>>();
            //loop through the network users for removed networks and with i myNetwork user flag
            for (Facility_User__c delFacUser : [    Select Network__c, User__c 
                                                    From 
                                                        Facility_User__c 
                                                    Where 
                                                        Network__c in :facilityIds 
                                                    and 
                                                        User__c != null
                                                    and 
                                                        Is_MyNetwork_User__c = true ]) {  
                if (delFacilityUsers.get(delFacUser.Network__c) == null) {
                    delFacilityUsers.put(delFacUser.Network__c, new Set<Id>());
                }
                delFacilityUsers.get(delFacUser.Network__c).add(delFacUser.User__c);               
            }
            System.debug('delFacilityUsers : ' + delFacilityUsers);
            
            //if we have records for removing case team members
            if (!delFacilityUsers.isEmpty()) {
                List<CaseTeamMember> caseTeamMembersToDelete = new List<CaseTeamMember>();                                               
                
                for (CaseTeamMember caseShare : [   Select Id, ParentId, MemberId 
                                                    From 
                                                        CaseTeamMember 
                                                    Where 
                                                        ParentId in :cases.keySet() ]) {
                    System.debug('Share user : ' + caseShare.MemberId + ' : ' + caseShare.ParentId); 
                    Id caseFacility = cases.get(caseShare.ParentId).Network__c;  
                    System.debug('Case Facility : ' + caseFacility);            
                    if (delFacilityUsers.containsKey(caseFacility)) {
                        if (delFacilityUsers.get(caseFacility).contains(caseShare.MemberId)) {
                            caseTeamMembersToDelete.add(caseShare);
                        }
                    }
                }
                
                if (!caseTeamMembersToDelete.isEmpty()) {
                    Database.DeleteResult[] caseResult = Database.delete(caseTeamMembersToDelete,false);                  
                }
            }
        }   
        
        // add sharing on cases
        if (!addCases.isEmpty()) {
            //insertCaseShares(addCases);
            insertCaseTeamMembers(addCases);
        }   
    }
}