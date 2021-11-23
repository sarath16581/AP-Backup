/**
 * @description Base component of Bulk Upload application which loads external dependencies.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created
 */
import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import PAPAPARSE from '@salesforce/resourceUrl/papaparse';

export default class BulkUploadBase extends LightningElement {

    resourcesLoaded;

    loadScripts() {
        if(!this.resourcesLoaded) {
            loadScript(this, PAPAPARSE).then(()=>{
                this.resourcesLoaded=true;
            });
        }
    }

    get hasExternalLibrariesLoaded() {
        return this.resourcesLoaded;
    }

}