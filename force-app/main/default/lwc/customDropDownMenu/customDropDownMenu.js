/**
 * Created by Nathan on 2019-06-08.
 */

import {LightningElement, api, track} from 'lwc';
import ASSETS_URL from '@salesforce/resourceUrl/MerchantPortalAssets';

export default class CustomDropDownMenu extends LightningElement {

    @api align = 'left';
    @api label;
    @api size = 'small';
    @track menuOpen;

    // Identify if being loaded on IE11, to handle how we render SVGs
    get ie11() {
        return !!window.MSInputMethodContext && !!document.documentMode;
    }

    get iconForIE11() {
        return ASSETS_URL + '/svg/chevron-down.svg'
    }

    toggleMenu() {
        this.menuOpen = !this.menuOpen;

        if(this.menuOpen) {
            //Timeout is to prevent the click from continuing and closing the element right away.
            //Just this slight delay of 0 is enough to stop propagation
            window.setTimeout(() => window.addEventListener('click', this.handleClose), 0);
        }
    }

    /**
     * Monitor for when another click event is received and hide the menu
     */
    handleClose = () => {
        this.menuOpen = false;
        window.removeEventListener('click', this.handleClose);
    }

    @api
    get menuCss() {
        let css = 'slds-dropdown-trigger slds-dropdown-trigger_click ' + this.class;
        if(this.menuOpen) {
            return css + ' slds-is-open';
        } else {
            return css;
        }
    }

    @api
    get dropDownCss() {
        return 'slds-dropdown slds-dropdown_' + this.align + ' slds-dropdown_' + this.size;
    }

}