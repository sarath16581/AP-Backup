/**
 * @description LWC action to trigger recalculation of Sales Team sharing for Account child objects.
 * @author Ranjeewa Silva
 * @date 2023-01-23
 * @domain Sales
 * @changelog
 * 2023-01-23 - Ranjeewa Silva - Created
 */
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// custom permission granting ability to recalculate sharing
import PERMISSION_RECALCULATESHARING from '@salesforce/customPermission/RecalculateSalesTeamSharing';

// custom labels
import LABEL_CONFIRM_INFO_MESSAGE from '@salesforce/label/c.ConfirmSharingRecalculationInfoMessage';
import LABEL_RECALCULATE_SHARING_TITLE from '@salesforce/label/c.RecalculateSharingModalTitle';
import LABEL_PERMISSION_ERROR_MESSAGE from '@salesforce/label/c.SharingRecalculationPermissionsErrorMessage';
import LABEL_RECALCULATION_ENQUEUED_MESSAGE from '@salesforce/label/c.SharingRecalculationRequestSuccessfullyEnqueuedMessage';

import recalculateSalesTeamSharing from '@salesforce/apex/SalesRecalculateSharingController.recalculateSalesTeamSharing'

export default class SalesRecalculateChildRecordSharing extends LightningElement {

    // record Id set by LWC framework
    @api recordId;

    // expose custom labels
    label = {
        confirmationInfoMessageLabel: LABEL_CONFIRM_INFO_MESSAGE,
        recalculateSharingModalTitle: LABEL_RECALCULATE_SHARING_TITLE,
        recalculateSharingPermissionsError: LABEL_PERMISSION_ERROR_MESSAGE,
        recalculationEnqueuedMessage: LABEL_RECALCULATION_ENQUEUED_MESSAGE

    };

    handleCancel(event) {
       this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleRecalculateSharing() {
        if (this.recordId) {

	        // recalculate sharing
	        recalculateSalesTeamSharing({
	            accountId: this.recordId
	        }).then(result => {
	            // recalculation request enqueued.
	            this.dispatchEvent( new ShowToastEvent({
	                title: 'Success',
	                message: this.label.recalculationEnqueuedMessage,
	                variant: 'success'
	            }));
	        }).catch(error => {
	            this.dispatchEvent(
	                new ShowToastEvent({
	                    title: 'Error recalculating sharing',
	                    message: error.body.message,
	                    variant: 'error'
	                })
	            );
	        }).finally(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        }
    }

    get isRecalculateSharingDisabled() {
        return !PERMISSION_RECALCULATESHARING && this.recordId;
    }
}