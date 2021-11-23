/**************************************************
Description:
History:
--------------------------------------------------
2019-08-01  sameed.khan@auspost.com.au  Created
2020-03-16  nathan.franklin@auspost.com.au  Adding custom event dispatch for closing modal
 **************************************************/
import { LightningElement, api, track } from 'lwc';

export default class Modal extends LightningElement {
    @api showModal
    @api closeModalCallback
    @api title
    @api size
    @api dontShowHeader = false;
    @api dontShowFooter = false;

    @track footerStyleClass = '';
    @track sizeStyleClass

    _hideModal = e => {
        const ESC_KEY = 27;
        if ((e.which === ESC_KEY || e.keyCode === ESC_KEY) && this.closeModalCallback) {
            this.closeModalCallback();
        }
    }
    
    connectedCallback() {
        window.addEventListener('keyup', this._hideModal);
    }

    closeModal() {

        // the new event driven way
        this.dispatchEvent(new CustomEvent('close'));

        // the old legacy way
        if(this.closeModalCallback)
            this.closeModalCallback();
    }

    get headerSyleClass() {
        return this.dontShowHeader ? 'slds-modal__header slds-modal__header_empty' : 'slds-modal__header';
    }

    get modalVisibilityClass() {
        return this.showModal ? '' : 'slds-hide';
    }

    disconnectedCallback() {
        window.removeEventListener('keyup', this._hideModal);
    }
}