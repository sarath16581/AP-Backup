/**
 * @description Step capturing enquiry details in Direct to Network Case creation flow.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 * 2020-11-06 - Ranjeewa Silva - Support pick list value restrictions on 'case originator' field
 * 2020-11-08 - Ranjeewa Silva - Add 'Priority' as a field on this step. Allow 'Origin' to be set by parent.
 */
import { LightningElement, api, wire } from 'lwc';
import DtnCaseWizardBase from "c/dtnCaseWizardBase";
import { CONSTANTS } from "c/dtnCaseService";

export default class DtnCaseWizardEnquiryDetailsStep extends DtnCaseWizardBase {

    //Input field values
    productCategory;
    productSubCategory;
    caseType;
    enquirySubType;
    complaint;
    originator;
    priority;
    origin;

    trackInputFieldValues = {
        isProductCategoryUpdated : false,
        isProductSubCategoryUpdated : false,
        isCaseTypeUpdated : false,
        isEnquirySubtypeUpdated : false,
        isComplaintUpdated : false,
        isOriginatorUpdated : false,
        isPriorityUpdated : false
    };

    //Default input values received from parent
    _caseDefaultValues;
    @api
    get caseDefaultValues() { return this._caseDefaultValues;}
    set caseDefaultValues(value) {
        this._caseDefaultValues = value;
        if (value) {
            this.productCategory = (this.trackInputFieldValues.isProductSubCategoryUpdated ? this.productCategory : value[CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_CATEGORY]);
            this.productSubCategory = (this.trackInputFieldValues.isProductSubCategoryUpdated ? this.productSubCategory : value[CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_SUB_CATEGORY]);
            this.caseType = (this.trackInputFieldValues.isCaseTypeUpdated ? this.caseType : value[CONSTANTS.CASE_FIELDS.FIELD_TYPE]);
            this.enquirySubType = (this.trackInputFieldValues.isEnquirySubtypeUpdated ? this.enquirySubType : value[CONSTANTS.CASE_FIELDS.FIELD_ENQUIRY_SUB_TYPE]);
            this.complaint = (this.trackInputFieldValues.isComplaintUpdated ? this.complaint : value[CONSTANTS.CASE_FIELDS.FIELD_COMPLAINT]);
            this.originator = (this.trackInputFieldValues.isOriginatorUpdated ? this.originator : value[CONSTANTS.CASE_FIELDS.FIELD_CASE_ORIGINATOR_FIELD]);
            this.priority = (this.trackInputFieldValues.isPriorityUpdated ? this.priority : value[CONSTANTS.CASE_FIELDS.FIELD_PRIORITY]);
            this.origin = value[CONSTANTS.CASE_FIELDS.FIELD_ORIGIN];
        }
    }

    // definitions of enquiry subtype picklist value restrictions.
    enquirySubTypeRestrictedValueDefinitions;

    // definitions of case originator picklist value restrictions.
    caseOriginatorRestrictedValueDefinitions;

    // case ppicklist value restrictions received from parent.
    _caseRestrictedPicklistValues;
    @api
    get caseRestrictedPicklistValues() { return this._caseRestrictedPicklistValues; }
    set caseRestrictedPicklistValues(value) {
        this._caseRestrictedPicklistValues = value;
        if (value) {
            //Populate enquiry subtype / case originator restriction definitions. Currently picklist value restrictions are supported
            // only for enquiry subtype and case originator.
            this.enquirySubTypeRestrictedValueDefinitions = this.getRestrictedPicklistValueDefinitions(CONSTANTS.CASE_FIELDS.FIELD_ENQUIRY_SUB_TYPE);
            this.caseOriginatorRestrictedValueDefinitions = this.getRestrictedPicklistValueDefinitions(CONSTANTS.CASE_FIELDS.FIELD_CASE_ORIGINATOR_FIELD);
        }
    }

    /**
     * Validate the form, checking for lightning-input errors and
     * controlling that wizard should advance to the next step
     */
    @api validate() {

        let isInputValid = true;
        // validate enquiry subtype restricted values
        if (this.enquirySubTypeRestrictedValueDefinitions) {
            let inputCmp = this.template.querySelector(".enquiry-sub-type");
            isInputValid = this.validateRestrictedPicklistFieldValues(inputCmp, this.enquirySubTypeRestrictedValueDefinitions, this.enquirySubType);
        }

        // Takes all the inputs from the step and validate
        const allValid = [...this.template.querySelectorAll('.enquiry-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp. checkValidity();
            }, isInputValid);

        // Returns true/false;
        return allValid;
    }

    /**
     * Allows the parent to retrieve field values collected in this step.
     */
    @api getFieldValues() {
        return {
            productCategory: this.productCategory,
            productSubCategory: this.productSubCategory,
            caseType: this.caseType,
            enquirySubType: this.enquirySubType,
            complaint: this.complaint,
            originator: this.originator,
            priority: this.priority,
            origin: this.origin,
            recordTypeId: this.caseRecordTypeId
        };
    }

