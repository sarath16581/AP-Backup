/*
@Description        : Apex class to save, retrieve external object records
@Author             : Ramtej Juloori
@Created            : 04/07/2018

================================ Modification Log =============================== 
Developer Name  Date            Comments

*/
public with sharing class ServiceNow_CreatePageApexController2 {
    /*
     * @description      : Method to update or insert service now case by passing record info in page layout format with values
     * @returns          : String
     * @parametes        : string, string, string
     */

    @AuraEnabled
    public static String save(string fieldMappingString, String objectAPIName, string salesforceId, string salesforceBillingAccount, string recordId) {
        try {
            System.Debug('TWO CALLS: 2');
            List < LayoutAPIRoot.DetailLayoutSection > detWrapList = (List < LayoutAPIRoot.DetailLayoutSection > ) JSON.deserialize(fieldMappingString, List < LayoutAPIRoot.DetailLayoutSection > .class);

            // create the passed object dynamically, in case of passing a null/empty/invalid name would be expected to handeled and thrown TODO: use aura exception
            sObject sobjectRecord = Schema.getGlobalDescribe().get(objectAPIName).newSObject();

            //deserialize the page layout API result with values and traverse to field level information and form sobject to insert or update
            // Layout section
            for (LayoutAPIRoot.DetailLayoutSection detail: detWrapList) {
                // row
                for (LayoutAPIRoot.LayoutRow layoutRow: detail.layoutRows) {
                    //item
                    for (LayoutAPIRoot.LayoutItem layoutItem: layoutRow.layoutItems) {
                        // component
                        for (LayoutAPIRoot.LayoutComponent layoutComponent: layoutItem.layoutComponents) {
                            if (layoutComponent.details != null) {
                                system.debug('type ' + layoutComponent.details.type + ' name ' + layoutComponent.details.name);

                                if ((layoutComponent.details.type == 'String' || layoutComponent.details.type == 'textarea') && layoutComponent.details.value != null) {
                                    sobjectRecord.put(layoutComponent.details.name, layoutComponent.details.value);
                                } 
                                //Commented for now, since there is not usage of fields with below data types
                                /*else if (layoutComponent.details.type == 'datetime' && layoutComponent.details.dateTimevalue != null) {
                                    sobjectRecord.put(layoutComponent.details.name, layoutComponent.details.dateTimevalue);
                                } else if (layoutComponent.details.type == 'date' && layoutComponent.details.dateValue != null) {
                                    sobjectRecord.put(layoutComponent.details.name, layoutComponent.details.dateValue);
                                } else if (layoutComponent.details.type == 'boolean' && layoutComponent.details.booleanValue != null) {
                                    sobjectRecord.put(layoutComponent.details.name, layoutComponent.details.booleanValue);
                                }*/
                            }
                        }
                    }
                }
            }

            if (objectAPIName.equalsIgnoreCase('Service_Now_Case__x')) {
                //get the generic salesforce id field to be stored in service now and pass to Third Party Reference field
                if(ServiceNowUtility.getNameByIdUtility(salesforceId) != null){
                    sobjectRecord.put('Third_Party_Reference__c', ServiceNowUtility.getNameByIdUtility(salesforceId).get('Id'));
                }
                //get the Billing Account no and pass to Billing Account field to store in Service Now
                sobjectRecord.put('Billing_Account__c', salesforceBillingAccount);
            } else if (objectAPIName.equalsIgnoreCase('Service_Now_Case_Comment__x')) {
                //Pass parent case external Id to save into appropriate case 
                if(ServiceNowUtility.getNameByIdUtility(salesforceId) != null){
					sobjectRecord.put('Service_Now_Case__c', ServiceNowUtility.getNameByIdUtility(salesforceId).get('Id'));                    
                }
                else if(salesforceId != null){
                    sobjectRecord.put('Service_Now_Case__c', salesforceId);                    
                }
            }

            system.debug('[ServiceNow_CreatePageApexController2] : save() sobjectRecord = ' + sobjectRecord);
			//Determine the opration in insert or update using recordId
            if (!String.isEmpty(recordId)) {
                sobjectRecord.put('Id', recordId);
            }
            if (!Test.isRunningTest()) {
                //determine whether the operation is update or insert based on the record Id passed
                if (!String.isEmpty(recordId)) {
                    //Update Operation
                    Database.SaveResult saveResult = database.updateImmediate(sobjectRecord);
                    system.debug('In Update123#' + sobjectRecord.Id);
					//Resturn result based on saveResult
                    if (saveResult.isSuccess()) {
                        return sobjectRecord.Id;
                    } else {
                        //Throw AuraHandled Exception to lightning component in case the DML operation fails
                        string errorMessage = saveResult.getErrors()[0].getMessage();
                        system.debug('errorMessage ' + errorMessage);
                        AuraHandledException aurException = new AuraHandledException(errorMessage);
                        aurException.setMessage(errorMessage);
                        throw aurException;
                    }
                } else {
                    //Insert Operation
                    Database.SaveResult saveResult = database.insertImmediate(sobjectRecord);
                    system.debug('In insert123#' + saveResult);

                    if (saveResult.isSuccess()) {
                        system.debug('saveResult '+saveResult);
                        if(objectAPIName.equalsIgnoreCase('Service_Now_Case_Comment__x')){
                            return 'x/service_now_case__x/'+(string) sobjectRecord.get('Service_Now_Case__c');
                        }
                        return sobjectRecord.Id;
                    } else {
                        //Throw AuraHandled Exception to lightning component in case the DML operation fails
                        string errorMessage = saveResult.getErrors()[0].getMessage();
                        system.debug('errorMessage ' + errorMessage);
                        AuraHandledException aurException = new AuraHandledException(errorMessage);
                        aurException.setMessage(errorMessage);
                        throw aurException;
                    }
                }
            } else {
                //Return string in the test class context
                return 'test class insert ';
            }
        } catch (exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[ServiceNow_CreatePageApexController2] : save() exception = ' + ex.getStackTraceString()+' Error message '+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
     * @description      : Method to get the record information for view or edit or create and return in pagelayout API result format
     * @returns          : List<LayoutAPIRoot.DetailLayoutSection>
     * @parametes        : string, string, string, string
     */
    @AuraEnabled
    public static List < LayoutAPIRoot.DetailLayoutSection > getFieldWrapList(string objectAPIName, string recordTypeId, string recordId, string templateId) {
        System.Debug('TWO CALLS: 3');
        // create the passed object dynamically, in case of passing a null/empty/invalid name would be expected to handeled and thrown TODO: use aura exception
        sObject snCase = Schema.getGlobalDescribe().get(objectAPIName).newSObject();
        Map < string, Service_Now_Template_Value__c > templateValues = new Map < string, Service_Now_Template_Value__c > ();
        //query record info to view or edit if record id exists
        if (recordId != '' && recordId != null) {
            if (!Test.isRunningTest()) {
                List < String > fieldNames = new List < String > (Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().keySet());
                String query = ' SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectAPIName + ' WHERE Id = \'' + recordId + '\' LIMIT 1';
                snCase = Database.query(query);
                System.debug('snCase ' + snCase);
            }
        }
        //query template info and assign the values accordingly to the fields if record id doesn't exists and user selects a template
        if (templateId != null) {
            for (Service_Now_Template_Value__c tempValue: [SELECT Id, Field_Name__c, Field_Value__c, Field_Boolean_value__c,
                    Field_Date_time_value__c, Field_Date_value__c, Field_Number_Value__c
            FROM Service_Now_Template_Value__c WHERE Service_Now_Data_Template__c =: templateId AND Object_Name__c =: objectAPIName
            ]) {
                templateValues.put(tempValue.Field_Name__c, tempValue);
            }
        }
        //get layout API information
        HttpRequest req = new HttpRequest();
        //use respective named credentials to query layout API since session id is invalid in case of lightning experience
        if(objectAPIName.equalsIgnoreCase('Service_Now_Case__x')){
			req.setEndpoint('callout:SFDescribeLayoutServiceNowCase' + '/'+recordTypeId);            
        }
        else if(objectAPIName.equalsIgnoreCase('Service_Now_Case_Comment__x')){
            req.setEndpoint('callout:SFDescribeLayoutServiceNowCaseComment' + '/'+recordTypeId);
        }
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = h.send(req);
        system.debug('layout response body' +  res.getBody());
        JSONParser parser = JSON.createParser(res.getBody());
        LayoutAPIRoot root = (LayoutAPIRoot) parser.readValueAs(LayoutAPIRoot.class);
        system.debug('root ' + root.layouts[0].detailLayoutSections);
        //Iterate through pagelayout API result and assign values and other info(required, renderas info, access level) 
        //at field level either from service now or template
        for (LayoutAPIRoot.DetaillayoutSection det: root.layouts[0].editLayoutSections) {
            // make the heading visible for all the sections for edit layouts
            det.useHeading = true;
            for (LayoutAPIRoot.LayoutRow rows: det.layoutRows) {
                for (LayoutAPIRoot.LayoutItem layoutItem: rows.layoutItems) {
                    if (layoutItem.editable) {
                        for (LayoutAPIRoot.LayoutComponent layoutcomp: layoutitem.layoutComponents) {
                            //Get the metadata info for the specific field on how the field to be displayed on page
                            List < External_object_field_override__mdt > fieldOverrideMetadata = [SELECT Id, Render_As__c, 
                                IsRequired__c, IsEditable__c, IsCreatable__c FROM External_object_field_override__mdt WHERE 
                                Field_Name__c =: layoutcomp.details.name AND Object_name__c =: objectAPIName LIMIT 1
                            ];
                            //get the helptext of the field and assign to appropriate wrapper variable
                            string helpText = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(layoutcomp.details.name).getDescribe().getInlineHelpText();//
                            if(helpText != null){
                                layoutcomp.details.helpText = helpText;
                            }
                            //if a metadata is found for the field, define the accessibility, view type into wrapper 
                            //class which will be used in lightning component
                            if (fieldOverrideMetadata != null && fieldOverrideMetadata.size() > 0) {
                                layoutcomp.details.renderAs = fieldOverrideMetadata[0].Render_As__c;
                                system.debug(layoutcomp.details.name + ' in metadata rendered as ' + fieldOverrideMetadata[0].Render_As__c);
                                layoutcomp.details.isEditable = fieldOverrideMetadata[0].IsEditable__c;
                                layoutcomp.details.isCreatable = fieldOverrideMetadata[0].IsCreatable__c;
                                layoutcomp.details.required = fieldOverrideMetadata[0].IsRequired__c;
                                //value assignment according to the data type
                                if (fieldOverrideMetadata[0].Render_As__c == 'Picklist') {
                                    for (External_Object_Field_Picklist_Values__mdt pickList: [SELECT Id, Label, Value__c FROM 
                                                                                                External_Object_Field_Picklist_Values__mdt WHERE
                                                                                                Field__c =: fieldOverrideMetadata[0].Id
                                    ]) {
                                        layoutcomp.details.pickListValues.add(new LayoutAPIRoot.picklistValue(pickList.label, pickList.Value__c));
                                    }
                                }
                            } else {
                                layoutcomp.details.renderAs = layoutcomp.details.type;
                                system.debug(layoutcomp.details.name + ' not in metadata rendered as ' + layoutcomp.details.type);
                                layoutcomp.details.isEditable = true;
                                layoutcomp.details.isCreatable = true;

                            }
                            //Assign values from queried result
                            if (recordId != '' && recordId != null) {
                                //commenting because of non usage of fields of all data types
                                /*if (layoutcomp.details.renderAs == 'datetime') {
                                    layoutcomp.details.dateTimevalue = (dateTime) snCase.get(layoutcomp.details.name);
                                } else if (layoutcomp.details.renderAs == 'date') {
                                    layoutcomp.details.dateValue = (date) snCase.get(layoutcomp.details.name);
                                } else if (layoutcomp.details.renderAs == 'boolean') {
                                    layoutcomp.details.booleanValue = (boolean) snCase.get(layoutcomp.details.name);
                                } else*/ 
                                if (layoutcomp.details.renderAs == 'string' || layoutcomp.details.renderAs == 'Picklist' || 
                                    layoutcomp.details.renderAs == 'textarea' || layoutcomp.details.renderAs == 'Lookup') {
                                        layoutcomp.details.value = (string) snCase.get(layoutcomp.details.name);
                                }
                                if(layoutcomp.details.renderAs == 'Picklist'){
                                    if(layoutcomp.details.pickListValues != null && layoutcomp.details.pickListValues.size() > 0){
                                        string pickSavedValue = (string) snCase.get(layoutcomp.details.name);
                                        for(LayoutAPIRoot.picklistValue pickVal :layoutcomp.details.pickListValues){
                                            if(pickSavedValue != null && pickSavedValue.length() >= 40){
                                                layoutcomp.details.value = pickSavedValue;
                                                break;
                                            }
                                            else if(pickVal.value == pickSavedValue){
                                                layoutcomp.details.value = pickVal.label;
                                                break;
                                            }
                                            else{
                                                layoutcomp.details.value = pickSavedValue;
                                            }
                                        }
                                    }
                                }
                            }
                            //Assign values from template
                            else if (templateId != null && templateId != '') {
                                if (templateValues.containsKey(layoutcomp.details.name)) {
                                    if (layoutcomp.details.renderAs == 'string' || layoutcomp.details.renderAs == 'Picklist' || 
                                        layoutcomp.details.renderAs == 'textarea') {
                                            layoutcomp.details.value = templateValues.get(layoutcomp.details.name).Field_Value__c;
                                    } 
                                    //commenting because of non usage of fields of all data types
                                    /*else if (layoutcomp.details.renderAs == 'datetime') {
                                        layoutcomp.details.dateTimevalue = templateValues.get(layoutcomp.details.name).Field_Date_time_value__c;
                                    } else if (layoutcomp.details.renderAs == 'date') {
                                        layoutcomp.details.dateValue = templateValues.get(layoutcomp.details.name).Field_Date_value__c;
                                    } else if (layoutcomp.details.renderAs == 'boolean') {
                                        layoutcomp.details.booleanValue = templateValues.get(layoutcomp.details.name).Field_Boolean_value__c;
                                    }*/
                                }
                            }
                        }
                    }
                    else{
                        for (LayoutAPIRoot.LayoutComponent layoutcomp: layoutitem.layoutComponents) {
                            if (recordId != '' && recordId != null) {
                                if(layoutcomp.details.name == 'ExternalId'){
                                    layoutcomp.details.value = (string) snCase.get(layoutcomp.details.name);
                                }
                            }
                        }
                    }
                }
            }
        }

        system.debug('root.layouts[0].editLayoutSections ' + root.layouts[0].editLayoutSections);
        List<LayoutAPIRoot.DetailLayoutSection> lst = new List<LayoutAPIRoot.DetailLayoutSection>();
        lst.addAll(root.layouts[0].editLayoutSections);
        lst.addAll(root.layouts[0].detailLayoutSections);
        return lst;
    }

    /*
     * @description      : Method to get the sobject key prefix when object name is passed. 
                           This is used to dynamically identify from for redirecting purpose
     * @returns          : string
     * @parametes        : string
     */
    @AuraEnabled
    public static string getObjectPrefix(string objectName) {
        Map < String, Schema.SObjectType > gd = Schema.getGlobalDescribe();
        Schema.SObjectType s = gd.get(objectName);
        return s.getDescribe().getKeyPrefix();
    }

    /*
     * @description      : Method to get the sobject from the record Id passed
     * @returns          : Sobject
     * @parametes        : string
     */
    @AuraEnabled
    public static string getObjectNameById(string recId) {
        System.Debug('TWO CALLS: 4');
        return ServiceNowUtility.findObjectNameFromRecordIdPrefix(recId);
    }

    /*
     * @description      : Method to validated the user selected record from custom lookup
     * @returns          : boolean
     * @parametes        : string
     */
    @AuraEnabled
    public static boolean validSelectedRecord(string recordId, string objectName) {
        System.Debug('TWO CALLS: 5');
        try {
            string sobjectName = ServiceNowUtility.findObjectNameFromRecordIdPrefix(recordId);
            Sobject checkSobj = Database.query('SELECT Id FROM ' + sobjectName + ' WHERE Id = \'' + recordId + '\' LIMIT 1 ');
            if (checkSobj != null) {
                return true;
            }
            return false;
        } catch (exception ex) {
            return false;
        } 

    }

    /*
     * @description      : Method to get the instancURL of Service now, used to form the Service now case URL
     * @returns          : string
     * @parametes        : NA
     */
    @AuraEnabled
    public static string getServiceNowInstanceURL(){
        AusPostSettings__c connectionDetails = AusPostSettings__c.getInstance('ServiceNowCredentials');
        return connectionDetails.URL__c;
    }

}