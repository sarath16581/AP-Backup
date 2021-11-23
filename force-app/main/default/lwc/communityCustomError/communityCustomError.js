/**
 * A very basic component for rendering custom error messages in lightning.
 * This component allows custom errorTitle and errorMessage to be passed in or will read ErrorDetails and ErrorDescription from querystring
 */
import {LightningElement, track, api} from 'lwc';

export default class CommunityCustomError extends LightningElement {

    @api errorTitle;
    @api errorMessage;
    @api showTitle;

    connectedCallback() {

        if(!this.errorTitle) {
            this.errorTitle = this.getParam('ErrorDescription');
            if(this.errorTitle) {
                this.showTitle = true;
            }
        }

        if(!this.errorMessage) {
            this.errorMessage = this.getParam('ErrorDetails') || 'There was an error that prevented the page from loading';
        }

    }

    getParam(name) {
        var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
        if (results==null) {
            return null;
        } else {
            return decodeURIComponent(results[1].replace(new RegExp('\\+', 'g'), ' ')) || 0;
        }
    }

}