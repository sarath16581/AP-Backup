/**
 * @description Allows the user to review details of bulk upload request that is currently being uploaded. Provides
 *              details on field mapping details and also a preview of file contents.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Core
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created.
 */

import { LightningElement, api } from 'lwc';
import { get } from 'c/utils';
import BulkUploadBase from "c/bulkUploadBase";
import { getConfig, CONSTANTS } from 'c/bulkUploadService';

export default class BulkUploadReviewInputFile extends BulkUploadBase {

    // file selected for upload
    @api selectedFile;

    // upload type defines the fields (required fields, field types etc), validations and how the line items are
    // processed.
    @api type;

    // number of rows to read and parsed for providing a preview of the file. set by the parent component.
    @api previewRows;

    // any error messages applicable to the currently reviewed file.
    errorMessage;

    // field mapping definitions (including field types, required fields) retrieved from server.
    _fieldMappingDefinitions;
    connectedCallback() {
        this.loadScripts();
        getConfig(this.type).then(result => {
            this._fieldMappingDefinitions = get(result, 'fieldMapping', {});
        });
    }

    get fileName() {
        if (this.selectedFile) {
            return this.selectedFile.name;
        }
        return '';
    }

    _csvFilePreview = {columns:[], data:[]};
    get filePreview() {

        if (this._csvFilePreview.columns && this._csvFilePreview.columns.length > 0) {
            // return if preview data is already available.
            return this._csvFilePreview;
        }

        if (this.selectedFile) {
            if (this.hasExternalLibrariesLoaded) {

                // call Papaparse in preview mode to read and parse a set number of CSV rows from file.
                Papa.parse(this.selectedFile, {
                    complete: results => {
                        let preview = {};
                        if (results.meta && results.meta.fields && results.meta.fields.length > 0) {
                            preview = {
                                columns: results.meta.fields,
                                data: []
                            }
                        }

                        if (results.data && results.data.length > 0) {

                            preview.data = results.data.map((item, index) => {

                                const columns = [...preview.columns].map((column, columnIndex) => {
                                    const col = {
                                        fieldName: column,
                                        fieldValue: item[column],
                                        fieldType: 'STRING',
                                        key: 'item' + index + '_col' + columnIndex
                                    };
                                    return col;
                                });

                                return {
                                    ...item,
                                    key: 'item_' + index,
                                    _columns: columns
                                };
                            });
                        }

                        this._csvFilePreview = preview;
                    },
                    header: true,
                    preview: this.previewRows
                });
            }
        }

        return this._csvFilePreview;
    }

    _fieldMapping = {
        mapping: [], missingFields: [], mappedFieldsCount: 0, unmappedFieldsCount: 0, missingFieldsCount: 0
    };
    get fieldMapping() {

        if (this._fieldMapping && this._fieldMapping.mapping && (this._fieldMapping.mapping.length > 0 || this._fieldMapping.missingFields.length > 0)) {
            // return if field mapping is already computed and available.
            return this._fieldMapping;
        }

        if (this._csvFilePreview && this._csvFilePreview.columns && this._csvFilePreview.columns.length > 0) {

            const fieldMapping = {
                mapping:[],
                missingFields: [],
                mappedFieldsCount: 0,
                unmappedFieldsCount: 0,
                missingFieldsCount: 0
            }

            const mapping = this._csvFilePreview.columns.map(column => {

                // check if the csv column name is included in field definitions for the upload type.
                const isFieldMapped = (this._fieldMappingDefinitions ? this._fieldMappingDefinitions.hasOwnProperty(column.toLowerCase()) : false);
                if (isFieldMapped) {
                    fieldMapping.mappedFieldsCount++;
                } else {
                    fieldMapping.unmappedFieldsCount++;
                }

                return {
                    fieldName : column,
                    isMissing : false,
                    isMapped :  isFieldMapped
                }
            });

            // check if any required fields are missing in current file. If required fields are missing we don't allow the
            // file to be uploaded.
            const missingFields = [];
            if (this._fieldMappingDefinitions) {
                const columnNamesLowerCase = this._csvFilePreview.columns.map(column => {
                    return column.toLowerCase();
                });
                Object.keys(this._fieldMappingDefinitions).filter(fieldName => {
                    return this._fieldMappingDefinitions[fieldName].required && !columnNamesLowerCase.includes(fieldName)
                }).forEach(missingField => {
                    const fieldDefinition = this._fieldMappingDefinitions[missingField];
                    if (fieldDefinition.required) {
                        missingFields.push({fieldName: fieldDefinition.fieldLabel, isMissing: true, isMapped: false});
                        fieldMapping.missingFieldsCount++;
                    }
                });
            }

            fieldMapping.mapping = mapping;
            fieldMapping.missingFields = missingFields;

            if (fieldMapping.missingFieldsCount > 0) {
                // there are required fields missing in current CSV file. show an error to the user and stop the process.
                this.errorMessage = 'Required fields missing in file - ' + this.selectedFile.name + '. Please review field mappings for missing fields.';
            }
            this._fieldMapping = fieldMapping;
        }

        return this._fieldMapping;
    }

    get hasErrors() {
        return (this.errorMessage && this.errorMessage.length > 0);
    }

    handleCancelUpload() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleConfirmUpload() {
        this.dispatchEvent(new CustomEvent('confirm'));
    }
}