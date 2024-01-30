import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getBaseUrl from '@salesforce/apex/CloseAccountController.getBaseUrl';
import getAPCN from '@salesforce/apex/CloseAccountController.getAPCN';

export default class CloseAccount extends NavigationMixin(LightningElement) {
	@api recordId
	baseUrl;
	apcn;

	async connectedCallback() {
		this.baseUrl = await getBaseUrl();
		this.apcn = await getAPCN({accId: this.recordId});

		this[NavigationMixin.Navigate]({
		type: 'standard__webPage',
			attributes: {
				url: this.baseUrl + this.apcn
			}
		});
	}
}