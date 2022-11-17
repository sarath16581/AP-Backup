import { LightningElement, api,track} from 'lwc';
import { loadStyle, loadScript} from 'lightning/platformResourceLoader';

export default class mynetworkAPAdvanceSearchPopUp extends LightningElement {
    @api rowIndex;
    @api 
    selectedarticle;
    @api relatedoptionswithrowindex;
    @api defaultoptionwithrowindex;
    @track eventmessageList = [];
    @track checkedBoxesIds = [];
    @track selectedNetworks = [];
    @track relatednetworks;
    @track selectedNetworks = [];
    @track defaultoption = [];
    connectedCallback(){
    }
}