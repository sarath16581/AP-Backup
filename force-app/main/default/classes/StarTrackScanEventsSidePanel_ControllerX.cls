/**
 ** Description: Controller for StarTrackScanEventsSidePanel page
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: NOV.25.2015
 ** History:--------------------------------------------
 **         NOV.25.2015 David Catindoy - Created
 **/
global class StarTrackScanEventsSidePanel_ControllerX {

    public Case caseRecord {get; set;}
    public List<String> conEventColumnFields {get; set;}
    public List<String> labelEventColumnFields {get; set;}
    public List<String> queryFields {get; set;}
    public List<Article__c> childConsignments {get; set;}
    public List<EventMessage__c> consignmentEvents {get; set;}
    public List<EventMessage__c> labelEvents {get; set;}
    public String conSortBy {get; set;}
    public String labelSortBy {get; set;}
    public String conOrder {get; set;}
    public String labelOrder {get; set;}
    public String prevConSortBy {get; set;}
    public String prevLabelSortBy {get; set;}
    public String reqTimeStamp {get; set;}
    public String respTimeStamp {get; set;}
    public String consignmentLastUpdateDate {get; set;}

    StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

    // Web service stub
    wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
    AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = new AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();

    // Web service response
    wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse;

    // Web service
    wwwAuspostComAuSchemaCustomercarema.Header header;
    wwwAuspostComAuSchemaCustomercarema.SearchRequest request;

    public String startTime {get; set;}

    public StarTrackScanEventsSidePanel_ControllerX(ApexPages.StandardController controller) {

        startTime = StarTrackIntegrationLogging.timeNowFormatted();

        if(!Test.isRunningTest()){
            controller.addFields(new List<String>{'Id', 'Network__c', 'ArticleTest__c', 'ArticleTest__r.ArticleID__c'});
        }
        caseRecord = (Case) controller.getRecord();
        conEventColumnFields = new List<String>();
        labelEventColumnFields = new List<String>();
        queryFields = new List<String>();
        childConsignments = new List<Article__c>();
        consignmentEvents = new List<EventMessage__c>();
        labelEvents = new List<EventMessage__c>();
        conSortBy = 'ActualDateTime__c';
        labelSortBy = 'ActualDateTime__c';
        prevConSortBy = '';
        prevLabelSortBy = '';
        conOrder = 'ASC';
        labelOrder = 'DESC';
        // Get consignment event column fields
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Consignment_Events').getFields()){
            conEventColumnFields.add(fsm.getFieldPath());
        }

        // Get event per label column fields
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Event_per_Label').getFields()){
            labelEventColumnFields.add(fsm.getFieldPath());
        }

        Set<String> feedFilter = new Set<String>{'ActualDateTime__c', 'Facility__c', 'Id', 'Article__r.Name','Article__r.Additionals__c'};
        feedFilter.addAll(conEventColumnFields);
        feedFilter.addAll(labelEventColumnFields);
        queryFields.addAll(feedFilter);

        if(caseRecord.ArticleTest__c != null){
            searchLocalEventMessages();
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will perform web call out Event Message search on page load
    Inputs:
    Returns:
    History:
    February 19, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void searchEventMessagesOnLoad(){
        try{
            if(stSettings.Get_Latest_Scan_Events_On_Load__c && String.isNotBlank(caseRecord.ArticleTest__r.ArticleID__c)
                    && StarTrackConsignmentSearchUtil.isWaitDone(caseRecord.ArticleTest__r.ArticleID__c)){
                StarTrackConsignmentSearchUtil.searchConsignment(caseRecord.ArticleTest__r.ArticleID__c, 'EVENTS', Date.today(), Date.today(), Date.today(), 'test');
                searchLocalEventMessages();
            }
        }
        catch(Exception e){
            GlobalUtility.logMessage('ERROR', 'StarTrackScanEventsSidePanel_ControllerX', 'searchEventMessagesOnLoad', '', 'Exception', e.getMessage(), '', e, 0);
            if(e.getMessage().contains('Time out')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues('Search Scan Event Timeout').Field_Name__c));
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will perform web call out Event Message search
    Inputs:
    Returns:       Continuation
    History:
    February 18, 2016 - Patrick James Franco - Created
    February 24, 2016 - Patrick James Franco - Added authentication to web callout
    ------------------------------------------------------------*/
    public Continuation searchEventMessages(){
        try{
            // Check if there is a callout search type
            if(stSettings.Get_Latest_Scan_Events__c && String.isNotBlank(caseRecord.ArticleTest__r.ArticleID__c)){
                header = new wwwAuspostComAuSchemaCustomercarema.Header();
                DateTime nowDT = DateTime.now();
                header.TimeStamp = nowDT;
                header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format('YYYYMMddHHmmss');
                header.SourceId = 'Salesforce';
                header.Action = 'Search';

                request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
                request.Date_x = DateTime.now();
                request.Header = header;
                //request.Suburb = searchSuburb;
                request.Type_x = 'EVENTS';
                request.Value = caseRecord.ArticleTest__r.ArticleID__c;
                if(stSettings.Get_All_Consignment_Details__c){
                    request.Action = 'FULL';
                }
                else{
                    request.Action = 'SUMMARY';
                }

                String endpoint = '';
                Map<String,String> httpHeaders = new Map<String,String>();
                String clientCert = '';

                // Basic Authentication
                if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                    endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                    httpHeaders.put('Authorization','Basic ' + stSettings.StarTrack_ConSearch_BA_Password__c);
                }
                // Certificate
                else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
                    endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                    clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                }

                // Continuation
                if(stSettings.Use_Continuation_for_Consignment_Search__c){
                    emsAsyncStub.endpoint_x = endpoint;
                    if(!httpHeaders.isEmpty()){
                        emsAsyncStub.inputHttpHeaders_x = httpHeaders;
                    }
                    if(String.isNotBlank(clientCert)){
                        emsAsyncStub.clientCertName_x = clientCert;
                    }

                    Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
                    cont.continuationMethod = 'processLatestEventMessages';
                    reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                    emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);

                    return cont;
                }
                // Standard
                else{
                    emsStub.endpoint_x = endpoint;
                    if(!httpHeaders.isEmpty()){
                        emsStub.inputHttpHeaders_x = httpHeaders;
                    }
                    if(String.isNotBlank(clientCert)){
                        emsStub.clientCertName_x = clientCert;
                    }

                    emsStub.timeout_x = Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c * 1000);
                    processLatestEventMessages();
                }
            }
        }
        catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackScanEventsSidePanel_ControllerX', 'searchEventMessages', '', 'CalloutException', e.getMessage(), String.valueOf(request), e, 0);
            if(e.getMessage().contains('Time out')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues('Search Scan Event Timeout').Field_Name__c));
            }
            else if(e.getMessage().contains('Failed to get next element') || e.getMessage().contains('Policy Falsified')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            }
            else if(e.getMessage().contains('Could not find client cert with dev name')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            }

            // Continue local search
            searchLocalEventMessages();
        }

        return null;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will process the callout response from a Event Message search
    Inputs:
    Returns:
    History:
    February 18, 2016 - Patrick James Franco - Created
    February 24, 2016 - Patrick James Franco - Added authentication to web callout
    ------------------------------------------------------------*/
    public Object processLatestEventMessages(){
        try{
            if(stSettings.Use_Continuation_for_Consignment_Search__c){
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse('StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', request.Value, 'INT-REQ - processLatestEventMessages', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse('StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', request.Value, 'INT-RES - processLatestEventMessages', respTimeStamp, emsAsyncResponse.getValue());
                }

                StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), caseRecord.ArticleTest__r.ArticleID__c, 'EVENTS');
            }
            else{
                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsResponse = emsStub.Search_x(request);
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse('StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', request.Value, 'INT-REQ - processLatestEventMessages', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse('StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', request.Value, 'INT-RES - processLatestEventMessages', respTimeStamp, emsResponse);
                }

                StarTrackConsignmentSearchUtil.processResponse(emsResponse, caseRecord.ArticleTest__r.ArticleID__c, 'EVENTS');
            }

            // Perform local search
            searchLocalEventMessages();
        }
        catch(CalloutException e){
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', request.Value, 'INT-REQ - processLatestEventMessages - ERROR', reqTimeStamp, request);
            }
            GlobalUtility.logMessage('ERROR', 'StarTrackScanEventsSidePanel_ControllerX', 'processLatestEventMessages', '', 'CalloutException', e.getMessage(), '', e, 0);
            if(e.getMessage().contains('Time out')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues('Search Scan Event Timeout').Field_Name__c));
            }

            // Continue local search
            searchLocalEventMessages();
        }

        return null;
    }

    public void searchLocalEventMessages(){
        //Removed sorting logic as per W-000856
        // Sorting logic
        /*if(String.isNotBlank(labelSortBy)){
            // Change sort direction
            if(labelSortBy.equals(prevLabelSortBy)){
                labelOrder = (labelOrder == 'DESC') ? 'ASC' : 'DESC';
            }
            else{
                prevLabelSortBy = labelSortBy;
                labelOrder = 'DESC';
            }
        }

        if(String.isNotBlank(conSortBy)){
            // Change sort direction
            if(conSortBy.equals(prevConSortBy)){
                conOrder = (conOrder == 'ASC') ? 'DESC' : 'ASC';
            }
            else{
                prevConSortBy = conSortBy;
                conOrder = 'ASC';
            }
        }*/

        List<SortWrapper> wrapper = new List<SortWrapper>();
        labelEvents = new List<EventMessage__c>();
        String consignmentQuery = 'SELECT Id, Consignment__c';
        String eventQuery = '';
        if(!queryFields.isEmpty()){
            consignmentQuery += ', (SELECT ' + String.join(queryFields, ',') + ' FROM Event_Messages__r WHERE Scan_Type__c = \'Label\' ORDER BY ActualDateTime__c DESC)';
            //eventQuery += 'SELECT ' + String.join(queryFields, ',') + ' FROM EventMessage__c WHERE Scan_Type__c = \'Consignment\' AND Article__c = \'' + caseRecord.ArticleTest__c + '\' ORDER BY ' + conSortBy + ' ' +conOrder+'';
            eventQuery += 'SELECT ' + String.join(queryFields, ',') + ' FROM EventMessage__c WHERE Scan_Type__c = \'Consignment\' AND Article__c = \'' + caseRecord.ArticleTest__c + '\' ORDER BY ActualDateTime__c ASC';
        }
        consignmentQuery += ', Name, Consignment__r.Last_Update_Received__c, Additionals__c FROM Article__c WHERE Consignment__c = \'' + caseRecord.ArticleTest__c + '\'';

        if(caseRecord.ArticleTest__c != null){
            childConsignments = Database.query(consignmentQuery);
        }

        if(!queryFields.isEmpty()){
            consignmentEvents = Database.query(eventQuery);
        }
        if(childConsignments.size() > 0){
            for(Article__c childCon : childConsignments){
                List<EventMessage__c> eventMessages = childCon.Event_Messages__r;
                if(eventMessages.size() > 0){
                    wrapper.add(new SortWrapper (eventMessages[0], labelSortBy, labelOrder));
                } else {
                    EventMessage__c evMsgWithNoScans = new EventMessage__c(Article__r = childCon, EventDescription__c = stSettings.EventDescforArticlesNotScanned__c, Scan_Count__c = 0);
                    evMsgWithNoScans.Article__c = childCon.Id;
                    wrapper.add(new SortWrapper(evMsgWithNoScans, labelSortBy, labelOrder));
                }
            }
        }
        //wrapper.sort();
        for(SortWrapper wrap : wrapper){
            labelEvents.add(wrap.ev);
        }

        if (!childConsignments.isEmpty()) {
            String lasUpdateStr = (childConsignments[0].Consignment__r.Last_Update_Received__c != null) ? childConsignments[0].Consignment__r.Last_Update_Received__c.format('dd-MMM-YYYY hh:mma') : '';
            consignmentLastUpdateDate = 'Last Update Received: ' + lasUpdateStr;
        }
    }

    global class SortWrapper implements Comparable {

        public EventMessage__c ev {get; set;}
        public String sortBy {get; set;}
        public String sortOrder {get; set;}

        public SortWrapper(EventMessage__c ev, String sortBy, String sortOrder) {
            this.ev = ev;
            this.sortBy = sortBy;
            this.sortOrder = sortOrder;
        }

        global Integer compareTo(Object compareTo) {
            SortWrapper compareToEvent = (SortWrapper)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (String.valueOf(ev.get(''+sortBy)) < String.valueOf(compareToEvent.ev.get(''+sortBy))) {
                if(sortOrder == 'DESC'){
                    returnValue = 1;
                }else{
                    returnValue = -1;
                }
            } else if (String.valueOf(ev.get(''+sortBy)) > String.valueOf(compareToEvent.ev.get(''+sortBy))) {
                if(sortOrder == 'ASC'){
                    returnValue = -1;
                }else{
                    returnValue = 1;
                }
            }
            return returnValue;
        }
    }

    public void logTime(){
        if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
            StarTrackIntegrationLogging.logRequestResponse('PAGE RENDER - START (StarTrackScanEventsSidePanel_ControllerX)', 'StarTrackScanEventsSidePanel_ControllerX', '', 'PAGE RENDER - START', startTime, null);
            StarTrackIntegrationLogging.logRequestResponse('PAGE RENDER - END (StarTrackScanEventsSidePanel_ControllerX)', 'StarTrackScanEventsSidePanel_ControllerX', '', 'PAGE RENDER - END', StarTrackIntegrationLogging.timeNowFormatted(), null);
        }
    }
}