/**
Description - 
Created By - Mausam Padhiyar
Created Date - 2nd Dec, 2015
Last Modified By - Mausam Padhiyar
Last Modified Date - 24th Jan, 2017 | Defect 1550 | Credit Assessment Rejected by Veda or Credit Assessment team.
 */
public with sharing  class APT_SendInstanceURL
{
    public Boolean multipleCreditAssessments {set;}
    public Boolean greaterThan25K {set;}   
    public String proposalNotComplete{get;set;}
    
    /* 
        Method returns boolean state of proposal.
    */
    public Boolean getAssessmentNotComplete(){
        return (APT_Constants.BOOLEAN_TRUE).equalsIgnoreCase(proposalNotComplete);
    }
    
    public String ProposalId{get;set;}
    
    private Apttus_Proposal__Proposal__c  proposal;
    
    private List<APT_Credit_Assessment__c> CreditAssessments;
    public string baseURL {get;set;}
    
     /* 
        Method to set baseurl.
    */
    public APT_SendInstanceURL() {
         try{   
            baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            System.Debug('-->' + ProposalId);
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            
        }   
    }


     /* 
        Method to query proposal.
    */    
    public Apttus_Proposal__Proposal__c getProposal(){
         try {
            if(proposal == null && String.IsNotBlank(ProposalId)){
                proposal = [select id, Name, APT_Credit_Assessment_Status__c, APT_Credit_Assessment_Status_Details__c,
                                Apttus_Proposal__Account__r.Name, Apttus_Proposal__Account__r.customer_Number__c,
                                Apttus_Proposal__Opportunity__r.Opportunity_Number__c, APT_Estimated_Credit_Amount__c,
                                APT_Credit_Referred_Manually__c, APT_Credit_Rejected_By_Veda__c
                                from Apttus_Proposal__Proposal__c 
                                where id =: ProposalId];
                                
               /* if(proposal != null && (APT_Constants.APPROVAL_STATUS_REJECTED).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c)){
                    proposal.APT_Credit_Assessment_Status__c = APT_Constants.CREDIT_ASSESSMENT_DECLINE;
                }*/
            }
        return proposal;
         } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }   
        
    }
    
    
     /* 
        Method to get credit assessments.
    */      
    public List<APT_Credit_Assessment__c> getCreditAssessments(){
        try {
            System.Debug('-->' + ProposalId);
            if(CreditAssessments == null){
                CreditAssessments = [SELECT ID FROM APT_Credit_Assessment__c WHERE APT_Proposal__c =: ProposalId];
            }
        return CreditAssessments;
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }   
    }

     /* 
        Method returns boolean based on estimated credit amount of proposal.
    */      
    public Boolean getGreaterThan25K(){
        try {
            return proposal != null && proposal.APT_Estimated_Credit_Amount__c > Decimal.ValueOf(Label.L2C_Upper_Threshold_Limit_For_Credit_Assessment);
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }   
    }

     /* 
        Method returns boolean based on credit assessments.
    */    
    public Boolean getMultipleCreditAssessments(){
        try {
            System.Debug('-->' + ProposalId);
            return getCreditAssessments() != null && getCreditAssessments().size() > 1;
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }   
        
    }
     /* 
        Method returns boolean based on credit assessments.
    */      
    public Boolean getSingleCreditAssessments(){
        try {
            System.Debug('-->' + ProposalId);
            return getCreditAssessments() == null || getCreditAssessments().size() <= 1;
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }     
        
    }
     /* 
        Method returns boolean based on credit assessments.
    */ 
    public Boolean getDeclinedCreditAssessments() {
        try {
            if(proposal == null){
                getProposal();
            }
            return (proposal != null && ((APT_Constants.APPROVAL_STATUS_REJECTED).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c))
                                           || (APT_Constants.CREDIT_ASSESSMENT_DECLINE).equalsIgnoreCase(proposal.APT_Credit_Assessment_Status__c));
        } catch(system.exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }                                  
    }
}