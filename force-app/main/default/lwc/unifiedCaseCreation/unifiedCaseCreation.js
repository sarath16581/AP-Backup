/**
 * @description An LWC Interface for displaying Case Creation form for unified experience.
 * @author: Marcel HK
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
 * 2024-08-29 - Seth Heang - Updated the Form UI and refactor codes
 * 2024-09-02 - Seth Heang - Added case creation handler and validation/error handling
 */
import { api, LightningElement, wire } from 'lwc';
import getCaseRecordTypeInfos from '@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos';
import createNewCase from '@salesforce/apex/UnifiedCaseCreationController.createNewCase';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getPicklistOptions, isPicklistOptionAvailable } from './util';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { isBlank } from 'c/utils';

const INVESTIGATION_RECORD_TYPE = 'UnifiedInvestigation';
const GENERAL_ENQUIRY_RECORD_TYPE = 'UnifiedGeneralEnquiry';
const INVESTIGATION_ENQUIRY_TYPE = 'Investigation';
const GENERAL_ENQUIRY_TYPE = 'General Enquiry';
const RECORD_TYPE_DEVELOPER_NAMES = [INVESTIGATION_RECORD_TYPE, GENERAL_ENQUIRY_RECORD_TYPE];
const DEFAULT_TYPE_AND_PRODUCT = 'Unified Model';

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

export const IMPACTED_ARTICLE_MISSING_ERROR = 'Impacted articles cannot be empty, Please link at least one impacted article.';
export const CONTACTID_MISSING_ERROR = 'Contact cannot be empty for investigation case, Please link a contact.';
export const INVALID_FORM_ERROR = 'Please Fix Errors and Try Again';

export default class UnifiedCaseCreation extends LightningElement {

	// Public Properties
	/**
	 * The Contact Id to associate with the Case record.
	 * @type {string}
	 */
	@api get contactId(){
		return this._contactId;
	}

	/**
	 * setter for contactId with functionality to dynamically clear contact lookup if contact is unlinked from liveChat
	 * @param value
	 */
	set contactId(value){
		this._contactId = value;
		const el = this.template.querySelector('lightning-record-picker[data-field-name=contactId]');
		if(el && !value){
			el.clearSelection();
		}
	}

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
	 * @returns {string}
	 */
	@api get enquiryType() {
		return this._enquiryType;
	}

	/**
	 * setter for Enquiry type which dynamically updates the record type Id to refresh the dependencies picklist on case creation form
	 * @returns {string}
	 */
	set enquiryType(value) {
		this._enquiryType = value;
		this._recordTypeId = this.getRecordTypeIdByEnquiryType();
	}

	/**
	 * getter for enquiry sub type value to associate with the Case record
	 * @returns {string}
	 */
	@api get enquirySubType() {
		return this._enquirySubType;
	}

	/**
	 * setter for Enquiry sub type
	 * @returns {string}
	 */
	set enquirySubType(value){
		this._enquirySubType = value;
	}

	/**
	 * getter for product category value to associate with the Case record
	 * @returns {string}
	 */
	@api get productCategory() {
		return this._productCategory;
	}

	/**
	 * setter for product category
	 * @returns {string}
	 */
	set productCategory(value){
		this._productCategory = value;
	}

	/**
	 * getter for product sub category value to associate with the Case record
	 * @returns {string}
	 */
	@api get productSubCategory() {
		return this._productSubCategory;
	}

	/**
	 * setter for product sub category
	 * @returns {string}
	 */
	set productSubCategory(value){
		this._productSubCategory = value;
	}

	/**
	 * Get latest the record type Id based on selected enquiry type
	 * @returns {Id}
	 */
	get recordTypeId() {
		return this._recordTypeId ??  this.getRecordTypeIdByEnquiryType();
	}

	// Private properties with getter and setter
	_contactId;
	_enquiryType;
	_isLoading = true;
	_recordTypeId;
	_enquirySubType = '';
	_productCategory = '';
	_productSubCategory = '';

