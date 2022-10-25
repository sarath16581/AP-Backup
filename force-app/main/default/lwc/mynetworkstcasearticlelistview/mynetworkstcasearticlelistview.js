import { LightningElement, wire, track, api } from 'lwc';
import getNetworks from '@salesforce/apex/MyNetworkSTCaseArticlesController.getNetworks';
import getArticles from '@salesforce/apex/MyNetworkSTCaseArticlesController.getArticles';
import updateRecords from '@salesforce/apex/MyNetworkSTCaseArticlesController.saveRecords';
import getNetworksFromEventMessage from '@salesforce/apex/MyNetworkSTCaseArticlesController.getNetworksFromEventMessage';



const columns = [
    {label: 'Article Name', fieldName: 'Id', type: 'link', linkLabel: 'Name', 
     sortable: true},
     {label: 'Last Event Description', fieldName: 'EventDescription', type: 'text', linkLabel: 'EventdescName',sortable: true},
     {label: 'Last Scan Date', fieldName: 'ActualDateTime', type: 'date', linkLabel: 'EventLastActualDate',sortable: true},
     {label: 'Last AP Network Scan', fieldName: 'Network__c', type: 'pill', linkLabel: 'ntwname',sortable: true}
];
const PAGESIZEOPTIONS = [10,20,40,60,80,100];

export default class Mynetworkstcasearticlelistview extends LightningElement {
    error;
   @track columns = columns;
    arts; //All Articles available for data table 
    showTable = false; //Used to render table after we get the data from apex controller    
    pageSizeOptions = PAGESIZEOPTIONS;
    isLoading = true;
    loadMessage = 'Loading...';
    @api recordId;
    subject;
    comments;
    @wire(getNetworks)
    wntws({error,data}){
        if(data){
            let networks = [];
             console.log('Network Data'+JSON.stringify(data));
            for(let i=0; i<data.length; i++){
                let obj = {value: data[i].Id, label: data[i].Name};
                console.log('networks'+JSON.stringify(networks));
                networks.push(obj);
            }
            this.columns[1].options = networks;
            console.log('columns[1].options'+JSON.stringify(columns[1].options));
        }else{
            this.error = error;
        }       
    }

    connectedCallback(){
        this.getArticles_();
    }

    getArticles_(){
        this.showTable = false;
        this.loadMessage = 'Loading...';
        this.isLoading = true;
        this.error = '';
        getNetworksFromEventMessage({caseId : this.recordId}).then(data => {
            this.showData = data;
            if(this.showData === true){
        getArticles({caseId : this.recordId})
        .then(data=>{
            console.log('Article Data'+JSON.stringify(data));
            this.arts = [];
            
            for(let i=0; i<data.length; i++){
                console.log('loop Article Data'+JSON.stringify(data));
                let obj = {...data[i]};
              
              obj.ntwname = data[i].Network__r.Name;
             //obj.EventdescName = data[i].Event_Messages__r.EventDescription__c;
            // obj.EventLastActualDate=data[i].Event_Messages__r.ActualDateTime__c;
               //obj.ntwname = data[i].Network__c ? data[i].Network__r.Id : "";
                 
                this.arts.push(obj);
            }
            this.showTable = true;
            console.log('showTable***'+JSON.stringify(showTable));
            this.isLoading = false;
        })
        .catch(error=>{
            console.log('showTable***error'+JSON.stringify(error));
            this.error = JSON.stringify(error);
            this.showTable = true;
            this.isLoading = false;
        });       
    }else {
        this.isLoading = false;
        this.showTable = false;
    }    
}).catch(error => {
    console.log('showData***error'+JSON.stringify(error));
    this.error = JSON.stringify(error);
    this.showData = false;
    this.isLoading = false;
}) 
}

    handleRowSelection(event){
        console.log('Records selected***'+JSON.stringify(event.detail));
    }

    saveRecords(event){
        this.loadMessage = 'Saving...';
        this.isLoading = true;
        this.error = '';
        updateRecords({recsString: JSON.stringify(event.detail)})
        .then(response=>{
            if(response==='success') this.getArticles_();
        })
        .catch(error=>{
            console.log('recs save error***'+error);
            this.error = JSON.stringify(error);
            this.isLoading = false;
        });
    }
}