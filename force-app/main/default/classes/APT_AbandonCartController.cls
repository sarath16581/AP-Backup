/**
Description: This apex class is using VF page "APT_AbandonCart" to redirect user from Cart/Catalog to Opportunity page
Created By: Yatika Bansal
Created Date: 05-05-2023
2023.04.19 Ken McGuire  Proposal field migration to opportunity
*/

public class APT_AbandonCartController {
	ID proposalId;

	//Passing the proposal id from the URL on click of a button from the cart/catalog page.
	public APT_AbandonCartController(){
		proposalId = ApexPages.currentPage().getParameters().get('businessObjectId');
	}

	/**
	*Using pageReference to redirect page from Cart page to Opportunity page.
	*@param
	*@return  Opportunity page
	*/
	public pageReference redirectToOpp(){
		Id oppId;

		//Abandons  current cart
		List<Apttus_Config2__ProductConfiguration__c>  prodConfig = ProductConfigurationSelector.newInstance().selectByProposalId(new Set<Id>{proposalID});
		if(prodConfig.size() > 0){
			Apttus_CPQApi.CPQ.AbandonCartRequestDO request = new Apttus_CPQApi.CPQ.AbandonCartRequestDO();
			request.CartId = prodConfig[0].Id ;
			Apttus_CPQApi.CPQWebService.abandonCart(request);
		}

		//Querying the proposal record by passing the proposal id
		List<Apttus_Proposal__Proposal__c> existingProposalList = APT_ProposalObjectsSelector.newInstance(0,new Set<SObjectField>{Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c}).selectByConfigIds(new Set<Id>{proposalId});
		for(Apttus_Proposal__Proposal__c proposal:existingProposalList){
			oppId = proposal.Apttus_Proposal__Opportunity__c;
		}
		//Redirecting to the Opportunity page
		PageReference oppPage = new PageReference('/lightning/r/Opportunity/'+oppId + '/view');
		oppPage.setRedirect(true);
		return oppPage;
	}
}