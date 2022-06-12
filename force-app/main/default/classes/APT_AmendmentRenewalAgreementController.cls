/**
Description: This apex class is controller for vf page  - APT_AmendmentRenewalAgreement. This will create Amendment/Renewal Agreement with Line Items.
Created By - Mausam Padhiyar
Created Date - 9th Nov, 2015

Last Modified By - Mausam Padhiyar
Last Modified Date - 25th Oct, 2016 | 1655 : copy and version SAP Contracts
**/ 
/*********************************
@ModifiedBy - Aditya Shetty
@ModifiedOn - 18/3/2020
@Description -  Change to redirect to the Agreement detail page instead of  Edit page
*********************************/
public with sharing class APT_AmendmentRenewalAgreementController {
    
    String proposalId;
    String proposalRecordTypeName;
    
    public boolean testRollBack {get; set;}
    public boolean haserrorMessages {get; set;} 
    
    /**
     * Constructor of the class APT_AmendmentRenewalAgreementController
     * */
    public APT_AmendmentRenewalAgreementController() {
        testRollBack = false;
        haserrorMessages = false;
        proposalId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID));
        proposalRecordTypeName = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_RECORDTYPE));
    }
    
    /**
     * Processes the amend and renew of the agreement     
     * */
    public PageReference doAmendRenew() {
        // Added by Adrian Recio to make sure cloning and file linking
        // cannot execute for amendment value updates on original and amendment contract.
        AgreementToSFContractTriggerHandler.disableCloning = true;
        Savepoint sp = Database.setSavepoint();
        try {        
            List<Apttus_Proposal__Proposal__c> proposalList = [SELECT Id, Name, Apttus_Proposal__Opportunity__c,
                                                    APT_Contract_Number__c, Apttus_Proposal__Primary_Contact__c
                                                    FROM Apttus_Proposal__Proposal__c WHERE ID = :proposalId limit 1];
            
            Apttus_Proposal__Proposal__c proposal;
            
            Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();               
            Apttus_Config2__ProductConfiguration__c configuration = new Apttus_Config2__ProductConfiguration__c();
            
            if(proposalList.size()==1) {
                proposal = proposalList[0];
                configuration = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c 
                                WHERE Apttus_QPConfig__Proposald__c = :proposal.Id
                                AND Apttus_Config2__Status__c = :APT_Constants.CONFIGURATION_STATUS_FINALIZED
                                limit 1];
                                
                                //System.debug(logginglevel.error,'** configuration : ' + configuration);
            } 
            
            
            if(proposalList.size()!=1 || (Test.isRunningTest()&&testRollBack)){
                Database.rollback(sp);
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.PROPOSAL_IS_MISSING));
                return null;
            }
            
            if(!String.isEmpty(proposal.APT_Contract_Number__c)) {
                agreement = [SELECT Id, Name,RecordTypeId, Apttus__Related_Opportunity__c, Apttus_QPComply__RelatedProposalId__c,
                            Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, APT_Contract_Number__c,
                            Apttus__Primary_Contact__c, Apttus__Account__c, Apttus__FF_Agreement_Number__c,
                            Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Proposal_Name__c,
                            Apttus__Version_Number__c
                            FROM Apttus__APTS_Agreement__c 
                            WHERE Apttus__FF_Agreement_Number__c = :proposal.APT_Contract_Number__c];               
            } else {
                Database.rollback(sp);
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.MISSING_CONTRACT_NUMBER));
                return null;
            }   
            
            //renewal                                            
            if(!String.isEmpty(proposal.APT_Contract_Number__c) && !String.isEmpty(proposalRecordTypeName) && 
               proposalRecordTypeName.equalsIgnoreCase(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE) ) {                
                //create agreement
                Apttus__APTS_Agreement__c  renewedAgreement = APT_AmendRenewUtility.renewAgreement(APT_Constants.RECORD_TYPE_RENEWAL_CONTRACT,proposal.Apttus_Proposal__Opportunity__c, proposalId, agreement);
				System.debug('ProposalRenewal - 0' +  proposal.Apttus_Proposal__Primary_Contact__c);
                if(proposal!=null){
                    renewedAgreement.Apttus__Primary_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                    renewedAgreement.APT_Customer_Application_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                    renewedAgreement.APT_Commercial_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                    renewedAgreement.APT_Operational_contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                    renewedAgreement.APT_System_User__c = proposal.Apttus_Proposal__Primary_Contact__c;
                    insert renewedAgreement;
                    System.debug('ProposalRenewal - 0' +  proposal.Apttus_Proposal__Primary_Contact__c);
                }
                
                /*
                //create configuration, cart line items and agreement line items
                String result = APT_AmendRenewUtility.createAgreementChildRecords(configuration.Id, renewedAgreement.ID);
                
                if(result != APT_Constants.SUCCESS_LABEL) {
                    Database.rollback(sp);
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result));
                    return null;
                } 
				*/                   
                
                // Commented out by Adrian Recio
                // Date 27/7/2017
                // Description Cloning of SAP Contract is moved in agreement activation process
                
                //1655
                //APT_AmendRenewUtility.copySAPContratcs(agreement.Id, renewedAgreement.Id, agreement.Apttus__Version_Number__c);                
                //1655   
                
                //build relationship with original agreement
                Boolean bResult = APT_AmendRenewUtility.afterRenew(agreement.Id, renewedAgreement.Id, false);
                if(!bResult) {
                    Database.rollback(sp);
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.RENEWAL_AGREEMENT_FAILED));
                    return null;
                } else {                
                    return getAgreementReturnURL(renewedAgreement.Id); //new PageReference('/' + renewedAgreement.Id + '/e?retURL=' + renewedAgreement.Id);     //APOST-1444
                }
                
                      
            }
            
            //amendment
            if(!String.isEmpty(proposal.APT_Contract_Number__c) && !String.isEmpty(proposalRecordTypeName) && proposalRecordTypeName.equalsIgnoreCase(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE)) {
                //create agreement            
                Apttus__APTS_Agreement__c  amendedAgreement = APT_AmendRenewUtility.amendAgreement(APT_Constants.RECORD_TYPE_DOV_CONTRACT, proposal.Apttus_Proposal__Opportunity__c,proposal.Id, agreement, APT_Constants.CREATE_AMENDMENT_CONTRACT);
                amendedAgreement.Apttus__Primary_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                amendedAgreement.APT_Customer_Application_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                amendedAgreement.APT_Commercial_Contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                amendedAgreement.APT_Operational_contact__c = proposal.Apttus_Proposal__Primary_Contact__c;
                amendedAgreement.APT_System_User__c = proposal.Apttus_Proposal__Primary_Contact__c;
                insert amendedAgreement;
                
                /*
                //create configuration, cart line items and agreement line items
                String result = APT_AmendRenewUtility.createAgreementChildRecords(configuration.Id, amendedAgreement.ID);
                
                if(result != APT_Constants.SUCCESS_LABEL) {
                    Database.rollback(sp);
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result));
                    return null;
                }                    
                */
                //build relationship with original agreement
                Boolean bResult = APT_AmendRenewUtility.afterAmend(agreement.Id, amendedAgreement.Id,false);
                if(!bResult) {
                    Database.rollback(sp);
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.AMEND_AGREEMENT_FAILED));
                    return null;
                } else {  
                    return getAgreementReturnURL(amendedAgreement.Id);
                    //return new PageReference('/' + amendedAgreement.Id + '/e?retURL=' + amendedAgreement.Id);     //APOST-1444
                }   
            }
        
        } catch(system.exception ex) {
            Database.rollback(sp);
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
		
        
        return null;
    }
    
    /**
     * Gets the return URL for Agreements
     * @param AgreementID Agreement ID
     * */
    @TestVisible private static PageReference getAgreementReturnURL(String AgreementID){
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.id = AgreementID;
        /*Aditya Shetty: Change to redirect to the Agreement detail page instead of Edit Page */
        PageReference pageRef = new PageReference('/'+AgreementID);
        pageRef.setRedirect(true);
        return pageRef ; 
        
    }
}