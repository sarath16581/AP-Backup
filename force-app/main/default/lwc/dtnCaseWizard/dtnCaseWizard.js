/**
 * @description Main component in Direct to Network Case creation flow. Defines the wizard together with wizard steps.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 * 2020-11-08 - Ranjeewa Silva - More fields populated on the case record - Priority and Origin.
 * 2021-10-10 - Nathan Franklin - Rename safedrop to delivery proof + uplift to v52
 */

import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';
import { get } from 'c/utils';
import DtnCaseWizardBase from "c/dtnCaseWizardBase";
import { CONSTANTS, createCase, getDefaultCaseDescription,  checkDuplicateCases} from "c/dtnCaseService";

export default class DtnCaseWizard extends DtnCaseWizardBase {

    // title of the wizard (displayed above progress indicators)
    @api title;

    // label of the finish button which completes the wizard.
    @api finishLabel = 'Send To Network';

    // record type of new case
    @api caseRecordTypeName;

    // Default field values for new case. Ensure property names match field API names.
    @api caseDefaultValues;

    // Restrictions on picklist values presented to the user. Ensure property names match field API names.
    @api caseRestrictedPicklistValues;

    // article record to which the new case is related to. Sender and Receiver address details from the article are used
    // as default values on case address fields (sender and addressee). Ensure property names match field API names.
    @api article;

    // delivery facility (network) responsible for delivery of the article. New case is linked to this delivery facility.
    // Ensure property names match field API names.
    @api network;

    // selection to attach delivery proof PDF to case.
    @api attachDeliveryProof = false;

    //User input collected by each step of the wizard.
    @track enquiryInput = {};
    @track customerInput = {};
    @track articleInput = {};

    isLoading = false;

    // can the current user ignore duplicates and proceed with case creation. this value is set based on the results received
    // from server.
    canIgnoreDuplicates = false;

    // has the current user decided to ignore duplicates and proceed with case creation.
    hasIgnoredDuplicates = false;

    // default message to network (i.e. Case Description) value as per the case description rules configured. case description
    // rules are evaluated in Apex based on the rules configured in SSSWRouting__c records.
    messageToNetworkDefaultValue = null;

    // errors encountered on saving the case
    errorMessage = '';

    get loading() {
        return this.isLoading || !this.fieldInfoLoaded;
    }

    /**
     * Close Direct to Network Case wizard. Invoked when "Cancel" button is clicked.
     * Dispatch the "close" event - which is handled by the parent component.
     */
    closeWizard() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * Validate the input components in wizard step-1. Delegate to "validate()" method in child component - dtnCaseWizardEnquiryDetailsStep.
     * If input data is valid, check for duplicate cases and display error message to user.
     */
    step1Validate = () => {
        this.errorMessage = null;
        if (this.template.querySelector('c-dtn-case-wizard-enquiry-details-step').validate()) {
            // collect validated input data
            this.enquiryInput = this.template.querySelector('c-dtn-case-wizard-enquiry-details-step').getFieldValues();

            // make a server call to retrieve the 'message to network' template based on other input field values. ensure
            // description field is blanked out before calling server.
            const newCaseRecord = this.newCaseFromInput();
            newCaseRecord[CONSTANTS.CASE_FIELDS.FIELD_DESCRIPTION] = null;
            getDefaultCaseDescription(newCaseRecord).then(result => {
                this.messageToNetworkDefaultValue = result;
            });

            if (!this.hasIgnoredDuplicates) {
                return this.doDuplicateCheck(newCaseRecord);
            }
            return true;
        }
        return false;
    }

    /**
     * Validate the input components in wizard step-2.
     * Delegate to "validate()" method in child component - dtnCaseWizardCustomerDetailsStep.
     */
    step2Validate = () => {
        if (this.template.querySelector('c-dtn-case-wizard-customer-details-step').validate()) {
            // collect validated input data
            this.customerInput = this.template.querySelector('c-dtn-case-wizard-customer-details-step').getFieldValues();
            return true;
        }
        return false;
    }

    /**
     * Validate the input components in wizard step-3.
     * Delegate to "validate()" method in child component - dtnCaseWizardArticleDetailsStep.
     */
    step3Validate = () => {
        if (this.template.querySelector('c-dtn-case-wizard-article-details-step').validate()) {
            // collect validated input data
            this.articleInput = this.template.querySelector('c-dtn-case-wizard-article-details-step').getFieldValues();
            return true;
        }
        return false;
    }

    /**
     * Check for duplicate cases.
     */
    async doDuplicateCheck(newCase) {
        this.isLoading = true;
        const result = await checkDuplicateCases(newCase);
        if (result && result.isDuplicate) {
            this.canIgnoreDuplicates = !!result.canIgnoreDuplicate;
            this.errorMessage = result.errorMessage;
            this.isLoading = false;
            return false;
        }
        this.isLoading = false;
        return true;
    }