    get productCategoryOptions() {
        return this.getPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_CATEGORY);
    }

    get complaintOptions() {
        return this.getPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_COMPLAINT);
    }

    get caseTypeOptions() {
        return this.getPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_TYPE);
    }

    get originatorOptions() {

        let caseOriginatorOptions = this.getPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_CASE_ORIGINATOR_FIELD);
        // check if case originator field values need to be restricted based on the definitions passed in
        // by parent.
         if (this.caseOriginatorRestrictedValueDefinitions && caseOriginatorOptions) {
             caseOriginatorOptions = caseOriginatorOptions.filter(item =>  {
                 return Object.keys(this.caseOriginatorRestrictedValueDefinitions).includes(item.value);
             });
         }

        return caseOriginatorOptions;
    }

    get priorityOptions() {
        return this.getPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_PRIORITY);
    }

    get defaultPriority() {

        if (this.priority) {
            return this.priority;
        }

        this.priority = this.getDefaultPicklistValueForCaseField(CONSTANTS.CASE_FIELDS.FIELD_PRIORITY, this.priorityOptions);
        return this.priority;
    }

    handleProductCategoryChange(event) {
        this.productCategory = event.target.value;this.trackInputFieldValues.isProductCategoryUpdated = true;
        this.productSubCategory = null;this.trackInputFieldValues.isProductSubCategoryUpdated = true;
        this.enquirySubType = null;this.trackInputFieldValues.isEnquirySubtypeUpdated = true;
    }

    handleProductSubCategoryChange(event) {
        this.productSubCategory = event.target.value;this.trackInputFieldValues.isProductSubCategoryUpdated = true;
        this.enquirySubType = null;this.trackInputFieldValues.isEnquirySubtypeUpdated = true;
    }

    handleCaseTypeChange(event) {
        this.caseType = event.target.value;this.trackInputFieldValues.isCaseTypeUpdated = true;
        this.enquirySubType = null;this.trackInputFieldValues.isEnquirySubtypeUpdated = true;
    }

    handleEnquirySubTypeChange(event) {
        this.enquirySubType = event.target.value;
        this.trackInputFieldValues.isEnquirySubtypeUpdated = true;
    }

    handleComplaintChange(event) {
        this.complaint = event.target.value;
        this.trackInputFieldValues.isComplaintUpdated = true;
    }

    handleOriginatorChange(event) {
        this.originator = event.target.value;
        this.trackInputFieldValues.isOriginatorUpdated = true;
    }

    handlePriorityChange(event) {
        this.priority = event.target.value;
        this.trackInputFieldValues.isPriorityUpdated = true;
    }

    get isProductSubCategoryDisabled() {
        if (this.productCategory) {
            return false;
        }
        return true;
    }

    get productSubCategoryDependantOptions() {
        if (this.productCategory) {
            return this.getDependentPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_PRODUCT_SUB_CATEGORY, this.productCategory);
        }
        return [];
    }

    get isEnquirySubTypeDisabled() {
        if (this.productCategory && this.productSubCategory && this.caseType) {
            return false;
        }
        return true;
    }

    get enquirySubTypeDependantOptions() {
        if (this.productCategory && this.productSubCategory && this.caseType) {
            const productAndType = (this.caseType + '|' + this.productCategory + '|' + this.productSubCategory);
            let enquirySubTypeOptions = this.getDependentPicklistValuesForCaseField(CONSTANTS.CASE_FIELDS.FIELD_ENQUIRY_SUB_TYPE, productAndType);

            // check if enquiry sub type field values need to be restricted based on the definitions passed in
            // by parent.
             if (this.enquirySubTypeRestrictedValueDefinitions && enquirySubTypeOptions) {
                 enquirySubTypeOptions = enquirySubTypeOptions.filter(item =>  {
                     return Object.keys(this.enquirySubTypeRestrictedValueDefinitions).includes(item.value);
                 });
             }

            return enquirySubTypeOptions;
        }
        return [];
    }

    getRestrictedPicklistValueDefinitions(fieldApiName) {
        const restrictedValueDefinitions = {};
        if (this._caseRestrictedPicklistValues[fieldApiName]) {
            this._caseRestrictedPicklistValues[fieldApiName].forEach(item => {
                restrictedValueDefinitions[item.name] = item;
            });
            return restrictedValueDefinitions;
        }
        return null;
    }

    validateRestrictedPicklistFieldValues(inputCmp, restrictedPicklistValueDefinitions, currentValue) {

        if (!currentValue) {
            //No value is selected. clear out any previous errors
            inputCmp.setCustomValidity("");
            return true;
        }

        if (!restrictedPicklistValueDefinitions[currentValue]) {
            //restrictions are not defined for current value. this is not possible as the value should not be available for selection
            //in the first place.
            return true;
        }

        if (restrictedPicklistValueDefinitions[currentValue].isValid) {
            //input is valid. clear out any previous errors
            inputCmp.setCustomValidity("");
            return true;
        } else {
            //input is not valid
            inputCmp.setCustomValidity(restrictedPicklistValueDefinitions[currentValue].errorMessage);
            return false;
        }
    }
}