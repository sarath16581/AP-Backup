/*@File Name		: ServiceNow_LookupListApexController
@Description 		: Apex class for generic record search using SOSL in multiple objects 
@Author				: Ramtej Juloori
@Created			: 10/07/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/
public with sharing class ServiceNow_LookupListApexController {

    /*******************************************************************************************************
     * @method name		: getRecordforAlllookups
     * @description 		: get records for all the lookup objects for a specified object
     * @returns 			: List<SobjectUtilityWrapper.ObjectClass>
     * @parameters		: string, integer, string
     */
    @AuraEnabled
    public static List < SobjectUtilityWrapper.ObjectClass > getRecordforAlllookups(string objectName, integer recLimit, string searchString, string searchObject) {
        List < SobjectUtilityWrapper.ObjectClass > objRecMap = new List < SobjectUtilityWrapper.ObjectClass > ();
        Map < string, Schema.SObjectField > SObjectFieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        SobjectUtilityWrapper.sObjectWrapper sObjectWrapper = new SobjectUtilityWrapper.sObjectWrapper();
        List < SobjectUtilityWrapper.ObjectClass > objectClassList = new List < SobjectUtilityWrapper.ObjectClass > ();
        set < string > searchObjects = new set < string > ();
        if (searchObject != '') {
            //Search Records in selected object
            searchObjects.add(searchObject);
        } else {
            //Search Records in all the lookup fields for the mentioned object
            searchObjects.addAll(SObjectFieldMap.keySet());
        }
        //Iterate through the Lookup fields and grab parent object information
        for (String str: searchObjects) {
            if (string.valueOf(SObjectFieldMap.get(str).getDescribe().getType()) == 'REFERENCE') {
                Schema.DescribeFieldResult f = SObjectFieldMap.get(str).getDescribe();
                for (Schema.SObjectType reference: f.getReferenceTo()) {
                    List < SobjectUtilityWrapper.fieldClass > fieldClassList = new List < SobjectUtilityWrapper.fieldClass > ();
                    SobjectUtilityWrapper.fieldClass fieldClass = new SobjectUtilityWrapper.fieldClass();
                    //Determine fields to be Returned BY SOSL
                    fieldClass.fieldLabel = 'Name';
                    fieldClass.fieldAPIName = 'Name';
                    if (reference.getDescribe().getName() == 'Case') {
                        fieldClass.fieldLabel = 'CaseNumber';
                        fieldClass.fieldAPIName = 'CaseNumber';
                    }
                    if (reference.getDescribe().getName() == 'Billing_Account__c') {
                        SobjectUtilityWrapper.fieldClass fieldClass1 = new SobjectUtilityWrapper.fieldClass();
                        fieldClass1.fieldLabel = 'Billing Account No.';
                        fieldClass1.fieldAPIName = 'LEGACY_ID__c';
                        fieldClassList.add(fieldClass1);
                    }
                    fieldClassList.add(fieldClass);
                    SobjectUtilityWrapper.ObjectClass objectClass = new SobjectUtilityWrapper.ObjectClass();
                    objectClass.objectLabel = reference.getDescribe().getLabel();
                    objectClass.objectAPIName = reference.getDescribe().getName();
                    objectClass.fieldClassList = fieldClassList;
                    objectClassList.add(objectClass);
                }
            }
        }
        sObjectWrapper.ObjectClassList = objectClassList;
        //get the records by passing wrapper info(object name and associated fields) created
        objRecMap = getRecordsGeneric(JSON.serialize(sObjectWrapper), recLimit, searchString);

        return objRecMap;
    }

    /*******************************************************************************************************
     * @method name		: getRecordsGeneric
     * @description 		: get the records by passing wrapper info(object name and associated fields), limit and search string
     * @returns 			: List<SobjectUtilityWrapper.ObjectClass>
     * @parameters		: string, integer, string
     */
    @AuraEnabled
    public static List < SobjectUtilityWrapper.ObjectClass > getRecordsGeneric(string sobjectList, integer recLimit, string searchString) {
        try {
            
            SobjectUtilityWrapper.sObjectWrapper sobWrapinput = (SobjectUtilityWrapper.sObjectWrapper) JSON.deserialize(sobjectList, SobjectUtilityWrapper.sObjectWrapper.class);
            List < SobjectUtilityWrapper.ObjectClass > sobjectWrapperListoutput = new List < SobjectUtilityWrapper.ObjectClass > ();
            //Form the SOSL string by adding the fields, objects, search string passed
            string soslString = 'FIND \'' + searchString + '\' IN ALL FIELDS RETURNING ';
            //Add return objects and corresponding fields to SOSL query using schema retrieved for objects listed in sobjectList
            string returnQueryString = '';
            for (SobjectUtilityWrapper.ObjectClass objClassVar: sobWrapinput.ObjectClassList) {
                returnQueryString += objClassVar.objectAPIName + ' ( ';
                for (SobjectUtilityWrapper.fieldClass fieldClassVar: objClassVar.fieldClassList) {
                    returnQueryString += fieldClassVar.fieldAPIName + ', ';
                }
                returnQueryString = returnQueryString.removeEnd(', ');
                returnQueryString += ' ), ';
            }
            soslString += returnQueryString.removeEnd(', ');
            system.debug('soslString ' + soslString);
            List < List < sObject >> soslResult = search.query(soslString);
            system.debug('soslResult ' + soslResult);
            //Iterate through SOSL result and form wrapper to hold sosl result grouped by object
            for (List < Sobject > sobj: soslResult) {
                if (sobj.size() > 0) {
                    //Form Object wrapper class to fill in SOSL results and sent to lightning component
                    SobjectUtilityWrapper.ObjectClass objWrap = new SobjectUtilityWrapper.ObjectClass();
                    objWrap.objectAPIName = string.valueOf(sobj.getSObjectType());
                    objWrap.objectLabel = string.valueOf(sobj.getSObjectType().getDescribe().getLabel());
                    set < string > fieldLabelSet = new set < string > ();
                    List < SobjectUtilityWrapper.record > recList = new List < SobjectUtilityWrapper.record > ();
                    for (Sobject sob: sobj) {
                        List < SobjectUtilityWrapper.fieldClass > recMapList = new List < SobjectUtilityWrapper.fieldClass > ();
                        SobjectUtilityWrapper.record rec = new SobjectUtilityWrapper.record();
                        for (string str: sob.getPopulatedFieldsAsMap().keySet()) {
                            if (str != 'Id') {
                                //Create Map of FIeldName, values
                                SobjectUtilityWrapper.fieldClass recMap = new SobjectUtilityWrapper.fieldClass();
                                recMap.fieldAPIName = str;
                                recMap.fieldLabel = sob.getSObjectType().getDescribe().fields.getMap().get(str).getDescribe().getLabel();
                                recMap.fieldValue = sob.getPopulatedFieldsAsMap().get(str);
                                recMap.fieldValueId = (ID) sob.getPopulatedFieldsAsMap().get('Id');
                                system.debug('objWrap.objectAPIName ' + objWrap.objectAPIName);
                                if (objWrap.objectAPIName == 'Case') {
                                    recMap.fieldValueName = (string) sob.getPopulatedFieldsAsMap().get('CaseNumber');
                                } else if (objWrap.objectAPIName == 'Billing_Account__c') {
                                    system.debug('inside billing account ');
                                    recMap.fieldValueName = (string) sob.getPopulatedFieldsAsMap().get('LEGACY_ID__c');
                                } else {
                                    recMap.fieldValueName = (string) sob.getPopulatedFieldsAsMap().get('Name');
                                }
                                //Add map to a list
                                recMapList.add(recMap);
                                //set the list to instance of a wrapper class
                                fieldLabelSet.add(recMap.fieldLabel);
                            }
                        }
                        rec.recordMap = recMapList;
                        recList.add(rec);
                        objWrap.fieldLabelSet = fieldLabelSet;
                        objWrap.record = recList;
                    }
                    sobjectWrapperListoutput.add(objWrap);
                }
            }
            system.debug('sobjectWrapperList ' + sobjectWrapperListoutput);
            return sobjectWrapperListoutput;
        } catch (exception ex) {
            system.debug('exception caught at ' + ex.getStackTraceString() + ' message ' + ex.getMessage());
            return null;
        }
    }

}