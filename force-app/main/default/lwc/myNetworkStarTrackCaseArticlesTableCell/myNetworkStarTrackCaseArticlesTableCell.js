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

}