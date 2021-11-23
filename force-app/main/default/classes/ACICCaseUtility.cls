/**
* @author       : gnana.muruganantham@auspost.com.au
* @date         : 25/03/2019
* @description  : Utility Class for ACIC Request Case object trigger 
*/
/*******************************  History ************************************************
    Date                User                                        Comments
    25/03/2019          gnana.muruganantham@auspost.com.au             Created to manage ACIC related methods
*******************************  History ************************************************/

public with sharing class ACICCaseUtility {
    
    /*********************************************************************************************************
    * @description       This method is invoked from the CaseTriggerHandler, to add Case Creator to a Case Team so they continue to have access to cases created by them
    * @param             caseList - List<Case>
    * @return            Void
    * @throws            Exceptions handled by the UTIL_LoggingService class
    *********************************************************************************************************/
    public void addCaseTeamMemberForACICCase(List<Case> caseList) {
        try {
            System.debug('inside assignDefaultValuesToACICCase ==> ' + caseList);
            
            // Get Case Team role
            Id caseTeamRoleId= [SELECT Id FROM CaseTeamRole WHERE Name = 'Case Viewer' LIMIT 1].id;
            
            // Get ACIC Case Record Type Id
            Id acicRecordTypeId = CaseUtility.getRecordIdWithDevName(Constants.RECORDTYPE_NAME_ACIC_REQUEST);
            
            // get only the records that need processing
            List<Case> filteredCases = (List<Case>)RecursionUtility.getUnprocessedRecords('addCaseTeamMemberForACICCase' + 'Insert', caseList, null);
            
            // Add Case Team Member record for each Case
            List<CaseTeamMember> catmList=new List<CaseTeamMember>();
            for(Case cs:filteredCases ){
                if (cs.RecordTypeId == acicRecordTypeId){
                    CaseTeamMember tm=new CaseTeamMember();
                    tm.ParentId=cs.Id;
                    tm.MemberId=cs.CreatedById;
                    tm.TeamRoleId =caseTeamRoleId;
                    catmList.add(tm);
                }
            }
            
            // Insert Case Team List
            if(!catmList.isEmpty()) {
                Insert catmList;
                
            }
        }
        catch(Exception exp){
            System.debug('addCaseTeamMemberForACICCase exception ==>'+exp);
            
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), Constants.ACIC_APP, ACICCaseUtility.class.getName(), Constants.METH_ADD_CASETEAM_MEMBER,Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**************************************************************************************************************
    * @description       This method is invoked from the CaseTriggerHandler, to update ACIC Request Approved checkbox on Proposal 
                         based on whether the ACIC Case has been Approved or Rejected
    * @param             caseList - List<Case>
    * @return            Void
    * @throws            Exceptions handled by the UTIL_LoggingService class
    **************************************************************************************************************/
    public void updateProposalBasedOnACICStatus(List<Case> caseList,Map<Id,Case> oldMap){
        try{
            System.debug('inside assignDefaultValuesToACICCase ==> '+caseList);
            
            // Get ACIC Case Record Type Id
            Id acicRecordTypeId = CaseUtility.getRecordIdWithDevName(Constants.RECORDTYPE_NAME_ACIC_REQUEST);
            
            // get only the records that need processing
            List<Case> filteredCases = (List<Case>)RecursionUtility.getUnprocessedRecords('updateProposalBasedOnACICStatus' +  (oldMap == null ? 'Insert' : 'Update'), caseList, new Set<String>{'Status'});
            
            if(filteredCases != null && !filteredCases.isEmpty() && oldMap != null && !oldMap.isEmpty()) {                
                //Iterate all cases and add the proposals to update
                List<Apttus_Proposal__Proposal__c> listOfProposalsToUpdate = new List<Apttus_Proposal__Proposal__c>();
                for (Case caseRec : filteredCases) {
                    Case oldCase = oldMap.get(caseRec.Id);
                    System.debug('inside assignDefaultValuesToACICCase ==> '+caseRec.Status + ' ' +oldCase.Status);
                    // Check for ACIC Case Record Type and Case Status
                    if (caseRec.RecordTypeId == acicRecordTypeId && caseRec.Status != oldCase.Status && (caseRec.Status==Constants.CASE_STATUS_REJECTED || caseRec.Status==Constants.CASE_STATUS_APPROVED)) {
                        
                        Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
                        proposal.Id=caseRec.Proposal__c;
                        proposal.ACIC_Request_Approved__c = caseRec.Status == Constants.CASE_STATUS_APPROVED ? true : proposal.ACIC_Request_Approved__c;
                        
                        // add Proposals to update
                        listOfProposalsToUpdate.add(proposal);
                    }
                }
                
                //Update Proposal records
                Update listOfProposalsToUpdate;
            }
        }
        catch(Exception exp){
            System.debug('sendACICRequestNotificationAndUpdateProposal exception message ==> Message =' +exp.getMessage());
            
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), Constants.ACIC_APP, ACICCaseUtility.class.getName(), Constants.METH_UPDATE_PROPOSAL, Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
}