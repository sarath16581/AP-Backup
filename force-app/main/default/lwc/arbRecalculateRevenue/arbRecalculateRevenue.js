import { LightningElement, api } from 'lwc';

import recalculateRevenue from '@salesforce/apex/AtRiskBusinessController.recalculateRevenue';
import { NavigationMixin } from 'lightning/navigation';

export default class ArbRecalculateRevenue extends LightningElement {
	@api recordId; 

	@api invoke() {
		recalculateRevenue({arbId: this.recordId})
			.then(() => {
				// Force navigation to refresh page
				this[NavigationMixin.Navigate]({
					type: 'standard__recordPage',
					attributes: {
						recordId: this.recordId,
						objectApiName: 'At_Risk_Business__c',
						actionName: 'view'
					}
				});
			})
			.catch(error => {
				console.error('[RECALCULATE REVENUE]', error);
			});
	}
}