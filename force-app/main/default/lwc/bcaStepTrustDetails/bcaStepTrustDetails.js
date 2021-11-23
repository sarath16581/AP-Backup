/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Trust input details to upload Trust deed documents
* @changelog
* 2020-01-20 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import uploadFile from '@salesforce/apex/BCAFormController.uploadFile';
import deleteFile from '@salesforce/apex/BCAFormController.deleteUploadedFile';
import bcaStepBase from "c/bcaStepBase";
import {acceptedFileFormats}  from "c/bcaStepBase";

//import { checkAllValidity, checkCustomValidity } from 'c/bcaStepBase';

//import {acceptedFileFormats} from "../bspCommonJS/bspCommonJS";

export default class BcaStepTrustDetails extends bcaStepBase {

    @api get trustFiles(){
        return this.filesUploaded;
    }

    @track loading = false;

    ERROR_MSG_FILE_SIZE = 'Must be less than 2MB';
    ERROR_MSG_FILE_TYPE = 'Must be a PDF, JPG or PNG';

    uploadFileFormats = acceptedFileFormats();

    get trustDeedLabel () {
        return this.filesUploaded.length === 1 ? 'Trust deed document': 'Trust deed documents';
    }

    get hasFiles() {
        return this.filesUploaded.length > 0;
    }

    get showAdditionalFiles() {
        return this.filesUploaded.length < 5;
    }

    get uploadLabelClass() {
        let sClass = 'slds-form-element';
        if(this.hasFiles)
        {
            sClass += ' optional-label';
        }
        return sClass;

    }

    get uploadInputClass() {
        let sClass = 'upload-file-list';
        if(this.errorMessage)
            sClass += ' slds-has-error';
        return sClass;
    }

    get uploadBtnClass () {
        let sClass ="slds-file-selector__button slds-button slds-button_icon slds-button_icon-border search-aligned-input-button upload-button-margin";
        if(!this.hasFiles)
            sClass += ' red-icon-button';
        return sClass;
    }

    onClickPreview = (event) => {
        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id;
        }
        else
        {
            index = event.target.dataset.id;
        }
        let fileObj = this.filesUploaded[index];
        window.open(fileObj.previewUrl, '_blank');
    }

    onClickDelete = (event) => {
        this.loading = true;
        this.updateNavButtons(false, false);

        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id;
        }
        else
        {
            index = event.target.dataset.id;
        }
        let fileObj = this.filesUploaded[index];
        deleteFile({contentDocumentId: fileObj.contentDocumentId})
            .then(result => {
                if(result && result.status.toLowerCase() === 'ok') {
                    this.filesUploaded.splice(index, 1);

                    for(let i = 0; i < this.filesUploaded.length; ++i){
                        this.filesUploaded[i].index = i;
                    }
                }
                else{
                    this.errorMessage = 'Error deleting file';
                }

                this.updateNextButtonVisibility();
                this.loading = false;
            })
            .catch(error => {
                this.errorMessage = 'Error deleting file';

                this.updateNextButtonVisibility();
                this.loading = false;
            });
    }

    fileInputId = 'file-upload-input-01';
    clearFileInput = () =>{
        let inputTag = this.template.querySelector('input[data-id="'+ this.fileInputId + '"]');
        inputTag.value = '';
    }

    @track filesUploaded = [];
    uploadTrustFile = (event) => {
        this.errorMessage = '';
        this.loading = true;
        this.updateNavButtons(false, false);
        if (event.target.files.length > 0) {

            let file = event.target.files[0];
            if(file.size > 2048000)
            {
                this.errorMessage = this.ERROR_MSG_FILE_SIZE;
                this.updateNextButtonVisibility();
                this.clearFileInput();
                this.loading = false;
            }
            else if(!this.validFileFormat(file.name))
            {
                this.errorMessage = this.ERROR_MSG_FILE_TYPE;
                this.updateNextButtonVisibility();
                this.clearFileInput();
                this.loading = false;
            }
            else
            {
                let reader = new FileReader();

                reader.onload = e => {
                    let base64 = 'base64,';
                    let content = reader.result.indexOf(base64) + base64.length;
                    let fileContents = reader.result.substring(content);

                    let fileObj = {index: this.filesUploaded.length
                        , url: reader.result
                        , PathOnClient: file.name
                        , Title: file.name
                        , VersionData: fileContents};

                    uploadFile({file: fileObj})
                        .then(result => {
                            if(result) {
                                fileObj.contentDocumentId = result.contentDocumentId;
                                fileObj.previewUrl = result.previewUrl;
                                this.filesUploaded.push(fileObj);
                            }
                            else{
                                this.errorMessage = 'Error uploading files';
                            }


                            this.updateNextButtonVisibility();
                            this.loading = false;
                            this.clearFileInput();
                        })
                        .catch(error => {
                            this.errorMessage = 'Error uploading files';

                            this.updateNextButtonVisibility();
                            this.loading = false;
                            this.clearFileInput();
                        });


                };
                reader.readAsDataURL(file);
            }
        }
        else
        {
            this.updateNextButtonVisibility();
            this.loading = false;
        }
    }

    validFileFormat(fileName)
    {
        let arrSplit = fileName.split('.');
        let type = '.' + arrSplit[arrSplit.length - 1];

        if(this.ACCEPTED_FILE_FORMATS.indexOf(type) >= 0)
        {
            return true;
        }
        return false;
    }

    updateNextButtonVisibility = () => {
        this.updateNavButtons(true, false);
        if (this.filesUploaded.length > 0)
            this.updateNavButtons(true, true);

    }

    @api checkAllValidity() {
        let allValid = this.filesUploaded.length > 0;

        if(allValid)
        {
            this.errorMessage = '';
        }

        return allValid;
    }

}