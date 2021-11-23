/**
 * @description Component which allows Bulk Edit capability of Opportunity Products via list button.
 * @author Mathew Jose
 * @date 2021-09-05
 * @changelog
 */
import { LightningElement, track, api , wire} from 'lwc';
import getOppProducts from '@salesforce/apex/APT_OpptyProductListController.getOpptyProducts';
import setOppProducts from '@salesforce/apex/APT_OpptyProductListController.updateOppProducts';

export default class CustomDatatableOnOppProduct extends LightningElement {

    @track data = [];
    //have this attribute to track data changed
    //with custom picklist or custom lookup
    @track draftValues = [];
    @api oppId;
    @api oppName;
    @api isSpinning = false;
    @track tableErrors = { rows: {}, table: {} };
    lastSavedData = [];

    connectedCallback() {
        this.columns = [
            { label: 'Product Name', fieldName: 'ProductName', editable: false, wrapText: true,initialWidth: 160},
            { label: 'Classification', fieldName: 'Classification__c', editable: false,initialWidth: 160},
            { label: 'Growth ?', fieldName: 'Growth', type: 'boolean',editable: true, wrapText: true, initialWidth: 160,
                cellAttributes: { alignment: 'center' }
            },
            { label: 'Quantity', fieldName: 'Quantity', type: 'Integer', editable: true, initialWidth: 160, iconName:'utility:stop'},
            { label: 'Revenue Start Date', fieldName: 'Contract_Start_Date__c', type: 'date-local', editable: true, initialWidth: 160,iconName:'utility:stop'},
            { label: 'Revenue End Date', fieldName: 'Contract_End_Date__c', type: 'date-local', editable: true, initialWidth: 160,iconName:'utility:stop'},
            { label: 'Unit Sales Price (Ex GST)', fieldName: 'UnitPrice', type: 'currency', editable: true ,initialWidth: 160,iconName:'utility:stop',
                cellAttributes: { alignment: 'left' }
            },
            { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency', editable: false,initialWidth: 160,
                cellAttributes: { alignment: 'left' }
            },
            { label: 'Contract Product?', fieldName: 'ContractProduct', type: 'boolean', editable: true, initialWidth: 160,iconName:'utility:stop',
                cellAttributes: { alignment: 'center' }
            },
            { label: 'Quote Number', fieldName: 'Contract_Number__c', type: 'text', editable: true,initialWidth: 160}                 
        ];
        //save last saved copy
        this.lastSavedData = JSON.parse(JSON.stringify(this.data));
    }

    @wire(getOppProducts, {oppId: '$oppId' })
    wiredOppProducts({ data, error }) {
        if (data) {
            // data
            this.data = JSON.parse(JSON.stringify(data));
            console.log('Data Length'+this.data.length);
            this.oppName = this.data[0].Opportunity.Name;
            for (let i = 0; i < this.data.length; i++) {
                this.data[i].ProductName = this.data[i].Product2.Name;
                if(this.data[i].Contract_Product__c == 'Yes'){
                    this.data[i].ContractProduct = true;
                }else{
                    this.data[i].ContractProduct = false;
                }
                if(this.data[i].Change_Classification__c == 'Yes'){
                    this.data[i].Growth = true;
                }else{
                    this.data[i].Growth = false;
                }
            }
        }
        else if (error) {
            window.console.log(error);
        }
    }

    handleSave(event) {
        this.draftValues = event.detail.draftValues;
        this.lastSavedData = JSON.parse(JSON.stringify(this.data));
        this.isSpinning = true;        
        for (let i = 0; i < this.draftValues.length; i++) {
            if(this.draftValues[i].ContractProduct === true){
                this.draftValues[i].Contract_Product__c = 'Yes';
            }else if(this.draftValues[i].ContractProduct === false){
                this.draftValues[i].Contract_Product__c = 'No';
            }
            if(this.draftValues[i].Growth === true){
                this.draftValues[i].Change_Classification__c = 'Yes';
            }else if(this.draftValues[i].Growth === false){
                this.draftValues[i].Change_Classification__c = 'No';
            }                          
        }
        this.updateDataValues(this.draftValues);
        let copyData = [... this.data];
        setOppProducts({ oppProds: copyData })
            .then((result) => {
                result = JSON.parse(result);
                console.log('Result Status'+result.status);                
                if(result.status == 'Success'){
                    this.dispatchEvent(new CustomEvent('navToRelated', 
                    {
                        detail: { recId : this.oppId, relatedName : 'OpportunityLineItems' },
                        bubbles: true,
                        composed: true,
                    }));
                }else{
                    this.isSpinning = false;
                    this.setTableError(result);
                }
            })
            .catch((error) => {
                this.error = error;
            });

    }

    handleCancel(event) {
        //remove draftValues & revert data changes
        this.data = JSON.parse(JSON.stringify(this.lastSavedData));
        this.draftValues = [];
    }
    
    updateDataValues(updateItems) {
        console.log('Entered Update Data Vlues');
        console.log(JSON.stringify(updateItems));
        let copyData = [... this.data];
        for (let i = 0; i < copyData.length; i++) {
            for(let j = 0; j < updateItems.length; j++){
                if(copyData[i].Id === updateItems[j].Id){
                    for(let field in updateItems[j]){
                        if(copyData[i][field] != updateItems[j][field]){
                            copyData[i][field] = updateItems[j][field];
                        }
                    }
                }
            }              
            
        }
        //write changes back to original data
        this.data = [...copyData];
    }    


    setTableError(errorData){
        let errorRows = {};
        errorRows = errorData.rows;
        for(let i=0; i< errorRows.length; i++){
            this.tableErrors.rows[errorRows[i].rowId] = { title: errorRows[i].title, messages: errorRows[i].errorMessages, fieldNames: errorRows[i].fieldNames};
        }
        this.tableErrors.table.title = errorData.table.title;
        this.tableErrors.table.messages = errorData.table.errorMessages;
    }

    handleNavigateToOpp(){
        console.log('Navigate to Opp');
        this.dispatchEvent(new CustomEvent('navToRecord', 
        {
            detail: { recId : this.oppId },
            bubbles: true,
            composed: true,
        }));
    }

    handleNavigateToOppProducts(){
        console.log('Navigate to Opp');
        this.dispatchEvent(new CustomEvent('navToRelated', 
        {
            detail: { recId : this.oppId , relatedName : 'OpportunityLineItems'},
            bubbles: true,
            composed: true,
        }));
    }    
}