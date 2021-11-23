/*
* @author       : Jansi Rani. jansi.rani@auspost.com.au
* @date         : 05/10/2020
* @description  : Component for display a Content Document (File).
--------------------------------------- History --------------------------------------------------
05.10.2020    Jansi Rani   Created
25-11-2020    avula.jansirani@auspost.com.au       removed console.log lines
*/
import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';
import GLOBAL_ASSETS_URL from '@salesforce/resourceUrl/GlobalAssets';

export default class BspContentDocumentRow extends LightningElement {
    _firstRender = false;


    @api contentVersion;
    @api contentDocIdNLinkedEntityNameMap;
    communityURL;

    get downloadURL(){
        var tempCV = {...this.contentVersion};
        return tempCV.ContentDocumentId ? this.communityURL+'/sfc/servlet.shepherd/document/download/'+tempCV.ContentDocumentId : '#';
    }

    handleDownload() {
        var tempCV = {...this.contentVersion};
        if(tempCV.ContentDocumentId) {
            const url = this.communityURL + '/sfc/servlet.shepherd/document/download/' + tempCV.ContentDocumentId;

            var xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);
            xhr.responseType = 'blob';
            xhr.onload = function () {
                 saveAs(xhr.response, 'report.zip');
            };
            xhr.send();
        }

    }

    async connectedCallback() {
        try {
            this.communityURL = await retrieveBspCommunityURL();
        } catch (er) {
            //console.error(er)
        }
    }

    renderedCallback() {
        if(!this._firstRender) {
            this._firstRender = true;

            loadScript(this, GLOBAL_ASSETS_URL + '/js/filesaver/2.0.4/FileSaver.js');
        }
    }

    get bilingAccName(){
        return this.contentDocIdNLinkedEntityNameMap ? this.contentDocIdNLinkedEntityNameMap[this.contentVersion.ContentDocumentId] : '';
    }
}