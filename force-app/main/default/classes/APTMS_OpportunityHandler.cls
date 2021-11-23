/*
* Created by: Apttus Managed Services
* Created Date: 19/04/2017
* Author: Ravi Chhatrala
* Apttus Case #: 00210442
* Last Modified by: Ravi Chhatrala
* Last Modified Date: 08/05/2017
* 28/05/2020      Lija Jawahar           SOQL Error fix update
*/

/*
* This Handler class is called from 'opportunityTrigger_16112011' trigger of Opportunity object
* This Handler class is developed to update the recordType of Opportunity Product LineItems (OPLs) of all the related proposal of updated Opportunities.
*/

public class APTMS_OpportunityHandler {

    public static final String NEW_CUSTOMER_MAP_KEY = 'New Customer';
    public static final String EXISTING_CUSTOMER_MAP_KEY = 'Existing Customer';

    //To update the recordType of Opportunity Product LineItems (OPLs) of all the related proposal of updated Opportunities.
    public static void updateRecordTypeOfOPLs(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        Set<String> setOppId = new Set<String>();
        List<APT_Opportunity_Product_Line_Item__c> listOPLs = new List<APT_Opportunity_Product_Line_Item__c>();
        Map<String, String> mapOPLRecTypeNameId = new Map<String, String>();

        //Create a list of Opportunities where the Type has been changed
        for(Opportunity oppRec : newList){
            if(oppRec.Type != oldMap.get(oppRec.Id).Type){
                setOppId.add(oppRec.Id);
            }
        }

        //Get all active record types of OPL object
        //28/05/2020 LJ Replaced SOQL with Schema.SobjectType
        Map<String, Schema.RecordTypeInfo> rc = Schema.SObjectType.APT_Opportunity_Product_Line_Item__c.getRecordTypeInfosByDeveloperName();
        for (Schema.RecordTypeInfo rtInfo: rc.values()){
            if(rtInfo.isActive() == true && rtInfo.getDeveloperName() == APT_Constants.OPPORTUNITY_RECORD_TYPE_NEW_OPPORTUNITY_TYPE){
                mapOPLRecTypeNameId.put(NEW_CUSTOMER_MAP_KEY,rtInfo.getRecordTypeId());
            } else if(rtInfo.isActive() == true && rtInfo.getDeveloperName()  == APT_Constants.OPPORTUNITY_RECORD_TYPE_EXISTING_OPPORTUNITY_TYPE){
                mapOPLRecTypeNameId.put(EXISTING_CUSTOMER_MAP_KEY, rtInfo.getRecordTypeId());
            }
        }

        // 01/06/2020 LJ Only run this SOQL if setOppId is not empty
        if(setOppId.size()> 0) {
            //Get all the OPL which are related to all proposals associated with updated Opportunities
            listOPLs = [
                    SELECT Id, APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Type
                    FROM APT_Opportunity_Product_Line_Item__c
                    WHERE APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c IN :setOppId
            ];
        }

        //Change the RecordType of OPL with respect to corresponding Opportunity
        for(APT_Opportunity_Product_Line_Item__c oplRec : listOPLs){
            if(oplRec.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER){
                oplRec.RecordTypeId = mapOPLRecTypeNameId.get(NEW_CUSTOMER_MAP_KEY);
            } else if(oplRec.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Type == APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER){
                oplRec.RecordTypeId = mapOPLRecTypeNameId.get(EXISTING_CUSTOMER_MAP_KEY);
            }

            //Clear classification picklist value
            oplRec.APT_Classification__c = '';

        }

        //Update the list of OPL if we have records to update
        if(listOPLs.size() > 0){
            update listOPLs;
        }
    }
}