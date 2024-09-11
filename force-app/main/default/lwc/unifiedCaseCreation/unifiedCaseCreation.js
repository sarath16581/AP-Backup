/**
 * @description An LWC Interface for displaying Case Creation form for unified experience.
 * @author: Marcel HK
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
 * 2024-08-29 - Seth Heang - Updated the Form UI and refactor codes
 * 2024-09-02 - Seth Heang - Added case creation handler and validation/error handling
 */
import { api, LightningElement, wire } from "lwc";
import getCaseRecordTypeInfos from "@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos";
import createNewCase from "@salesforce/apex/UnifiedCaseCreationController.createNewCase";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import { getPicklistOptions, isPicklistOptionAvailable } from "./util";
import { reduceErrors } from "c/ldsUtils";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { isBlank } from "c/utils";

import LIVECHAT_INTENT_FIELD from "@salesforce/schema/LiveChatTranscript.Chat_Intent__c";
import LIVECHAT_CONTACT_ID_FIELD from "@salesforce/schema/LiveChatTranscript.ContactId";

const INVESTIGATION_RECORD_TYPE = 'UnifiedInvestigation';
const GENERAL_ENQUIRY_RECORD_TYPE = 'UnifiedGeneralEnquiry';
const INVESTIGATION_ENQUIRY_TYPE = 'Investigation';
const GENERAL_ENQUIRY_TYPE = 'General Enquiry';
const RECORD_TYPE_DEVELOPER_NAMES = [INVESTIGATION_RECORD_TYPE, GENERAL_ENQUIRY_RECORD_TYPE];
const DEFAULT_TYPE_AND_PRODUCT = 'Unified Model';
const LIVECHAT_FIELDS = [LIVECHAT_INTENT_FIELD, LIVECHAT_CONTACT_ID_FIELD];

// Element selectors
export const INPUT_ELEMENT_SELECTORS = ['lightning-textarea', 'lightning-combobox', 'lightning-record-picker'];

// Field and button labels
export const ARTICLES_LABEL = 'Articles';
export const CONTACT_LABEL = 'Contact';
export const ENQUIRY_TYPE_LABEL = 'Enquiry Type';
export const ENQUIRY_SUBTYPE_LABEL = 'Enquiry Sub Type';
export const PRODUCT_CATEGORY_LABEL = 'Product Category';
export const PRODUCT_SUBCATEGORY_LABEL = 'Product Sub Category';
export const NOTES_LABEL = 'Notes';
export const CREATE_BUTTON_LABEL = 'Create';
export const ENQUIRY_TYPE_OPTIONS = [
	{
		label: INVESTIGATION_ENQUIRY_TYPE,
		value: INVESTIGATION_ENQUIRY_TYPE
	},
	{
		label: GENERAL_ENQUIRY_TYPE,
		value: GENERAL_ENQUIRY_TYPE
	}
];

export const CONTACTID_MISSING_ERROR = 'Contact cannot be empty for investigation case, Please link a contact.';
export const INVALID_FORM_ERROR = 'Please fix errors and try again';

export default class UnifiedCaseCreation extends LightningElement {
	// ChatTranscript Obj
	@api recordId;

	// Public Properties
	/**
	 * The Contact Id to associate with the Case record.
	 * @type {string}
	 */
	@api contactId;

	/**
	 * The consignment SF Id to associate with the Case record.
	 * @type {string}
	 */
	@api consignmentId;

	/**
	 * A list of article identifiers to associate with the Case via the `ImpactedArticle__c` object.
	 * @type {string[]}
	 */
	@api impactedArticles;

	/**
	 * getter for enquiry type value to associate with the Case record
	 * @type {string[]}
	 */
	@api get enquiryType() {
		return this._enquiryType;
	}

	/**
	 * setter for enquiry type value to associate with the Case record.
	 * update recordTypeId when enquiry type is set
	 * @param value
	 */
	set enquiryType(value) {
		this._enquiryType = value;
		this.recordTypeId = this.getRecordTypeIdByEnquiryType(value);
	}

	// Used to show spinner while retrieving object schema data and when creating the Case
	get isLoading() {
		return this._isLoading;
	}

	set isLoading(value) {
		this._isLoading = value;
	}

	// Private properties with getter and setter
	_enquiryType;
	_isLoading = true;

	// Private properties without getter and setter
	recordTypeId;
	caseRecordTypeInfos;
	casePicklistFieldValues;
	typeAndProduct = DEFAULT_TYPE_AND_PRODUCT; // Controlling value for 'Enquiry Sub Type'
	enquirySubType = '';
	productCategory = '';
	productSubCategory = '';
	notes = '';

