/**
 * @description Upload new supporting documents and attach to existing Cases.
 * @author Ranjeewa Silva
 * @date 2021-02-12
 * @changelog
 * 2021-02-12 - Ranjeewa Silva - Created.
 */

import { LightningElement, api, track, wire } from 'lwc';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { debounce, get } from 'c/utils';
import searchCases from '@salesforce/apex/CaseSupportingDocumentsController.searchCases';
import uploadSupportingDocument from '@salesforce/apex/CaseSupportingDocumentsController.uploadSupportingDocument';

export default class CaseSupportingDocuments extends LightningElement {

    // maximum number of files that can be selected
    @api numberOfFilesLimit = 10;

    // maximum file size (in MB) supported
    @api fileSizeLimit = 2;

    // record type developer name of cases
    @api caseRecordTypeName;

    // separator character for extracting case number / reference from file name.
    CASENUMBER_SEPARATOR_CHAR = '_';

    // regular expression to use for detecting case number in file name.
    cachedCaseNumberRegEx = new RegExp('^[0-9]+_');

    // collection of javascript File objects representing the files selected for upload.
    //selectedFiles;

    // collection of supporting documents selected for upload. A supporting document contains the details of the file
    // and the case where that file needs to be attached.
    // the case number / reference Id may be specified as file name prefix, in which case the case details are populated after looking up
    // case number / reference id in the server. if case number / reference id is not specified in file name or the specified case number / reference id
    // does not exist, the user can still lookup case in user interface.
    @track supportingDocuments = [];

    // flag indicating the case details are currently being retrieved from server.
    retrievingCaseDetails = false;

    // flag indicating uploading the currently selected files has been already attempted.
    hasAttemptedUpload = false;

