/**
 *  Type: Controller for Cognition Lightning Component and Cognition VF Pages
 *  History:
 *	 17-05-2018: Created - Subbu C, Gaurav A and Omair A (Salesforce)
 *	 12-09-2018: Modified - H Liyanage : Cognition Phase 2 changes
 *  --------------------------------------------------
 **/
global with sharing class Cognition_Controller {

    public List<Cognition_DataModel.ReportData> reportDataList{get;set;}
    public static String reqGUIDParam{get;set;}
    public static String categoryParam{get;set;}
    public static String categoryNameParam{get;set;}
    public static String seqValueParam{get;set;}
    public static String reportCategory{get;set;}
    public string lcBaseURL {get; set;}
    public Cognition_Controller(){}

    //Account List structure class
    public with sharing class accountList{
        @AuraEnabled public list<String> accName;
        @AuraEnabled public String userName ;
        @AuraEnabled public String errorMsg ;
    }

    /**
     * getAccountString - Retrieves the Accounts authorized for the user
     * Retrieves data from Authorization Rules table and Pilot Accounts Custom Metadata
     * Output - Returns a List of Billing Account Names as Strings
     **/
    @AuraEnabled
    public static accountList getAccountString(){

        CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
        Integer custLimit = Integer.valueOf(customerCognitionSettings.MaxAccountsforCustomer__c);
        Integer internalLimit = Integer.valueOf(customerCognitionSettings.MaxAccountsforInternal__c);
        Integer pilotLimit = Integer.valueOf(customerCognitionSettings.MaxPilotAccountsforInternal__c );
        String authzRectype = String.valueOf(customerCognitionSettings.AuthorizationRuleRecordTypeID__c);

        User currentLoggedUser = [SELECT ID, UserName, Name, ContactId From User WHERE ID=:UserInfo.getUserId() LIMIT 1];
        List<Authorization_Rule__c> BAList = new List<Authorization_Rule__c>();
        List<Cognition_Pilot_Accounts__mdt> pilotAccounts = new List<Cognition_Pilot_Accounts__mdt>();
        List<String> accName = new List<String>();
        accName.add(''+','+customerCognitionSettings.CustomerSelectListOption__c);
        Set<String> AccountNumbers = new Set<String>();
        accountList accList = new accountList();
        accList.UserName = currentLoggedUser.UserName;

        // If Community User, get the related Authz Rules, else get all AuthzRules of Cognition Record Type
        try {
            // If Community User
            If(currentLoggedUser.ContactId!=null){
                BAList = [  SELECT
                            Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Name, AccessRole__c
                            FROM Authorization_Rule__c
                            WHERE AccessRole__c=: Label.Cognition_User
                            AND Contact__c = :currentLoggedUser.ContactId
                            AND RecordTypeId = :authzRectype
                            LIMIT :custLimit ];
            } else {
                // get all AuthzRules of Cognition Record Type
                BAList = [  SELECT Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Name, AccessRole__c
                            FROM Authorization_Rule__c
                            WHERE AccessRole__c=:Label.Cognition_User
                            AND RecordTypeId = :authzRectype
                            LIMIT :internalLimit ];

                //Get pilot accounts
                pilotAccounts =  [  SELECT DeveloperName,Label
                                    FROM Cognition_Pilot_Accounts__mdt
                                    LIMIT :pilotLimit ];

                // prepare pilot account number list
                for(Cognition_Pilot_Accounts__mdt pilotAcc : pilotAccounts) {
                    String pilotAccountNumber = String.valueOf(pilotAcc.DeveloperName);
                    accName.add(pilotAccountNumber.substring(1)+','+pilotAcc.Label);
                    AccountNumbers.add(pilotAccountNumber.substring(1));
                }
            }
        } catch(Exception ex){
            System.debug('ERROR:Failed to get Account list'+ex.getMessage());
        }

        // prepare billing account name
        if(!(BAList.isEmpty() && pilotAccounts.isEmpty())){
            for(Authorization_Rule__c acc : BAList){
                String BillingAccountNumber = String.valueOf(acc.Billing_Account__r.LEGACY_ID__c);
                if(BillingAccountNumber.startsWithIgnoreCase('P') || BillingAccountNumber.startsWithIgnoreCase('T')) {
                    BillingAccountNumber = BillingAccountNumber.substring(1);
                }
                String accIDName = BillingAccountNumber +','+acc.Billing_Account__r.Name;
                if(!AccountNumbers.contains(BillingAccountNumber)) {
                    accName.add(accIDName);
                    AccountNumbers.add(BillingAccountNumber);
                }
            }
            accList.accName = accName;
        } else{
            // if the billing account and pilot acct not found throw the error message
            CognitionAPIs__c CustomersNotFound = CognitionAPIs__c.getInstance('CustomersNotFound');
            accList.accName =null;
            accList.errorMsg = CustomersNotFound.Error_Message__c;
        }
        return accList;
    }

    /**
     * generate requestGUID: GUID will be generated when the user selects the customer from the UI,
     * once the customer is selected then the SubmitQuery request will be sent with the requestGUID,
     * cognition server will query all the data related to the particular customer and cache against the customer
     * every following any request to cognition must contain this requestGUID in order to access the cache
     * and response with requested data
     *
     * @param objInnerController
     */
    @AuraEnabled
    public static void generateRequestGUID(Cognition_Controller.CustomerControllerInnerClass objInnerController){
        Blob aes = Crypto.generateAesKey(128);
        String requestGUID = EncodingUtil.convertToHex(aes);
        objInnerController.rGUID = requestGUID;
    }

    /**
     * load any common configurations for cognition application
     * Community_Base_Url : base url for AP
     * isInternalUser : identify wheather the logged in user is internal or BSP
     * @return
     */
    @AuraEnabled
    public static Cognition_DataModel.Config loadConfigs(){
        try{
            Cognition_DataModel.Config config = new Cognition_DataModel.Config();
            // isInternalUser : identify wheather the logged in user is internal or BSP
            config.isInternalUser = Cognition_Util.isInternalUser();
            // Community_Base_Url : base url for AP
            sObject apCustSsetting = Cognition_Util.getSystemCustomSettingListByName('AusPostSettings__c','BSP_Community_Base_Url');
            config.baseUrl = String.valueOf(apCustSsetting.get('URL__C'));
            config.refreshInterval = Cognition_Util.getRefreshInterval();
            return config;
        } catch(exception e){
            system.debug(' Error: loadConfigs failed, '+e);
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Controller', LightningUtilityController.class.getName(), 'loadConfigs',
                    null, LoggingLevel.ERROR
            );
        }
        return null;
    }

    // Invokes the ReceiverETA Callout
    @AuraEnabled
    public static Object getReceiverETA(String id, String param1){
        Cognition_DataModel.receiverETARequest recvETAReq = new Cognition_DataModel.receiverETARequest();
        recvETAReq.id = id;
        recvETAReq.param1 = param1;
        String requestBody = JSON.serialize(recvETAReq);

        System.debug('jsonRequest>>>'+requestBody);

        // calling ReceiverETA endpoint
        CognitionAPIs__c ReceiverETA = CognitionAPIs__c.getInstance('ReceiverETA');
        String jsonResponse = Cognition_CalloutUtility.executeCallout (
                'POST',
                ReceiverETA.API_Name__c,
                requestBody
        );

        System.debug('1 jsonResponse>>>'+jsonResponse);

        // parse the response
        Cognition_DataModel.receiverETAResponse recvETAResp = (Cognition_DataModel.receiverETAResponse) System.JSON.deserialize(
                jsonResponse,
                Cognition_DataModel.receiverETAResponse.class
        );
        return recvETAResp;
    }

    /**
     * getReportInfoRemotingAsync - Uses Continuation Callout with longer timeout because
     * Report API may take more than 4 seconds.
     **/
    @RemoteAction
    global static Object getReportInfoRemotingAsync(String reqGUID,String category, String categoryName,String seqValue, Integer fromSeq){
        CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
        // prepare request
        Cognition_DataModel.ReportDataRequest objReportDataRequest = new Cognition_DataModel.ReportDataRequest();
        objReportDataRequest.RequestGUID = reqGUID;
        objReportDataRequest.Category = category;
        objReportDataRequest.FromSeq = fromSeq;
        objReportDataRequest.ToSeq = Integer.valueOf(seqValue);
        objReportDataRequest.ClientIpAddress ='::1';
        objReportDataRequest.ClientUserName =UserInfo.getUserName();

        reportCategory = category;
        String requestBody = JSON.serialize(objReportDataRequest);

        Integer timeOut;
        CognitionAPIs__c ReportDataRecord;
        String continuationMethod  = '';

        //set different call back base on the category
        if(Cognition_Util.pickupCategory.contains(category)){
            ReportDataRecord = CognitionAPIs__c.getInstance('PickReportData');
            timeOut = Integer.valueOf(ReportDataRecord.Timeout__c) / 1000;
            continuationMethod = 'PickupReportInfoAsyncCallback';
        } else {
            ReportDataRecord = CognitionAPIs__c.getInstance('ConsignmentReportData');
            timeOut = Integer.valueOf(ReportDataRecord.Timeout__c) / 1000;
            continuationMethod = 'ConsignmentReportInfoAsyncCallback';
        }

        Continuation con = new Continuation(timeOut);
        con.continuationMethod = continuationMethod;


        String authorizationHeader = 'Basic ' + customerCognitionSettings.BasicAuthnHeader__c;
        if(reqGUID != null && reqGUID != '') {
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setBody(requestBody);
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(customerCognitionSettings.EndPoint__c + ReportDataRecord.API_Name__c);

            con.state = con.addHttpRequest(req);

            System.debug('Async Call triggered-Timeout-requestBody ->'+timeOut+'-'+requestBody);

        }
        return con;
    }

    /**
     * ConsignmentReportInfoAsyncCallback - Callback for ReportData Continuation Callout
	 **/
    global static Cognition_DataModel.ReportDataResponse ConsignmentReportInfoAsyncCallback (Object state) {
        HttpResponse response = Continuation.getResponse((String)state);
        String jsonResponse ='';
        Integer statusCode = response.getStatusCode();

        if (statusCode >= 2000) {
            System.debug('Report Data Async Callout Error : ' + statusCode);
            return null;
        }

        jsonResponse = response.getBody();
        System.debug('ConsignmentReportInfoAsyncCallback jsonResponse>>>'+jsonResponse);

        List<List<String>> reportJsonList  = new   List<List<String>>();
        Cognition_DataModel.ReportDataResponse reportWrapper = new Cognition_DataModel.ReportDataResponse();
        List<Cognition_DataModel.ReportData> reportDataLst = new List<Cognition_DataModel.ReportData>();

        if(jsonResponse != null && jsonResponse != ''){
            Cognition_DataModel.ReportDataResponse reportInfo = (Cognition_DataModel.ReportDataResponse) System.JSON.deserialize(jsonResponse, Cognition_DataModel.ReportDataResponse.class);

            for(Cognition_DataModel.ReportData reportData : reportInfo.ReportData){
                //Convert time
                reportData.LastEventDateTime = Cognition_Util.convertTimeStamp(reportData.LastEventDateTime);
                reportData.ReadyTime = Cognition_Util.convertTimeStamp(reportData.ReadyTime);
                reportData.CloseTime = Cognition_Util.convertTimeStamp(reportData.CloseTime);

                reportDataLst.add(reportData);
            }

        }
        reportWrapper.ReportData =  reportDataLst;
        return reportWrapper;
    }
	
     /**
     * PickupReportInfoAsyncCallback - Callback for pickup ReportData Continuation Callout
     * Author: Xiang Zheng
     * Date: 2018-10-03
	 **/
    global static Cognition_DataModel.PickupReportDataResponse PickupReportInfoAsyncCallback (Object state) {
        HttpResponse response = Continuation.getResponse((String)state);
        String jsonResponse ='';
        Integer statusCode = response.getStatusCode();

        if (statusCode >= 2000) {
            System.debug('Pickup Report Data Async Callout Error : ' + statusCode);
            return null;
        }

        jsonResponse = response.getBody();

        List<List<String>> reportJsonList  = new   List<List<String>>();
        Cognition_DataModel.PickupReportDataResponse reportWrapper = new Cognition_DataModel.PickupReportDataResponse();
        List<Cognition_DataModel.PickupReportData> reportDataLst = new List<Cognition_DataModel.PickupReportData>();

        if(jsonResponse != null && jsonResponse != ''){
            Cognition_DataModel.PickupReportDataResponse reportInfo = (Cognition_DataModel.PickupReportDataResponse) System.JSON.deserialize(jsonResponse, Cognition_DataModel.PickupReportDataResponse.class);

            for(Cognition_DataModel.PickupReportData reportData : reportInfo.ReportData){
                //Convert time
                reportData.LastEventDateTime = Cognition_Util.convertTimeStamp(reportData.LastEventDateTime);
                reportData.ReadyTime = Cognition_Util.convertTimeStamp(reportData.ReadyTime);
                reportData.CloseTime = Cognition_Util.convertTimeStamp(reportData.CloseTime);

                reportDataLst.add(reportData);
            }

        }
        reportWrapper.ReportData =  reportDataLst;
        return reportWrapper;
    }
    
    /**
     * getConsignmentDetailsAsync - Retrieves details of a Consignment after clicking on the Google Maps Marker
     * Called by the Google Maps VF Page using Remote Action
     * Input - Request GUID and Consignment ID
     * Output - CustomerViewConInfo object with data to display in the Popup window
    **/
    @RemoteAction
    global static Object getConsignmentDetailsAsync(String reqGUID, String ConsignmentID){
        try {
            CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
            // prepare request
            Cognition_DataModel.ConsignmentInfoRequest objConsignmentInfoRequest = new Cognition_DataModel.ConsignmentInfoRequest();
            objConsignmentInfoRequest.RequestGUID = reqGUID;
            objConsignmentInfoRequest.Consignment = ConsignmentID;
            objConsignmentInfoRequest.ClientIpAddress = '::1';
            objConsignmentInfoRequest.ClientUserName = UserInfo.getUserName();

            String requestBody = JSON.serialize(objConsignmentInfoRequest);
            System.debug('getConsignmentDetailsAsync jsonRequest>>> 1: '+requestBody);
            CognitionAPIs__c ConsignmentInfo = CognitionAPIs__c.getInstance('ConsignmentInfo');
            System.debug('getConsignmentDetailsAsync jsonRequest>>> 2: '+requestBody);
            // make sure timeout is defined in custom setting
            Integer timeOut = Integer.valueOf(ConsignmentInfo.Timeout__c) / 1000;
            System.debug('getConsignmentDetailsAsync jsonRequest>>> 3: '+requestBody);
            String authorizationHeader = 'Basic ' + customerCognitionSettings.BasicAuthnHeader__c;
            System.debug('getConsignmentDetailsAsync jsonRequest>>> 4: '+requestBody);
            Continuation con = new Continuation(timeOut);
            if(reqGUID != null && reqGUID != '') {
                System.debug('getConsignmentDetailsAsync jsonRequest>>> 5: '+requestBody);
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setBody(requestBody);
                req.setHeader('Authorization', authorizationHeader);
                req.setHeader('Content-Type', 'application/json');
                req.setEndpoint(customerCognitionSettings.EndPoint__c + ConsignmentInfo.API_Name__c);

                con.state = con.addHttpRequest(req);
                con.continuationMethod = 'consDetailsAsyncCallback';

                System.debug('getConsignmentDetailsAsync: requestBody ->'+requestBody);
            }

            return con;

        } catch(exception e) {
            System.debug('getConsignmentDetailsAsync: exception ->'+e);
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Controller', LightningUtilityController.class.getName(), 'getConsignmentDetailsAsync',
                    null, LoggingLevel.ERROR
            );
        }
        return null;
    }

    /**
     * consDetailsAsyncCallback - Callback for Consignment details Continuation Callout
	 **/
    global static Cognition_DataModel.CustomerViewConInfo consDetailsAsyncCallback (Object state) {
        try{
            HttpResponse response = Continuation.getResponse((String)state);
            String jsonResponse = response.getBody();

            Cognition_DataModel.CustomerViewConInfo customerViewConInfoData = (Cognition_DataModel.CustomerViewConInfo) System.JSON.deserialize(
                    jsonResponse,
                    Cognition_DataModel.CustomerViewConInfo.class);

            System.debug('consDetailsAsyncCallback jsonResponse >>>>>'+jsonResponse);
            String eventDT = customerViewConInfoData.EventDateTime;
            String despatchDT = customerViewConInfoData.DespatchDate;
            String etaDT = customerViewConInfoData.ETADateTime;
            String predictedETADT = customerViewConInfoData.PredictedETADateTime;
            customerViewConInfoData.EventDateTime = Cognition_Util.convertTimeStamp(eventDT);
            customerViewConInfoData.DespatchDate = Cognition_Util.convertTimeStamp(despatchDT);
            customerViewConInfoData.ETADateTime = Cognition_Util.convertTimeStamp(etaDT);
            customerViewConInfoData.PredictedETADateTime = Cognition_Util.convertTimeStamp(predictedETADT);
            System.debug('consDetailsAsyncCallback customerViewConInfoData'+customerViewConInfoData);
            return customerViewConInfoData;
        } catch(exception e) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Controller', LightningUtilityController.class.getName(), 'getConsignmentDetailsAsync',
                    null, LoggingLevel.ERROR
            );
        }
        return null;
    }

    /**
     * getPickupDetailsAsync - Retrieves details of a pickup booking after clicking on the Google Maps Marker
     * Called by the Google Maps VF Page using Remote Action
     * Input - Request GUID and pickup ID
     * Output - CustomerViewPickupInfo object with data to display in the Popup window
    **/
    @RemoteAction
    global static Object getPickupDetailsAsync(String reqGUID, String PickupID){
        try {
            CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
            // prepare request
            Cognition_DataModel.PickupInfoRequest objPickupInfoRequest = new Cognition_DataModel.PickupInfoRequest();
            objPickupInfoRequest.RequestGUID = reqGUID;
            objPickupInfoRequest.BookingNbr = PickupID;
            objPickupInfoRequest.ClientIpAddress = '::1';
            objPickupInfoRequest.ClientUserName = UserInfo.getUserName();

            String requestBody = JSON.serialize(objPickupInfoRequest);
            System.debug('jsonRequest>>> getPickupDetailsAsync '+requestBody);
            CognitionAPIs__c pickupInfoAPI = CognitionAPIs__c.getInstance('PickupInfo');
            // make sure timeout is defined in custom setting
            Integer timeOut = Integer.valueOf(pickupInfoAPI.Timeout__c) / 1000;
            String authorizationHeader = 'Basic ' + customerCognitionSettings.BasicAuthnHeader__c;

            Continuation con = new Continuation(timeOut);

            if(reqGUID != null && reqGUID != '') {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setBody(requestBody);
                req.setHeader('Authorization', authorizationHeader);
                req.setHeader('Content-Type', 'application/json');
                req.setEndpoint(customerCognitionSettings.EndPoint__c + pickupInfoAPI.API_Name__c);

                con.state = con.addHttpRequest(req);
                con.continuationMethod = 'pickupDetailsAsyncCallback';

                System.debug('getPickupDetailsAsync:' +requestBody);
            }
            return con;
        } catch(exception e) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Controller', LightningUtilityController.class.getName(), 'getPickupDetailsAsync',
                    null, LoggingLevel.ERROR
            );
        }
        return null;
    }


    /**
     * pickupDetailsAsyncCallback - Callback for pickup details Continuation Callout
	 **/
    global static Cognition_DataModel.CustomerViewPickupInfo pickupDetailsAsyncCallback (Object state) {
        try{
            HttpResponse response = Continuation.getResponse((String)state);
            String jsonResponse = response.getBody();

            Cognition_DataModel.CustomerViewPickupInfo CustomerViewPickupInfoData = (Cognition_DataModel.CustomerViewPickupInfo) System.JSON.deserialize(
                    jsonResponse,
                    Cognition_DataModel.CustomerViewPickupInfo.class);

            String eventDT = CustomerViewPickupInfoData.EventDateTime;
            String readyTime  = CustomerViewPickupInfoData.ReadyTime;
            String closeTime  = CustomerViewPickupInfoData.CloseTime;

            CustomerViewPickupInfoData.EventDateTime = Cognition_Util.convertTimeStamp(eventDT);
            CustomerViewPickupInfoData.ReadyTime = Cognition_Util.convertTimeStamp(readyTime);
            CustomerViewPickupInfoData.CloseTime = Cognition_Util.convertTimeStamp(closeTime);
            System.debug('pickupDetailsAsyncCallback : CustomerViewPickupInfoData>>>>> '+CustomerViewPickupInfoData);
            return CustomerViewPickupInfoData;
        } catch(exception e) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Cognition_Controller', LightningUtilityController.class.getName(), 'getPickupDetailsAsync',
                    null, LoggingLevel.ERROR
            );
        }
        return null;
    }

    /**
     * queryStatusInfo - Checks the progress of the Query submitted earlier
     * Input - Request GUID of the Query
     * Output - queryStatusResponse object to with data to display Progress Bar
     **/
    @AuraEnabled
    public static Cognition_DataModel.queryStatusResponse queryStatusInfo(String reqGUID){//String reqGUID
        System.debug('reqGUID>>>'+reqGUID);
        Cognition_DataModel.queryStatusRequest  qsRequest = new Cognition_DataModel.queryStatusRequest();
        qsRequest.RequestGUID = reqGUID;
        String requestBody = JSON.serialize(qsRequest);
        System.debug('jsonRequest>>>'+requestBody);
        String jsonResponse ='';
        CognitionAPIs__c QueryStatus = CognitionAPIs__c.getInstance('QueryStatus');

        if(reqGUID != null && reqGUID != '')
            jsonResponse = Cognition_CalloutUtility.executeCallout (
                    'POST',
                    QueryStatus.API_Name__c,
                    requestBody
            );

        System.debug('4 jsonResponse>>>'+jsonResponse);
        Cognition_DataModel.queryStatusResponse queryStatusInfoData = (Cognition_DataModel.queryStatusResponse)
                System.JSON.deserialize(jsonResponse,
                        Cognition_DataModel.queryStatusResponse.class);
        System.debug('queryStatusInfoData>>>>>'+queryStatusInfoData);
        return queryStatusInfoData;
    }

    /**
	 * submitQueryRequest - Submits a Query request for a Customer Account
	 * Input - Depot Name, Customer Account Number and Customer Name
	 * Output - InnerClass object that has data to display Progress Bar
	 **/
    @AuraEnabled
    public static Cognition_Controller.CustomerControllerInnerClass submitQueryRequest(String depotName, String customerNumber, String customerName){
        Cognition_Controller.CustomerControllerInnerClass objInnerController = new Cognition_Controller.CustomerControllerInnerClass();
        // generate GUID when the SubmitQueryRequest
        generateRequestGUID(objInnerController);
        // prepare request for callout
        Cognition_DataModel.CustomerViewRequestV2 objCustomerViewRequest = new Cognition_DataModel.CustomerViewRequestV2();
        objCustomerViewRequest.RequestGUID = objInnerController.rGUID;
        objCustomerViewRequest.Account = integer.valueOf(customerNumber);
        objCustomerViewRequest.AccountString = customerNumber;
        objCustomerViewRequest.ClientIpAddress = '::1';
        objCustomerViewRequest.RequestAction = 2;
        objCustomerViewRequest.CustomerName = customerName;
        objCustomerViewRequest.ClientUserName = UserInfo.getUserName();
        objCustomerViewRequest.Depot = depotName;

        String requestBody = JSON.serialize(objCustomerViewRequest);
        CognitionAPIs__c SubmitQuery = CognitionAPIs__c.getInstance('SubmitQuery');

        // send the request
        String jsonResponse = Cognition_CalloutUtility.executeCallout (
                'POST',
                SubmitQuery.API_Name__c,
                requestBody
        );
        System.debug('5 jsonResponse>>>'+jsonResponse);

        // parese the response
        Cognition_DataModel.queryStatusResponse queryResponseData = (Cognition_DataModel.queryStatusResponse)
                System.JSON.deserialize(
                        jsonResponse,
                        Cognition_DataModel.queryStatusResponse.class
                );
        System.debug('queryResponseData>>>>>'+queryResponseData);

        objInnerController.PercentageComplete = queryResponseData.PercentageComplete;
        objInnerController.DisplayMessage = queryResponseData.DisplayMessage;
        return objInnerController;
    }

    /**
     * customerSummaryRequest - Retrieves the Customer Summary data, processes the response,
     * sets the Width percentage of various status types on the Summary Bar.
     * This method is called after verifying the Query is completed.
     * Input - Request GUID
     * Output - InnerClass object that has all the data for Summary Table and the Summary Bar
     **/
    @AuraEnabled
    public static Cognition_Controller.CustomerControllerInnerClass customerSummaryRequest(String reqGUID){
        System.debug('customerSummaryRequest-reqGUID>>>'+reqGUID);
        Cognition_Controller.CustomerControllerInnerClass objInnerController = new Cognition_Controller.CustomerControllerInnerClass();
        Cognition_DataModel.customerSummaryRequestWithRGUID custSummaryReq = new Cognition_DataModel.customerSummaryRequestWithRGUID();
        custSummaryReq.RequestGUID = reqGUID;
        String requestBody = JSON.serialize(custSummaryReq);
        System.debug('customerSummaryRequest-requestBody>>>'+requestBody);
        CognitionAPIs__c CustomerSummary = CognitionAPIs__c.getInstance('CustomerSummary');

        String jsonResponse = Cognition_CalloutUtility.executeCallout ( 'POST',
                CustomerSummary.API_Name__c,
                requestBody);
        System.debug('customerSummaryRequest-jsonResponse>>>'+jsonResponse);
        List<Cognition_DataModel.CustomerViewResponse> customerViewResponseList = (List<Cognition_DataModel.CustomerViewResponse>) System.JSON.deserialize(
                '['+jsonResponse+']',
                List<Cognition_DataModel.CustomerViewResponse>.class);
        List<Cognition_DataModel.DisplayStats> displayStatsList = new List<Cognition_DataModel.DisplayStats>();

        List<Cognition_DataModel.Stats> displayStatsDelivering = new List<Cognition_DataModel.Stats>();
        List<Cognition_DataModel.Stats> displayStatsPending = new List<Cognition_DataModel.Stats>();
        List<Cognition_DataModel.Stats> displayStatsExceptions = new List<Cognition_DataModel.Stats>();
        List<Cognition_DataModel.Stats> displayStillOutstanding = new List<Cognition_DataModel.Stats>();
        List<Cognition_DataModel.Stats> displayPickupBookings = new List<Cognition_DataModel.Stats>();


        List<Cognition_DataModel.cls_Depots> depotList = new List<Cognition_DataModel.cls_Depots>();
        Cognition_DataModel.cls_Depots startDepot = new Cognition_DataModel.cls_Depots();
        List<String> customerStatesStrList = new List<String>();
        CustomerCognitionSettings__c customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
        startDepot.Depot = '';
        startDepot.DepotName = customerCognitionSettings.DepotSelectListOption__c;
        depotList.add(startDepot);


        System.debug('DueNotOnboardAlreadyDelivered>>'+customerViewResponseList[0].DueNotOnboardAlreadyDelivered);
        System.debug('DueOnboardDeliverySuccess>>'+customerViewResponseList[0].DueOnboardDeliverySuccess);
        System.debug('DueOnboardDeliveryFailed>>'+customerViewResponseList[0].DueOnboardDeliveryFailed);
        System.debug('DueOnboardStillOutstanding>>'+customerViewResponseList[0].DueOnboardStillOutstanding);
        System.debug('DueNotOnboard>>'+customerViewResponseList[0].DueNotOnboard);
        System.debug('DueOnboardDeliveryFailureCarded>>'+customerViewResponseList[0].DueOnboardDeliveryFailureCarded);

        objInnerController.deliveredEarly = customerViewResponseList[0].DueNotOnboardAlreadyDelivered;
        objInnerController.deliveredToday = customerViewResponseList[0].DueOnboardDeliverySuccess;
        objInnerController.deliveredUnsuccessful = customerViewResponseList[0].DueOnboardDeliveryFailed;
        objInnerController.onboardForDelivery = customerViewResponseList[0].DueOnboardStillOutstanding;
        objInnerController.notOnboardForDelivery = customerViewResponseList[0].DueNotOnboard;
        objInnerController.delvFailCarded =  customerViewResponseList[0].DueOnboardDeliveryFailureCarded;

        for(Cognition_DataModel.CustomerViewResponse summary : customerViewResponseList){
            for(Cognition_DataModel.DisplayStats displayStats : summary.DisplayStats){
                displayStatsList.add(displayStats);
                if(displayStats.Heading == System.Label.Cognition_SummTableSection1) {
                    displayStatsDelivering = displayStats.Stats;
                } else if(displayStats.Heading == System.Label.Cognition_SummTableSection2) {
                    displayStatsPending = displayStats.Stats;
                } else if(displayStats.Heading == System.Label.Cognition_SummTableSection3) {
                    displayStatsExceptions = displayStats.Stats;
                } else if(displayStats.Heading == System.Label.Cognition_SummTableSection4) {
                    displayStillOutstanding = displayStats.Stats;
                } else if(displayStats.Heading == System.Label.Cognition_SummTableSection5) {
                    displayPickupBookings = displayStats.Stats;
                }
            }
            for(Cognition_DataModel.cls_Depots depot : summary.Depots){
                if(depot.Depot.trim() != '' && depot.DepotName.trim() != ''){
                    depotList.add(depot);
                }
            }
        }

        objInnerController.displayStatsList = displayStatsList;
        objInnerController.displayStatsDelivering = displayStatsDelivering;
        objInnerController.displayStatsPending = displayStatsPending;
        objInnerController.displayStatsExceptions = displayStatsExceptions;
        objInnerController.displayStillOutstanding = displayStillOutstanding;
        objInnerController.displayPickupBookings = displayPickupBookings;

        objInnerController.depotList = depotList;
        Integer deliveryStatSum = 0;
        objInnerController.DueNotOnboardAlreadyDelivered = 0;
        objInnerController.DueOnboardDeliverySuccess = 0;
        objInnerController.DueOnboardDeliveryFailed = 0;
        objInnerController.DueOnboardStillOutstanding = 0;
        objInnerController.DueOnboardDeliveryFailureCarded = 0;

        if(customerViewResponseList[0].DueNotOnboardAlreadyDelivered > 0){
            objInnerController.DueNotOnboardAlreadyDelivered = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueNotOnboardAlreadyDelivered) / customerViewResponseList[0].DueNbr )*100));
            deliveryStatSum += objInnerController.DueNotOnboardAlreadyDelivered;

            System.debug('objInnerController.DueNotOnboardAlreadyDelivered>>'+objInnerController.DueNotOnboardAlreadyDelivered);
        }
        if(customerViewResponseList[0].DueOnboardDeliverySuccess > 0){
            objInnerController.DueOnboardDeliverySuccess = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueOnboardDeliverySuccess) / customerViewResponseList[0].DueNbr )*100));
            deliveryStatSum += objInnerController.DueOnboardDeliverySuccess;
            System.debug('objInnerController.DueOnboardDeliverySuccess>>'+objInnerController.DueOnboardDeliverySuccess);
        }
        if(customerViewResponseList[0].DueOnboardDeliveryFailed > 0){
            objInnerController.DueOnboardDeliveryFailed = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueOnboardDeliveryFailed) / customerViewResponseList[0].DueNbr )*100));
            deliveryStatSum += objInnerController.DueOnboardDeliveryFailed;
            System.debug('objInnerController.DueOnboardDeliveryFailed>>'+objInnerController.DueOnboardDeliveryFailed);
        }
        if(customerViewResponseList[0].DueOnboardDeliveryFailureCarded > 0){
            objInnerController.DueOnboardDeliveryFailureCarded = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueOnboardDeliveryFailureCarded) / customerViewResponseList[0].DueNbr )*100));
            deliveryStatSum += objInnerController.DueOnboardDeliveryFailureCarded;
            System.debug('objInnerController.DueOnboardDeliveryFailureCarded>>'+objInnerController.DueOnboardDeliveryFailureCarded);
        }
        if(customerViewResponseList[0].DueOnboardStillOutstanding > 0){
            objInnerController.DueOnboardStillOutstanding = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueOnboardStillOutstanding) / customerViewResponseList[0].DueNbr )*100));
            deliveryStatSum += objInnerController.DueOnboardStillOutstanding;
            System.debug('objInnerController.DueOnboardStillOutstanding>>'+objInnerController.DueOnboardStillOutstanding);
        }


        Integer total = customerViewResponseList[0].DueNbr - ((customerViewResponseList[0].DueNotOnboardAlreadyDelivered) + (customerViewResponseList[0].DueNotOnboardHeldForCollection));

        objInnerController.notOnboardPer = 0;
        if (customerViewResponseList[0].DueNotOnboard > 0) {
            objInnerController.notOnboardPer = Integer.valueOf(Math.floor((Double.valueOf(customerViewResponseList[0].DueNotOnboard) /total ) * 100));
            System.debug('---notOnboardPer---TOTAL>>'+total);
            System.debug('---notOnboardPer---objInnerController.notOnboardPer>>'+objInnerController.notOnboardPer);
        }
        if ((deliveryStatSum + objInnerController.notOnboardPer) > 100) {
            objInnerController.notOnboardPer = 100 - deliveryStatSum;
            System.debug('---notOnboardPer-SUM Exceeded 100-Deducting sum of other values from 100');
        }
        System.debug('objInnerController.notOnboardPer>>'+objInnerController.notOnboardPer);

        System.debug('objInnerController.displayStatsList ->'+objInnerController.displayStatsList);
        System.debug('objInnerController.depotList ->'+objInnerController.depotList);
        objInnerController.customer_logo = customerViewResponseList[0].customer_logo;
        objInnerController.TotalNbr = customerViewResponseList[0].TotalNbr;
        objInnerController.rGUID = reqGUID;


        System.debug('customerSummaryRequest-objInnerController>>>>>'+objInnerController);
        return objInnerController;
    }

    /**
     * CustomerControllerInnerClass - Inner Class that describes data returned to the Lightning Component
     **/
    public with sharing class CustomerControllerInnerClass{
        @AuraEnabled public String rGUID;
        @AuraEnabled public List<Cognition_DataModel.DisplayStats> displayStatsList{get;set;}
        @AuraEnabled public List<Cognition_DataModel.Stats> displayStatsDelivering{get;set;}
        @AuraEnabled public List<Cognition_DataModel.Stats> displayStatsPending{get;set;}
        @AuraEnabled public List<Cognition_DataModel.Stats> displayStatsExceptions{get;set;}
        @AuraEnabled public List<Cognition_DataModel.Stats> displayPickupBookings{get;set;}
        @AuraEnabled public List<Cognition_DataModel.Stats> displayStillOutstanding{get;set;}

        @AuraEnabled public List<Cognition_DataModel.cls_Depots> depotList{get;set;}
        @AuraEnabled public List<Cognition_DataModel.cls_ConInfo> conInfoList{get;set;}
        @AuraEnabled public Integer DueNotOnboardAlreadyDelivered{get;set;}
        @AuraEnabled public Integer DueOnboardDeliverySuccess{get;set;}
        @AuraEnabled public Integer DueOnboardDeliveryFailed{get;set;}
        @AuraEnabled public Integer DueOnboardStillOutstanding{get;set;}
        @AuraEnabled public Integer DueOnboardDeliveryFailureCarded{get;set;}
        @AuraEnabled public Integer DueNotOnboard{get;set;}
        @AuraEnabled public Integer notOnboardPer{get;set;}
        @AuraEnabled public Integer delvFailCarded{get;set;}
        @AuraEnabled public Integer TotalNbr{get;set;}

        @AuraEnabled public Integer deliveredEarly{get;set;}
        @AuraEnabled public Integer deliveredToday{get;set;}
        @AuraEnabled public Integer deliveredUnsuccessful{get;set;}
        @AuraEnabled public Integer onboardForDelivery{get;set;}
        @AuraEnabled public Integer notOnboardForDelivery{get;set;}
        @AuraEnabled public String customer_logo{get;set;}
        @AuraEnabled public Integer PercentageComplete {get;set;}
        @AuraEnabled public String DisplayMessage {get;set;}
        @AuraEnabled public Boolean isInternalUser {get;set;}
    }

}