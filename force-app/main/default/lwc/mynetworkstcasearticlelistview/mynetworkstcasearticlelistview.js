import { LightningElement, wire, track, api } from 'lwc';
import getArticles from '@salesforce/apex/MyNetworkSTCaseArticlesController.getArticles';
import createCaseInv from '@salesforce/apex/MyNetworkSTCaseArticlesController.createCaseInv';
import getNetworksFromEventMessage from '@salesforce/apex/MyNetworkSTCaseArticlesController.getNetworksFromEventMessage';
import fetchCriticalIncident from '@salesforce/apex/MyNetworkSTCaseArticlesController.fetchCriticalIncidents';





const columns = [
    {label: 'Article Name', fieldName: 'Id', type: 'link', linkLabel: 'Name', 
     sortable: true},
     {label: 'Last AP Network Scan', fieldName: 'Network__c', type: 'pill', linkLabel: 'ntwname',sortable: true},
     {label: 'Last Event Description', fieldName: 'EventDescription', type: 'text', linkLabel: 'EventdescName'},
     {label: 'Last Scan Date', fieldName: 'ActualDateTime', type: 'date', linkLabel: 'EventLastActualDate'}
    
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
    existingCaseInv;
    showData = false;
    showToast = false;
    showSuccess = false;
    showerror = false;
    errorMessage; 
    successMessage;
    @track criticalIncidents = [];
 
    connectedCallback(){
        this.getArticles_();
    }
      
    @wire(fetchCriticalIncident)
    fetchCI(result){
        if(result.data){
            debugger;
            this.criticalIncidents = result.data;
            console.log('ci==>',this.criticalIncidents);
        }else{
            this.error = result.error;
        }       
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
            this.arts = [];
            
            for(let i=0; i<data.length; i++){
                let obj = {...data[i]};                 
                this.arts.push(obj);
            }
            this.showTable = true;
            this.isLoading = false;
        })
        .catch(error=>{
            this.error = JSON.stringify(error);
            this.showTable = false;
            this.showData = false;
            this.isLoading = false;
        });       
    }else {
        this.isLoading = false;
        this.showTable = false;
        this.showData = false;
    }    
}).catch(error => {
    this.error = JSON.stringify(error);
    this.showData= false;
    this.isLoading = false;
}) 
}

    handleRowSelection(event){
        console.log('Records selected***'+JSON.stringify(event.detail));
    }


    saveCaseInv(event){
        this.loadMessage = 'Saving...';
        this.isLoading = true;
        this.error = '';
        if(event.detail !== undefined && event.detail !== null && event.detail.length > 0){
            createCaseInv({recsString: JSON.stringify(event.detail), recordId : this.recordId})
            .then(response=>{
                if(response==='success') {
                    this.getArticles_();
                    this.isLoading = false;
                    this.successMessage = 'Case investigation saved successfully.';
                    this.showSuccess = true;
                    this.showToast = true;
                    this.showerror = false;
                    setTimeout(() => {
                        eval("$A.get('e.force:refreshView').fire();");
                   }, 1000);
                } else if(response === 'error'){
                    this.errorMessage = 'There is already existing case investigation for this article and this network, please check the related case investigation list for latest status.';
                    this.showerror = true;
                    this.showToast = true;
                    this.showSuccess = false;
                    this.isLoading = false; 
                    }
            })
            .catch(error=>{
                console.log('recs save error***'+error);
                this.error = JSON.stringify(error);
                this.isLoading = false;
            });
        }
    }
    handleInputChange(event){
        console.log(JSON.stringify(event.target.dataset), JSON.stringify(event.target.value));
        if(event.target.dataset.id === 'subject'){
            this.subject = event.target.value
        }else if(event.target.dataset.id === 'comment'){
            this.comments = event.target.value
        }
    }
    handleClose(){
        this.showToast = false;
    }
    handleToast(event){
        if(event.detail !== undefined && event.detail !== null){
            this.errorMessage = event.detail.message;
             this.showerror = event.detail.showerror;
            this.showToast = event.detail.showerror;
            this.showSuccess = false; 
        }
       
    }
    
}