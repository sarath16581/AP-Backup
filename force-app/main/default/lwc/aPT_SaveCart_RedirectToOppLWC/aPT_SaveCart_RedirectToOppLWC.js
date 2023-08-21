/**
*@author Bharat Patel
*@date 2023-05-11
*@group Synchronizing
*@tag ShoppingCart
*@tag Opportunity
*@domain Apttus
*@description The class will redirect user to OpportunityLineItems of respected Opportunity.
* NOTE:As Synchronisation of Products selected in Shopping Cart with Opportunity is running in background.
*      The LWC added, to reduce the number of instance/ experice of not able to see sync product's under
*      OpportunityLineItems as the process running in background (async mode) and to break the transaction
*      chain as observed the synchronisaion process start after the transation execution complete.
*      Please refresh your browser after a few seconds in case products are not synchronised instantly.
*      This class is responsible only redirect user to respected UI.
* @changelog
* 2023-05-11 - Bharat Patel - Created
* 2023-07-31 - Nasir Jawed - Made changes on the redirection of the URL, now landing at BULK EDIT SCREEN
*/
import { LightningElement, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class APT_SaveCart_RedirectToOppLWC extends NavigationMixin(LightningElement){
	/**
	*@description Opportunity record Id, receive as parameter, on action 'Save & Add Products to Opportunity' execution
	from Apttus Shopping Cart UI
	*/
	@api recordId;
	connectedCallback() {
		let opportunityLineItemsURL = '/lightning/cmp/c__opcNavToBulkEdit?c__oppId='+this.recordId;
		setTimeout(() => {
			window.location.href = opportunityLineItemsURL;
		}, 5000);
	}
}