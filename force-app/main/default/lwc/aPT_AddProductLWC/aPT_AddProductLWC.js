/**
*@author Nasir Jawed
*@date 2023-02-13
*@description LWC component which is getting called from Aura component "Aura_AddProduct.cmp" which is placed as a lightning Action button
*on the page layout of Opportunity (Add Product) *
*/
import { LightningElement,api ,track} from 'lwc';
import validationCheck from "@salesforce/apex/APT_LandingCartController.validationCheck";
import { NavigationMixin } from 'lightning/navigation';
export default class APT_AddProductLWC extends NavigationMixin(LightningElement) {
	@api recordId;
	@api proposalId;
	@api flow
	@api resultfromAura
	isLoading;
	success;
	error;
	disablebutton;

	// Calling the function on click of "Add Product" button from opportunity and passing the opportunity record id to process proposal and land of Catalog page
	connectedCallback(){
		this.isLoading = true;
		validationCheck(
			{
				recordId: this.recordId
			})
			.then((result) => {
				if(result != null){
					this.resultfromAura = result;
					let splitUrl = this.resultfromAura.split("+");
					this.proposalId = splitUrl[0];
					this.flow = splitUrl[1];

					//Redirecting the proposal created to the Catalogue page
					if(this.flow !=null ){
						this[NavigationMixin.Navigate]({
							type: 'standard__webPage',
							attributes: {
								url:'/apex/Apttus_Config2__Cart?businessObjectId='+ this.proposalId  +'&flow='+ this.flow +'&useAdvancedApproval=true&useDealOptimizer=true&productOrderByClause=APT_Most_Popular__c%20NULLS%20LAST&launchState=catalog#!/search/'
								}
						},
						true
					  );
					} else{
						this[NavigationMixin.Navigate]({
							type: 'standard__webPage',
							attributes: {
								url :'/apex/Apttus_Config2__Cart?businessObjectId='+ this.proposalId +'&useAdvancedApproval=true&useDealOptimizer=true'
							}
						},
						true
					);
					}

				}
			})
			.catch((error) => {
				this.isLoading = false;
				this.error = error.body.message;
			})
	}
}