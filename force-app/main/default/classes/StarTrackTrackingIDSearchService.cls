/**
 * Created by hasan on 7/11/2022.
 */

public inherited sharing class StarTrackTrackingIDSearchService extends ApplicationDomain.Module {
    public static StarTrackTrackingIDSearchService newInstance() {
        return (StarTrackTrackingIDSearchService) Application.Utilities.newInstance(StarTrackTrackingIDSearchService.class);
    }

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

    // Fields using specified search parameters
    public String reqTimeStamp { get; set; }
    public String respTimeStamp { get; set; }

    private string filterType(String fieldname, String value, boolean type) {
        String filter = '';
        if (type) {
            filter = fieldname + '=\'' + value + '\'';
        } else {
            filter = fieldname + ' LIKE \'%' + value + '%\'';
        }
        return filter;
    }

    //Query all consignment search custom settings in order.
    public List<Consignment_Search_Settings__c> lst_consignmentSearch {
        get {
            return Consignment_Search_Settings__c.getAll().values();
        }
        set;
    }
    //case record for validation and insert
    public Case c { get; set; }

    //Capture field user selected for search, default with consignment #
    public String fieldName {
        get {
            if (fieldName == null) {
                return getItems[0].getValue();
            }
            return fieldName;
        }
        set;
    }

    //dummy case record to capture start and end date with standard SF date picker
    public Case datesFilter {
        get {
            if (datesFilter == null)
                datesFilter = new case();
            return datesFilter;
        }
        set;
    }

    //Capture user input search string
    public String searchString { get; set; }
    //List of articles
    public List<Article__c> lst_article { get; set; }

    /*map to capture article id as key and article as value to quickly
      cases for the selected article
    */
    public Map<String, Article__c> map_article { get; set; }

    //capture date type field for search
    public String dateType { get; set; }
    //capture selected date range, default is This Dat
    public String dateRange { get; set; }
    //capture selected article id
    public String selectedArticle { get; set; }
    //map to capture all custom settings data for consignment search page
    public Map<String, Consignment_Search_Settings__c> map_searchCustomSettings = new map<String, Consignment_Search_Settings__c>();

    public boolean isConsole { get; set; }

    public string recordId { get; set; }

    public void searchLocalConsignments() {
        for (Article__c thisArticle : (List<Article__c>) query()) {
            map_article.put(thisArticle.ArticleID__c, thisArticle);
        }
        lst_article = map_article.values();
    }

    public void searchConsignment() {
        system.debug('HASANTHA TEST 2');
        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap;
        selectedArticle = '';
        lst_article = null;
        map_article = new Map<String, Article__c>();

        if (validate()) {
            system.debug('HASANTHA TEST 3');
            searchLocalConsignments();
            try {
                // Check if there is a callout search type
                if (String.isNotBlank(map_searchCustomSettings.get(fieldName).Callout_Search_Type__c)) {
                    system.debug('HASANTHA TEST 4');
                    header = new wwwAuspostComAuSchemaCustomercarema.Header();
                    DateTime nowDT = DateTime.now();
                    header.TimeStamp = nowDT;
                    header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format(StarTrack_Constants.DATETIMEFORMAT);
                    header.SourceId = StarTrack_Constants.SOURCEID_SALESFORCE;
                    header.Action = StarTrack_Constants.ACTION_SEARCH;

                    request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();

                    if (map_searchCustomSettings.get(fieldName).Show_Date_Field__c && !StarTrack_Constants.CUSTOM.equals(dateRange)) {
                        request.ToDate = DateTime.now();
                        request.Date_x = (DateTime.now()).addDays(-(Integer.valueOf(dateRange)));
                    } else if (map_searchCustomSettings.get(fieldName).Show_Date_Field__c && StarTrack_Constants.CUSTOM.equals(dateRange)) {
                        request.Date_x = datesFilter.Closed_Date__c;
                        request.ToDate = datesFilter.Action_Date__c;
                    }

                    request.Header = header;

                    request.Type_x = map_searchCustomSettings.get(fieldName).Callout_Search_Type__c;
                    request.Value = searchString;

                    request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;


                    String endpoint = '';
                    Map<String, String> httpHeaders = new Map<String, String>();
                    String clientCert = '';

                    // Basic Authentication
                    if (stSettings.StarTrack_ConSearch_Authentication_Level__c == 1) {
                        endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                        httpHeaders.put(StarTrack_Constants.AUTHORIZATION, StarTrack_Constants.BASIC + stSettings.StarTrack_ConSearch_BA_Password__c);
                    }
                    // Client Certificate
                    else if (stSettings.StarTrack_ConSearch_Authentication_Level__c == 2) {
                        endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                        clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                    }
                    system.debug('HASANTHA TEST 5');
                    emsStub.endpoint_x = endpoint;
                    if (!httpHeaders.isEmpty()) {
                        emsStub.inputHttpHeaders_x = httpHeaders;
                    }
                    if (String.isNotBlank(clientCert)) {
                        emsStub.clientCertName_x = clientCert;
                    }
                    emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);
                    system.debug('HASANTHA TEST 6');
                    processSearchConsignment();

                }
            } catch (CalloutException e) {
                GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH,
                        StarTrack_Constants.METHOD_SEARCHCONSIGNMENT, '', StarTrack_Constants.CALLOUTEXCEPTION,
                        e.getMessage(), String.valueOf(request), e, 0);
            } catch (Exception e) {
                GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH,
                        StarTrack_Constants.METHOD_SEARCHCONSIGNMENT, '', StarTrack_Constants.EXCEPTION_KYWRD,
                        e.getMessage(), String.valueOf(request), e, 0);
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
                system.debug(e.getStackTraceString());
            }
        }

        return;
    }

    //capture all search item values
    public List<SelectOption> getItems {
        get {
            if (getItems == null) {
                getItems = new List<SelectOption>();
                for (Consignment_Search_Settings__c c : lst_consignmentSearch) {
                    map_searchCustomSettings.put(c.Field_Name__c, c);
                    system.debug('** Value - IF *** ' + c.Field_Name__c + ' ' + '*** Label ' + c.Name);
                    if (c.Search_Type__c)
                        getItems.add(new SelectOption(c.Field_Name__c, c.Name));
                }
                return getItems;
            }
            return getItems;
        }
        set;
    }

    public boolean validate() {
        Boolean result = true;
        if (String.isEmpty(searchString) || searchString.length() < Integer.valueOf(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOOFSEARCHCHAR).Field_Name__c)) {
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOOFCHARERR).Field_Name__c));
            system.debug(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOOFCHARERR).Field_Name__c);
            result = false;
        }
        return result;
    }

    public Object processSearchConsignment() {
        system.debug('HASANTHA TEST 7 ');
        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap;
        try {
            reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
            system.debug('HASANTHA TEST 8 ');
            emsResponse = emsStub.Search_x(request);
            system.debug('HASANTHA TEST 8 after search');
            respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();

            // REQUEST/RESPONSE LOG
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT,
                        searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT,
                        searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsResponse);
            }
            system.debug('HASANTHA TEST 9 ');
            conWrap = StarTrackConsignmentSearchUtil.processResponse(emsResponse, isConsole);


            if (StarTrack_Constants.ERR_CODE_0.equals(conWrap.errorCode)) {
                for (Article__c thisArticle : conWrap.articleList) {
                    if (!map_article.containsKey(thisArticle.ArticleID__c)) {
                        map_article.put(thisArticle.ArticleID__c, thisArticle);
                    }
                }
                lst_article = map_article.values();
            }

        } catch (CalloutException e) {
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH,
                    StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, '', StarTrack_Constants.CALLOUTEXCEPTION,
                    e.getMessage(), String.valueOf(request), e, 0);

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT,
                        searchString, 'INT-REQ - consignmentSearch - ERROR', reqTimeStamp, request);
            }
        }

        return conWrap;
    }

    public list<sobject> query() {
        ArticlesSelector selector = ArticlesSelector.newInstance();

        Map<Id, Article__c> articles = selector.selectByArticleNames(
                new Set<String> {searchString},
                'Consignment',
                new Set<String> {'TEAM', 'TRACK & TRACE'},
                new Set<Object>{ ArticlesSelector.Options.WITH_RECORDTYPE, ArticlesSelector.Options.WITH_CONSIGNMENT});
        return articles.values();
        /*
        String articleFilter = '(SELECT articleTest__c FROM Case WHERE ' + filterType(map_searchCustomSettings.get(fieldName).Field_Name__c, searchString, map_searchCustomSettings.get(fieldName).Exact_Search__c) + ')';
        String query1 = 'SELECT Id, ArticleID__c, Freight_Amount__c, CID__c, Billing_Account__c ';
        for (Schema.FieldSetMember f : SObjectType.Article__c.FieldSets.Consignment_Search_Results.getFields()) {
            query1 += ',' + f.getFieldPath();
        }

        query1 += ' FROM Article__c WHERE RecordType.Name = \'Consignment\' AND ';

        String query = 'SELECT Id, ArticleID__c, Freight_Amount__c, CID__c, Billing_Account__c';
        for (Schema.FieldSetMember f : SObjectType.Article__c.FieldSets.Consignment_Search_Results.getFields()) {
            query += ',' + f.getFieldPath();
        }

        if (stSettings.SearchforSTConsignmentsOnly__c) {
            query += ' FROM Article__c WHERE Source_System__c IN (\'TEAM\', \'TRACK & TRACE\') AND RecordType.Name = \'Consignment\' AND ';
        } else {
            query += ' FROM Article__c WHERE RecordType.Name = \'Consignment\' AND ';
        }

        if (map_searchCustomSettings.get(fieldName).Article_Case_field__c) {
            query += filterType(fieldName, searchString, map_searchCustomSettings.get(fieldName).Exact_Search__c);
        } else {
            query += 'ID IN ' + articleFilter;
        }

        if (map_searchCustomSettings.get(fieldName).Show_Suburb_Field__c) {
            query += ' AND ' + filterType('Receiver_Suburb__c', suburb, true);
        }

        if (map_searchCustomSettings.get(fieldName).Show_Date_Field__c && map_searchCustomSettings.get(dateRange).Field_Name__c != 'Custom') {
            query += ' AND ' + map_searchCustomSettings.get(dateType).Field_Name__c + '= LAST_N_DAYS:' + map_searchCustomSettings.get(dateRange).Field_Name__c;
        }
*//*
        if (StarTrack_Constants.CUSTOM.equals(map_searchCustomSettings.get(dateRange).Field_Name__c)) {
            Date startdate = datesFilter.Closed_Date__c;
            Date enddate = datesFilter.Action_Date__c;
            query += ' AND ' + map_searchCustomSettings.get(dateType).Field_Name__c + ' >=: startDate';
            query += ' AND ' + map_searchCustomSettings.get(dateType).Field_Name__c + ' <=: endDate';
        }*//*


        if (stSettings.SOQLLimitonArticle__c != null) {
            query += ' LIMIT ' + Integer.valueOf(stSettings.SOQLLimitonArticle__c);
        }

        System.debug('*** Query ***  ' + query);
        return Database.query(query);*/
    }

    // TODO old query method to be removed
    public list<sobject> query1() {
        String articleFilter = '(SELECT articleTest__c FROM Case WHERE ' + filterType(map_searchCustomSettings.get(fieldName).Field_Name__c, searchString, map_searchCustomSettings.get(fieldName).Exact_Search__c) + ')';
        String query1 = 'SELECT Id, ArticleID__c, Freight_Amount__c, CID__c, Billing_Account__c ';
        for (Schema.FieldSetMember f : SObjectType.Article__c.FieldSets.Consignment_Search_Results.getFields()) {
            query1 += ',' + f.getFieldPath();
        }

        query1 += ' FROM Article__c WHERE RecordType.Name = \'Consignment\' AND ';

        String query = 'SELECT Id, ArticleID__c, Freight_Amount__c, CID__c, Billing_Account__c';
        for (Schema.FieldSetMember f : SObjectType.Article__c.FieldSets.Consignment_Search_Results.getFields()) {
            query += ',' + f.getFieldPath();
        }

        if (stSettings.SearchforSTConsignmentsOnly__c) {
            query += ' FROM Article__c WHERE Source_System__c IN (\'TEAM\', \'TRACK & TRACE\') AND RecordType.Name = \'Consignment\' AND ';
        } else {
            query += ' FROM Article__c WHERE RecordType.Name = \'Consignment\' AND ';
        }

        if (map_searchCustomSettings.get(fieldName).Article_Case_field__c) {
            query += filterType(fieldName, searchString, map_searchCustomSettings.get(fieldName).Exact_Search__c);
        } else {
            query += 'ID IN ' + articleFilter;
        }

        if (map_searchCustomSettings.get(fieldName).Show_Date_Field__c && map_searchCustomSettings.get(dateRange).Field_Name__c != 'Custom') {
            query += ' AND ' + map_searchCustomSettings.get(dateType).Field_Name__c + '= LAST_N_DAYS:' + map_searchCustomSettings.get(dateRange).Field_Name__c;
        }


        if (stSettings.SOQLLimitonArticle__c != null) {
            query += ' LIMIT ' + Integer.valueOf(stSettings.SOQLLimitonArticle__c);
        }

        System.debug('*** Query *** HASANTHA  ' + query);
        return Database.query(query);
    }
}