	// Field and button labels
	contactLabel = CONTACT_LABEL;
	enquiryTypeLabel = ENQUIRY_TYPE_LABEL;
	enquirySubTypeLabel = ENQUIRY_SUBTYPE_LABEL;
	productCategoryLabel = PRODUCT_CATEGORY_LABEL;
	productSubCategoryLabel = PRODUCT_SUBCATEGORY_LABEL;
	notesLabel = NOTES_LABEL;
	createBtnLabel = CREATE_BUTTON_LABEL;
	liveChatIntent;
	errorMessage;

	/**
	 * get default Investigation recordType Id
	 * @returns Id
	 */
	get defaultRecordTypeId() {
		// Use the SObject schema to get Record IDs, and return the Id for the one
		// that is configured as the default in this component.
		return Object.values(this.caseRecordTypeInfos || {}).find((recordTypeInfo) => recordTypeInfo.developerName === INVESTIGATION_RECORD_TYPE)?.recordTypeId;
	}

	/**
	 * get unified general enquiry recordType Id
	 * @returns Id
	 */
	get generalEnquiryRecordTypeId() {
		// Use the SObject schema to get Record IDs, and return the Id for the one
		// that is configured as the default in this component.
		return Object.values(this.caseRecordTypeInfos || {}).find((recordTypeInfo) => recordTypeInfo.developerName === GENERAL_ENQUIRY_RECORD_TYPE)?.recordTypeId;
	}

	get linkedArticlesLabel() {
		return !this.impactedArticles ? ARTICLES_LABEL + ' (None Linked)' : ARTICLES_LABEL + ' (' + this.impactedArticles?.length + ')';
	}

	get isUnifiedGeneralEnquiryCase() {
		return this.enquiryType === GENERAL_ENQUIRY_TYPE;
	}

	get isUnifiedInvestigationCase() {
		return this.enquiryType === INVESTIGATION_ENQUIRY_TYPE;
	}

	getRecordTypeIdByEnquiryType(enquiryType) {
		return this.isUnifiedGeneralEnquiryCase ? this.generalEnquiryRecordTypeId : this.defaultRecordTypeId;
	}

	/**
	 * Wire adaptor to retrieve LiveChatTranscript data such as liveChatIntent
	 */
	@wire(getRecord, { recordId: '$recordId', fields: LIVECHAT_FIELDS })
	wiredChatTranscriptRecord({ data, error }) {
		if (error) {
			this.caseRecordTypeInfos = undefined;
			console.error(error);
			this.errorMessage = reduceErrors(error).join(',');
		} else if (data) {
			this.liveChatIntent = getFieldValue(data, LIVECHAT_INTENT_FIELD);
			if (!this.contactId) {
				this.contactId = getFieldValue(data, LIVECHAT_CONTACT_ID_FIELD);
			}
		}
	}

	/**
	 * Wire adaptor to retrieve case's record type
	 */
	@wire(getCaseRecordTypeInfos, { developerNames: RECORD_TYPE_DEVELOPER_NAMES })
	wiredCaseRecordTypeInfos({ data, error }) {
		if (error) {
			this.caseRecordTypeInfos = undefined;
			console.error(error);
			this.errorMessage = reduceErrors(error).join(',');
		} else if (data) {
			this.caseRecordTypeInfos = data;
			// Set the default record type (but don't overwrite if already set)
			if (!this.enquiryType) {
				this.enquiryType = INVESTIGATION_ENQUIRY_TYPE;
			}
			this.recordTypeId = this.getRecordTypeIdByEnquiryType(this.enquiryType);
			this.isLoading = false;
		}
	}

	/**
	 * Wire adaptor to retrieve case's picklist values by record type
	 */
	@wire(getPicklistValuesByRecordType, {
		recordTypeId: '$recordTypeId',
		objectApiName: CASE_OBJECT
	})
	wiredCasePicklists({ data, error }) {
		if (error) {
			this.casePicklistFieldValues = undefined;
			console.error(error);
			this.errorMessage = reduceErrors(error).join(',');
		} else if (data) {
			const { EnquirySubType__c, ProductCategory__c, ProductSubCategory__c } = data.picklistFieldValues;
			this.casePicklistFieldValues = {
				EnquirySubType__c,
				ProductCategory__c,
				ProductSubCategory__c
			};

			// Revalidate picklists when the Case Record Type changes
			this.revalidatePicklists();
			this.handleDefaultInputFieldValues();
		}
	}

