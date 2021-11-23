/**
 ** Description: Controller for StarTrackViewAllScanEvents page
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: DEC.11.2015
 ** History:--------------------------------------------
 **         DEC.11.2015 David Catindoy - Created
 **/
global class StarTrackViewAllScanEvents_ControllerX {
    
    public Article__c consignment {get; set;}
    public List<String> queryFields {get; set;}
    public List<String> conSummaryFields {get; set;}
    public List<String> relatedSubdocketFields {get; set;}
    public List<String> relatedPODFields {get; set;}
    public List<String> eventByArticleFields {get; set;}
    public List<Article__c> childConsignments {get; set;}
    public List<EventMessage__c> consignmentEvents {get; set;}
    public List<Sub_Docket__c> relatedSubdockets {get; set;}
    public List<Proof_of_Delivery__c> relatedPODs {get; set;}
    public String consignmentLastUpdateDate {get; set;}
    public boolean isConsole {get; set;}
    public Map<Id, EventMessage__c> lastScanEventByArticle {get; set;}
    
    public StarTrackViewAllScanEvents_ControllerX(ApexPages.StandardController controller) {
        consignment = (Article__c) controller.getRecord();
        queryFields = new List<String>();
        conSummaryFields = new List<String>();
        eventByArticleFields = new List<String>();
        relatedSubdocketFields = new List<String>();
        relatedPODFields = new List<String>();
        childConsignments = new List<Article__c>();
        consignmentEvents = new List<EventMessage__c>();
        relatedSubdockets = new List<Sub_Docket__c>();
        relatedPODs = new List<Proof_of_Delivery__c>();
        isConsole = true;
        
        Set<String> tempFields = new Set<String>{'Id', 'Name', 'Consignment__c', 'ArticleID__c'};
        for(Schema.FieldSetMember fsm : SObjectType.Article__c.FieldSets.getMap().get('StarTrack_Consignment_Summary').getFields()){
            tempFields.add(fsm.getFieldPath());
        }
        conSummaryFields.addAll(tempFields);
        for(Schema.FieldSetMember fsm : SObjectType.Article__c.FieldSets.getMap().get('StarTrack_Events_by_Article').getFields()){
            tempFields.add(fsm.getFieldPath());
        }
        eventByArticleFields.addAll(tempFields);
        
        Set<String> feedFilter = new Set<String>{'Facility__c', 'Id', 'Article__r.Name','Article__r.Additionals__c'};
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_View_All_Consignment_Events').getFields()){
            feedFilter.add(fsm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_View_All_Label_Events').getFields()){
            feedFilter.add(fsm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Consignment_Events_Summary').getFields()){
            feedFilter.add(fsm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fsm : SObjectType.EventMessage__c.FieldSets.getMap().get('StarTrack_Labels_Events_Summary').getFields()){
            feedFilter.add(fsm.getFieldPath());
        }
        
        queryFields.addAll(feedFilter);
        searchEventMessages();
        queryConsignment();

    }
    
    public void searchEventMessages(){
        
        String consignmentQuery = '';
        String eventQuery = '';
        if(eventByArticleFields.size() > 0){
            consignmentQuery += 'SELECT LastScanEventEvMsgMax__c, ' + String.join(eventByArticleFields, ',');
        } else{
            consignmentQuery += 'SELECT Id, Consignment__c';
        }
        if(!queryFields.isEmpty()){
            consignmentQuery += ', (SELECT ' + String.join(queryFields, ',') + ' FROM Event_Messages__r WHERE Scan_Type__c = \'Label\' ORDER BY ActualDateTime__c ASC)';
            eventQuery += 'SELECT ' + String.join(queryFields, ',') + ' FROM EventMessage__c WHERE Scan_Type__c = \'Consignment\' AND Article__c = \'' + consignment.Id + '\' ORDER BY ActualDateTime__c ASC';
        }
        consignmentQuery += ' FROM Article__c WHERE Consignment__c = \'' + consignment.Id + '\'';    

        childConsignments = Database.query(consignmentQuery);

        lastScanEventByArticle = new Map<Id, EventMessage__c>();
        for(Article__c childCon : childConsignments) {
            List<EventMessage__c> eventMessages = childCon.Event_Messages__r;
            if(eventMessages.size() > 0) {
                lastScanEventByArticle.put(childCon.Id, eventMessages.get(eventMessages.size() - 1));
            } else {
                EventMessage__c evMsgWithNoScans = new EventMessage__c(Article__r = childCon, EventDescription__c = stSettings.EventDescforArticlesNotScanned__c, Scan_Count__c = 0);
                evMsgWithNoScans.Article__c = childCon.Id;
                lastScanEventByArticle.put(childCon.Id, evMsgWithNoScans);
            }
        }
        
        if(!queryFields.isEmpty()){
            consignmentEvents = Database.query(eventQuery);
        }
    }
    
    public void queryConsignment(){
        relatedPODFields = new List<String>();
        relatedSubdocketFields = new List<String>();
        String query = '';
        if(conSummaryFields.size() > 0){
            query += 'SELECT ' + String.join(conSummaryFields, ',') + '';
        }
        Set<String> fieldFilter = new Set<String>{'Consignment__r.Name'};
        for(Schema.FieldSetMember fsm : SObjectType.Sub_Docket__c.FieldSets.getMap().get('StarTrack_View_All_Subdockets').getFields()){
            fieldFilter.add(fsm.getFieldPath());
        }
        for(Schema.FieldSetMember fsm : SObjectType.Sub_Docket__c.FieldSets.getMap().get('StarTrack_Subdocket_Summary').getFields()){
            fieldFilter.add(fsm.getFieldPath());
        }
        
        relatedSubdocketFields.addAll(fieldFilter);
        
        for(Schema.FieldSetMember fsm : SObjectType.Proof_of_Delivery__c.FieldSets.getMap().get('StarTrack_View_All_POD').getFields()){
            relatedPODFields.add(fsm.getFieldPath());
        } 

        if(relatedSubdocketFields.size() > 0){
            query += ', (SELECT ' + String.join(relatedSubdocketFields, ',') + ' FROM Sub_Dockets__r)';
        }
        
        query += ' FROM Article__c WHERE Id = \'' + consignment.Id + '\'';
        
        System.debug('~~ consignment query : ' + query);
        consignment = Database.query(query);
        relatedSubdockets.addAll(consignment.Sub_Dockets__r);
        
       if(relatedPODFields.size() > 0){
             String podQuery = 'SELECT ' + String.join(relatedPODFields, ',') + ', (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1) FROM Proof_of_Delivery__c WHERE Consignment__c = \'' + consignment.Id + '\' ORDER BY POD_Received_Date__c DESC';
             relatedPODs = Database.query(podQuery);
        }

        String lasUpdateStr = (consignment.Last_Update_Received__c != null) ? consignment.Last_Update_Received__c.format('dd-MMM-YYYY hh:mma') : '';
        consignmentLastUpdateDate = 'Last Update Received: ' + lasUpdateStr;
    }

    // Web service
    wwwAuspostComAuSchemaCustomercarema.Header header;
    wwwAuspostComAuSchemaCustomercarema.SearchRequest request;

    StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

    // Web service stub
    wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
    AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = new AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();

    // Web service response
    wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse;
    
    public String reqTimeStamp {get; set;}
    public String respTimeStamp {get; set;}

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Company:       Cloud Sherpas
    Description:   Method that will perform web call out Event Message search (Copied from StarTrackScanEventsSidePanel_ControllerX)
    Inputs:
    Returns:       Continuation
    History:
    February 18, 2016 - Patrick James Franco - Created
    February 24, 2016 - Patrick James Franco - Added authentication to web callout
    March 30, 2016 - Jen Karen Tan - Copied from StarTrackScanEventsSidePanel_ControllerX
    ------------------------------------------------------------*/
    public Continuation searchEventMessagesCont(){

        //try{
            // Check if there is a callout search type
            if(String.isNotBlank(consignment.ArticleID__c)
                && StarTrackConsignmentSearchUtil.isWaitDone(consignment.ArticleID__c)){

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
                request.Value = consignment.ArticleID__c;
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

                emsStub.endpoint_x = endpoint;
                if(!httpHeaders.isEmpty()){
                    emsStub.inputHttpHeaders_x = httpHeaders;
                }
                if(String.isNotBlank(clientCert)){
                    emsStub.clientCertName_x = clientCert;
                }

                emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);
                processLatestEventMessages();
                queryConsignment();

            }
        /*}
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
            searchEventMessages();
        }*/

        return null;
    }

    public String articleId {get; set;}

    public Continuation searchEventMessagesOnDemand(){
        List<Article__c> article = new List<Article__c>([SELECT Id, ArticleID__c FROM Article__c WHERE Id =: articleId]);
        //try{
            // Check if there is a callout search type
            if(stSettings.GetArticleEventsOnDemand__c && !article.isEmpty()){
                header = new wwwAuspostComAuSchemaCustomercarema.Header();
                DateTime nowDT = DateTime.now();
                header.TimeStamp = nowDT;
                header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format('YYYYMMddHHmmss');
                header.SourceId = 'Salesforce';
                header.Action = 'Search';

                request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
                request.Date_x = DateTime.now();
                request.Header = header;
                request.Type_x = 'EVENTS';
                request.Value = article[0].ArticleID__c;
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

                emsStub.endpoint_x = endpoint;
                if(!httpHeaders.isEmpty()){
                    emsStub.inputHttpHeaders_x = httpHeaders;
                }
                if(String.isNotBlank(clientCert)){
                    emsStub.clientCertName_x = clientCert;
                }

                emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);
                processLatestEventMessages();
            }
        /*}
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
            searchEventMessages();
        }*/

        return null;
    }

    public Object processLatestEventMessages(){
        try{
            reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
            emsResponse = emsStub.Search_x(request);
            respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();

            // REQUEST/RESPONSE LOG
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackViewAllScanEvents_ControllerX', 'processLatestEventMessages', request.Value, 'INT-REQ - processLatestEventMessages', reqTimeStamp, request);
                StarTrackIntegrationLogging.logRequestResponse('StarTrackViewAllScanEvents_ControllerX', 'processLatestEventMessages', request.Value, 'INT-RES - processLatestEventMessages', respTimeStamp, emsResponse);
            }

            StarTrackConsignmentSearchUtil.processResponse(emsResponse, consignment.ArticleID__c, 'EVENTS');
            // Perform local search
            searchEventMessages();
        }
        catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackViewAllScanEvents_ControllerX', 'processLatestEventMessages', '', 'CalloutException', e.getMessage(), '', e, 0);
            if(e.getMessage().contains('Time out')){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues('Search Scan Event Timeout').Field_Name__c));
            }
            // Continue local search
            searchEventMessages();
        }

        return null;
    }

    public void searchLocalEventMessages(){

        String consignmentQuery = 'SELECT Id, Consignment__c';
        String eventQuery = '';
        if(!queryFields.isEmpty()){
            consignmentQuery += ', (SELECT ' + String.join(queryFields, ',') + ' FROM Event_Messages__r WHERE Scan_Type__c = \'Label\' ORDER BY ActualDateTime__c DESC)';
            eventQuery += 'SELECT ' + String.join(queryFields, ',') + ' FROM EventMessage__c WHERE Scan_Type__c = \'Consignment\' AND Article__c = \'' + consignment.Id + '\' ORDER BY ActualDateTime__c ASC';
        }
        consignmentQuery += ' FROM Article__c WHERE Consignment__c = \'' + consignment.Id + '\'';

        if(consignment.Id != null){
            childConsignments = Database.query(consignmentQuery);
        }

        if(!queryFields.isEmpty()){
            consignmentEvents = Database.query(eventQuery);
        }
    }

    public Continuation searchConsignment(){

        try {
            if (StarTrackConsignmentSearchUtil.isWaitDone(consignment.ArticleID__c)) {
                wwwAuspostComAuSchemaCustomercarema.Header header = new wwwAuspostComAuSchemaCustomercarema.Header();
                DateTime nowDT = DateTime.now();
                
                header.TimeStamp = nowDT;
                header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format('YYYYMMddHHmmss');
                header.SourceId = 'Salesforce';
                header.Action = 'Search';

                request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();

                request.Header = header;
                request.Type_x = 'UNIQUEEXTERNALID';
                request.Value = consignment.ArticleID__c;
                request.Action = 'FULL';
                            
                String endpoint = '';
                Map<String,String> httpHeaders = new Map<String,String>();
                String clientCert = '';

                // Basic Authentication
                if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                    endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                    httpHeaders.put('Authorization','Basic ' + stSettings.StarTrack_ConSearch_BA_Password__c);
                }
                // Client Certificate
                else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
                    endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                    clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                }

                // Continuation
                emsAsyncStub.endpoint_x = endpoint;
                if(!httpHeaders.isEmpty()){
                    emsAsyncStub.inputHttpHeaders_x = httpHeaders;
                }
                if(String.isNotBlank(clientCert)){
                    emsAsyncStub.clientCertName_x = clientCert;
                }      

                Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
                cont.continuationMethod = 'processSearchConsignment';

                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);

                return cont;
            } else {
                return null;
            }   

        }  catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentDetails_ControllerX', 'searchConsignment', '', 'CalloutException', e.getMessage(), String.valueOf(request), e, 0);
            return null;
        }
        
    }

    public Object processSearchConsignment(){

        try{
            respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
            // REQUEST/RESPONSE LOG
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-REQ - consignmentSearch - consignDetail (refresh)', reqTimeStamp, request);
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-RES - consignmentSearch - consignDetail (refresh)', respTimeStamp, emsAsyncResponse.getValue());
            }

            StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), true);        

            List<String> fields = new List<String>();
            for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('Consignment_Detail_Page').getFields()){
                fields.add(fsm.getFieldPath());
            }

            queryConsignment();

        } catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', '', 'CalloutException', e.getMessage(), String.valueOf(request), e, 0);                        

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-REQ - consignmentSearch - consignDetail (refresh) - ERROR', reqTimeStamp, request);
            }
        }
        return null;
    }

    public String eventMessageId {get; set;}
    public PageReference toEventPage() {
        return new PageReference('/' + eventMessageId);
    }

    public void initializePageAttr() {
        System.debug('~~ isConsole : ' + isConsole);
    }

}