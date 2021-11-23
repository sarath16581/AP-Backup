public class APT_DGTProposalApprovalsCustomController{
   String Query;
   public Apttus_Proposal__Proposal__c propSO {get;set;}
   public String propID {get;set;}
   //public String ProductLines{get;set;}
   //public String ApprovalRequestComment{get;set;}
        public String getApprovalRequestComment(){
            List<Apttus_Approval__Approval_Request__c> approvalRequestObject = [Select ID,Apttus_Approval__Approver_Comments__c from Apttus_Approval__Approval_Request__c where Apttus_Approval__Object_Id__c =:propID and Apttus_Approval__Initial_Submitter__c!= null ORDER BY CreatedDate DESC LIMIT 1];
            if(approvalRequestObject .size() > 0)
            return approvalRequestObject[0].Apttus_Approval__Approver_Comments__c;
            else
            return null;
        }
        
     //for Product Line items
    
        public String getProductLines(){
            String proposalLineItems = '';
            Query = 'Select ID from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c = :propID  AND Apttus_Config2__Status__c = \'Finalized\' LIMIT 1';
            List<Apttus_Config2__ProductConfiguration__c> var= Database.query(Query);
            List<Apttus_Config2__LineItem__c> liLineItem= [select ID,APT_Product_Name__c,Apttus_Config2__ProductId__r.Name, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__IsOptionRollupLine__c , Apttus_Config2__LineType__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:var  and Apttus_Config2__IsPrimaryLine__c = true and Apttus_Config2__IsOptionRollupLine__c = false and Apttus_Config2__LineType__c = 'Product/Service'];
            for(integer i=0;i<liLineItem.size();i++){
                    if(liLineItem.size()==(i+1)){
                        proposalLineItems = proposalLineItems + liLineItem[i].Apttus_Config2__ProductId__r.Name ;
                    }
                    else{
                    proposalLineItems = proposalLineItems + liLineItem[i].Apttus_Config2__ProductId__r.Name + ','; 
                    }
            }           
            return proposalLineItems;
        }   
    }