/**
 * Created by alexvolkov on 3/3/20.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldUsageDetails from '@salesforce/apex/BG_DataDictionaryService.getFieldUsageDetails';

export default class BgDatadicFieldTrip extends LightningElement {

    @api recordId;

    @track tableData;
    @track showTable = false;
    @track showReports = false;
    @track showReportTypes = false;
    @track showLayouts = true;

    fullTableData;

    tableDef = [
            { label: 'Type', fieldName: 'DependencyType'},
            { label: 'Name', fieldName: 'DependencyLink', type: 'url', typeAttributes: {label: { fieldName: 'DependencyName' }, target: '_blank' }}
        ];

    fieldName;
    objectName;

    @wire(getRecord, {recordId: '$recordId', fields: ['Data_Dictionary_Field__c.Object_API_Name__c', 'Data_Dictionary_Field__c.Field_API_Name__c']})
            wiredRecord({error, data}) {
                    if(data) {
                        this.objectName = data.fields.Object_API_Name__c.value;
                        this.fieldName = data.fields.Field_API_Name__c.value;
                    } else {
                       this.dispatchEvent(new ShowToastEvent({
                                                             title: 'Error on field data retrieval',
                                                             message: 'Unable to retrieve metadata for specified object/field combination',
                                                             variant: 'error',
                                                         }),
                                                     );
                    }
                }

     @wire(getFieldUsageDetails, {pObjectAPIName : '$objectName', pFieldAPIName : '$fieldName'})
              fieldUsageDetails({ error, data }) {
                                  if (data) {
                                      //initialize a temporary object to mutate individual attribute values
                                      let lTableData = [];
                                      this.fullTableData = [];
                                      data.forEach(record => {
                                        let lRow = {};
                                        lRow.DependencyType = record.MetadataComponentType;
                                        lRow.DependencyName = record.MetadataComponentName;
                                        lRow.DependencyLink = record.MetadataComponentType === 'Layout' ? '/lightning/setup/ObjectManager/' + this.objectName + '/PageLayouts/' + record.MetadataComponentId + '/view' : '/' + record.MetadataComponentId;
                                        if ((this.showReports || record.MetadataComponentType !== 'Report')
                                             && (this.showReportTypes || record.MetadataComponentType !== 'ReportType')
                                             && (this.showLayouts || record.MetadataComponentType !== 'Layout')){
                                             lTableData.push(lRow);
                                             }
                                        this.fullTableData.push(lRow);
                                       });
                                      this.tableData = lTableData.length > 0 ? lTableData : null;
                                      this.showTable = this.fullTableData.length > 0;
                                  } else if (error) {
                                      this.dispatchEvent(new ShowToastEvent({title: 'Error on field data retrieval',
                                                                             message: 'Unable to retrieve metadata for specified object/field combination: '+ error,
                                                                             variant: 'error',
                                                                                           }),
                                                                                       );
                                  }
                              }

        applyFilters(event){
            this[event.target.name] = event.target.checked;
            this.tableData = this.fullTableData.filter(row => (this.showReports || row.DependencyType !== 'Report')
                                                                          && (this.showReportTypes || row.DependencyType !== 'ReportType')
                                                                          && (this.showLayouts || row.DependencyType !== 'Layout'));
                       }
}