/**
* Description: This apex class is handler for apex trigger - APT_CreditAssessmentTrigger
* Created By - Mausam Padhiyar
* Created Date - 15th Sept, 2016
* 
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 7th Nov, 2016 | Defect 1688 | Copy Credit Limit on proposal from credit assessment.
*
* Last Modified By - Mausam Padhiyar
* Last Modified Date - 19th Dec, 2016 | Defect 1550
*
* Last Modified By - avula.jansirani@auspost.com.au 
* Last Modified Date - 11-05-2021 | BCA application, billing account creation(1. added isAllowTocreateBillingAccount block in afterUpdateEvent() method 2. Added afterInsertEvent() method)
**/
public with sharing class APT_CreditAssessmentTriggerHandler {
    
    /**
     * After Update Trigger Event
     */
    public static final string AUTO_APPROVED = 'Auto-Approved' ;
    public static final string CREDIT_ASSESMENT_INITIATION_TYPE_ONLINE = 'Online';
    public static final string CREDIT_ASSESSMENT_STATUS_APPROVED = 'Approved' ;
    
    public static String afterUpdateEvent(list<APT_Credit_Assessment__c> listCreditAssessment, map<Id, APT_Credit_Assessment__c> mapOldCreditAssessment) {
        try {
            map<Id, APT_Credit_Assessment__c> mapProposalCreditAssessmentStatus = new map<Id, APT_Credit_Assessment__c>();
            map<Id, decimal> mapChargeAccountCreditLimit = new map<Id, decimal>();
            map<Id, APT_Credit_Assessment__c > mapChargeAccountApStartrackCreditLimit = new map<Id, APT_Credit_Assessment__c >();
            Map<Id, APT_Credit_Assessment__c > creditAssessmentIdRecordMap = new  Map<Id, APT_Credit_Assessment__c >();
            Set<Id> idSet = new Set<Id>();
            Set<Id> caIdSetToCreateBillingAcc = new Set<Id>(); 
            //1550
            set<Id> setChargeAccountId = new set<Id>();
            map<Id, Boolean> mapCreditManagementRejectedProposal = new map<Id, Boolean>();
            //1550
            for(APT_Credit_Assessment__c ca : listCreditAssessment) {
                //is credit assessment status changed?
                if((String.isNotBlank(ca.APT_Credit_Assessment_Status__c) && mapOldCreditAssessment.get(ca.Id) != null && String.isNotBlank(mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c) && !ca.APT_Credit_Assessment_Status__c.equalsIgnoreCase(mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c))
                    || (String.isNotBlank(ca.APT_Credit_Assessment_Status__c) && mapOldCreditAssessment.get(ca.Id) != null && String.isBlank(mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c))
                    || (String.isBlank(ca.APT_Credit_Assessment_Status__c) && mapOldCreditAssessment.get(ca.Id) != null && String.isNotBlank(mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c))) {
                    mapProposalCreditAssessmentStatus.put(ca.APT_Proposal__c, ca);

                    //1550
                    if(String.isNotBlank(ca.APT_Credit_Assessment_Status__c) && ca.APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
                        setChargeAccountId.add(ca.APT_Charge_Account__c);
                    }
                    //1550
                }
                
                //is credit limit changed?
                if((ca.L2C_AP_Proposed_Credit_Limit__c != null && mapOldCreditAssessment.get(ca.id).L2C_AP_Proposed_Credit_Limit__c != ca.L2C_AP_Proposed_Credit_Limit__c) ||
                    (ca.L2C_Star_Track_Proposed_Credit_Limit__c!= null && mapOldCreditAssessment.get(ca.id).L2C_Star_Track_Proposed_Credit_Limit__c != ca.L2C_Star_Track_Proposed_Credit_Limit__c) ||
                     mapOldCreditAssessment.get(ca.id).APT_Organisation_Name__c == null && ca.APT_Organisation_Name__c!=null) {
                        mapChargeAccountApStartrackCreditLimit.put(ca.APT_Charge_Account__c , ca);
                    }
                    
                if(APT_Constants.APPROVAL_STAGE_APPROVED.equalsIgnoreCase(ca.APT_Credit_Assessment_Status__c) && mapOldCreditAssessment.get(ca.id).APT_Credit_Assessment_Status__c != ca.APT_Credit_Assessment_Status__c ){
                    idSet.add(ca.Id);
                    //creditAssessmentIdRecordMap.put(ca.id , ca);    
                }
                system.debug('**** Charge Account AP Star Track Map ****'+mapChargeAccountApStartrackCreditLimit);
                if(String.isNotBlank(ca.APT_Credit_Assessment_Status__c) && (ca.APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED) || ca.APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_REJECT)) 
                    && mapOldCreditAssessment.get(ca.Id) != null && String.isNotBlank(mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c) && (mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED) || mapOldCreditAssessment.get(ca.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFER))) {

                    mapCreditManagementRejectedProposal.put(ca.APT_Proposal__c, true);
                } else {
                    mapCreditManagementRejectedProposal.put(ca.APT_Proposal__c, false);
                }
                
                // Check the CA's eligibility to create billing accounts
                if(BCABillingAccountCreationController.isAllowTocreateBillingAccount(ca)){
                       caIdSetToCreateBillingAcc.add(ca.Id); 
                   }

            }

            //calling future method to create billing accounts for respected eligible CA records
            if(caIdSetToCreateBillingAcc.size() > 0 && !System.isFuture()) 
                BCABillingAccountCreationController.createBillingAccount(caIdSetToCreateBillingAcc);
            
            //1550
            //map<Id, list<APT_Credit_Assessment__c>> mapCreditAssessmentByChargeAccount = new map<Id, list<APT_Credit_Assessment__c>>();
            map<Id, APT_Charge_Account__c> mapChargeAccount2 = new map<Id, APT_Charge_Account__c>([SELECT Id, APT_Entity_Type__c
                                                                                                FROM APT_Charge_Account__c
                                                                                             WHERE Id IN :setChargeAccountId]);
            
            map<Id, Boolean> mapPartnershipCreditAssessmentStatus = new map<Id, Boolean>();
            if(setChargeAccountId.size() > 0) {
                Boolean bPartnershipCreditAssessmentStatus;
                for(APT_Credit_Assessment__c ca : [SELECT Id, Name, APT_Charge_Account__c, 
                                                APT_Credit_Assessment_Status__c, APT_Credit_Assessment_Complete__c
                                                FROM APT_Credit_Assessment__c
                                                WHERE APT_Charge_Account__c IN :setChargeAccountId]) {
                    
                    if(ca.APT_Credit_Assessment_Complete__c && String.isNotBlank(ca.APT_Credit_Assessment_Status__c) && ca.APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
                        bPartnershipCreditAssessmentStatus = mapPartnershipCreditAssessmentStatus.get(ca.APT_Charge_Account__c);
                        if(bPartnershipCreditAssessmentStatus != null) {
                            if(bPartnershipCreditAssessmentStatus) {
                               mapPartnershipCreditAssessmentStatus.put(ca.APT_Charge_Account__c, true);
                            }
                        } else {
                            mapPartnershipCreditAssessmentStatus.put(ca.APT_Charge_Account__c, true);
                        }
                    } else {
                        mapPartnershipCreditAssessmentStatus.put(ca.APT_Charge_Account__c, false);
                    }

                    /*
                    list<APT_Credit_Assessment__c> listCreditAssessments = mapCreditAssessmentByChargeAccount.get(ca.APT_Charge_Account__c);
                    if(listCreditAssessment != null && listCreditAssessment.size() > 0) {
                        listCreditAssessments.add(ca);
                        mapCreditAssessmentByChargeAccount.put(ca.APT_Charge_Account__c, listCreditAssessments);
                    } else {
                        listCreditAssessments = new list<APT_Credit_Assessment__c>();
                        listCreditAssessments.add(ca);
                        mapCreditAssessmentByChargeAccount.put(ca.APT_Charge_Account__c, listCreditAssessments);
                    }
                    */
                }
            }
            //1550
            
            //update proposal for credit assessment status
            map<Id, Apttus_Proposal__Proposal__c> mapProposal = new map<Id, Apttus_Proposal__Proposal__c>([SELECT Id, APT_Credit_Assessment_Status__c
                                                                                                            FROM Apttus_Proposal__Proposal__c
                                                                                                            WHERE Id IN :mapProposalCreditAssessmentStatus.keySet()]);
                        
            list<Apttus_Proposal__Proposal__c> listProposal = new list<Apttus_Proposal__Proposal__c>();
            for(Apttus_Proposal__Proposal__c proposal : mapProposal.values()) {
                if(mapProposalCreditAssessmentStatus.get(proposal.Id) != null && String.isNotBlank(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c)) {
                    //1550
                    if((mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED) || mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVE2)) && String.isNotBlank(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Charge_Account__c)) {
                        if(mapPartnershipCreditAssessmentStatus.get(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Charge_Account__c) != null && mapPartnershipCreditAssessmentStatus.get(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Charge_Account__c)) {
                            proposal.APT_Credit_Assessment_Status__c = mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c;
                            //system.debug('*** proposal.APT_Credit_Assessment_Status__c ***'+proposal.APT_Credit_Assessment_Status__c);
                        } else {/*do not set approved status*/}
                    } else {
                        if(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Complete__c) {
                            proposal.APT_Credit_Assessment_Status__c = mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c;
                        }
                        
                        //system.debug('*** credit assessment status ***'+mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c);
                        if(String.isNotBlank(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c) && (mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED) || mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_REJECT)) ) {
                            //system.debug('*** Credit Rejected By Veda? ***'+mapCreditManagementRejectedProposal.get(proposal.Id));
                            if(mapCreditManagementRejectedProposal.get(proposal.Id)) {
                                proposal.APT_Credit_Rejected_By_Veda__c = false;
                            } else{
                                proposal.APT_Credit_Rejected_By_Veda__c = true;
                            }
                        }
                    }
                    //1550

                    proposal.APT_Estimated_Credit_Amount__c = mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Amount_Required__c;
                    listProposal.add(proposal);
                } else if(mapProposalCreditAssessmentStatus.containsKey(proposal.Id) && mapProposalCreditAssessmentStatus.get(proposal.Id) != null && String.isBlank(mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Assessment_Status__c)){
                    proposal.APT_Credit_Assessment_Status__c = null;
                    proposal.APT_Estimated_Credit_Amount__c = mapProposalCreditAssessmentStatus.get(proposal.Id).APT_Credit_Amount_Required__c;
                    listProposal.add(proposal);
                } else {}
            }
            
            if(listProposal != null && listProposal.size() > 0) {
                update listProposal;
            }
            
            //update charge account for credit limit
            map<Id, APT_Charge_Account__c> mapChargeAccount = new map<Id, APT_Charge_Account__c>([SELECT Id, APT_Credit_Limit_Required__c, AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c
                                                                                                FROM APT_Charge_Account__c
                                                                                                WHERE Id IN :mapChargeAccountApStartrackCreditLimit.keySet()]);
            list<APT_Charge_Account__c> listChargeAccount = new list<APT_Charge_Account__c>();
            for(APT_Charge_Account__c ca : mapChargeAccount.values()) {
                if(mapChargeAccountApStartrackCreditLimit !=null && mapChargeAccountApStartrackCreditLimit.get(ca.Id) != null) {
                    ca.AP_Proposed_Credit_Limit__c = mapChargeAccountApStartrackCreditLimit.get(ca.Id).L2C_AP_Proposed_Credit_Limit__c;
                    ca.Star_Track_Proposed_Credit_Limit__c = mapChargeAccountApStartrackCreditLimit.get(ca.Id).L2C_Star_Track_Proposed_Credit_Limit__c;
                    ca.APT_Organisation__c = mapChargeAccountApStartrackCreditLimit.get(ca.Id).APT_Organisation_Name__c;
                    listChargeAccount.add(ca);
                } 
            }
            // Checking if Status of the Credit Assessment is Approved and there have been any changes to Credit Amounts for Star Track or Auspost or a approved Credit is being manually attached to Organisation
            if(((APT_Constants.APPROVAL_STAGE_APPROVED.equalsIgnoreCase(listCreditAssessment[0].APT_Credit_Assessment_Status__c) || AUTO_APPROVED.equalsIgnoreCase(listCreditAssessment[0].APT_Credit_Assessment_Status__c))&& mapOldCreditAssessment.get(listCreditAssessment[0].id).APT_Credit_Assessment_Status__c != listCreditAssessment[0].APT_Credit_Assessment_Status__c) || 
                ((APT_Constants.APPROVAL_STAGE_APPROVED.equalsIgnoreCase(listCreditAssessment[0].APT_Credit_Assessment_Status__c) || AUTO_APPROVED.equalsIgnoreCase(listCreditAssessment[0].APT_Credit_Assessment_Status__c)) && mapOldCreditAssessment.get(listCreditAssessment[0].id).APT_Organisation_Name__c==NULL && listCreditAssessment[0].APT_Organisation_Name__c!=NULL)){
                List<Account> accList = new List<Account>();
                if(!listCreditAssessment.isEmpty() && listCreditAssessment[0].APT_Organisation_Name__c != null){
                    // Querying the account which islinked to the credit assessment record
                    accList = [Select id , L2C_Approved_AP_Credit_Limit__c , L2C_Star_Track_Approved_Credit_Limit__c from Account where id = :listCreditAssessment[0].APT_Organisation_Name__c LIMIT 1];
                }
                if(!accList.IsEmpty()){
                    // Updating the Account's Approved Auspost Credit Limit Field
                    accList[0].L2C_Approved_AP_Credit_Limit__c = listCreditAssessment[0].L2C_AP_Proposed_Credit_Limit__c;
                    // Updating the Account's Approved Startrack Credit Limit Field
                    accList[0].L2C_Star_Track_Approved_Credit_Limit__c = listCreditAssessment[0].L2C_Star_Track_Proposed_Credit_Limit__c ;   
                    // Updating Account List
                    Database.update(accList);
                } 
            }
            
            if(listChargeAccount != null && listChargeAccount.size() > 0) {
                update listChargeAccount;
            }
            
        } catch(system.exception ex) {
            return ex.getMessage();
        }
        return APT_Constants.SUCCESS_LABEL;
    }
    
    /**
     * Added by - avula.jansirani@auspost.com.au , 11-05-2021
     * */
    public static void afterInsertEvent(list<APT_Credit_Assessment__c> listCreditAssessment, map<Id, APT_Credit_Assessment__c> mapOldCreditAssessment){
        
        Set<Id> caIdSetToCreateBillingAcc = new Set<Id>(); 
        
        for(APT_Credit_Assessment__c ca : listCreditAssessment) {
            // Check the CA's eligibility to create billing accounts.
            if(BCABillingAccountCreationController.isAllowTocreateBillingAccount(ca)){
                   caIdSetToCreateBillingAcc.add(ca.Id);
               }   
        }
        
        //calling future method to create billing accounts for eligible CA records
        if(caIdSetToCreateBillingAcc.size() > 0)   
            BCABillingAccountCreationController.createBillingAccount(caIdSetToCreateBillingAcc);
    }
    

}