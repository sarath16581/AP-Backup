/**
This apex class is used as controller for vf component - APT_CartApprovalsComponent.
Created By - Kushal Bhalodiya
Created Date - 13th July, 2016
Last Modified By -
Last Modified Date -
**/
public class APT_ProposalApprovedRejectedController {
   public ID getproposalID() { 
       return proposalID;
   }
    public Id proposalId;
    public void setproposalID (ID s){
        proposalID  = s;
        APT_ProposalApprovedRejectedController ();
    }

    public Apttus_Proposal__Proposal__c proposalSO {get; set;}
    public Apttus_Config2__ProductConfiguration__c productConfigSO {get; set;}
    public List<Apttus_Approval__Approval_Request__c> approvalRequestList {get; set;}
    public List<ID> lineItemIDList {get; set;}
    public Map<ID,Apttus_Config2__LineItem__c> lineItemMap {get; set;}
    public void APT_ProposalApprovedRejectedController()
    {
        lineItemMap = new Map<ID,Apttus_Config2__LineItem__c>();
        lineItemIDList = new List<ID>();
        init();      
    }
    
    public void init () {
        productConfigSO = [select ID,Name,Apttus_Config2__AccountId__r.Customer_Number__c,Apttus_Config2__AccountId__r.Name from Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c =:proposalID and ( Apttus_Config2__Status__c = 'Finalized' OR Apttus_Config2__Status__c = 'Ready For Finalization' OR Apttus_Config2__Status__c = 'Rejected') ORDER BY createdDate DESC LIMIT 1];
        approvalRequestList = [select ID,Apttus_Approval__ChildObjectId__c,Apttus_Approval__Actual_Approver__r.Name,
                                     Apttus_Approval__Approver_Comments__c,Apttus_Approval__Approval_Status__c,
                                     Apttus_Approval__SubmissionComment1__c
                                     from Apttus_Approval__Approval_Request__c where Apttus_CQApprov__CartId__c =:productConfigSO.ID AND Apttus_Approval__ParentRequestId__c!=null];
        for(Apttus_Approval__Approval_Request__c approvalSO : approvalRequestList)
        {
           lineItemIDList.add(approvalSO.Apttus_Approval__ChildObjectId__c);
        }
        lineItemMap = new Map<ID,Apttus_Config2__LineItem__c>([select ID, APT_Pricing_Reason__c,
                                                                    Apttus_Config2__ProductId__r.Name,
                                                                    Apttus_Config2__AttributeValueId__r.Category__c,
                                                                    Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
                                                                    Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone__r.Name,
                                                                    APT_Display_Adjustment_Amount__c,APT_Previous_Discount__c,Apttus_Config2__AdjustmentAmount__c,
                                                                    APT_Rate_Card_Key__c, APT_Product_Name__c , APT_Product_Family__c 
                                                                    from Apttus_Config2__LineItem__c where ID IN :lineItemIDList]);
    }
    /**
    Get line item
    **/
    public String getProposalURL() {
         Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        String proposalURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalId;
        System.Debug('________Kushal+proposalURL'+proposalURL);
        return proposalURL;
    }
 
}