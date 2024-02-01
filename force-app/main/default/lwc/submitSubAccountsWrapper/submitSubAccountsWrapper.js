/**
 * @description Wrapper component of submit billing accounts request
 * @author Harry Wang
 * @date 2024-01-17
 * @group Controller
 * @changelog
 * 2024-01-17 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from 'lightning/navigation';
import getBillingAccountDetails from "@salesforce/apex/CreateSubAccountsController.getBillingAccountDetails";
import hasAccess from "@salesforce/customPermission/BG_Core";
import LABEL_TITLE from "@salesforce/label/c.StarTrackSubAccountsCreationTitle";
import LABEL_NO_ACCESS_ERROR from "@salesforce/label/c.StarTrackSubAccountsCreationNoAccessError";
import SUB_ACCOUNT_DELETION_ERROR_MESSAGE from "@salesforce/label/c.SubAccountDeletionErrorMessage";
import SUB_ACCOUNT_NO_ABN_ERROR_MESSAGE from "@salesforce/label/c.SubAccountNoABNErrorMessage";
import SUB_ACCOUNT_NOT_LEADER_ERROR_MESSAGE from "@salesforce/label/c.SubAccountNotLeaderErrorMessage";
import SUB_ACCOUNT_PEOPLE_SOFT_ERROR_MESSAGE from "@salesforce/label/c.SubAccountPeopleSoftErrorMessage";
import SUB_ACCOUNT_FROM_SUB_ACCOUNT_ERROR_MESSAGE from "@salesforce/label/c.SubAccountFromSubAccountErrorMessage";
import SUB_ACCOUNT_AGENCY_OR_CASH_ERROR_MESSAGE from "@salesforce/label/c.SubAccountAgencyOrCashErrorMessage";
import LightningAlert from "lightning/alert";

export default class SubmitSubAccountsWrapper extends NavigationMixin(LightningElement) {
	@api recordId;
	errorMessage;

	@wire(getBillingAccountDetails, {billingAccountRecord: "$recordId"})
	wiredBillingAccount({error, data}) {
		if (data) {
			if (data.SAP_marked_for_deletion__c === true) {
				this.errorMessage = SUB_ACCOUNT_DELETION_ERROR_MESSAGE;
			} else if (data.ABN__c == null) {
				this.errorMessage = SUB_ACCOUNT_NO_ABN_ERROR_MESSAGE;
			} else if (data.Source_System__c === 'TEAM' && (data.LeaderAccount__c != null || data.PAYER_ACCOUNT_ID__c != null)) {
				this.errorMessage = SUB_ACCOUNT_NOT_LEADER_ERROR_MESSAGE;
			} else if (data.Source_System__c === 'TEAM' && data.LeaderAccount__c == null && data.PAYER_ACCOUNT_ID__c == null) {
				this.navigateToCreateSubAccounts('true');
			} else if (data.Source_System__c === 'PeopleSoft'){
				this.errorMessage = SUB_ACCOUNT_PEOPLE_SOFT_ERROR_MESSAGE;
			} else if (data.PAYER_ACCOUNT_ID__c != null) {
				this.errorMessage = SUB_ACCOUNT_FROM_SUB_ACCOUNT_ERROR_MESSAGE;
			} else if (data.Type__c !== 'CUST') {
				this.errorMessage = SUB_ACCOUNT_AGENCY_OR_CASH_ERROR_MESSAGE;
			} else {
				this.navigateToCreateSubAccounts('false');
			}
		} else if (error) {
			if (!hasAccess) {
				LightningAlert.open({
					message: LABEL_NO_ACCESS_ERROR,
					theme: 'error',
					label: LABEL_TITLE
				}).then(() => {
					// close popup modal
					this.dispatchEvent(new CloseActionScreenEvent());
				});
				return;
			}
			console.log(error);
		}
	}

	navigateToCreateSubAccounts(isTeamRequest) {
		// close popup modal
		this.dispatchEvent(new CloseActionScreenEvent());
		// navigate to Create Sub Accounts component
		this[NavigationMixin.Navigate]({
			type: 'standard__navItemPage',
			attributes: {
				apiName: 'Create_Sub_Accounts'
			},
			state: {
				"c__recordId": this.recordId,
				"c__initialLoad": true,
				"c__isTEAMRequest": isTeamRequest,
				"c__isBillingAccount": "true"
			}
		});
	}
}