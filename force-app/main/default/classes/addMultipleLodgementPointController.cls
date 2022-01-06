/*****************************************************************************************
@description:   Controller class for the 'addLodgementPoint' LWC component &
                'addMultipleLodgementPoint' Aura component
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
10/12/2020   	seth.heang@auspost.com.au			                created
20/07/2021      seth.heang@auspost.com.au                           Update SOQL query on Network Selector Class
27/07/2021      naveen.rajanna@auspost.com.au                       REQ2570601 - Update SOQL query on Network Selector Class
*****************************************************************************************/
public with sharing class addMultipleLodgementPointController {

    @TestVisible private static final String NETWORK_NAME_SEARCH_SUBSTRING = 'DWS';

    /**
     * @description    Method to SOQL query the lodgement point data from the DSR, and return back results as a list
     * @param          String DSR ID, used to query the existing lodgement point data
     * @return         List<SObJectResult> used to display in the table
     */
    @AuraEnabled
    public static List<SObJectResult> onLoadLPdata(String dsrId){
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        Deal_Support_Request__c currentDSR = new Deal_Support_Request__c();
        try{
            // query the DSR and retrieve 'Lodgement_Point_to_Work_Centre_Code__c' based on the DSR ID
            currentDSR = DealSupportRequestsSelector.newInstance().selectById(new Set<Id>{dsrId}).values();

            List<String> parseMapping = new List<String>();
            // Parse the lodgement point and work centre code mapping by line break "\n", and save into a list of String
            if(String.IsBlank(currentDSR.Lodgement_Point_to_Work_Centre_Code__c) == false || currentDSR.Lodgement_Point_to_Work_Centre_Code__c != null){
                parseMapping = currentDSR.Lodgement_Point_to_Work_Centre_Code__c.split('\n');
            }
            Map<String, String> lPWCCMap = new Map<String, String>();
            if(parseMapping.isEmpty() == false){
                for(String lPToWCCLine : parseMapping){
                    // Parse the split apart the lodgement point and work centre code, and save into a map of LP -> WCC
                    List<String> mapTemp = lPToWCCLine.split(':');
                    lPWCCMap.put(mapTemp[0], mapTemp[1]);
                }
                // get Set<String> of the Lodgement Point and Work Centre Code as separate Set
                Set<String> lpSet = new Set<String>(lPWCCMap.keySet());
                Set<String> wccSet = new Set<String>();
                wccSet.addAll(lPWCCMap.values());
                // query the Network based on the lodgement point name and the work centre code
                for(Network__c net: NetworksSelector.newInstance().selectByNameAndOrgId(lpSet, wccSet).values()){
                    // save the results into the custom object for table display
                    sObjectResultList.add(new SObjectResult(net.Name,net.Org_ID__c,net.Network_Address__c, net.Id));
                }
            }
        }catch (Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'CreditDSR_lwcMultiLookupLPController' , 'onLoadLPdata', null, LoggingLevel.ERROR);
        }
        return sObjectResultList;
    }

    /**
     * @description    Method to SOQL query the Network records based on the input in the LWC component's search box
     * @param          List<String> selectedRecId; list of selected record ID 
     * @return         void
     */
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String value, List<String> selectedRecId) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        try{
            // retrieve the filter for organisation unit type from custom setting
            DSR_Settings__c orgUnitTypeCustomSetting = DSR_Settings__c.getInstance();
            List<String> orgUnitTypeList = new List<String>();
            Set<String> orgUnitTypeSet = new Set<String>();
            if(String.ISBLANK(orgUnitTypeCustomSetting.Lodgement_Point_Org_Unit_Type_Filter__c) == FALSE){
                // split unit type code by comma and save into a Set
                orgUnitTypeList = orgUnitTypeCustomSetting.Lodgement_Point_Org_Unit_Type_Filter__c.split(',');
                orgUnitTypeSet.addAll(orgUnitTypeList);
            }

            Set<String> selectedRecIdSet = new Set<String>();
            selectedRecIdSet.addAll(selectedRecId);

            if(selectedRecId == null){
                selectedRecId = new List<String>();
            }

            if(String.isNotEmpty(value)) {
                // perform SOQL search based on the input in the Lodgement Point search box and limit the result to 5 records in the dropdown list
                //REQ2570601
                List<Network__c> networkQuery = NetworksSelector.newInstance(5).selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(
                                                    value.trim(),orgUnitTypeSet, selectedRecIdSet, NETWORK_NAME_SEARCH_SUBSTRING).values();  
                // save results into a custom object for front-end display in the table
                for(Network__c network : networkQuery) {
                    String fieldNamevalue = network.Name;
                    String fieldWCCvalue = network.Org_ID__c;
                    String fieldAddressvalue = network.Network_Address__c;
                    sObjectResultList.add(new SObjectResult(fieldNamevalue,fieldWCCvalue,fieldAddressvalue, network.Id));
                }
            }
        }catch (Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'CreditDSR_lwcMultiLookupLPController' , 'getResults', null, LoggingLevel.ERROR);
        }
        // return results to the LWC/Aura component so they can be displayed in the table
        return sObjectResultList;
    }

    /**
     * @description    Method to update lodgement point to work centre code mapping & update the lodgement point counter on the DSR
     * @param          String dsrId
     * @param          JSON_String of Lodgement point to Work Centre Code mapping
     * @return         void
     */
    @AuraEnabled
    public static void addMultiLodgementPointsWCC(
        String dsrId, String lodgementPointWCCs){
            try{
                // deserialise the JSON and convert to the custom Sboject 
                List<SObjectResult> responseDetail = (List<SObjectResult>)System.JSON.deserialize(lodgementPointWCCs, List<SObjectResult>.class);

                Deal_Support_Request__c curDSR = new Deal_Support_Request__c();

                curDSR = DealSupportRequestsSelector.newInstance().selectById(new Set<Id>{dsrId}).values();
                // get existing value of the lodgment point to work centre code mapping
                String existinglPWCCMapping = curDSR.Lodgement_Point_to_Work_Centre_Code__c;

                // track the count of lodgement point added and stored in 'Lodgement_Point_Counter__c' backend field
                Integer lPcounter = 0;
                // initialise 'Lodgement_Point_to_Work_Centre_Code__c' to blank
                curDSR.Lodgement_Point_to_Work_Centre_Code__c = '';
                for(SObjectResult so: responseDetail){
                    // format the lodgement point and work centre code, and put a line break
                    curDSR.Lodgement_Point_to_Work_Centre_Code__c += so.recName + ':' + so.recWCC + '\n';
                    // increase the count
                    lPcounter++;
                }
                
                // Update the lodgement point counter to the DSR
                curDSR.Lodgement_Point_Counter__c = lPcounter;

                /**
                 * Define a list of DSR for update operation as ApplicationDatabase.getInstance().dmlUpdate() only take List<SObject> as parameter
                 * Though given the business scenario, there can only be a single DSR per operation
                 *  */ 
                List<Deal_Support_Request__c> dsrUpdateList = new List<Deal_Support_Request__c>();
                // add DSR to List for update DML operation
                dsrUpdateList.add(curDSR);
                // update the lodgement point counter and lodgement point to work centre code mapping to the dsr record
                if(dsrUpdateList.size() > 0 && curDSR.Lodgement_Point_to_Work_Centre_Code__c.equals(existinglPWCCMapping) == false){
                    ApplicationDatabase.getInstance().dmlUpdate(dsrUpdateList);
                }
            }catch (Exception ex){
                UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Deal Support Request', 'CreditDSR_lwcMultiLookupLPController' , 'addMultiLodgementPointsWCC', null, LoggingLevel.ERROR);
            }
        }


    /**
     * @description    Method to retrieve the Network object Icon from the Salesforce Tab and display on the LWC component
     *                 Source Code: https://salesforce.stackexchange.com/a/212722
     * @param          String sObjectName; Network__c
     * @return         void
     */
    @AuraEnabled(cacheable=true)
    public static String getIconName(String sObjectName){
        String u;
        try{
            List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
            List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
            List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

            for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

            // check if the object is standard or custom, and build appropriate icon's string
            for(Schema.DescribeTabResult tr : tabDesc) {
                if( sObjectName == tr.getSobjectName() ) {
                    if( tr.isCustom() == true ) {
                        iconDesc.addAll(tr.getIcons());
                    } else {
                        u = 'standard:' + sObjectName.toLowerCase();
                    }
                }
            }
            // query for the image/svg extension and build the correct icon's string for the custom object icon 
            for (Schema.DescribeIconResult ir : iconDesc) {
                if (ir.getContentType() == 'image/svg+xml'){
                    u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                    break;
                }
            }
        }catch (Exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Network__c', 'CreditDSR_lwcMultiLookupLPController' , 'getIconName', null, LoggingLevel.ERROR);
        }
        return u;
    }
    
    // @description Class for custom object used to store and display the data on table
    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public String recWCC;
        @AuraEnabled
        public String recAddress;
        @AuraEnabled
        public Id recId;
        
        public SObJectResult(String recNameTemp, String recWCCTemp, String recAddressTemp, Id recIdTemp) {
            recName = recNameTemp;
            recWCC = recWCCTemp;
            recAddress = recAddressTemp;
            recId = recIdTemp;
        }
    }
}