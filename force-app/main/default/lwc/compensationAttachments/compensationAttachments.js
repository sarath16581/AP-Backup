/**
 *
 *     @author Hasantha Liyanage
 *     @date 2023-07-17
 *     @group lwc
 *     @tag js Controller
 *     @tag Attachments
 *     @domain ui
 *     @description listing attachments for the compensation record
 *     @changelog
 *     2023-07-17 - hasantha.liyanage@auspost.com.au - Created
 *
 */

import {LightningElement, api} from 'lwc';
import getAttachmentsByParentId from '@salesforce/apex/CompensationAttachmentsController.getAttachmentsByParentId';
import createAttachments from '@salesforce/apex/CompensationAttachmentsController.createAttachments';
import getPageConfig from '@salesforce/apex/CompensationAttachmentsController.getPageConfig';

// Data table columns
const columns = [
    {label: 'Attachment Name', fieldName: 'name'},
    {label: 'Type', fieldName: 'contentType'},
    {
        label: 'Size (KB)', fieldName: 'bodyLength', type: 'number', sortable: true,
        cellAttributes: {alignment: 'center'}
    },
    {
        label: 'Preview', type: 'button',
        typeAttributes: {
            label: 'Preview',
            name: 'Preview',
            variant: 'base',
            iconName: 'utility:preview',
            iconPosition: 'right'
        },
        cellAttributes: {alignment: 'center'}
    },
    {
        label: 'Actions',
        type: 'button',
        sortable: true,
        fieldName: 'isSelected',
        typeAttributes: {
            iconName: {fieldName: 'buttonIconName'},
            iconPosition: 'center',
            name: 'selectFileAction',
            iconSize: 1,
            variant: 'base',
            disabled: {fieldName: 'isSelected'}
        },

        cellAttributes: {
            class: 'slds-text-align_center',
            alignment: 'center'
        },
        initialWidth: 120
    }
];
export default class CompensationAttachments extends LightningElement {
    @api recordId;
    isLoading = false; //flag to show/hide the spinner
    attachments = [];
    columns = columns;
    isDisableSelection = true;
    messages = {};
    config = {};
    sortedBy;
    sortedDirection;

    connectedCallback() {
        this.isLoading = true;
        this.messages = {};
        this.initialLoad();
    }
    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const actionedRow = event.detail.row;

        switch (actionName) {
            case 'selectFileAction':
                if (this.attachments) {
                    // render the selection button icons based on the selections
                    this.attachments = this.attachments.map(row => {
                        if (actionedRow.id === row.id) {
                            let isSelectedNew = !row.isSelectedNew
                            let buttonIconName = isSelectedNew ? 'utility:check' : 'utility:add';
                            return {...row, isSelectedNew, buttonIconName};
                        }
                        return {...row};

                    });
                    // user should have permissions to link files or create attachments
                    if (this.config.isAllowedToCreateCompensation) {
                        // enable/disable the attachment button based on the selection
                        this.isDisableSelection = !(this.attachments.some(row => row.isSelectedNew === true));
                    }
                }
                break;
            case 'Preview':
                // dispatch an event to vf page to preview file action
                const detail = {
                    attachmentId: actionedRow.id,
                    isAttachment: actionedRow.isAttachment
                }
                this.dispatchEvent(new CustomEvent('preview', {detail: detail, bubbles: true, composed: true}));
                break;
            default:
                break;
        }
    }

    /**
     * Initial load
     */
    async initialLoad() {
        try {
            await this.loadConfig()
            await this.loadAttachments()
        } catch (e) {
            this.messages.showError = true;
            this.messages.message = error.body.message;
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Initial load of the configs
     */
    async loadConfig() {
        return getPageConfig({recordId: this.recordId})
            .then((result) => {
                this.config = result;
            })
            .catch((error) => {
                console.error(error);
                this.messages.showError = true;
                this.messages.message = error.body.message;
            }).finally(() => {
            this.isLoading = false;
        });
    }

    /**
     * load of the attachments
     */
    async loadAttachments() {
        // load all the attachments and the files related to the case
        return getAttachmentsByParentId({compensation: this.config.compensation})
            .then((result) => {
                this.attachments = result;
                if (this.attachments) {
                    let buttonIconName;
                    this.attachments = this.attachments.map(row => {
                        buttonIconName = (row.isSelected === true ? 'utility:check' : 'utility:add');
                        return {...row, buttonIconName}
                    })
                }
                // list the selected files first
                this.sortData('isSelected', 'desc');
            })
            .catch((error) => {
                console.error(error);
                this.messages.showError = true;
                this.messages.message = error.body.message;
            }).finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Create/link selected attachments/files against the compensation record
     */
    handleCreateAttachments() {
        this.isLoading = true;
        this.messages = {};
        createAttachments({attachmentDetails: this.attachments, recordId: this.recordId})
            .then(() => {
                this.messages.showSuccess = true;
                this.messages.message = 'Attachments created successfully.';
                this.loadAttachments();
            })
            .catch((error) => {
                this.messages.showError = true;
                this.messages.message = error.body.message;
            }).finally(() => {
            this.isLoading = false;
        });
    }

    /**
     * notify to vf page then the vf page will refresh the tab
     */
    notifyParent(){
        const detail = {}
        this.dispatchEvent(new CustomEvent('selfRefresh', {detail: detail, bubbles: true, composed: true}));
    }

    /**
     * handle close for the message box
     */
    handleClose() {
        const successMessage = this.template.querySelector('[data-id="successMessage"]');
        if (successMessage) {
            successMessage.style.display = 'none';
        }
    }

    /**
     * sort the sortable columns on the table
     * @param event
     */
    onSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    /**
     * Sorting table data based on the given field name and direction
     * @param fieldName
     * @param direction
     */
    sortData(fieldName, direction) {
        let parseData = JSON.parse(JSON.stringify(this.attachments));
        let keyValue = (a) => {
            return a[fieldName];
        };
        let isReverse = direction === "asc" ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : "";
            y = keyValue(y) ? keyValue(y) : "";
            return isReverse * ((x > y) - (y > x));
        });
        this.attachments = parseData;
    }
}