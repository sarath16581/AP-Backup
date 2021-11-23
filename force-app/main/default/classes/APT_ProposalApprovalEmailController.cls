public class APT_ProposalApprovalEmailController{
   String Query;
   //public Apttus_Proposal__Proposal__c propSO {get;set;}
   //public Apttus_Approval__Approval_Request__c approvalRequestSO {get;set;}
   public String propID {get;set;}
   
     //for Product Line items
    
        public String getProductLines(){
            String proposalLineItems = '';
            
            Query = 'Select ID from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c = :propID  AND (Apttus_Config2__Status__c= \'Ready For Finalization\' OR Apttus_Config2__Status__c = \'Finalized\') LIMIT 1';
       
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