/**
 * @description LWC action to trigger dispatch system sync for the PUD Job.
 * @author Ranjeewa Silva
 * @date 2021-08-16
 * @changelog
 * 2021-08-16 - Ranjeewa Silva - Created
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import triggerDispatchSystemSync from '@salesforce/apex/PUDPickupBookingController.triggerDispatchSystemSync'

export default class PudForcePushJob extends LightningElement {

    // PUD job record Id set by LWC framework
    @api recordId;

    // indicates the previous invocation of the action is still executing
    isExecuting = false;

    @api async invoke() {

        if (!this.isExecuting && this.recordId) {
            this.isExecuting = true;
            // call controller method to perform the action
            triggerDispatchSystemSync({jobId: this.recordId})
                .then(result => {

                    if (result.status === 'SUCCESSFUL') {
                        // dispatch system sync triggered successfully.
                        this.dispatchEvent( new ShowToastEvent({
                            title: 'Success',
                            message: 'Job details sent to Dispatch System',
                            variant: 'success'
                        }));

                        // notify LDS the record is updated - to refresh LDS cache.
                        getRecordNotifyChange([{recordId: this.recordId}]);
                    } else {
                        this.errorMessage = result.errorMessage;
                        this.dispatchEvent( new ShowToastEvent({
                            title: 'Job not allowed to be sent to Dispatch System.',
                            message: result.errorMessage,
                            variant: 'warn'
                        }));
                    }
                    this.isExecuting = false;
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error sending Job',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.isExecuting = false;
                });
        }

    }
}