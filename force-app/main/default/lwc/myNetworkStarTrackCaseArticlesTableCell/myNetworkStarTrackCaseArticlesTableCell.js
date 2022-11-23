import { api, LightningElement } from 'lwc';

export default class MyNetworkStarTrackCaseArticlesTableCell extends LightningElement {
	@api articleId; //article id
    @api label; //field label
    @api name; //field name
    @api type; //field type
    @api url; //field url
    @api pillItems; //pill items for pill container
    source; //field value supplied from the parent

    @api
    get value() { return this.source; }
    set value(v) {
        this.source = v;
    }

    /**
	 * returns true if this field is a Pill field
	 */
     get isPill() {
        return this.type === 'PILL';
    }

    handleSearchClick(event){
        let articleId = event.target.dataset.articleId;
        console.log('articleId==>'+articleId);
    }

}