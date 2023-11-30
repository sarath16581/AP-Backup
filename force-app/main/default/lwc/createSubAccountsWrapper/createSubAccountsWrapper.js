/**
 * @description Wrapper component of creating sub accounts request
 * @author Harry Wang
 * @date 2023-11-28
 * @group Controller
 * @changelog
 * 2023-11-28 - Harry Wang - Created
 */
import {LightningElement, wire} from 'lwc';
import {CurrentPageReference} from "lightning/navigation";
import LightningAlert from 'lightning/alert';
import errorMessage from "@salesforce/label/c.StarTrackSubAccountsCreationTabError";

export default class CreateSubAccountsWrapper extends LightningElement {
	recordId;
	isTEAMRequest;
	initialLoad;
	isBillingAccount;
	hasPageReferenceState = false;

	/**
	 * Retrieve URL parameters from page reference
	 * Show error if no parameters passed
	 */
	@wire(CurrentPageReference)
	async setCurrentPageReference(currentPageReference) {
		if (Object.keys(currentPageReference?.state).length === 0) {
			await LightningAlert.open({
				message: errorMessage,
				theme: 'error',
				label: 'Create Sub Accounts Error'
			});
			return;
		}
		this.hasPageReferenceState = true;
		this.recordId = currentPageReference?.state?.c__recordId;
		// isTEAMRequest is string if passed from Apt_CreditAssessmentController apex or is boolean if passed from createSubAccountsRequestWrapper aura
		this.isTEAMRequest = currentPageReference?.state?.c__isTEAMRequest === true || currentPageReference?.state?.c__isTEAMRequest === 'true';
		this.initialLoad = currentPageReference?.state?.c__initialLoad;
		this.isBillingAccount = currentPageReference?.state?.c__isBillingAccount;
	}
}