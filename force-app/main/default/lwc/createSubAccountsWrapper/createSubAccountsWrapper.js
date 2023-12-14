/**
 * @description Wrapper component of creating sub accounts request
 * @author Harry Wang
 * @date 2023-11-28
 * @group Controller
 * @changelog
 * 2023-11-28 - Harry Wang - Created
 */
import {LightningElement, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import LightningAlert from 'lightning/alert';
import hasAccess from "@salesforce/customPermission/BG_Core";
import LABEL_TAB_ERROR from "@salesforce/label/c.StarTrackSubAccountsCreationTabError";
import LABEL_NO_ACCESS_ERROR from "@salesforce/label/c.StarTrackSubAccountsCreationNoAccessError";
import LABEL_TITLE from "@salesforce/label/c.StarTrackSubAccountsCreationTitle";

export default class CreateSubAccountsWrapper extends NavigationMixin(LightningElement) {
	recordId;
	isTEAMRequest;
	initialLoad;
	isBillingAccount;
	contextId;
	hasPageReferenceState = false;

	/**
	 * If user has no access to create sub account requests
	 */
	get hasNoAccess() {
		return !hasAccess;
	}

	/**
	 * Retrieve URL parameters from page reference
	 * Show error if no parameters passed
	 */
	@wire(CurrentPageReference)
	async setCurrentPageReference(currentPageReference) {
		// assign current page parameters
		this.recordId = currentPageReference?.state?.c__recordId;
		this.isTEAMRequest = currentPageReference?.state?.c__isTEAMRequest === 'true';
		this.initialLoad = currentPageReference?.state?.c__initialLoad;
		this.isBillingAccount = currentPageReference?.state?.c__isBillingAccount;
		this.contextId = currentPageReference?.state?.c__contextId;

		// pop up error if user go via the lightning tab directly
		if (Object.keys(currentPageReference?.state).length === 0) {
			await LightningAlert.open({
				message: LABEL_TAB_ERROR,
				theme: 'error',
				label: LABEL_TITLE
			});
			return;
		}
		// pop up error if user don't have access
		if (this.hasNoAccess) {
			LightningAlert.open({
				message: LABEL_NO_ACCESS_ERROR,
				theme: 'error',
				label: LABEL_TITLE
			}).then(() => {
				this.navigateBackToLeader();
			});
			return;
		}

		// navigate back to leader if no recordId passed - existing sub account is referred
		if (!this.recordId) {
			this.navigateBackToLeader();
			return;
		}

		// show child components if no errors or issues
		this.hasPageReferenceState = true;
	}

	/**
	 * Navigate back to leader - Billing Account or Opportunity Record
	 */
	navigateBackToLeader() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.isBillingAccount === 'true'? this.recordId : this.contextId,
				actionName: 'view'
			},
		});
	}

}