    //record type id populated by wire adapter
    caseRecordTypeId;
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT.objectApiName })
    caseObjectInfo({ error, data }) {
        if (data && this.caseRecordTypeName) {
            const recordTypeInfos = data.recordTypeInfos;
            this.caseRecordTypeId = Object.keys(recordTypeInfos).find(rti => {
                return (recordTypeInfos[rti].name === this.caseRecordTypeName)
            });
        } else if (error) {
            this.caseRecordTypeId = null;
        }
    }

    handleSelectFilesToUpload(event) {

        if (event.target.files) {

            //uploading new files. so reset the flag to indicate this is a new upload attempt.
            this.hasAttemptedUpload = false;

            const selectedFiles = [...event.target.files];

            if (!this.validateSelectedFiles(selectedFiles)) {
                // validation has failed. cannot continue.
                return;
            }

            // iterate through the list of files selected and populate into a list of supporting documents.
            // extract case numbers / reference ids from file name, if available. this will then be used to retrieve case details
            const caseReferences = [];
            this.supportingDocuments = selectedFiles.map((item, index) => {

                const file = {
                    file: item,
                    sizeInKB : this.getFileSizeInKB(item.size),
                    docTypeIconName: this.getDocTypeIconName(item.type)
                }

                let caseReference = this.getCaseReferenceFromFileName(item.name);
                if (caseReference) {
                    caseReferences.push(caseReference);
                }

                // case record wrapper. if case number / reference id is not specified in file name set the error message displayed to user.
                // if case number / reference id is specified, the case id is updated after looking up cases (in bulk).
                const caseRecord = {
                    Id: null,
                    errorMessage: (!caseReference ? 'Case reference not specified.' : null)
                }

                return {
                    documentIndex: index,
                    file: file,
                    fileName: item.name,
                    caseReference: caseReference, //  case reference extracted from file name. this could be a case number or reference id
                    case: caseRecord,
                    isSelected: false, // by default the record is not selected for upload. update this if we find a case record with the case reference
                    isDisabled: true, // by default the record selection is disabled. update this if we find a case record with the case reference
                    uploadStatus: null,
                    showCaseLookup: false // by default no need to show the case lookup. update this if we don't find a case record with the case reference
                };
            });

            if (caseReferences.length > 0) {

                // case references extracted from file names. lookup cases and retrieve case ids.

                this.retrievingCaseDetails = true;
                const recordTypeFilter = (this.caseRecordTypeId ? [this.caseRecordTypeId] : null);
                searchCases({searchTerms: caseReferences, recordTypeIds: recordTypeFilter})
                    .then(result => {
                        this.supportingDocuments.forEach(doc => {
                            if (result[doc.caseReference] && result[doc.caseReference].length === 1) {
                                doc.case = result[doc.caseReference][0];
                                doc.isSelected = true;
                                doc.isDisabled = false;
                            } else if (result[doc.caseReference] && result[doc.caseReference].length > 1) {
                                doc.case = {
                                    errorMessage : 'Non unique case reference - ' + doc.caseReference
                                }
                            } else if (doc.caseReference) {
                                doc.case = {
                                    errorMessage : 'Invalid case reference - ' + doc.caseReference
                                }
                            }
                       });
                    })
                    .finally(() => {
                        this.retrievingCaseDetails = false;
                    });
            }
        }
    }

    /**
     * handles the event when one of the cases is selected from the case lookup result set.
     */
    handleCaseSelected(event) {

        if (event.detail && event.detail.record) {

            // extract document index from the context (in event detail). this allows us to identify the supporting document
            // on which the case selection has occurred.
            let supportingDocIndex = event.detail.context;
            if (this.supportingDocuments[supportingDocIndex]) {
                // update the relevant supporting document with the details.
                this.supportingDocuments[supportingDocIndex].caseReference = event.detail.record.CaseNumber;
                this.supportingDocuments[supportingDocIndex].showCaseLookup = false; // case selection has been made. no need to show case lookup.
                if (event.detail.record.Id) {
                    this.supportingDocuments[supportingDocIndex].case = {
                        Id : event.detail.record.Id,
                        CaseNumber: event.detail.record.CaseNumber
                    };
                    this.supportingDocuments[supportingDocIndex].isDisabled = false; // now that a related case is identified, enable selection of supporting document for upload.
                    this.supportingDocuments[supportingDocIndex].isSelected = true; // by default make the supporting document selected for upload.
                }
            }
        }
    }

    /**
     * handles the event when currently selected case on the supporting document is removed.
     */
    handleRemoveSelectedCase(event) {

        if (this.hasAttemptedUpload) {
            return;
        }

        if ((event.target.name || event.target.name === 0) && this.supportingDocuments[event.target.name]) {
            const doc = this.supportingDocuments[event.target.name];
            doc.showCaseLookup = true;
            doc.isDisabled = true;
            doc.isSelected = false;
        }
    }

    /**
     * handles the event when a supporting document is selected / deselected for upload.
     * only the selected supporting documents are uploaded and agttached to cases.
     */
    handleSelectSupportingDocument(event) {
        if ((event.target.name || event.target.name === 0) && this.supportingDocuments[event.target.name]) {
            const doc = this.supportingDocuments[event.target.name];
            doc.isSelected = event.target.checked;
        }
    }

    get hasSelectedFiles() {
        return (this.supportingDocuments && this.supportingDocuments.length > 0);
    }

    get isUploadAndAttachDisabled() {
        if (!this.supportingDocuments) {
            return true;
        }

        const docsWithValidCases = this.supportingDocuments.filter(doc => {
           return (doc.case && doc.case.Id)
        });
        return (!docsWithValidCases || docsWithValidCases.length === 0);
    }

    get isLoading() {
        return (this.retrievingCaseDetails || this.isUploadingFiles);
    }

    get isUploadingFiles() {
        if (!this.supportingDocuments || this.supportingDocuments.length == 0) {
            return false;
        }

        const docsUploading = this.supportingDocuments.filter(doc => {
            return (doc.uploadStatus && doc.uploadStatus.name === 'In-Progress');
        });

        return docsUploading.length > 0;
    }

    get canUploadAndAttachSupportingDocuments() {
        if (!this.supportingDocuments) {
            return false;
        }

        return ((this.supportingDocuments.filter(doc => {
           return (doc.isSelected);
        }).length > 0) && !this.hasAttemptedUpload);
    }

    get caseLookupFilters() {
        if (this.caseRecordTypeId) {
            return {
                RecordTypeId : this.caseRecordTypeId
            }
        }
        return {};
    }

    closeFileUpload() {
        this.supportingDocuments = null;
        this.canUploadAndAttach = false;
    }

    /**
     * upload selected supporting documents and attach to cases
     */
    uploadAndAttachToCases() {

        this.hasAttemptedUpload = true;

        const docsToAttach = [];
        this.supportingDocuments.forEach(doc => {
            doc.isDisabled = true;
            doc.showCaseLookup = false;
            if (doc.isSelected) {
                docsToAttach.push(doc);
            }
        })

        docsToAttach.forEach(document => {

            let reader = new FileReader()
            reader.onload = () => {
                document.uploadStatus = {
                    name: 'In-Progress',
                    iconName: null,
                    message: null
                };

                let base64 = reader.result.split(',')[1];
                uploadSupportingDocument({
                    caseId: document.case.Id,
                    fileContentBase64: base64,
                    fileName: document.fileName
                })
                .then(() => {
                    document.uploadStatus = {
                        name: 'Successful',
                        iconName: 'utility:success',
                        iconVariant: 'success',
                        message: null
                    }
                })
                .catch(error => {
                    console.log('file uploaded error > ' + document.fileName);
                    console.log(error);
                    document.uploadStatus = {
                        name: 'Failed',
                        iconName: 'utility:error',
                        iconVariant: 'error',
                        message: error.body.message
                    };
                })
            }
            reader.readAsDataURL(document.file.file);
        });
    }

    getDocTypeIconName(type) {

        switch (type) {
            case 'text/csv' : return 'doctype:csv';
            case 'text/plain' : return 'doctype:txt';
            case 'application/pdf' : return 'doctype:pdf';
            case 'application/zip' : return 'doctype:zip';
            default: return 'doctype:unknown';
        }

    }

    getFileSizeInKB(size) {
        if (size) {
            return Math.round(size/1024, 2) + ' KB';
        }

        return '0 KB';
    }

    getCaseReferenceFromFileName(fileName) {
        //if (this.cachedCaseNumberRegEx.test(fileName)) {
        if (fileName.indexOf(this.CASENUMBER_SEPARATOR_CHAR) != -1) {
            return fileName.split(this.CASENUMBER_SEPARATOR_CHAR)[0];
        }
        return null;
    }

    validateSelectedFiles(selectedFiles) {
        const inputCmp = this.template.querySelector(".file-input");
        let isValid = true;
        if (selectedFiles.length > this.numberOfFilesLimit) {
            inputCmp.setCustomValidity('Please select up to ' + this.numberOfFilesLimit + ' supporting documents at a time.');
            isValid = false;
        } else if (selectedFiles.filter(file => { return file.size > (this.fileSizeLimit * 1024 * 1024) }).length > 0) {
            inputCmp.setCustomValidity('Each supporting document must be smaller than ' + this.fileSizeLimit + ' MB in size.');
            isValid = false;
        } else {
            inputCmp.setCustomValidity("");
        }
        inputCmp.reportValidity();
        return isValid;
    }

}