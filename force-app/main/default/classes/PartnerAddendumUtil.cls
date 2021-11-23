/**************************************************
Type:       Utility Class for Partner Addendum Object
Purpose:    Performas Various Actions on Partner Addendum trigger including
            - Verification of Duplicate Partner Addendum Records
            - Update of Network Manager on Submission for Approval
            - Update Licence Minimum Approval Level
Used By:    PartnerAddendumTrigger
History:
--------------------------------------------------
04.08.2015  Ritika Dhandia(Salesforce.com)      Created
04.07.2019  Disha.kariya@auspost.com.au         Updated updateNetworkManagerAndStateAdmin method to update State Admin
**************************************************/
public with sharing class PartnerAddendumUtil{
    
    public static final string ERROR_PARTNER_ADDENDUM = 'Another Partner Addendum of this type is already active for this start date';
    public static final string ERROR_NETWORK_MANAGER = 'Failed to determine the approval authority for this Facility. Please contact business support team.';
    public static final string APPROVAL_STATUS_PENDING = 'Pending';
    public static final string STATUS_CEASED = 'Ceased';

    // Update Network Manager from Parent Facility or Lience's Facility
    // On Submission for Approval
    public static void updateNetworkManagerAndStateAdmin(list<Partner_Addendum__c> addendums, map<id, Partner_Addendum__c> oldAddendums){
        
        set<id> accountIds = new set<id>();
        Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();
        for(Partner_Addendum__c addendum : addendums){
            if(trigger.isInsert || 
                (addendum.Approval_Status__c == APPROVAL_STATUS_PENDING && addendum.Approval_Status__c != oldAddendums.get(addendum.id).Approval_Status__c) ){
                    accountIds.add(addendum.Facility__c);
                    accountIds.add(addendum.Licence__c);
            }
        }

        accountIds.remove(null);

        map<id, Account> accounts = new map<id, Account>([
                                                            SELECT id, Facility__c, Network_Facility__r.Parent_Network__r.Network_Manager__c,
                                                            Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c,
                                                                    Network_Facility__r.Parent_Network__r.State__c,
                                                                    Facility__r.Network_Facility__r.Parent_Network__r.State__c
                                                            FROM Account
                                                            WHERE id in: accountIds
                                                        ]);

        for(Partner_Addendum__c addendum : addendums){
            if(trigger.isInsert || 
                (addendum.Approval_Status__c == APPROVAL_STATUS_PENDING && addendum.Approval_Status__c != oldAddendums.get(addendum.id).Approval_Status__c) ){
                    
                    // Fetch Network Manager from Facility
                    if(addendum.Facility__c != null){
                        if( accounts.get(addendum.Facility__c).Network_Facility__r.Parent_Network__r.Network_Manager__c != null){
                            addendum.Network_Manager__c = accounts.get(addendum.Facility__c).Network_Facility__r.Parent_Network__r.Network_Manager__c;
                            addendum.State_Admin__c = String.isNotBlank(accounts.get(addendum.Facility__c).Network_Facility__r.Parent_Network__r.State__c) ?
                                    String.valueOf(setting.get('Email_List_'+accounts.get(addendum.Facility__c).Network_Facility__r.Parent_Network__r.State__c+'__c')) : '';
                        }
                        else{
                            addendum.addError(ERROR_NETWORK_MANAGER);
                        }                       
                    }
                    // Fetch Network Manager from Licence's Facility
                    else if(addendum.Licence__c != null){
                        if( accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c != null){
                            addendum.Network_Manager__c = accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c;
                            System.debug('accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.State__c-->'+accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.State__c);
                            addendum.State_Admin__c = String.isNotBlank(accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.State__c) ?
                                    String.valueOf(setting.get('Email_List_'+accounts.get(addendum.Licence__c).Facility__r.Network_Facility__r.Parent_Network__r.State__c+'__c')) : '';
                        } 
                        else{
                            addendum.addError(ERROR_NETWORK_MANAGER);
                        } 
                    }    
            }
        }

    }

    // Verify Duplicate Partner Addendum 
    public static void verifyDuplicatePartnerAddendum(list<Partner_Addendum__c> addendums, map<id, Partner_Addendum__c> oldAddendums){
        
        set<id> facilites = new set<id>();
        set<id> licences = new set<id>();

        for(Partner_Addendum__c addendum : addendums){
            if(trigger.isInsert || 
            (
                addendum.Facility__c != oldAddendums.get(addendum.id).Facility__c ||
                addendum.Licence__c != oldAddendums.get(addendum.id).Licence__c ||
                addendum.Sub_Type__c != oldAddendums.get(addendum.id).Sub_Type__c ||
                addendum.Start_Date__c != oldAddendums.get(addendum.id).Start_Date__c
            )){
                facilites.add(addendum.Facility__c);
                licences.add(addendum.Licence__c);
            }
        }
        
        facilites.remove(null);
        licences.remove(null);
        
        map<id, list<Partner_Addendum__c>> accountToAddednum = new map<id, list<Partner_Addendum__c>>();
        
        for(Partner_Addendum__c addendum : [
                                                SELECT Id, Start_Date__c, End_Date__c, Licence__c,Facility__c,
                                                        Sub_Type__c, RecordTypeId
                                                FROM Partner_Addendum__c
                                                WHERE (Facility__c in: facilites
                                                OR Licence__c in: licences)
                                                AND Status__c != : STATUS_CEASED
                                                AND id not in: addendums
                                            ]){
            
            if(addendum.Licence__c != null){
                if(!accountToAddednum.containsKey(addendum.Licence__c)){
                    accountToAddednum.put(addendum.Licence__c, new list<Partner_Addendum__c>());
                }                               
                accountToAddednum.get(addendum.Licence__c).add(addendum);
            }
            else if(addendum.Facility__c != null){
                if(!accountToAddednum.containsKey(addendum.Facility__c)){
                    accountToAddednum.put(addendum.Facility__c, new list<Partner_Addendum__c>());
                }                               
                accountToAddednum.get(addendum.Facility__c).add(addendum);
            }
        }
        
        integer i =0;
        boolean errorFound = false;
        for(Partner_Addendum__c addendum : addendums){
            
            errorFound = false;
            if(trigger.isInsert || 
            (
                addendum.Facility__c != oldAddendums.get(addendum.id).Facility__c ||
                addendum.Licence__c != oldAddendums.get(addendum.id).Licence__c ||
                addendum.Sub_Type__c != oldAddendums.get(addendum.id).Sub_Type__c ||
                addendum.Start_Date__c != oldAddendums.get(addendum.id).Start_Date__c
            )){
            
                id accId = (addendum.Licence__c != null)?addendum.Licence__c:(addendum.Facility__c);

                if(accountToAddednum.containsKey(accId)){
                    
                    for(Partner_Addendum__c otherAddendum : accountToAddednum.get(accId)){
                        if(
                           (otherAddendum.Facility__c == addendum.Facility__c ||
                           otherAddendum.Licence__c == addendum.Licence__c) &&
                           otherAddendum.Sub_Type__c == addendum.Sub_Type__c &&
                           otherAddendum.RecordTypeId == addendum.RecordTypeId &&
                           otherAddendum.End_Date__c >= addendum.Start_Date__c
                           ){
                                 
                               addendum.addError(ERROR_PARTNER_ADDENDUM);
                               errorFound = true;
                               break;
                        }
                    }
                }
                
                if(!errorFound && trigger.isInsert){
                    for(Integer j=i+1; j<addendums.size(); j++){
                        
                        Partner_Addendum__c otherAddendum = addendums[j];
                        if(
                           (otherAddendum.Licence__c == addendum.Licence__c ||
                           otherAddendum.Facility__c == addendum.Facility__c) &&
                           otherAddendum.Sub_Type__c == addendum.Sub_Type__c &&
                           otherAddendum.RecordTypeId == addendum.RecordTypeId &&
                           otherAddendum.End_Date__c >= addendum.Start_Date__c){
                            
                               addendum.addError(ERROR_PARTNER_ADDENDUM);
                               errorFound = true;
                               break;
                        }
                    }
                }
            
            }
            
            i++;
        }
    }

    // Updates the Minimum Approval Level on Licence Accounts
    // Based on the pre set conditions from Custom Settings
    public static void updateMinimumLevelOnLicence(list<Partner_Addendum__c> addendums, map<id, Partner_Addendum__c> oldAddendums){
        map<id, Account> licences = new map<id, Account>();

        list<RecordType> recTypes = RecordTypes.getRecordTypesByName(new set<String>{'Loan', 'Repayment_Arrangement'}, 'Partner_Addendum__c');

        Id repaymentRecordTypeId;
        Id loanRecordTypeId;

        if(recTypes[0].DeveloperName == 'Loan'){
            loanRecordTypeId = recTypes[0].id;
            repaymentRecordTypeId = recTypes[1].id;
        }
        else{
            loanRecordTypeId = recTypes[1].id;
            repaymentRecordTypeId = recTypes[0].id;
        }

        Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();

        for(Partner_Addendum__c addendum : addendums){
            if(addendum.Licence__c != null){
                if(trigger.isInsert || 
                (
                    addendum.Amount__c != oldAddendums.get(addendum.id).Amount__c ||
                    addendum.Annual_Amount__c != oldAddendums.get(addendum.id).Annual_Amount__c ||
                    addendum.Negotiated_Lump_Sum__c != oldAddendums.get(addendum.id).Negotiated_Lump_Sum__c ||
                    addendum.Term__c != oldAddendums.get(addendum.id).Term__c
                )){

                    if(addendum.Amount__c > setting.Level_3_Approval_Amount__c ||
                        addendum.Annual_Amount__c > setting.Level_3_Approval_Annual_Amount__c ||
                        addendum.Negotiated_Lump_Sum__c > setting.Level_3_Approval_Negotiated_Lump_Sum__c ||
                        (addendum.RecordTypeId == loanRecordTypeId && addendum.Term__c > setting.Level_3_Approval_Loan_Term__c) ||
                        (addendum.RecordTypeId == repaymentRecordTypeId && addendum.Term__c > setting.Level_3_Approval_Repayment_Term__c)){

                        if(!licences.containsKey(addendum.Licence__c)){
                            licences.put(addendum.Licence__c, new Account(id = addendum.Licence__c));
                        }
                        
                        licences.get(addendum.Licence__c).Minimum_Approval_Level__c = 3;
                    }

                }
            }
        }

        update licences.values();

    }
    
}