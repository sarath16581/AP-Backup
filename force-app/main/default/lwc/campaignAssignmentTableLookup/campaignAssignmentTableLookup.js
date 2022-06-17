/**
 * @description lookup component created to add lookup types to campaign contact lightning datatable.
 * @author Mathew Jose
 * @date 2021-12-21
 * @group 
 * @changelog
 * 2021-12-21 - Mathew Jose - Created.
 */
 import { api, LightningElement, track, wire } from 'lwc';
 import getSearchResults from '@salesforce/apex/LookupController.getSearchResults'
 export default class CampaignAssignmentTableLookup extends LightningElement {
     //record Id selected
     @api valueId;
     //Object name
     @api objName;
     //Icon to be used for lookup
     @api iconName;
     //@api labelName;
     //Used to set the lookup as non-editable.
     @api readOnly = false;
     //Filters for the SOQL
     @api filters = new Map();
     //Key that can be passed from the parent.
     @api uniqueKey;
     @api placeholder = 'Search';
     @api displayFields = 'Name';
     //Fields to be searched 
     @api fieldsToSearch;
     //Used to generate the label
     @api displayFormat;    
     //Generated label for the record looked up.
     @track label;
     //lookup values
     @api options; 
     //Track if a values is selected.
     @track isValue;
     //Default value based on value Id.
     @track defaultValue;
     //keyword being searched
     searchTerm='';
     //Link to the record.
     href;
 
     //css
     @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
     @track inputClass = '';
 
     connectedCallback() {
         //Setting the default value.
         this.defaultValue = this.valueId;
         //Used to generate label to be shown.
         if (!this.displayFormat) {
             let splitFields = this.displayFields.split(',');
             this.displayFormat = splitFields[0];
         } 
     }
 
     /*Wire methods - using c-lookup controller*/
     @wire(getSearchResults, { searchTerm: '$searchTerm', fieldList: '$displayFields', sobjectName: '$objName', fieldsToSearch: '$fieldsToSearch', filterMap: '$filters'})
     wiredRecords({ error, data }) {
         console.log('Entered serach results here'+JSON.stringify(data));
         if (data) {
             this.error = undefined;
             this.options = [];
             if (this.valueId) {
                 this.selectItem(data[0]);
                 this.options = undefined;
             }else{
                //Set value to false if values are cancelled in the data table.  
                 this.isValue = false;              
                 data.forEach(item => {
                     let option = { ...item };
                     option.label = this.generateLabel(option);
                     this.options.push(option);
                 });
             }
         } else if (error) {
             this.error = error;
         }
     }    
 
     
     handleClick() {
         this.searchTerm = '';
         this.inputClass = 'slds-has-focus';
         this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
     }
 
     /*
     Used to set the selected Id and key based on the record selected by the user from the drop down.
     Event is fired so that the parent components can sense the selection of a value.
     */
     onSelect(event) {
         let ele = event.currentTarget;
         let selectedId = ele.dataset.id;
         let key = this.uniqueKey;
         console.log('key'+key);
         console.log('selectedId'+selectedId);
         this.dispatchEvent(new CustomEvent('valueselect', {
             composed: true,
             bubbles: true,
             cancelable: true,
             detail: {
                 data: { selectedId, key },
             }
         }));
 
         this.options.forEach(option => {
             if (option.Id === selectedId) {
                 this.selectItem(option);
             }
         });
     }
 
     /*
     Used show selection value on screen with the content and styling.
     */
     selectItem(record) {
         this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
         this.label = this.generateLabel(record);
         this.href = '/' + record.Id;
         this.isValue = true;
         this.options = undefined;
     }
 
     /*
     Used to generate the label for the lookup based on the display fields specified.
     */
     generateLabel(record) {
         console.log('record', record);
         let label = this.displayFormat;
         let splitFields = this.displayFields.split(',');
         splitFields.forEach(field => {
             field = field.trim();
             let value;
 
             //logic to handle relationhships in queries
             if (field.indexOf('.') > -1) {
                 let splitRelations = field.split('.');
                 splitRelations.forEach(item => {
                     value = (value ? value[item] : record[item]);
                 });
             } else {
                 value = record[field];
             }
             label = label.replace(field, value);
         });
         return label;
     }
 
     /*
      For tracking the search term in the lightning input.
     */
     onChange(event) {
         console.log('Search term changed'+event.target.value);
         this.searchTerm = event.target.value;
         this.searchObject = {
            searchTerm: this.searchTerm,
            fieldList: this.displayFields,
            sobjectName: this.objName,
            fieldsToSearch: this.fieldsToSearch,
            filterMap: this.filters,
            maxResults: 50
         };
     }
 
     /*
     To handle if the user decide to change the lookup value by removing the pill.
     Event is fired when the pill is removed which will let the parent know.
     */
     handleRemovePill() {
         //remove filter on Id in order to get rid of the filter on default value.
         let {Id, ...rest}  = this.filters;
         this.filters = Object.assign({}, {...rest});
         this.isValue = false;
         this.valueId = '';
         let selectedId = '';        
         let key = this.uniqueKey;
         this.dispatchEvent(new CustomEvent('valueselect', {
             composed: true,
             bubbles: true,
             cancelable: true,
             detail: {
                 data: { selectedId, key },
             }
         }));
     }
 
 }