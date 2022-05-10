/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Controller
 * @tag Controller
 * @domain ICPS
 * @description Javascript Controller for ICPS Clone.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import cloneICPS from '@salesforce/apex/ICPSServiceController.cloneICPS';

export default class IcpsClone extends NavigationMixin(LightningElement) {
	@api recordId;

	@api invoke() {
		if (confirm("Are you sure to clone the current ICPS record?")) {
			this.startToast('Processing clone...', 'info');
			this.startCloning();
		}
	}

	startCloning() {
		cloneICPS({icpsId: this.recordId}).then(result => {
			this.navigateToViewICPSPage(result.Id);
			this.startToast('Cloning completed', 'success');
		}).catch(error => {
			this.startToast('An Error occurred during cloning: ' + error.body.message, 'error');
		});
	}

	startToast(msg, variant) {
		let event = new ShowToastEvent({
			title: 'ICPS Clone',
			message: msg,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	navigateToViewICPSPage(recordId) {
		let icpsViewPageRef = {
			type: 'standard__recordPage',
			attributes: {
				recordId: recordId,
				actionName: 'view'
			}
		};
		this[NavigationMixin.Navigate](icpsViewPageRef);
	}
}