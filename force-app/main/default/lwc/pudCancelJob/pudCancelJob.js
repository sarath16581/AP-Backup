/**
 * @description LWC action to trigger cancellation for the PUD Job.
 * @author Ranjeewa Silva
 * @date 2021-08-27
 * @changelog
 * 2021-08-27 - Ranjeewa Silva - Created
 */

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import LABEL_CONFIRM_PROMPT from '@salesforce/label/c.PUDConfirmCancellationPrompt';
import cancel from '@salesforce/apex/PUDPickupBookingController.cancel'

export default class PudCancelJob extends LightningElement {

    // PUD job record Id set by LWC framework
    @api recordId;

    // indicates the previous invocation of the action is still executing
    isExecuting = false;

    confirmationPromptLabel = LABEL_CONFIRM_PROMPT;

    handleConfirmCancellation() {

        if (!this.isExecuting && this.recordId) {
            this.isExecuting = true;

            // call controller method to perform the action
            cancel({jobId: this.recordId})
                .then(result => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                    if (result.status === 'SUCCESSFUL') {
                        // cancellation sent to dispatch system successfully.
                        this.dispatchEvent( new ShowToastEvent({
                            title: 'Success',
                            message: 'Job cancellation sent to dispatch system',
                            variant: 'success'
                        }));

                        // notify LDS the record is updated - to refresh LDS cache.
                        getRecordNotifyChange([{recordId: this.recordId}]);
                    } else {
                        this.errorMessage = result.errorMessage;
                        this.dispatchEvent( new ShowToastEvent({
                            title: 'Job not allowed to be cancelled.',
                            message: result.errorMessage,
                            variant: 'warn'
                        }));
                    }
                    this.isExecuting = false;
                })
                .catch(error => {
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error cancelling Job',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.isExecuting = false;
                });
        }
    }

    handleClose(event) {
       this.dispatchEvent(new CloseActionScreenEvent());
    }
}