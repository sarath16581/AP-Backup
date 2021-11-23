/*
6/4/2018 Disha Kariya - Modified class to add editable feature for NCCC.
24/09/2018 Dilshan Egodawela - bug fix to handle both uppercase and lowercase safedrop off values.
27/02/2019 Disha Kariya - Modified Class to pass Agent Name for updating Delivery Preferences to CRM
16/08/2019 Disha Kariya - Modified class to accept Code for Delivery Preferences.
20/01/2021 Madhuri Awasthi - Modified class when Select option is selected and prevent sending 'Select' to SAP when nothing is saved in Delivery Preference
*/
public with sharing class MyPostDeliveriesController {
    //Declare variables
    //Store external object records in below variable
    @TestVisible public static List<MyPostPreferences__x> allPostPreferences = new List<MyPostPreferences__x>();
    //Store Account and APCN in below variable
    public Account acc {get;set;}
    @TestVisible public static MyPostPreferences__x deliveryPreference{get;set;}
    //Different variables used in VF Page
    Public String message {get; set;}
    Public String img {get ; set;}
    Public Boolean showSetSection {get; set;}
    Public Boolean showEditButton {get; set;}
    Public string selectedDelPref{get;set;}
    public boolean aboveChecked {get; set;}
    public boolean belowChecked {get; set;}
    public boolean safeDropOff {get; set;}
    public String deliveryPreferenceToDisplay {get; set;}

    //Variables used in Apex
    Map<String, String> codeValuesMap;
    Map<String, String> valuesCodeMap;
    List<Delivery_Preference__mdt> deliveryPreferences {
        get {
            //Get Delivery Preference Metadata
            system.debug('#Delivery Preferences');
            if(deliveryPreferences == null) {
                deliveryPreferences = [SELECT id,DeveloperName,MasterLabel, Code__c, Text_to_be_displayed__c
                            FROM Delivery_Preference__mdt];
            }
            return deliveryPreferences;
        }
        set;
    }
    String safeDropTurnedOff = 'x';
    String actualDelPref;
    Boolean actualAC;
    Boolean actualBC;
    String actualAllNotifications;
    String actualParcelLocker;
    String actualTimeBlock;
    Final String MSGSUCCESS = 'Record updated successfully';
    Final String MSGERROR = 'Something went wrong. Please contact System Admin.';
    /**
     * Constructor to initiate values.
     * @param stdController
     */
    public MyPostDeliveriesController(ApexPages.StandardController stdController){
        //Do not display Edit section on load
        showSetSection =false;
        //Get Account
        this.acc = [select Id, APCN__pc from Account where Id = :stdController.getId()];
        //Create Delivery Preference Code Value Map
        codeValuesMap = new Map<String, String>();
        valuesCodeMap = new Map<String, String>();
        for(Delivery_Preference__mdt dp : deliveryPreferences){
            codeValuesMap.put(dp.Code__c.toLowerCase(), dp.Text_to_be_displayed__c);
            valuesCodeMap.put(dp.MasterLabel.toLowerCase(), dp.Code__c.toLowerCase());
        }
        if(acc.APCN__pc != null) {
            //Set Initial values
            setInitialValue(acc.APCN__pc);
            //store existing values
            actualDelPref = selectedDelPref;
            actualAC = aboveChecked;
            actualBC = belowChecked;
            if(deliveryPreference!=null) {
                showEditButton = true; //Display Edit Button if there is result returned from CRM
                //Store Existing Values
                actualAllNotifications = deliveryPreference.AllNotifications__c==null ? '' : deliveryPreference.AllNotifications__c;
                actualParcelLocker = deliveryPreference.ParcelLockerRegistered__c==null ? '' : deliveryPreference.ParcelLockerRegistered__c;
                actualTimeBlock = deliveryPreference.TimeBlockOption__c==null ? '' : deliveryPreference.TimeBlockOption__c;
            }
        }
        System.debug('showSetSection --->'+showSetSection);
        System.debug('deliveryPreference--->'+deliveryPreference);
        System.debug('selectedDelPref--->'+selectedDelPref);

    }
    /**
    * Adding Safe drop options to picklist
    * @return
    */
    Public List<Selectoption> getselectedPreferences(){
        System.debug('<---Inside getselectedPreferences--->');
        List<selectoption> options= new List<selectoption>();
        //Set SELECT if Delivery Preference was never set
        if(selectedDelPref=='--Select--') {
            options.add(new SelectOption('--Select--','--Select--'));
            selectedDelPref = '--Select--';
        }
        //Get values from Metadata
        for(Delivery_Preference__mdt dp :deliveryPreferences) {
            system.debug('dp.Text_to_be_displayed__c--->'+dp.Text_to_be_displayed__c);
            if(selectedDelPref.equalsIgnoreCase('--Select--') && !(dp.Code__c.equalsIgnoreCase(safeDropTurnedOff))) {
                options.add(new selectoption(dp.Code__c.toLowerCase(),dp.Text_to_be_displayed__c));
            }
            else if(selectedDelPref != '--Select--') {
                options.add(new selectoption(dp.Code__c.toLowerCase(), dp.Text_to_be_displayed__c));
            }
        }
        System.debug('selectedDelPref--->'+selectedDelPref);
        return options;
    }
    /**
     * PUSH changes to CRM when saved*
     * @return - PageReference
     */
    public PageReference saveToSAP() {
        System.debug('<---Inside saveToSAP--->');
        try{
            //Check if any thing is changed on Click of Save button
            System.debug('actualDelPref--->'+actualDelPref);
            System.debug('selectedDelPref--->'+selectedDelPref);
            if((!selectedDelPref.equalsIgnoreCase('--select--') && !actualDelPref.equals(selectedDelPref)) || actualAC!=aboveChecked || actualBC!=belowChecked) {
                HttpRequest reqHead = new HttpRequest();
                reqHead.setMethod('HEAD');
                String endPoint;
                //Get custom setting of Authorization details and endpoint
                AusPostSettings__c setting = AusPostSettings__c.getValues('SAP_SearchByProductParameters');
                if (setting != null) {
                    endPoint = setting.URL2__c;
                }
                //Set endpoint for HEAD request to get x-csrf token
                reqHead.setEndpoint(endPoint);
                Blob headerValue = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                reqHead.setHeader('Authorization', authorizationHeader);
                reqHead.setHeader('x-csrf-token', 'fetch');
                Http http = new Http();
                //Send the request to get csrf token
                HTTPResponse resGet = http.send(reqHead);
                //Get the session Id for PUT request
                String cookiesAll = resGet.getHeader('Set-Cookie');
                List<String> cookies = cookiesAll.split(';');
                String cookieSession;
                for (String s : cookies) {
                    //Get SESSION ID for next request
                    if(s.subStringBefore('=').startsWithIgnoreCase('SAP_SESSIONID')) {
                        cookieSession = s;
                    }
                    System.debug('cookieSession--->' + cookieSession);
                }
                system.debug('cookieSession--->' + cookieSession);
                System.debug('cookies--->' + cookies);
                System.debug('resGet.getHeader(x-csrf-token)--->' + resGet.getHeader('x-csrf-token'));
                if(resGet.getStatusCode() == 200) {
                    //Get the token from HEAD request
                    String token = resGet.getHeader('x-csrf-token');
                    //Send a request to update Delivery Preferences in CRM
                    HttpRequest reqPut = new HttpRequest();
                    reqPut.setMethod('PUT');
                    //Set the endpoint
                    endPoint = endPoint + 'MyDeliveryPreferences(\'' + acc.APCN__pc + '\')';
                    reqPut.setEndpoint(endPoint);
                    Blob headerValue1 = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
                    String authorizationHeader1 = 'Basic ' + EncodingUtil.base64Encode(headerValue1);
                    //Set headers for the request
                    reqPut.setHeader('Authorization', authorizationHeader1);
                    reqPut.setHeader('x-csrf-token', token);
                    reqPut.setHeader('Cookie', cookieSession);
                    reqPut.setHeader('Accept', 'application/json');
                    reqPut.setHeader('Content-Type', 'application/json');
                    System.debug('actualDelPref--->' + actualDelPref + '<--selectedDelPref-->' + selectedDelPref);
                    System.debug('actualAC--->' + actualAC + '<--aboveChecked-->' + aboveChecked);
                    System.debug('actualBC--->' + actualBC + '<--belowChecked-->' + belowChecked);
                    String ac = aboveChecked == true ? 'Y' : 'N';
                    String bc = belowChecked == true ? 'Y' : 'N';
                    //Create a payload to set the body
                    Map<String, String> payload = new Map<String, String>{
                            'APCN' => acc.APCN__pc,
                            'SafeDropInstruction' => selectedDelPref.equalsIgnoreCase('--select--') ? '' : selectedDelPref.toUpperCase(),
                            'SafeDropRequester' => UserInfo.getUserId(),
                            'HeightLessThan15M' => ac,
                            'HeightMoreThan05M' => bc,
                            'AllNotifications' => actualAllNotifications,
                            'ParcelLockerRegistered' => actualParcelLocker,
                            'TimeBlockOption' => actualTimeBlock
                    };
                    System.debug('payload--->' + payload);
                    //Serialize the payload
                    reqPut.setBody(JSON.serialize(payload));
                    Http httpPut = new Http();
                    //Send the PUT request to update changes in CRM
                    HttpResponse resPut = httpPut.send(reqPut);
                    System.debug('resPut.getStatusCode()--->' + resPut.getStatusCode());
                    System.debug('resPut.getbody()--->' + resPut.getbody());
                    //System.debug('allPostPreferences[0]--->'+allPostPreferences[0]);
                    //If response is not valid show an error
                    if(resPut.getStatusCode() != 204) {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, MSGERROR));
                    } else {
                        //If successful then set initial values
                        setInitialValue(acc.APCN__pc);
                        System.debug('allPostPreferences[0]--->' + allPostPreferences[0]);
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, MSGSUCCESS));
                    }
                } else {
                    //If head request failed display error message.
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, MSGERROR));
                }
                //Hide edit section and show Edit button
                showSetSection = false;
                showEditButton = true;
                return Null;
            } else {
                //Display message when nothing is changed and clicked on Save
                setInitialValue(acc.APCN__pc);
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, MSGSUCCESS));
                showSetSection = false;
                showEditButton = true;
                return Null;
            }
        }
        catch(Exception exp) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,MSGERROR));
            return Null;
        }
    }

    /**
     * Method to shoe editable section and hide edit button*
     * @return PageReference
     */
    public PageReference editMethod() {
        System.debug('<---Inside editMethod--->');
        showSetSection= true; //Display editable fields
        showEditButton = false; //Hide Edit Button
        System.debug('In Edit showSetSection--->'+showSetSection);
        System.debug('selectedDelPref--->'+selectedDelPref);
        return null;
    }

    /**
    * Method for cancel button to hide editable section and show Edit button*
    * @return PageReference
    */
    public PageReference cancel() {
        allPostPreferences.addAll(new List<MyPostPreferences__x>([select APCN__c, HeightLessThan15M__c, HeightMoreThan05M__c, SafeDropInstruction__c, ParcelLockerRegistered__c from MyPostPreferences__x where APCN__c =: acc.APCN__pc]));
        System.debug('allPostPreferences--->'+allPostPreferences);
        if(allPostPreferences.size() != 0) {
            deliveryPreference= allPostPreferences[0];
            showEditButton = true; // Show Edit Button only if there is Delivery Preference in CRM
        } else {
            showEditButton = false; //Hide Edit Button
        }
        System.debug('<---Inside editMethod--->');
        showSetSection= false; //Hide editable fields
        return null;
    }

    /**
     * Get Initial values form External Data Object*
     * @param void
     */
    public void setInitialValue(String apcn){
        //Get delivery Preference based on APCN
        allPostPreferences.addAll(new List<MyPostPreferences__x>([select APCN__c, AllNotifications__c, HeightLessThan15M__c, HeightMoreThan05M__c, SafeDropInstruction__c, ParcelLockerRegistered__c, TimeBlockOption__c from MyPostPreferences__x where APCN__c =: apcn]));
        System.debug('allPostPreferences--->'+allPostPreferences);
        System.debug('allPostPreferences[0].SafeDropInstruction__c--->'+allPostPreferences[0].SafeDropInstruction__c);
        //Check if details available in CRM
        if(allPostPreferences.size() != 0) {
            deliveryPreference= allPostPreferences[0];
            String safeDropInst;
            //Set initial value of Delivery Preference
            if(deliveryPreference!=null && deliveryPreference.SafeDropInstruction__c != null){
                safeDropInst = deliveryPreference.SafeDropInstruction__c.toLowerCase();
            }
            //Set initial value to SELECT if blank then set to SAFEDROPTURNEDOFF or initial value and get a code value
            selectedDelPref = (deliveryPreference==null || deliveryPreference.SafeDropInstruction__c == null) ? '--Select--' : ((deliveryPreference.SafeDropInstruction__c=='')? safeDropTurnedOff : safeDropInst.length()==1 ? safeDropInst : valuesCodeMap.get(safeDropInst));
            System.debug('valuesCodeMap---->'+valuesCodeMap);
            System.debug('codeValuesMap---->'+codeValuesMap);
            System.debug('safeDropInst---->'+safeDropInst);
            System.debug('selectedDelPref---->'+selectedDelPref);
            safeDropOff = safeDropInst!=null && safeDropInst.length()>1 ? (valuesCodeMap.containsKey(safeDropInst) && valuesCodeMap.get(safeDropInst).equalsIgnoreCase(safeDropTurnedOff) ? true : false ) : ( safeDropInst!=null && safeDropInst.length()==1 ? (safeDropInst.equalsIgnoreCase(safeDropTurnedOff) ? true :false) : false );
            //Set value to display on load page
            deliveryPreferenceToDisplay = codeValuesMap.get(selectedDelPref);
            //Check height if set less than 15M or more than 5M and display image accordingly
            if(deliveryPreference.HeightLessThan15M__c == 'Y' && deliveryPreference.HeightMoreThan05M__c == 'Y') {
                message = System.Label.ParcelLockerBoth;
                img = 'above-and-below.png';
                aboveChecked = true;
                belowChecked = true;
            }
            else if(deliveryPreference.HeightLessThan15M__c == 'Y' && deliveryPreference.HeightMoreThan05M__c == 'N') {
                message = System.Label.ParcelLockerAbove;
                img = 'above.png';
                aboveChecked = true;
            }
            else if(deliveryPreference.HeightLessThan15M__c == 'N' && deliveryPreference.HeightMoreThan05M__c == 'Y') {
                message = System.Label.ParcelLockerBelow;
                img = 'below.png';
                belowChecked = true;
            }
            else if(deliveryPreference.HeightLessThan15M__c == 'N' && deliveryPreference.HeightMoreThan05M__c == 'N'){
                message = System.Label.ParcelLockerNA;
                img = 'no-difficulty.png';
                aboveChecked = false;
                belowChecked = false;
            }
            else {
                message = System.Label.ParcelLockerNeverSet;
                img = 'N-A.png';
                aboveChecked = false;
                belowChecked = false;
            }
        }else {
            // Hide Edit button
            showEditButton = false;
            deliveryPreference = null;}
    }
}