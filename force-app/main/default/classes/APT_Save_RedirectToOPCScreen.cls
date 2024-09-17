/**
Description: This apex class is using VF page "APT_Save_RedirectToOPCScreen" to redirect user from Cart to Bulk Edit page
Created By: Nasir Jawed
Created Date: 22-02-2023
Last Modified By:
Last Modified Date:
@changelog:
06-12-2023 Bharat Patel - STP-9773: Update oPCScreenRedirect(), set configuration update's version logic
*/

public class APT_Save_RedirectToOPCScreen{
	ID proposalId;
	//Passing the proposal id from the URL on click of a button from the cart page.
	public APT_Save_RedirectToOPCScreen(){
		proposalId = ApexPages.currentPage().getParameters().get('businessObjectId');
	}
	/**
	*Using pageReference to redirect page from Cart page to OpportunityLineItems page.
	*@param
	*@return  OpportunityLineItems page with OpportunityId
	*/
	public pageReference oPCScreenRedirect(){
	Application.Profiler.start('ShoppingCartSaveRedirectToOPC.APT_Save_RedirectToOPCScreen.oPCScreenRedirect');
	Id oppId;
	List<Apttus_Config2__ProductConfiguration__c>  prodConfigListToUpdate = new List<Apttus_Config2__ProductConfiguration__c>();
	// Query product configuration record
	List<Apttus_Config2__ProductConfiguration__c>  prodConfigList = ProductConfigurationSelector.newInstance().selectByProposalId(new Set<Id>{proposalID});
		for(Apttus_Config2__ProductConfiguration__c productConfig : prodConfigList){
		if(productConfig.Apttus_Config2__Status__c == APT_Constants.URL_SAVED || productConfig.Apttus_Config2__Status__c == APT_Constants.CASE_STATUS_NEW) {
			if(productConfig.Apttus_Config2__Status__c == APT_Constants.CASE_STATUS_NEW) {
				productConfig.Apttus_Config2__Status__c = APT_Constants.URL_SAVED;
			}
				productConfig.APT_Configuration_Update_Version__c = productConfig.APT_Configuration_Update_Version__c + 1;
				prodConfigListToUpdate.add(productConfig);
			}
		}

		ApplicationDatabase.getInstance().dmlUpdate(prodConfigListToUpdate);

	//Querying the proposal record by passing the proposal id
	List<Apttus_Proposal__Proposal__c> existingProposalList = APT_ProposalObjectsSelector.newInstance(0,new Set<SObjectField>{Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c}).selectByConfigIds(new Set<Id>{proposalId});
	for(Apttus_Proposal__Proposal__c proposal:existingProposalList){
		oppId = proposal.Apttus_Proposal__Opportunity__c;
	}

	PageReference bulkEditProduct = new PageReference('/lightning/cmp/c__APT_SaveCart_RedirectToOpp?c__oppId='+ oppId + '&t=' + Math.random());
	bulkEditProduct.setRedirect(true);

	Application.Profiler.stop('ShoppingCartSaveRedirectToOPC.APT_Save_RedirectToOPCScreen.oPCScreenRedirect');
	return bulkEditProduct;
	}
}