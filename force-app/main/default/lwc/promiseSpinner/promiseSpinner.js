/**
 * Created by Nathan on 2019-03-10.
 */

import {LightningElement, track, api} from 'lwc';

export default class PromiseSpinner extends LightningElement {

    @track waitingCount = 0;

    get shouldShow() {
        return (this.waitingCount > 0);
    }

    stopWait() {
        this.waitingCount--;
        if(this.waitingCount < 0) {
            this.waitingCount = 0;
        }
    }

    startWait() {
        this.waitingCount++;
    }

    @api
    addPromise(promise) {
        this.startWait();
        promise.finally(() => {
            this.stopWait();
        });
    }

}