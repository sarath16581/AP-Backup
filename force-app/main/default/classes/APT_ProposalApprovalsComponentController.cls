/**
This apex class is controller of visual force component - APT_ProposalApprovalsComponent.
Created By - Mausam Padhiyar
Created Date - 13th April, 2016
Last Modified Date-
Last Modified By -
*/
public with sharing class APT_ProposalApprovalsComponentController {
    
    public Apttus_Proposal__Proposal__c proposalSO {get; set;}
    public String proposalSOId {get; set;}
    /**
        Method to retrieve proposal record
    **/
    public Apttus_Proposal__Proposal__c getProposal() {
        Apttus_Proposal__Proposal__c  proposal;
        try {
            if(proposalSOId != null) {
                proposal = [SELECT Id, Name
                            FROM Apttus_Proposal__Proposal__c 
                            WHERE Id = :proposalSOId];
                
                
            } else {
                proposal = new Apttus_Proposal__Proposal__c();
            }
        } catch(system.exception ex) {
                   
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
        }
        return proposal;        
    }
    /**
        Method to retrieve cart url
    **/
    public String getCartURL() {
        String recordTypeName = APT_Constants.RECORD_TYPE_PROPOSAL;
        String cartURL;
           try {
                if(proposalSOId != null) {
                    Apttus_Proposal__Proposal__c proposal1 = [SELECT Id, RecordTypeId, RecordType.DeveloperName 
                                                            FROM Apttus_Proposal__Proposal__c 
                                                            WHERE Id = :proposalSOId];
                    
                    if(proposal1 != null && proposal1.RecordType.DeveloperName != null) {
                        recordTypeName = proposal1.RecordType.DeveloperName;
                    }
                }
                
                Profile p = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId()];
                
             
                Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
                
                if(recordTypeName != null && APT_Constants.RECORD_TYPE_PROPOSAL != null && APT_Constants.STRING_PRICING_MANAGEMENT!=null && recordTypeName.equalsIgnoreCase(APT_Constants.RECORD_TYPE_PROPOSAL) == true && p != null && p.Name != null && p.Name.equalsIgnoreCase(APT_Constants.STRING_PRICING_MANAGEMENT) == false) {
                    cartURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.STRING_URL_PROPOSAL_CONFIGURATION + proposalSOId + APT_Constants.STRING_FLOW_NEW_QUOTE_ADVANCED;
                } else if(recordTypeName != null && APT_Constants.RECORD_TYPE_PROPOSAL != null && APT_Constants.STRING_PRICING_MANAGEMENT!=null &&  recordTypeName.equalsIgnoreCase(APT_Constants.RECORD_TYPE_PROPOSAL) == true && p != null && p.Name != null && p.Name.equalsIgnoreCase(APT_Constants.STRING_PRICING_MANAGEMENT) == true) {
                    cartURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.STRING_URL_PROPOSAL_CONFIGURATION + proposalSOId + APT_Constants.STRING_URL_FLOW_APPROVAL;
                } else if(recordTypeName != null && APT_Constants.APT_RENEWAL_QUOTE!=null && APT_Constants.APT_AMENDMENT_QUOTE!=null && recordTypeName.equalsIgnoreCase(APT_Constants.APT_RENEWAL_QUOTE) == true || recordTypeName.equalsIgnoreCase(APT_Constants.APT_AMENDMENT_QUOTE) == true) {
                    cartURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.STRING_URL_PROPOSAL_CONFIGURATION + proposalSOId + APT_Constants.STRING_URL_RENEWAL_QUOTE;
                } else {}
        } catch(system.exception ex) {
                   
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
        } 
        return cartURL;
    }
}