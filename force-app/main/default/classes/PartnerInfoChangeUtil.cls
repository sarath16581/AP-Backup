/**************************************************
Type:       Utility Class for Partner Info Change Object
Purpose:    Performas Various Actions on Partner Info trigger including
            - Verification of Duplicate Partner Info Records
            - Update of Network Manager on Submission for Approval
            - Update of Account Fields on Approval
Used By:    PartnerInfoChangeTrigger
History:
--------------------------------------------------
05.08.2015  Ritika Dhandia (Salesforce.com)     Created
25.05.2016  Andrew Judd (Salesforce.com)     Added set of Licence Status to 'Not Activated'
03.10.2016  Andrew Judd (for David Lai) Added set of Approval Status to 'Not Activated Approved' and ln 168
**************************************************/
public with sharing class PartnerInfoChangeUtil{
    
    public static final string ERROR_CHANGE_EXISTS = 'Another Change Record is waiting for approval. Please retry after that approval is completed';
    public static final string ERROR_NETWORK_MANAGER = 'Failed to determine the approval authority for this Facility. Please contact business support team.';
    public static map<string, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
    public static final string APPROVAL_STATUS_PENDING = 'Pending';
    public static final string APPROVAL_STATUS_APPROVED = 'Approved';
    public static final string PI_STATUS_SUSPEND_WITH_FEES = 'Suspended With Fees';
    public static final string PI_STATUS_SUSPEND_NO_FEES = 'Suspended Without Fees';
    public static final string APPROVAL_STATUS_SUSPEND_WITH_FEES = 'Suspend With Fees Start Approved';
    public static final string APPROVAL_STATUS_SUSPEND_NO_FEES = 'Suspend Without Fees Start Approved';
    public static final string APPROVAL_STATUS_CEASE_APPROVED = 'Cease Approved';
    public static final string APPROVAL_STATUS_RESUME_APPROVED = 'Suspend End Approved';
    public static final Schema.SObjectField LICENCE_EFFECTIVE_END_DATE = Partner_Info_Change__c.Assignment_Effective_To_Date__c;
    public static final Schema.SObjectField LICENCE_SUSPEND_END_DATE = Partner_Info_Change__c.Interrupted_End_Date__c;
    public static final string PI_STATUS_NOT_ACTIVATED = 'Not Activated';
    public static final string STATUS_NOT_ACTIVATED = 'Not Activated';
    public static final string APPROVAL_STATUS_NOT_ACTIVATED_APPROVED = 'Not Activated Approved';
    // Updates the Network Manager on Partner Info on submission for Approval
    public static void updateNetworkManager(list<Partner_Info_Change__c> changes, map<id, Partner_Info_Change__c> oldChanges){

        set<id> accountIds = new set<id>();
        for(Partner_Info_Change__c change : changes){
            if(trigger.isInsert || 
                (change.Approval_Status__c == APPROVAL_STATUS_PENDING && change.Approval_Status__c != oldChanges.get(change.id).Approval_Status__c) ){
                    accountIds.add(change.Facility__c);
                    accountIds.add(change.Licence__c);
            }
        }

        accountIds.remove(null);

        map<id, Account> accounts = new map<id, Account>([
                                                            SELECT id, Facility__c, Network_Facility__r.Parent_Network__r.Network_Manager__c,
                                                            Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c
                                                            FROM Account
                                                            WHERE id in: accountIds
                                                        ]);

         for(Partner_Info_Change__c change : changes){
            if(trigger.isInsert || 
                (change.Approval_Status__c == APPROVAL_STATUS_PENDING && change.Approval_Status__c != oldChanges.get(change.id).Approval_Status__c) ){
                    
                    // Fetch Network Manager from Facility
                    if(change.Facility__c != null){
                        if( accounts.get(change.Facility__c).Network_Facility__r.Parent_Network__r.Network_Manager__c != null){
                            change.Network_Manager__c = accounts.get(change.Facility__c).Network_Facility__r.Parent_Network__r.Network_Manager__c;
                        } 
                        else{
                            change.addError(ERROR_NETWORK_MANAGER);
                        }                       
                    }
                    // Fetch Network Manager from Licence's Facility
                    else if(change.Licence__c != null){
                        if( accounts.get(change.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c != null){
                            change.Network_Manager__c = accounts.get(change.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c;
                        } 
                        else{
                            change.addError(ERROR_NETWORK_MANAGER);
                        } 
                    }    
            }
        }
    }

    // Verfiy on insert, no other Pending Info Change is present for the same Licence/Facility
    public static void verifyPartnerInfoDuplicate(list<Partner_Info_Change__c> changes){
        
        set<id> parentAccountIds = new set<id>();
        for(Partner_Info_Change__c change : changes){
            parentAccountIds.add(change.Licence__c);
            parentAccountIds.add(change.Facility__c);
        }
        parentAccountIds.remove(null);
        
        set<id> existingAccountIds = new set<id>();

        for(Partner_Info_Change__c exChange : [
                                                    SELECT id, Licence__c,Facility__c 
                                                    FROM Partner_Info_Change__c
                                                    WHERE Approval_Status__c =: APPROVAL_STATUS_PENDING
                                                    AND 
                                                    (
                                                        Licence__c in: parentAccountIds
                                                        OR Facility__c in: parentAccountIds
                                                    )
                                              ]){
            existingAccountIds.add(exChange.Licence__c);
            existingAccountIds.add(exChange.Facility__c);
        }
        
        existingAccountIds.remove(null);
        
        for(Partner_Info_Change__c change : changes){
            if(change.Licence__c != null && existingAccountIds.contains(change.Licence__c)){
                change.addError(ERROR_CHANGE_EXISTS);
            }
            if(change.Facility__c != null && existingAccountIds.contains(change.Facility__c)){
                change.addError(ERROR_CHANGE_EXISTS);
            }
        }
    }
    
    // On approval, update Licence / Facility with the new values 
    // Also consider change in Licence Status to Update Approval Status on Licence
    public static void updateAccount(map<id, Partner_Info_Change__c> oldChanges, map<id, Partner_Info_Change__c> newChanges){
        
        List<Schema.FieldSetMember> licenceFields = SObjectType.Partner_Info_Change__c.FieldSets.Licence_Fields.getFields();
        List<Schema.FieldSetMember> facilityFields = SObjectType.Partner_Info_Change__c.FieldSets.Facility_Fields.getFields();
        
        
        map<id, Account> parentAccounts = new map<id, Account>();
        for(Partner_Info_Change__c change : newChanges.values()){
            if(change.Approval_Status__c != oldChanges.get(change.id).Approval_Status__c && change.Approval_Status__c == APPROVAL_STATUS_APPROVED){
            
                // For Licence Accounts
                if(change.Licence__c != null){
                    
                    if(!parentAccounts.containsKey(change.Licence__c)){
                        parentAccounts.put(change.Licence__c, new Account(id = change.Licence__c));
                    }
                    
                    for(Schema.FieldSetMember fieldMember : licenceFields){
                        string fieldApiName = fieldMember.getFieldPath();
                        // The Change record needs the Account to be updated with this field
                        if(change.get(fieldApiName) != null){

                            if(accountFields.containsKey(fieldApiName)){
                                parentAccounts.get(change.Licence__c).put(fieldApiName, change.get(fieldApiName));

                                // Handling Cease Request
                                if(fieldApiName == LICENCE_EFFECTIVE_END_DATE.getDescribe().getName()){
                                    parentAccounts.get(change.Licence__c).Approval_Status__c = APPROVAL_STATUS_CEASE_APPROVED;
                                }
                                // Handling Resume Request
                                else if(fieldApiName == LICENCE_SUSPEND_END_DATE.getDescribe().getName()){
                                    parentAccounts.get(change.Licence__c).Approval_Status__c = APPROVAL_STATUS_RESUME_APPROVED;   
                                }
                            }
                        }
                    }

                    // If Licence Status is Updated, then we need to Update Account Approval Status
                    // field accordingly for Suspension
                    if(change.Licence_Status__c != null){
                        if(change.Licence_Status__c == PI_STATUS_SUSPEND_NO_FEES){
                            parentAccounts.get(change.Licence__c).Approval_Status__c = APPROVAL_STATUS_SUSPEND_NO_FEES;
                        }
                        else if(change.Licence_Status__c == PI_STATUS_SUSPEND_WITH_FEES){
                            parentAccounts.get(change.Licence__c).Approval_Status__c = APPROVAL_STATUS_SUSPEND_WITH_FEES;   
                        }
                        //AJ POMS Enhancement. Update the Licence Status to 'Not Activated'
                        if(change.Licence_Status__c == PI_STATUS_NOT_ACTIVATED){
                            parentAccounts.get(change.Licence__c).Licence_Status__c = STATUS_NOT_ACTIVATED;
                            parentAccounts.get(change.Licence__c).Approval_Status__c = APPROVAL_STATUS_NOT_ACTIVATED_APPROVED;
                        }                        
                        parentAccounts.get(change.Licence__c).Interrupted_End_Date__c = null;
                    }
                }
                // For Facility Accounts
                if(change.Facility__c != null){
                    
                    if(!parentAccounts.containsKey(change.Facility__c)){
                        parentAccounts.put(change.Facility__c, new Account(id = change.Facility__c));
                    }
                    
                    for(Schema.FieldSetMember fieldMember : facilityFields){
                        string fieldApiName = fieldMember.getFieldPath();
                        
                        if(change.get(fieldApiName) != null && accountFields.containsKey(fieldApiName)){
                            parentAccounts.get(change.Facility__c).put(fieldApiName, change.get(fieldApiName));
                        }
                    }
                }
            }
        }
        
        update parentAccounts.values();
    }
}