/**
 * @description Wrapper component of creating TEAM follower offspring request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CreateTeamFollowerOffspringRequest extends NavigationMixin(LightningElement) {
	@api recordId;
	@api isBillingAccount;
	subAccountId;
	isABNConfirmation = true;
	isEditView = false;
	showEditForm() {
		this.isABNConfirmation = false;
		this.isEditView = true;
		console.log('SubAccountId: ' + this.subAccountId);
	}

	navigateToLeader(event) {
		// This method is called from: ABN Confirmation Close button, List View navigation bar, Edit Form Close button
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: event.detail,
				actionName: 'view'
			},
		});
	}
}