import { LightningElement, api,track} from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import CANetworkStyles from '@salesforce/resourceUrl/NetworkSelectionStyle';

export default class Mynetworkapmodalpopup extends LightningElement {

    

    @track value = [];
    @api
    selectedarticle;
    @track relatednetworks;
    @track defaultoption = [];
    showPopUp;
    @track selectedNetworks = [];
    @api rowIndex;
    @api defaultoptionwithrowindex;
    @api relatedoptionswithrowindex;
    @track eventmessageList = [];
    @track checkedBoxesIds = [];
    showSelect = false;
    showRequiredMessage = false;
    @track eventmessageListFinal = [];
    @api criticalincidents = [];
    
    get options() {
        return this.relatednetworks;
    }

    connectedCallback(){
        Promise.all([
            loadStyle(this, CANetworkStyles),
            ]).then(() => {
                console.log(JSON.stringify(this.selectedarticle));
                if(this.relatedoptionswithrowindex != undefined && this.relatedoptionswithrowindex != null){
                    this.relatednetworks = this.relatedoptionswithrowindex.get(this.rowIndex);
                }
                console.log('Related Networks',JSON.stringify(this.relatednetworks));
                if(this.defaultoptionwithrowindex != undefined && this.defaultoptionwithrowindex != null && this.relatednetworks !== undefined && this.relatednetworks !== null){
                    this.defaultoption = [...this.defaultoptionwithrowindex.get(this.rowIndex)];
                    for(let i = 0; i< this.defaultoption.length; i++){
                        this.value.push(this.defaultoption[i].value);
                    }
                    for(let i=0; i < this.value.length; i++){
                        let obj = this.relatednetworks.find(o => o.value===this.value[i]);
                        this.selectedNetworks.push(obj);
                    }
                    
                }
                
                if(this.selectedarticle !== undefined && this.selectedarticle !== null){
                    this.eventmessageList = [...this.selectedarticle.Event_Messages__r];
                    console.log('test',JSON.stringify(this.eventmessageList));
                    if(this.eventmessageList !== undefined && this.eventmessageList !== null && this.eventmessageList.length > 0){
                        this.showSelect = true;
                        for(let j = 0; j < this.eventmessageList.length; j++){
                            let temp = {...this.eventmessageList[j]};
                            if(this.eventmessageList[j].Facility__r !== undefined && this.eventmessageList[j].Facility__r !== null && this.eventmessageList[j].Facility__r.Contact_Facility__c !== undefined && this.eventmessageList[j].Facility__r.Contact_Facility__c !== null && this.eventmessageList[j].Facility__r.Contact_Facility__c == 'MyNetwork'){
                                temp.disabledcheck = false;
                            }else{
                                temp.disabledcheck = true;
                            }
                            //set network name with relative url
                            if(this.eventmessageList[j].Facility__c !== null && this.eventmessageList[j].Facility__c !== undefined){
                                temp.facility = '/'+this.eventmessageList[j].Facility__c;
                            }
                            //assign critical networks
                            temp.criticalIncidentList = [];
                            if(this.criticalincidents !== undefined && this.criticalincidents !== null){
                                let incidentListWrapper =  this.criticalincidents.find(obj => obj.networkOrgId === this.eventmessageList[j].FacilityOrganisationID__c);
                                if(incidentListWrapper && incidentListWrapper.criticalIncidentList){
                                    temp.criticalIncidentList = incidentListWrapper.criticalIncidentList;
                                }           
                            }
                            this.eventmessageListFinal.push(temp);
                        }
                    }else{
                        this.showSelect = false;
                    }
                    console.log('Modal Pop Up Event Message',this.eventmessageList);
    
                }
            });
    }
    handlePopUpClose(event){
        console.log("event pop up close");
        this.dispatchEvent(new CustomEvent('popupclose',{detail: false}));
    }

    handleCheckboxSelect(event){
        console.log(JSON.stringify(event.target.checked));
        console.log('Checkbox select',JSON.stringify(event.target.dataset));
    }
    submitNetworks(){
        this.selectedNetworks = [];
        this.checkedBoxesIds = [...this.template.querySelectorAll('lightning-input')].filter(element => element.checked).map(element => element.dataset.id);
        console.log(JSON.stringify(this.checkedBoxesIds));
        for(let i=0;i<this.checkedBoxesIds.length;i++){
            let obj = this.relatednetworks.find(o => o.value === this.checkedBoxesIds[i]);
            this.selectedNetworks.push(obj);
        }
        console.log("selected Networks are:",JSON.stringify(this.selectedNetworks));
        if(this.selectedNetworks !== undefined && this.selectedNetworks !== null && this.selectedNetworks.length > 0){
            let networkData = { 
                selectedNetwork : this.selectedNetworks,
                rowIndex : this.rowIndex

            }
            this.dispatchEvent(new CustomEvent('networkselect', {detail : networkData}));
        }else{
            this.showRequiredMessage = true;
        }
        
    }

    navigateToCriticalIncident(event) {
    }
}