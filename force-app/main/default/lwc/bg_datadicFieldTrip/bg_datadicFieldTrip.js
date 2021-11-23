/**
 * Created by alexvolkov on 3/3/20.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldTripDetails from '@salesforce/apex/BG_DataDictionaryService.getFieldTripDetails';

export default class BgDatadicFieldTrip extends LightningElement {

    @api recordId;

    @track tableData;

    tableDef = [
            { label: 'Report Name', fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'ReportName' }, target: '_blank' }, cellAttributes: { alignment: 'left' }},
            { label: 'Report Date', fieldName: 'CreatedDate', type: 'date', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric',
                                                                                             hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false}, cellAttributes: { alignment: 'left' }},
            { label: 'Populated On', fieldName: 'PopulatedOn', type: 'number', cellAttributes: { alignment: 'left' }},
            { label: 'Populated On %', fieldName: 'PopulatedOnPercent', type: 'percent', typeAttributes: {minimumIntegerDigits: 1, maximumFractionDigits : 2}, cellAttributes: { alignment: 'left' }}
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

     @wire(getFieldTripDetails, {pObjectAPIName : '$objectName', pFieldAPIName : '$fieldName'})
              fieldTripDetails({ error, data }) {
                                  if (data) {
                                      //initialize a temporary object to mutate individual attribute values
                                      let lTableData = [];
                                      data.forEach(function(record) {
                                        let lRow = {};
                                        lRow.ReportName = record.Field_Trip__Object_Analysis__r.Name;
                                        lRow.RecordLink = '/' + record.Id;
                                        lRow.CreatedDate = record.CreatedDate;
                                        lRow.PopulatedOn = record.Field_Trip__Populated_On__c;
                                        lRow.PopulatedOnPercent = record.Field_Trip__Populated_On_Percent__c/100;
                                        lTableData.push(lRow);
                                       });
                                      this.tableData = lTableData.length > 0 ? lTableData : null;
                                  } else if (error) {
                                      this.dispatchEvent(new ShowToastEvent({title: 'Error on field data retrieval',
                                                                             message: 'Unable to retrieve metadata for specified object/field combination: '+ error,
                                                                             variant: 'error',
                                                                                           }),
                                                                                       );
                                  }
                              }
}