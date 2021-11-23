public class UserSharingUtil {    
    public static void insertFacilityAndCaseShares(List<Facility_User__c> newFacilityUsers) {
        Map<Id, List<Id>> facilityUsers = new Map<Id, List<Id>>();
        for (Facility_User__c facUser : newFacilityUsers) {
            if (facUser.Network__c != null && facUser.User__c != null) {
                if (facilityUsers.get(facUser.Network__c) == null) {
                    facilityUsers.put(facUser.Network__c, new List<Id>());
                }
                facilityUsers.get(facUser.Network__c).add(facUser.User__c);
            }
        }
        
        if (!facilityUsers.isEmpty()) {        
            // Facility Apex Managed Sharing
            List<Network__Share> facilityShares = new List<Network__Share>();
            Set<Id> facilityIds = facilityUsers.keySet();
            for (Id facId : facilityIds) {
                for (Id userId : facilityUsers.get(facId)) {
                    facilityShares.add(new Network__Share(
                        ParentId = facId,
                        UserOrGroupId = userId,
                        AccessLevel = 'edit',
                        RowCause = Schema.Network__Share.RowCause.Facility_Staff__c
                    ));
                }               
            }                       
            Database.SaveResult[] faciltyResult = Database.insert(facilityShares,false);          
           
            // Case User Managed Sharing
            List<CaseShare> caseShares = new List<CaseShare>();
            for (Case cas : [Select Id, Network__c From Case Where Network__c in :facilityUsers.keySet()]) {
                // each user has access to each case
                for (Id userId : facilityUsers.get(cas.Network__c)) {
                    caseShares.add(new CaseShare(
                        CaseAccessLevel = 'Edit',
                        CaseId = cas.Id,                        
                        UserOrGroupId = userId
                    ));
                }
            }
            
            if (!caseShares.isEmpty()) {
                Database.SaveResult[] caseResult = Database.insert(caseShares,false); 
            }
        }  
                              
    }
    
    public static void updateFacilityAndCaseShares(List<Facility_User__c> newFacilityUsers, List<Facility_User__c> oldFacilityUsers) {
        List<Facility_User__c> newFacUsers = new List<Facility_User__c>();
        List<Facility_User__c> delFacUsers = new List<Facility_User__c>();
        
        Integer index = 0;
        for (Facility_User__c facUser : newFacilityUsers) {                                            
            // facility has not change
            if (facUser.Network__c != null && facUser.Network__c == oldFacilityUsers[index].Network__c) { 
                // either with new user or old user and new user is not the same as old user  
                if ((facUser.User__c != null || oldFacilityUsers[index].User__c != null) && facUser.User__c != oldFacilityUsers[index].User__c) {
                    if (facUser.User__c == null && oldFacilityUsers[index].User__c != null) {
                        delFacUsers.add(oldFacilityUsers[index]);
                    } else if (facUser.User__c != null && oldFacilityUsers[index].User__c == null) {
                        newFacUsers.add(facUser);
                    } else {
                        newFacUsers.add(facUser);
                        delFacUsers.add(oldFacilityUsers[index]);
                    }
                }
            } else { 
                // facility has change
                if (facUser.Network__c != null || oldFacilityUsers[index].Network__c != null) {
                    // no old facility and with new facility
                    if (facUser.Network__c != null && oldFacilityUsers[index].Network__c == null) {
                        if (facUser.User__c != null) {
                            newFacUsers.add(facUser);
                        }
                    } else if (facUser.Network__c == null && oldFacilityUsers[index].Network__c != null) {
                        if (oldFacilityUsers[index].User__c != null) {
                            delFacUsers.add(oldFacilityUsers[index]);
                        }
                    } else { //old facility not the same with new facility
                        // either with new user or old user and new user is not the same as old user  
                        if ((facUser.User__c != null || oldFacilityUsers[index].User__c != null) && facUser.User__c != oldFacilityUsers[index].User__c) {              
                            if (facUser.User__c == null && oldFacilityUsers[index].User__c != null) {
                                delFacUsers.add(oldFacilityUsers[index]);
                            } else if (facUser.User__c != null && oldFacilityUsers[index].User__c == null) {
                                newFacUsers.add(facUser);
                            } else {
                                newFacUsers.add(facUser);
                                delFacUsers.add(oldFacilityUsers[index]);
                            }
                        }
                    }
                }
            }                                                              
            index++;
        }
                
        // delete shares
        if (!delFacUsers.isEmpty()) {
            deleteFacilityAndCaseShares(delFacUsers);            
        }
        
        // insert new shares
        if (!newFacUsers.isEmpty()) {
            insertFacilityAndCaseShares(newFacUsers);
        }
    }   

    public static void deleteFacilityAndCaseShares(List<Facility_User__c> delFacUsers) {        
        Map<Id, Set<Id>> delFacilityUsers = new Map<Id, Set<Id>>();
        for (Facility_User__c delFacUser : delFacUsers) {
            if (delFacUser.Network__c != null && delFacUser.User__c != null) {
                if (delFacilityUsers.get(delFacUser.Network__c) == null) {
                    delFacilityUsers.put(delFacUser.Network__c, new Set<Id>());
                }
                delFacilityUsers.get(delFacUser.Network__c).add(delFacUser.User__c);
            }
        }
        
        if (!delFacilityUsers.isEmpty()) {              
            // Remove Facility Apex Managed Sharing 
            List<Network__Share> facShareToDelete = new List<Network__Share>();      
            for (Network__Share facShare : [Select Id, ParentId, UserOrGroupId From Network__Share Where ParentId in :delFacilityUsers.keySet()]) {
                if (delFacilityUsers.get(facShare.ParentId).contains(facShare.UserOrGroupId)) {
                    facShareToDelete.add(facShare);
                }
            }
            
            if (!facShareToDelete.isEmpty()) {
                Database.DeleteResult[] facilityResult = Database.delete(facShareToDelete,false);
            }
        
            // Remove Case User Managed Sharing
            List<CaseShare> caseShareToDelete = new List<CaseShare>();              
            Map<Id, Case> cases = new Map<Id, Case>([Select Id, Network__c From Case Where Network__c in :delFacilityUsers.keySet()]);                                                      
            for (CaseShare caseShare : [Select Id, CaseId, UserOrGroupId From CaseShare Where CaseId in :cases.keySet()]) {
                if (delFacilityUsers.get(cases.get(caseShare.CaseId).Network__c).contains(caseShare.UserOrGroupId)) {
                    caseShareToDelete.add(caseShare);
                }
            }
            
            if (!caseShareToDelete.isEmpty()) {
                Database.DeleteResult[] caseResult = Database.delete(caseShareToDelete,false);                  
            }
        }        
    }
}