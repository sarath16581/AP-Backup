/**
 * @description Base component of Direct to Network Case Wizard which defines useful methods and properties for dealing
 *              with record types and pick list fields.
 * @author Ranjeewa Silva
 * @date 2020-10-05
 * @changelog
 * 2020-10-05 - Ranjeewa Silva - Created
 * 2020-11-06 - Ranjeewa Silva - Added a method to get default value of a picklist field as configured in field metadata.
 */

import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { CONSTANTS } from "c/dtnCaseService";

export default class DtnCaseWizardBase extends LightningElement {

    // record type name of new case
    @api caseRecordTypeName;

    // indicates if retrieval of field metadata is completed
    fieldInfoLoaded = false;

    // record type id populated by wire adapter
    caseRecordTypeId;

    // case picklist field metadata (including dependent picklist values) populated by wire adapter.
    _casePicklistFieldValues;

    @wire(getObjectInfo, { objectApiName: CONSTANTS.CASE_OBJECT })
    caseObjectInfo({ error, data }) {
        if (data) {
            const recordTypeInfos = data.recordTypeInfos;
            this.caseRecordTypeId = Object.keys(recordTypeInfos).find(rti => recordTypeInfos[rti].name === this.caseRecordTypeName);
        } else if (error) {
            this.caseRecordTypeId = null;
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: CONSTANTS.CASE_OBJECT, recordTypeId: '$caseRecordTypeId'})
    caseFieldInfo({error, data}) {
        if (data && data.picklistFieldValues) {
            this._casePicklistFieldValues = data.picklistFieldValues;
            this.fieldInfoLoaded = true;
        }
    }

    get casePicklistFieldValues() {
        return this._casePicklistFieldValues;
    }

    /**
     * Retrieve picklist value definitions for the field passed in.
     */
    getPicklistValuesForCaseField(fieldApiName) {
        if (this.casePicklistFieldValues && this.casePicklistFieldValues[fieldApiName]) {
            return this.casePicklistFieldValues[fieldApiName].values;
        }
        return [];
    }

    /**
     * Retrieve all applicable dependent picklist values for controlling picklist value.
     */
    getDependentPicklistValuesForCaseField(fieldApiName, controllerValue) {
        if (this.casePicklistFieldValues && this.casePicklistFieldValues[fieldApiName]) {
            let key = this.casePicklistFieldValues[fieldApiName].controllerValues[controllerValue];
            return this.casePicklistFieldValues[fieldApiName].values.filter(opt => opt.validFor.includes(key));
        }
        return [];
    }

    /**
     * Retrieve default picklist value for the field passed in.
     */
    getDefaultPicklistValueForCaseField(fieldApiName, validOptions) {
        if (this.casePicklistFieldValues && this.casePicklistFieldValues[fieldApiName] && validOptions.length > 0) {
            const defaultValue = this.casePicklistFieldValues[fieldApiName].defaultValue;
            if (defaultValue && validOptions.filter(item => item.value === defaultValue.value).length > 0) {
                return defaultValue.value;
            }
        }
        return null;
    }
}