    ignoreDuplicatesAndProceed() {
        this.hasIgnoredDuplicates = true;
        this.errorMessage = null;
    }

    /**
     * Create new Direct to Network Case.
     * If successful, dispatch "complete" event with the Id of the newly created case.
     * Any errors encountered on save are displayed on screen allowing the user to retry case creation.
     */
    handleCreateCase() {

        this.errorMessage = '';
        let newCaseRecord = this.newCaseFromInput();
        this.isLoading = true;

        createCase(newCaseRecord, this.hasIgnoredDuplicates, this.attachDeliveryProof)
            .then(result => {
                this.isLoading = false;
                if (result.status === 'SUCCESSFUL') {
                    //Case created successfully.
                    this.dispatchEvent(new CustomEvent('complete', { detail: { id: result.caseId }} ));
                } else {
                    this.errorMessage = result.errorMessage;
                    this.canIgnoreDuplicates = !!result.canIgnoreDuplicate;
                }
            })
            .catch(error => {
                console.log('Error creating case : ', JSON.stringify(error));
                this.errorMessage = reduceErrors(error).join(', ');
                this.isLoading = false;
            });
    }

    /**
     * Returns a new case from input collected.
     */
    newCaseFromInput() {
        const fields = {};
        fields[CONSTANTS.CASE_FIELDS.FIELD_RECORDTYPEID] = this.caseRecordTypeId;
        fields[CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_CATEGORY] = get(this.enquiryInput, 'productCategory', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_SUB_CATEGORY] = get(this.enquiryInput, 'productSubCategory', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_ENQUIRY_SUB_TYPE] = get(this.enquiryInput, 'enquirySubType', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_TYPE] = get(this.enquiryInput, 'caseType', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_COMPLAINT] = get(this.enquiryInput, 'complaint', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_CASE_ORIGINATOR_FIELD] = get(this.enquiryInput, 'originator', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_PRIORITY] = get(this.enquiryInput, 'priority', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_ORIGIN] = get(this.enquiryInput, 'origin', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_REFERENCEID] = get(this.article, 'ArticleID__c', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_CONTACTID] = get(this.caseDefaultValues, 'ContactId', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_ARTICLE] = get(this.article, 'Id', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_AUTOMATED_NETWORK_ASSIGNMENT] = true;
        fields[CONSTANTS.CASE_FIELDS.FIELD_NETWORK] = get(this.network, 'Id', null);

        //Sender Details
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1] = get(this.customerInput, 'senderAddress.address', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_LINE1] = get(this.customerInput, 'senderAddress.addressLine1', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_LINE2] = get(this.customerInput, 'senderAddress.addressLine2', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_SUBURB] = get(this.customerInput, 'senderAddress.city', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_STATE] = get(this.customerInput, 'senderAddress.state', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_POSTCODE] = get(this.customerInput, 'senderAddress.postcode', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_COUNTRY] = get(this.customerInput, 'senderAddress.countryName', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_ADDRESS1_DPID] = get(this.customerInput, 'senderAddress.dpid', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_PRIMARY_NAME] = get(this.article, 'SenderName__c', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_PRIMARY_COMPANY] = get(this.article, 'SenderCompany__c', null);
        fields[CONSTANTS.CASE_FIELDS.SENDER.FIELD_PRIMARY_EMAIL] = get(this.article, 'SenderEmail__c', null);

        //Receiver Details
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2] = get(this.customerInput, 'receiverAddress.address', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_LINE1] = get(this.customerInput, 'receiverAddress.addressLine1', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_LINE2] = get(this.customerInput, 'receiverAddress.addressLine2', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_SUBURB] = get(this.customerInput, 'receiverAddress.city', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_STATE] = get(this.customerInput, 'receiverAddress.state', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_POSTCODE] = get(this.customerInput, 'receiverAddress.postcode', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_COUNTRY] = get(this.customerInput, 'receiverAddress.countryName', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_ADDRESS2_DPID] = get(this.customerInput, 'receiverAddress.dpid', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_SECONDARY_CONTACT] = get(this.article, 'ReceiverName__c', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_SECONDARY_COMPANY] = get(this.article, 'ReceiverCompany__c', null);
        fields[CONSTANTS.CASE_FIELDS.RECEIVER.FIELD_SECONDARY_EMAIL] = get(this.article, 'ReceiverEmail__c', null);

        fields[CONSTANTS.CASE_FIELDS.FIELD_VALUE_OF_CONTENTS] = get(this.articleInput, 'valueOfContents', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_DESCRIPTION_OF_CONTENTS] = get(this.articleInput, 'descriptionOfContents', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_DATE_POSTED] = get(this.articleInput, 'datePosted', null);
        fields[CONSTANTS.CASE_FIELDS.FIELD_DESCRIPTION] = get(this.articleInput, 'messageToNetwork', null);

        return {
            ...fields,
            sobjectType: CONSTANTS.CASE_OBJECT
        };
    }
}