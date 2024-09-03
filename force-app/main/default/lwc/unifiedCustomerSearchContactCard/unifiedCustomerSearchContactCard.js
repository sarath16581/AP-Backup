import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Contact.Name';
import PREFERRED_NAME_FIELD from '@salesforce/schema/Contact.Preferred_Name__c';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Contact.AccountId';
import VERIFIED_EMAIL_FIELD from '@salesforce/schema/Contact.VerifiedEmail__c';
import VERIFIED_MOBILE_FIELD from '@salesforce/schema/Contact.VerifiedMobile__c';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import MOBILE_PHONE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import IS_PERSON_ACCOUNT_FIELD from '@salesforce/schema/Contact.IsPersonAccount';

/**
 * Simple component to display the Contact record as a read-only card.
 * Follows the Salesforce Lightning Design System to look as close to standard components as possible.
 */
export default class UnifiedCustomerSearchContactCard extends NavigationMixin(LightningElement) {
	@api recordId;

	/**
	 * Show or hide the 'Unlink' button on the UI.
	 * @type {boolean}
	 */
	@api showUnlinkButton = false;

	/**
	 * Use this to remove the additional padding on the card. This is useful where card is embedded on another card to
	 * align with other items on the screen. This drives `css` classes used to manage the padding.
	 * @type {boolean}
	 */
	@api useCompact = false;

	/**
	 * Returns the fields for the Contact record. Used to set fields in the `lightning-output-field` components.
	 * @type {object}
	 */
	get fields() {
		return {
			name: NAME_FIELD,
			preferredName: PREFERRED_NAME_FIELD,
			accountId: ACCOUNT_ID_FIELD,
			verifiedEmail: VERIFIED_EMAIL_FIELD,
			verifiedMobile: VERIFIED_MOBILE_FIELD,
			email: EMAIL_FIELD,
			mobilePhone: MOBILE_PHONE_FIELD
		};
	}

	/**
	 * Used to display loading spinner. Defaults to `true` while the Contact record is being loaded.
	 * @type {boolean}
	 */
	isLoading = true;

	/**
	 * Returns the value for Contact.IsPersonAccount.
	 * @type {boolean}
	 */
	get isPersonAccount() {
		return getFieldValue(this.contact.data, IS_PERSON_ACCOUNT_FIELD);
	}

	/**
	 * Used to enable/disable the 'Unlink' button.
	 * @type {boolean}
	 */
	get unlinkButtonDisabled() {
		return !this.showUnlinkButton;
	}

	/**
	 * Returns the css class for the card based on the `useCompact` property.
	 * @type {string}
	 */
	get lightningCardClass() {
		return this.useCompact === true ? 'compact' : '';
	}

	/**
	 * Returns the css class for the card body based on the `useCompact` property.
	 * @type {string}
	 */
	get lightningCardContentClass() {
		return this.useCompact === true ? '' : 'slds-var-m-around_medium';
	}

	/**
	 * Wire the Contact record to get the value for Contact.IsPersonAccount.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, IS_PERSON_ACCOUNT_FIELD] })
	contact;

	/**
	 * Handles when user clicks an Action button from the menu.
	 *
	 * @param {CustomEvent} event - The `onselect` event.
	 */
	handleActionButton(event) {
		switch (event.detail?.value) {
			case 'view':
				this.handleViewContact();
				break;
			case 'unlink':
				this.handleUnlinkContact();
				break;
			default:
				break;
		}
	}

	/**
	 * Handles the `onload` event from the `lightning-record-view-form` to hide the loading spinner.
	 */
	handleRecordLoaded() {
		this.isLoading = false;
	}

	/**
	 * Unlink the Contact
	 *
	 * @fires UnifiedCustomerSearchContactCard#unlinkcontact
	 */
	handleUnlinkContact() {
		this.dispatchEvent(new CustomEvent('unlinkcontact', { detail: { contactId: null } }));
	}

	/**
	 * Navigate to the Contact record.
	 */
	handleViewContact() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				actionName: 'view'
			}
		});
	}
}