	// Private properties without getter and setter
	notes = '';
	caseRecordTypeInfos;
	casePicklistFieldValues;
	typeAndProduct = DEFAULT_TYPE_AND_PRODUCT; // Controlling value for 'Enquiry Sub Type'

	// Field and button labels
	contactLabel = CONTACT_LABEL;
	enquiryTypeLabel = ENQUIRY_TYPE_LABEL;
	enquirySubTypeLabel = ENQUIRY_SUBTYPE_LABEL;
	productCategoryLabel = PRODUCT_CATEGORY_LABEL;
	productSubCategoryLabel = PRODUCT_SUBCATEGORY_LABEL;
	notesLabel = NOTES_LABEL;
	createBtnLabel = CREATE_BUTTON_LABEL;
	_errorMessage;
	disableCreateBtn = false;

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

	// Used to show spinner while retrieving object schema data and when creating the Case
	get isLoading() {
		return this._isLoading;
	}

	set isLoading(value) {
		this._isLoading = value;
	}

	// Use to set or get error message, disable create button when there is error message
	get errorMessage(){
		return this._errorMessage;
	}
	set errorMessage(value){
		this._errorMessage = value;
		this.disableCreateBtn = true;
	}

	/**
	 * Show the impacted article label with count on the case creation form
	 * @returns {string}
	 */
	get linkedArticlesLabel() {
		return !this.impactedArticles ? ARTICLES_LABEL + ' (None Linked)' : ARTICLES_LABEL + ' (' + this.impactedArticles?.length + ')';
	}

	get isUnifiedGeneralEnquiryCase() {
		return this.enquiryType === GENERAL_ENQUIRY_TYPE;
	}

	get isUnifiedInvestigationCase() {
		return this.enquiryType === INVESTIGATION_ENQUIRY_TYPE;
	}

	/**
	 * Get record type Id based on currently selected enquiry type
	 * @returns {Id}
	 */
	getRecordTypeIdByEnquiryType() {
		return this.isUnifiedGeneralEnquiryCase ? this.generalEnquiryRecordTypeId : this.defaultRecordTypeId;
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
			this._recordTypeId = this.getRecordTypeIdByEnquiryType();
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
	 * Re-calculate selected picklist values which have controlling fields.
	 * This is used to prevent unintentionally saving values which are not allowed.
	 */
	revalidatePicklists() {
		if (this.enquirySubType && !isPicklistOptionAvailable(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct, this.enquirySubType)) {
			this.enquirySubType = '';
		}
		if (this.productCategory && !isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductCategory__c', null, this.productCategory)) {
			this.productCategory = '';
		}
		if ((this.productSubCategory && this.productCategory)
				&& !isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory, this.productSubCategory)) {
			this.productSubCategory = '';
		}
	}

	/**
	 * Handle default values for input fields on LWC form
	 */
	handleDefaultInputFieldValues() {
		if(!this.enquirySubType){
			const enquirySubTypeOptions = getPicklistOptions(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct);
			this.enquirySubType = enquirySubTypeOptions.length === 1 ? enquirySubTypeOptions[0].value : this.enquirySubType;
		}

		if(!this.productCategory){
			const productCategoryOptions = getPicklistOptions(this.casePicklistFieldValues, 'ProductCategory__c');
			this.productCategory = productCategoryOptions.length === 1 ? productCategoryOptions[0].value : this.productCategory;
		}

		if(!this.productSubCategory){
			const productSubCategoryOptions = getPicklistOptions(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory);
			this.productSubCategory = productSubCategoryOptions.length === 1 ? productSubCategoryOptions[0].value : this.productSubCategory;
		}
	}

	/**
	 * Handle input field changes
	 * @param {*} event
	 */
	handleInputChange(event) {
		this.disableCreateBtn = false;
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

			// check for blank contact for unified investigation case
			if (this.isUnifiedInvestigationCase && isBlank(this.contactId)) {
				isValid = false;
				this.errorMessage = CONTACTID_MISSING_ERROR;
			}

			// check for blank impacted articles
			if (!this.impactedArticles) {
				isValid = false;
				this.errorMessage = IMPACTED_ARTICLE_MISSING_ERROR;
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
