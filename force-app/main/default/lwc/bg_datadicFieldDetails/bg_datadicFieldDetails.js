/**
  * @author       : alex.volkov@auspost.com.au
  * @date         : 27/02/2020
  * @description  : Component exposing field metadata
--------------------------------------- History --------------------------------------------------
27/02/2020   alex.volkov@auspost.com.au    Initial creation
**/

import { LightningElement,api,wire,track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldDetails from '@salesforce/apex/BG_DataDictionaryService.getFieldDetails';

export default class BgDatadicFieldDetails extends LightningElement {

    @api recordId;

    @track fieldData;
    @track fieldName;
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

    @wire(getFieldDetails, {pObjectAPIName : '$objectName', pFieldAPIName : '$fieldName'})
        fieldDetails({ error, data }) {
                            if (data) {
                                //initialize a temporary object to mutate individual attribute values
                                let lFieldData = {};
                                //add a slash in front of Ids to form links
                                Object.keys(data).forEach(function(key) {
                                    lFieldData[key] = ['CreatorLink','LastModifiedLink','DataOwnerLink'].includes(key) ? '/' + data[key] : data[key];
                                    });
                                 this.fieldData = lFieldData;
                            } else if (error) {
                                this.dispatchEvent(new ShowToastEvent({title: 'Error on field data retrieval',
                                                                       message: 'Unable to retrieve metadata for specified object/field combination: '+ error,
                                                                       variant: 'error',
                                                                                     }),
                                                                                 );
                            }
                        }
}