/**
 * @description An LWC Interface for displaying Case Creation form for unified experience.
 * @author: Marcel HK
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
 * 2024-08-29 - Seth Heang - Updated the Form UI and refactor codes
*/
import { api, LightningElement, wire } from "lwc";
import getCaseRecordTypeInfos from "@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import { getPicklistOptions, isPicklistOptionAvailable } from "./util";

const DEFAULT_RECORD_TYPE = "UnifiedInvestigation";
const RECORD_TYPE_DEVELOPER_NAMES = ['UnifiedInvestigation','UnifiedGeneralEnquiry'];
const DEFAULT_TYPE_AND_PRODUCT = 'Unified Model';

// Field and button labels
export const ARTICLES_LABEL = 'Articles';
export const CONTACT_LABEL = 'Contact';
export const ENQUIRY_TYPE_LABEL = 'Enquiry Type';
export const ENQUIRY_SUBTYPE_LABEL = 'Enquiry Sub Type';
export const PRODUCT_CATEGORY_LABEL = 'Product Category';
export const PRODUCT_SUBCATEGORY_LABEL = 'Product Sub Category';
export const NOTES_LABEL = 'Notes';
export const CREATE_BUTTON_LABEL = 'Create';

export default class UnifiedCaseCreation extends LightningElement {

	/**
	 * The Contact Id to associate with the Case record.
	 * @type {string}
	 */
	@api contactId;

	/**
	 * A list of article identifiers to associate with the Case via the `ImpactedArticle__c` object.
	 * @type {string[]}
	 */
	@api impactedArticles;

	// Private properties
	caseRecordTypeInfos;
	casePicklistFieldValues;
	recordTypeId; // Enquiry Type
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

	get defaultRecordTypeId() {
		// Use the SObject schema to get Record IDs, and return the Id for the one
		// that is configured as the default in this component.
		return Object.values(this.caseRecordTypeInfos || {}).find(recordTypeInfo => recordTypeInfo.developerName === DEFAULT_RECORD_TYPE)?.recordTypeId;
	}

	// Used to show spinner while retrieving object schema data and when creating the Case
	get isLoading() {
		if (this.caseRecordTypeInfos) {
			return false;
		}
		return true;
	}

	get linkedArticlesLabel(){
		return !this.impactedArticles ? ARTICLES_LABEL + ' (None Linked)' : ARTICLES_LABEL + ' (' + (this.impactedArticles?.length) + ')';
	}

	// Wire Adapters to retrieve case's record type
	@wire(getCaseRecordTypeInfos, { developerNames: RECORD_TYPE_DEVELOPER_NAMES })
	wiredCaseRecordTypeInfos({ data, error }) {
		if (error) {
			this.caseRecordTypeInfos = undefined;
			// TODO: handle errors for next story: https://australiapost.jira.com/browse/CSLU-616
			console.error(error);
		} else if (data) {
			this.caseRecordTypeInfos = data;
			// Set the default record type (but don't overwrite if already set)
			if (!this.recordTypeId) {
				this.recordTypeId = this.defaultRecordTypeId;
			}
		}
	}

	@wire(getPicklistValuesByRecordType, {
		recordTypeId: '$recordTypeId',
		objectApiName: CASE_OBJECT
	})
	wiredCasePicklists({ data, error }) {
		if (error) {
			this.casePicklistFieldValues = undefined;
			// TODO: handle errors for next story: https://australiapost.jira.com/browse/CSLU-616
			console.error(error);
		} else if (data) {
			const { EnquirySubType__c, ProductCategory__c, ProductSubCategory__c } = data.picklistFieldValues;
			this.casePicklistFieldValues = {
				EnquirySubType__c,
				ProductCategory__c,
				ProductSubCategory__c
			};

			// Revalidate picklists when the Case Record Type changes
			this.revalidatePicklists();
		}
	}


	handleInputChange(event) {
		const { fieldName } = event.target.dataset;
		const value = event.target.value;
		const previousValue = this[fieldName];
		this[fieldName] = value;

		// Only re-calculate if picklists are changing (not any field)
		const fieldsToRevalidate = {
			recordTypeId: this.recordTypeId,
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
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct, this.enquirySubType)){
			this.enquirySubType = '';
		}
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductCategory__c', null, this.productCategory)){
			this.productCategory = '';
		}
		if (!isPicklistOptionAvailable(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory, this.productSubCategory)){
			this.productSubCategory = '';
		}
	}

	// Picklist Options
	get enquiryTypeOptions() {
		return Object.values(this.caseRecordTypeInfos || {}).map((recordTypeInfo) => ({
			label: recordTypeInfo.name,
			value: recordTypeInfo.recordTypeId
		}));
	}

	get enquirySubTypeOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'EnquirySubType__c', this.typeAndProduct);
		return [{ label: 'None', value: '' }, ...options];
	}

	get productCategoryOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'ProductCategory__c');
		return [{ label: 'None', value: '' }, ...options];
	}

	get productSubCategoryOptions() {
		const options = getPicklistOptions(this.casePicklistFieldValues, 'ProductSubCategory__c', this.productCategory);
		return [{ label: 'None', value: '' }, ...options];
	}

	handleCaseCreation() {
		// TODO	for the next story: https://australiapost.jira.com/browse/CSLU-616
	}
}