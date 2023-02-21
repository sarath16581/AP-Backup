import {
    api,
    LightningElement
} from 'lwc';

export default class MyNetworkStarTrackCaseArticlesTableCell extends LightningElement {
    @api articleId; //article id
    @api eventMessageId; //event message id
    @api label; //field label
    @api name; //field name
    @api type; //field type
    @api url; //field url
    @api pillItems = []; //pill items for pill container
    source; //field value supplied from the parent

    @api
    get value() {
        return this.source;
    }
    set value(v) {
        this.source = v;
    }

    //returns true if this field is a Pill field
    get isPill() {
        return this.type === 'PILL';
    }

    //returns true if this field is a URL field
    get isURL() {
        return this.type === 'URL';
    }

    //returns true if this field is not pill or URL
    get isOther() {
        return this.type !== 'PILL' && this.type !== 'URL';
    }

    //dispatches event to the parent to show the modal for related networks
    handleSearchClick(event) {
        this.dispatchEvent(new CustomEvent('networksearch', {
            detail: {
                articleId: event.target.dataset.articleId,
                eventMsgId: event.target.dataset.eventMsgId,
                selectedNetworks: this.getSelectedNetworks()
            }
        }));
    }

    //returns selected networks
    getSelectedNetworks() {
        return this.pillItems.map(item => item.name);
    }

    //handler for pill item remove click
    handleItemRemove(event) {
        this.dispatchEvent(new CustomEvent('networkremoved', {
            detail: {
                articleId: event.target.dataset.articleId,
                network: event.detail.item.name
            }
        }))
    }

    //handler for url click
    handleUrlClick(event) {
        let recordId = event.target.dataset.url;
        //dispatches event to the vf page to open record in the subtab
        this.dispatchEvent(new CustomEvent('subtab', {
            bubbles: true,
            composed: true,
            detail: {
                recordId: recordId
            }
        }));
    }

}