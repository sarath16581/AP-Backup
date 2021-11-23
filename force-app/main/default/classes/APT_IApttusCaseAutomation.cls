/**************************************************
Description: Interface for Apttus Proposal Customization
History    : 2019-08-05 Neha - Define all the methods that requires customization in related to Workforce
**************************************************/
public interface APT_IApttusCaseAutomation {
/**
 * This is method for Auto ACIC Case Creation when Proposal is in Accepted Stage
 * @param List<Apttus_Proposal__Proposal__c> will get List of Proposal
 * @param Map<Id, Apttus_Proposal__Proposal__c> will get Map of Old Proposal
 **/
void caseCreate(List<Apttus_Proposal__Proposal__c> listProposal, Map<Id, Apttus_Proposal__Proposal__c> mapProposalOld);
}