	/**
	 * Handle default values for input fields on LWC form
	 */
	handleDefaultInputFieldValues() {
		const enquirySubTypeOptions = getPicklistOptions(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct);
		this.enquirySubType = enquirySubTypeOptions.length === 1 ? enquirySubTypeOptions[0].value : this.enquirySubType;

		const productCategoryOptions = getPicklistOptions(this.casePicklistFieldValues, 'ProductCategory__c');
		this.productCategory = productCategoryOptions.length === 1 ? productCategoryOptions[0].value : this.productCategory;

		const productSubCategoryOptions = getPicklistOptions(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory);
		this.productSubCategory = productSubCategoryOptions.length === 1 ? productSubCategoryOptions[0].value : this.productSubCategory;
	}

	/**
	 * Handle input field changes
	 * @param {*} event 
	 */
	handleInputChange(event) {
		const { fieldName } = event.target.dataset;
		const value = event.target.value;
		const previousValue = this[fieldName];
		this[fieldName] = value;

		// Only re-calculate if picklists are changing (not any field)
		const fieldsToRevalidate = {
			enquiryType: this.enquiryType,
			enquirySubType: this.enquirySubType,
			productCategory: this.productCategory,
			productSubCategory: this.productSubCategory
		};
		if (Object.hasOwnProperty.call(fieldsToRevalidate, fieldName) && previousValue !== value) {
			this.revalidatePicklists();
		}
	}

	/**
	 * Re-calculate selected picklist values which have controlling fields.
	 * This is used to prevent unintentionally saving values which are not allowed.
	 */
	revalidatePicklists() {
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct, this.enquirySubType)) {
			this.enquirySubType = '';
		}
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductCategory__c', null, this.productCategory)) {
			this.productCategory = '';
		}
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory, this.productSubCategory)) {
			this.productSubCategory = '';
		}
	}

	// Picklist Options
	get enquiryTypeOptions() {
		return ENQUIRY_TYPE_OPTIONS;
	}

	// Picklist options for enquiry sub type field
	get enquirySubTypeOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct);
		return options.length === 0 ? [{ label: 'None', value: '' }] : options;
	}

	// Picklist options for product category field
	get productCategoryOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'ProductCategory__c');
		return options.length === 0 ? [{ label: 'None', value: '' }] : options;
	}

	// Picklist options for product sub category field
	get productSubCategoryOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory);
		return options.length === 0 ? [{ label: 'None', value: '' }] : options;
	}

	/**
	 * Validate all form inputs
	 * @returns {boolean}
	 */
	validateInputs() {
		try {
			this.errorMessage = undefined;

			// Collect all form input elements
			const inputElements = [...this.template.querySelectorAll(INPUT_ELEMENT_SELECTORS.join(','))];

			// Check each individual field is valid
			let isValid = inputElements.reduce((validSoFar, el) => {
				el.reportValidity();
				return validSoFar && el.checkValidity();
			}, true);

			// If one or more fields is invalid, stop validating (field will display error message)
			if (!isValid) {
				return false;
			}

			if (this.isUnifiedInvestigationCase && isBlank(this.contactId)) {
				isValid = false;
				this.errorMessage = CONTACTID_MISSING_ERROR;
			}
			return isValid;
		} catch (err) {
			this.errorMessage = reduceErrors(err).join(',');
			return false;
		}
	}

	/**
	 * handle new case creation and new impacted article with all appropriate fields mapped from the UI form
	 * @returns {Promise<void>}
	 * @fire UnifiedCaseCreation#casecreated
	 */
	async handleCaseCreation() {
		// Validate inputs before invoking the search method
		if (!this.validateInputs()) {
			if (this.errorMessage === undefined) {
				this.errorMessage = INVALID_FORM_ERROR;
			}
			return;
		}

		this.isLoading = true;
		try {
			const caseId = await createNewCase({
				request: {
					impactedArticles: this.impactedArticles,
					contactId: this.contactId,
					enquiryType: this.enquiryType,
					enquirySubType: this.enquirySubType,
					productCategory: this.productCategory,
					productSubCategory: this.productSubCategory,
					notes: this.notes,
					liveChatIntent: this.liveChatIntent,
					recordTypeId: this.recordTypeId,
					consignmentId: this.consignmentId
				}
			});

			this.dispatchEvent(new CustomEvent('casecreated', { detail: { caseId }, bubbles: true, composed: true }));

			// Dispatch the ShowToastEvent
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Success!',
					message: 'Case Created Successfully',
					variant: 'success'
				})
			);
		} catch (error) {
			console.error(error);
			this.errorMessage = reduceErrors(error).join(',');
		} finally {
			this.isLoading = false;
		}
	}
}
