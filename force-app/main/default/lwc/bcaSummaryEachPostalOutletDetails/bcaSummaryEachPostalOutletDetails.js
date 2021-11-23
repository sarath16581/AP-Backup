import { LightningElement, api } from 'lwc';
import { replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryEachPostalOutletDetails extends LightningElement {
    @api postalOutlet;
    @api index;

    get label(){
        return 'Postal outlet  '+((+this.index)+1);
    }

    get value(){
        let name = this.postalOutlet.name;
        let address = this.postalOutlet.addressLine2.toLowerCase()+', '+this.postalOutlet.suburb.toLowerCase()+', '+this.postalOutlet.state+', '+this.postalOutlet.postcode;
        return [{"val":name},{"val":address}];
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="postalOutlet"]')[0].innerHTML;

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                '<c-bca-summary-row', '</c-bca-summary-row>');

        }

        return cmpHtml;
    }
}