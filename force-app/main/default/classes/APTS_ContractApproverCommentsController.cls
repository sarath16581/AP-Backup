public class APTS_ContractApproverCommentsController{

   public Apttus__APTS_Agreement__c ContractSO {get;set;}
   public String ContractID {get;set;}

   //public String ApprovalRequestComment{get;set;}
        public String getApprovalRequestComment(){
            Apttus_Approval__Approval_Request__c approvalRequestObject = [Select ID,Apttus_Approval__Approver_Comments__c from Apttus_Approval__Approval_Request__c where Apttus_Approval__Object_Id__c=:ContractSO.ID and (Apttus_Approval__Approval_Status__c = 'Approved' OR Apttus_Approval__Approval_Status__c ='Rejected')  ORDER BY CreatedDate DESC LIMIT 1];
            return approvalRequestObject.Apttus_Approval__Approver_Comments__c;
        } 
    }