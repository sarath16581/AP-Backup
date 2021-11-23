/**
 * @description Step capturing customer address details in Direct to Network Case creation flow.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 * 2020-11-06 - Ranjeewa Silva - Make sender address optional when sender address not available on article.
 */

import { LightningElement, api } from 'lwc';
import { CONSTANTS } from "c/dtnCaseService";

export default class DtnCaseWizardCustomerDetailsStep extends LightningElement {

    // article record received from parent
    @api article;

    // sender address as captured by address validation service.
    senderAddress;
    // receiver address as captured by address validation service.
    receiverAddress;

    addressHelpText = CONSTANTS.LABEL_DIRECTTONETWORKADDRESSHELPTEXT;

    get senderAddressFromArticle() {
        return {
            address: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_ADDRESS),
            addressLine1: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_ADDRESSLINE1),
            addressLine2: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_ADDRESSLINE2),
            city: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_CITY),
            state: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_STATE),
            postcode: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_POSTCODE),
            countryCode: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_COUNTRY),
            countryName: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_COUNTRYNAME)
        };
    }

    get senderAddressText() {
        const senderAddressText = this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_ADDRESS);
        return (senderAddressText ? senderAddressText : '');
    }

    get isLocalSenderAddress() {
        return !this.isOverseas(this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_COUNTRYNAME), this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_COUNTRY));
    }

    get overseasSenderAddress() {
        if (this.isLocalSenderAddress) {
            return {};
        }
        return this.senderAddressFromArticle;
    }

    isOverseas(countryName, countryCode) {
        if (countryName && countryName.toUpperCase() === 'AUSTRALIA') {
            return false;
        } else if (countryCode && countryCode.toUpperCase() === 'AU') {
            return false;
        } else if (!countryName && !countryCode) {
            return false;
        } else {
            return true;
        }
    }

    get isSenderAddressRequired() {
        return (this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_ADDRESS) || this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_SENDER_POSTCODE));
    }

    get receiverAddressFromArticle() {
        return {
            address: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_ADDRESS),
            addressLine1: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_ADDRESSLINE1),
            addressLine2: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_ADDRESSLINE2),
            city: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_CITY),
            state: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_STATE),
            postcode: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_POSTCODE),
            countryCode: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_COUNTRY),
            countryName: this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_COUNTRYNAME)
        };
    }

    get receiverAddressText() {
        const receiverAddressText = this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_ADDRESS);
        return (receiverAddressText ? receiverAddressText: '');
    }

    get isLocalReceiverAddress() {
        return !this.isOverseas(this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_COUNTRYNAME), this.get(this.article, CONSTANTS.ARTICLE_FIELDS.FIELD_RECEIVER_COUNTRY));
    }

    get overseasReceiverAddress() {
        if (this.isLocalReceiverAddress) {
            return {};
        }
        return this.receiverAddressFromArticle;
    }

    handleConfirmedSenderAddress(event) {
        if (event.detail) {
            this.senderAddress = event.detail;
        }
    }

    handleConfirmedReceiverAddress(event) {
        if (event.detail) {
            this.receiverAddress = event.detail;
        }
    }

    get(value, field) {
        if (value) {
            return value[field];
        }
        return;
    }

    /**
     * Validates the form, checking for input errors and
     * controlling that wizard should advance to the next step
     */
    @api validate() {
        const allValid = [...this.template.querySelectorAll('c-ame-address-validation2')]
            .reduce((validSoFar, ameAddressCmp) => {
                ameAddressCmp.reportValidity();
                return validSoFar && ameAddressCmp.checkValidity();
            }, true);
        return allValid;
    }

    /**
     * Return form data gathered in this step.
     * If user has provided sender / receiver address details use them. Defaults to address details received in article.
     */
    @api getFieldValues() {
        const customerInput = {};
        customerInput['senderAddress'] = (this.senderAddress ? this.senderAddress : this.senderAddressFromArticle);
        customerInput['receiverAddress'] = (this.receiverAddress ? this.receiverAddress : this.receiverAddressFromArticle);
        return customerInput;
    }

}