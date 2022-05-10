/**
 * @description Used for campaign contact assignments extending lightning datatable using custom types (lookup)
 * @author Mathew Jose
 * @date 2021-12-21
 * @group 
 * @changelog
 * 2021-12-21 - Mathew Jose - Created.
 */
 import LightningDatatable from 'lightning/datatable';
 //import the template so that it can be reused
 import LookupTemplate from './lookup-template.html';
 import { loadStyle } from 'lightning/platformResourceLoader';
 import EnhancedDataTableResource from '@salesforce/resourceUrl/CustomDataTable';
 
 export default class CampaignAssignmentDatatable extends LightningDatatable {
     static customTypes = {
         lookup: {
             template: LookupTemplate,
             typeAttributes: ['uniqueId', 'object', 'icon', 'label', 'displayFields', 'displayFormat', 'placeholder', 'filters', 'valueId', 'readOnly','fieldsToSearch']
         }
     };
 
     constructor() {
         super();
         Promise.all([
             loadStyle(this, EnhancedDataTableResource),
         ]).then(() => {})
     }
 }