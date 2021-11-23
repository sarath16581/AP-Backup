public class APT_ContractSOPApprovedRejController{
    public String contractId {get;set;}
    public Apttus_Approval__Approval_Request__c getapprovalRequestSO(){
        Apttus_Approval__Approval_Request__c  approvalRequestSO = new Apttus_Approval__Approval_Request__c();
        if(null != contractId)
            approvalRequestSO = [Select ID,Apttus_Approval__SubmissionComment1__c,Apttus_Approval__Approver_Comments__c,Apttus_Approval__ActualApproverName__c from Apttus_Approval__Approval_Request__c where Apttus_Approval__Object_Id__c =:contractId LIMIT 1];
        return approvalRequestSO;
    }
    public Apttus__APTS_Agreement__c getagreementSO(){
        Apttus__APTS_Agreement__c  agreementSO = new Apttus__APTS_Agreement__c();
        if(null != contractId)
            agreementSO = [Select ID,Owner.Name,Included_Product_Lines__c,APT_Price_Plan__c,Apttus_Approval__Approval_Status__c from Apttus__APTS_Agreement__c where ID =:contractId];
        return agreementSO;
    }
}