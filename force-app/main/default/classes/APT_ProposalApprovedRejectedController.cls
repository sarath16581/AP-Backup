/**
This apex class is used as controller for vf component - APT_CartApprovalsComponent.
Created By - Kushal Bhalodiya
Created Date - 13th July, 2016
Last Modified By -  Nasir Jawed
Last Modified Date - 2-12-2022
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
    public set<ID> lineitemSet = new set<ID>();
    public void APT_ProposalApprovedRejectedController()
    {
        lineItemMap = new Map<ID,Apttus_Config2__LineItem__c>();
        lineItemIDList = new List<ID>();
        init();      
    }
    
    public void init () {
		Set<String> picklist = new Set<String>();
		picklist.add('Finalized');
		picklist.add('Ready For Finalization');
		picklist.add('Rejected');
		
		if((ProductConfigurationSelector.newInstance(1).selectByProposalIdAndStatusWithOrder(new set<ID>{(ID)proposalID},picklist,new set<Object>{ProductConfigurationSelector.options.WITH_ACCOUNT})).size() > 0) {
		
			productConfigSO =ProductConfigurationSelector.newInstance(1).selectByProposalIdAndStatusWithOrder(new set<ID>{(ID)proposalID},picklist,new set<Object>{ProductConfigurationSelector.options.WITH_ACCOUNT})[0];
			system.debug('productConfigSO:'+ productConfigSO );
		}
		
		approvalRequestList = APT_ApprovalRequestsSelector.newInstance().selectByProdConfigId(new Set<ID>{productConfigSO.id},new Set<Object>{APT_ApprovalRequestsSelector.Options.WITH_USER,APT_ApprovalRequestsSelector.Options.FILTER_APPROVAL_REQUEST});                          
		for(Apttus_Approval__Approval_Request__c approvalSO : approvalRequestList)
		{
			lineItemIDList.add(approvalSO.Apttus_Approval__ChildObjectId__c);
		}
		
		lineitemSet.addAll(lineItemIDList);        
		lineItemMap = LineItemsSelector.newInstance().selectById(lineitemSet,new set<Object>{LineItemsSelector.options.WITH_PRODUCT,LineItemsSelector.options.WITH_PRODUCT_ATTRIBUTE_VALUE});
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