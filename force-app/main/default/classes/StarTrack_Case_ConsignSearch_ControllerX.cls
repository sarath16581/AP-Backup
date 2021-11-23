/**************************************************
Description:    Consignment search controller.
                (This class must run without sharing because users need to update
                    Consignment data and its related data created by other users)
History:
--------------------------------------------------
Aug-2015:  Fahad.Akhtar@cloudsherpas.com  Created
Jan-2016:  patrick.franco@cloudsherpas.com - Added web service call out to search external system for Consignments
                                           - Moved search parameter display logic to Visualforce page
Feb-2016:  patrick.franco@cloudsherpas.com - Added new methods to accommodate assignment of Consignment to Case
FEB.01.2018 Angelo Rivera (Accenture)     - CCTR Project - Added variable and method to prepopulate seacrh String
May-2018: Hasantha.Liyanage@auspost.com.au - Updated Make available the page through cpVisualforceWrapper.cmp
2018-06-01 kalpita.talwadekar@auspost.com.au - IVR functionality (CCTR/CTI Project)
2018-06-21 nathan.franklin@auspost.com.au - Adding non transactional IVR exclusions (CCTR/CTI Project)
2008-07-01 clint.dsilva@auspost.com.au - Addeed function getConNotesFromArticles, getShowImageLink
09.06.2020  Lija Jawahar     Omni-channel bug fix - Removed standard controller
**************************************************/
public without sharing class StarTrack_Case_ConsignSearch_ControllerX{

    //Query all consignment search custom settings in order.
    public List<Consignment_Search_Settings__c> lst_consignmentSearch{
        get{
            if(lst_consignmentSearch == null)
                lst_consignmentSearch = [
                                            SELECT
                                                    Id,
                                                    Name,
                                                    Article_Case_field__c,
                                                    Date_Literal__c,
                                                    Date_Type__c,
                                                    Exact_Search__c,
                                                    Field_Name__c,
                                                    Order__c,
                                                    Search_Type__c,
                                                    Show_Date_Field__c,
                                                    Show_Date_Range__c,
                                                    Show_Suburb_Field__c,
                                                    Callout_Search_Type__c
                                            FROM
                                                    Consignment_Search_Settings__c
                                            ORDER BY
                                                    ORDER__c
                                        ];
            return lst_consignmentSearch;
        }
        set;
    }
    //case record for validation and insert
    public Case c {get; set;}

    //flag to capture validation error and display error on UI
    public boolean flag {get; set;}

    //Capture field user selected for search, default with consignment #
    public String fieldName{
        get{
            if(fieldName == null){
                return getItems[0].getValue();
            }
            return fieldName;
        }
        set;
    }

    //dummy case record to capture start and end date with standard SF date picker
    public Case datesFilter{
        get{
            if(datesFilter == null)
                datesFilter = new case();
            return datesFilter;
        }
        set;
    }

    //Capture user input search string
    public String searchString              {get; set;}
    //List of articles
    public List<Article__c> lst_article     {get; set;}

    //list of cases for selected articles
    public List<Case> lst_case              {get; set;}
    
    //list of ivr cases for selected articles
    public List<Case> lst_case_ivr              {get; set;}
    
    /*map to capture article id as key and article as value to quickly
      cases for the selected article
    */
    // public map<id,Article__c> map_article   {get; set;}
    public Map<String,Article__c> map_article   {get; set;}

    //capture date type field for search
    public String dateType                  {get; set;}
    //capture selected date range, default is This Dat
    public String dateRange                 {get; set;}
    //capture suburb field data for search
    public String suburb                    {get; set;}
    //capture if subrurb field should render
    public boolean showSuburb               {get; set;}
    //capture if date type field should render
    public boolean showDate                 {get; set;}
    //capture if date range field should render
    public boolean showDateRange            {get; set;}
    //capture if no consignment found message should render
    public boolean noConsignmentFound       {get; set;}
    //capture if no cases found message should render
    public boolean noCaseFound              {get; set;}
    //capture if no ivr cases found message should render
    public boolean noIVRCaseFound              {get; set;}
    //capture if no article selected message should render
    public boolean noArticleSelected        {get; set;}
    //capture selected article id
    public String selectedArticle           {get; set;}
    //map to capture all custom settings data for consignment search page
    public Map<String,Consignment_Search_Settings__c> map_searchCustomSettings = new map<String,Consignment_Search_Settings__c>();

    //create case flag
    public boolean createCaseInd            {get; set;}

    public Article__c savedConsignment      {get; set;}

    public boolean isConsole                {get; set;}

    public  string recordId {get; set;}

    // Set page title for consignment Search
    public String pageTitle{
        get{
            if(pageTitle == null)
                pageTitle = Consignment_Search_Settings__c.getValues('Page title').Field_Name__c;
            return pageTitle;
        }
        set;
    }

    /**
     * if the page is opened via the iFrame and need to be read only considered
     * when the related VF page is opened via cpVisulforceWrapper lightning component trough an iFrame,
     * isReadOnly should be passed to hide some functionality that are not required to display for the lightning user
     * eg: if the isReadOnly is null or true, this could make the decision to make the section read only OR hidden
    **/
    public Boolean isReadOnly {
        get {
            if(isReadOnly !=null) {
                return isReadOnly;
            }
            String iframeCheck = ApexPages.currentPage().getParameters().get('isReadOnly');
            return ((iframeCheck == null || iframeCheck == 'true') ? true : false);
        }
        set;
    }

    //capture all search item values
    public List<SelectOption> getItems{
        get{
            if(getItems == null){
                getItems = new List<SelectOption>();
                for(Consignment_Search_Settings__c c : lst_consignmentSearch){
                    map_searchCustomSettings.put(c.Field_Name__c,c);
                    system.debug('** Value - IF *** ' + c.Field_Name__c + ' ' + '*** Label ' +c.Name);
                    if(c.Search_Type__c)
                        getItems.add(new SelectOption(c.Field_Name__c,c.Name));
                }
                return getItems;
            }
            return getItems;
        }
        set;
    }
    //capture all date type values
    public List<SelectOption> getDateTypes{
        get{
            getDateTypes = new List<SelectOption>();
            if(getDateTypes == null || getDateTypes.size() == 0){
                for(Consignment_Search_Settings__c c : lst_consignmentSearch){
                    if(c.Date_Type__c)
                        getDateTypes.add(new SelectOption(c.Field_Name__c,c.Name));
                }
                return getDateTypes;
            }
        return getDateTypes;
        }
        set;
    }
    //capture all date range values
    public List<SelectOption> getDateRange{
        get{
            getDateRange = new List<SelectOption>();
            if(getDateRange == null || getDateRange.size() == 0){
                for(Consignment_Search_Settings__c c : lst_consignmentSearch){
                    if(c.Date_Literal__c)
                        getDateRange.add(new SelectOption(c.Field_Name__c,c.Name));
                }
                return getDateRange;
            }
        return getDateRange;
        }
        set;
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
    public String dateFields {get; set;}
    public String dateRangeFields {get; set;}
    public String suburbFields {get; set;}
    
    public String reqTimeStamp {get; set;}
    public String respTimeStamp {get; set;}

    public List<SelectOption> getCaseRecordType {
        get{
            if (getCaseRecordType == null || getCaseRecordType.size() == 0) {
                getCaseRecordType = new List<SelectOption>();
                Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([Select Id, Name, DeveloperName, IsActive From RecordType  Where SobjectType = 'Case']);

                List<Id> activeRecTypeIds = new List<Id>();
                Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Case.getRecordTypeInfosById();

                Id defaultRecType = null;

                for (Id recTypeInfoId : rtMapById.keySet()) {
                    if (rtMapById.get(recTypeInfoId).isAvailable()) {
                        activeRecTypeIds.add(recTypeInfoId);
                    }
                    if (rtMapById.get(recTypeInfoId).DefaultRecordTypeMapping) {
                        defaultRecType = recTypeInfoId;
                    }
                }
                for (Id recTypeId : activeRecTypeIds) {
                    if (recordTypeMap.get(recTypeId) != null && recordTypeMap.get(recTypeId).DeveloperName.contains(StarTrack_Constants.STARTRACK)) {
                        getCaseRecordType.add(new SelectOption(recTypeId, recordTypeMap.get(recTypeId).Name));
                    }
                }
                c.RecordTypeId = defaultRecType;
            } else {
                return getCaseRecordType;
            }
            return getCaseRecordType; 
        }
        set;        
    }

    // 09.06.2020  LJ    Omni-channel bug fix - Removed standard controller
    public StarTrack_Case_ConsignSearch_ControllerX() {
        recordId =  ApexPages.CurrentPage().getparameters().get('caseId');
        if(!String.isEmpty(recordId)){
              String caseQuery = 'SELECT Id';
            String caseFilter = '';

            Set<String> casefields = new Set<String>();
            for(Schema.FieldSetMember f : SObjectType.Case.FieldSets.Consignment_Search_Results.getFields()){
                casefields.add(f.getFieldPath());
            }

            for(Schema.FieldSetMember f : SObjectType.Case.FieldSets.Consignment_Search_Caller_Detail.getFields()){
                casefields.add(f.getFieldPath());
            }

            for(String s :casefields){
                caseQuery +=  ','+ s;
            }

            caseQuery += ' FROM Case ';
            caseFilter += 'WHERE Id= :recordId';

            caseQuery += caseFilter;

            System.debug('** Case Query ** ' + caseQuery);

            c =  Database.query(caseQuery);
        } else {
            c = new case();
        }

        selectedArticle = '';
        flag = false;
        showDate = false;
        showDateRange = false;
        showSuburb = false;
        noConsignmentFound = false;
        noCaseFound = false;
        noIVRCaseFound = false;
        noArticleSelected = false;
        createCaseInd = true;
        initializeSearchFilters();        
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will initialize which fields should have Date, Date Range, and Suburb search params in page
    Inputs:
    Returns:
    History:
    January 21, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public void initializeSearchFilters(){
        dateFields = '';
        dateRangeFields = '';
        suburbFields = '';

        List<String> dateList = new List<String>();
        List<String> dateRangeList = new List<String>();
        List<String> suburbList = new List<String>();

        for(Consignment_Search_Settings__c css : lst_consignmentSearch){
            if(css.Show_Date_Field__c){
                dateList.add(css.Field_Name__c);
            }
            if(css.Show_Date_Range__c){
                dateRangeList.add(css.Field_Name__c);
            }
            if(css.Show_Suburb_Field__c){
                suburbList.add(css.Field_Name__c);
            }
        }
        dateFields = JSON.serialize(dateList);
        dateRangeFields = JSON.serialize(dateRangeList);
        suburbFields = JSON.serialize(suburbList);
    }

    //On change of type method, check which field and section should be rendered on UI
    // Replaced by client side logic in Visualforce page
    /*public PageReference searTypeChange(){
        showSuburb = map_searchCustomSettings.get(fieldName).Show_Suburb_Field__c;
        showDate = map_searchCustomSettings.get(fieldName).Show_Date_Field__c;
        showDateRange = false;
        return null;
    }*/

    //On change of date range method, check if date range should be rendered on UI
    // Replaced by client side logic in Visualforce page
    /*public PageReference dateRangeChange(){
        showDateRange = map_searchCustomSettings.get(dateRange).Show_Date_Range__c;
        return null;
    }*/

    //Article and related cases search method.
    public void searchLocalConsignments(){
        for(Article__c thisArticle : (List<Article__c>)query()){
            map_article.put(thisArticle.ArticleID__c, thisArticle);
        }
        lst_article = map_article.values();
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will perform local and web call out Consignment search
    Inputs:
    Returns:       Continuation
    History:
    January 21, 2016 - Patrick James Franco - Created
    February 24, 2016 - Patrick James Franco - Added authentication to web callout
    March 2, 2016 - Jen Karen Tan - Added request.Action = FULL if not on console
    ------------------------------------------------------------*/
    public Continuation searchConsignment(){
        selectedArticle = '';
        noCaseFound = false;
        noIVRCaseFound = false;
        lst_article = null;
        lst_case = null;
        lst_case_ivr = null;
        map_article = new Map<String, Article__c>();

        if(validate()){
            searchLocalConsignments();
            try{
                // Check if there is a callout search type
                if(String.isNotBlank(map_searchCustomSettings.get(fieldName).Callout_Search_Type__c)){

                    header = new wwwAuspostComAuSchemaCustomercarema.Header();
                    DateTime nowDT = DateTime.now();
                    header.TimeStamp = nowDT;
                    header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format(StarTrack_Constants.DATETIMEFORMAT);
                    header.SourceId = StarTrack_Constants.SOURCEID_SALESFORCE;
                    header.Action = StarTrack_Constants.ACTION_SEARCH;

                    request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();

                    if(map_searchCustomSettings.get(fieldName).Show_Date_Field__c && !StarTrack_Constants.CUSTOM.equals(dateRange)){
                        request.ToDate = DateTime.now();
                        request.Date_x = (DateTime.now()).addDays(-(Integer.valueOf(dateRange)));
                    } else if(map_searchCustomSettings.get(fieldName).Show_Date_Field__c && StarTrack_Constants.CUSTOM.equals(dateRange)){
                        request.Date_x = datesFilter.Closed_Date__c;
                        request.ToDate = datesFilter.Action_Date__c;
                    }

                    request.Header = header;
                    if (map_searchCustomSettings.get(fieldName).Show_Suburb_Field__c) {
                        request.Suburb = suburb;
                    }
                    request.Type_x = map_searchCustomSettings.get(fieldName).Callout_Search_Type__c;
                    request.Value = searchString;
                    
                    if (isConsole) {
                        if(stSettings.Get_All_Consignment_Details__c){
                            request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                        }
                        else{
                            request.Action = StarTrack_Constants.REQUEST_ACTION_SUMMARY;
                        }
                    } else {
                        request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                    }


                    String endpoint = '';
                    Map<String,String> httpHeaders = new Map<String,String>();
                    String clientCert = '';

                    // Basic Authentication
                    if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                        endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                        httpHeaders.put(StarTrack_Constants.AUTHORIZATION, StarTrack_Constants.BASIC + stSettings.StarTrack_ConSearch_BA_Password__c);
                    }
                    // Client Certificate
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
                        cont.continuationMethod = StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT;

                        reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                        emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);
						system.debug('  Startrack ws callout '+emsAsyncResponse);
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
                        emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);
                        processSearchConsignment();
                    }
                }
            }
            catch(CalloutException e){

                GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                    StarTrack_Constants.METHOD_SEARCHCONSIGNMENT, '', StarTrack_Constants.CALLOUTEXCEPTION, 
                    e.getMessage(), String.valueOf(request), e, 0);

                if(lst_article.isEmpty()){
                    noConsignmentFound = true;
                }
                else if(lst_article.size() == 1){
                    selectedArticle = lst_article.get(0).ArticleID__c;
                    noArticleSelected = false;
                    noConsignmentFound = false;
                    getCases();
                }
                else{
                    noArticleSelected = true;
                    noConsignmentFound = false;
                }

                if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
                }
            }
            catch(Exception e){
                GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                    StarTrack_Constants.METHOD_SEARCHCONSIGNMENT, '', StarTrack_Constants.EXCEPTION_KYWRD, 
                    e.getMessage(), String.valueOf(request), e, 0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
            }
        }
        else{
            noConsignmentFound = true;
        }

        return null;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will process the callout response from a Consignment search
    Inputs:
    Returns:
    History:
    January 21, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public Object processSearchConsignment(){
        try{
            StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap;

            if(stSettings.Use_Continuation_for_Consignment_Search__c){
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 
                        searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 
                        searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsAsyncResponse.getValue());
                }
                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), isConsole);
            }
            else{
                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsResponse = emsStub.Search_x(request);
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 
                        searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 
                        searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsResponse);
                }
                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsResponse, isConsole);
            }

            if(StarTrack_Constants.ERR_CODE_0.equals(conWrap.errorCode)){
                for(Article__c thisArticle : conWrap.articleList){
                    if(!map_article.containsKey(thisArticle.ArticleID__c)){
                        map_article.put(thisArticle.ArticleID__c, thisArticle);
                    }
                }
                lst_article = map_article.values();
            }

            if(lst_article.isEmpty()){
                noConsignmentFound = true;
            }
            else if(lst_article.size() == 1){
                selectedArticle = lst_article.get(0).ArticleID__c;
                noArticleSelected = false;
                noConsignmentFound = false;
                getCases();
            }
            else{
                noArticleSelected = true;
                noConsignmentFound = false;
            }
        }
        catch(CalloutException e){
            
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, '', StarTrack_Constants.CALLOUTEXCEPTION, 
                e.getMessage(), String.valueOf(request), e, 0);

            if(lst_article.isEmpty()){
                noConsignmentFound = true;
            }
            else if(lst_article.size() == 1){
                selectedArticle = lst_article.get(0).ArticleID__c;
                noArticleSelected = false;
                noConsignmentFound = false;
                getCases();
            }
            else{
                noArticleSelected = true;
                noConsignmentFound = false;
            }

            if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            }
            else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
            }

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSSEARCHCONSIGNMENT, 
                    searchString, 'INT-REQ - consignmentSearch - ERROR', reqTimeStamp, request);
            }
        }

        return null;
    }

    //method to get all related cases when user select an article
    public void getCases(){
        noArticleSelected = false;
        lst_case = getRelatedCases();
        lst_case_ivr = getRelatedCasesIVR();
        noCaseFound = false;
        noIVRCaseFound = false;
        if(lst_case.isempty()){
            noCaseFound = true;
        }
        if(lst_case_ivr.isempty()){
            noIVRCaseFound = true;
        }
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will get the Cases related to the selected Consignment with origin not IVR
    Inputs:        String, String, Date, Date, Date, String
    Returns:       ConsignmentWrapper
    History:
    January 21, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public List<Case> getRelatedCases(){
        String caseQuery = 'SELECT ';
        String caseFilter = '';

        for(Schema.FieldSetMember f : SObjectType.Case.FieldSets.Consignment_Search_Results.getFields()){
            caseQuery += f.getFieldPath() + ',';
        }

        caseQuery = caseQuery.subString(0, caseQuery.length() - 1); //trim last comma
        caseQuery += ' FROM Case ';
        caseFilter += 'WHERE ' + filterType('ArticleTest__r.ArticleID__c', selectedArticle,map_searchCustomSettings.get(fieldName).Exact_Search__c);

        // make sure we exclude all the 'transactional' IVR cases
        caseFilter += ' AND (Origin != \'IVR\' Or (Origin = \'IVR\' ' ;
        for(String fieldKey : StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.keySet()) {
            Set<String> values = StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get(fieldKey);

            caseFilter += ' AND ' + String.escapeSingleQuotes(fieldKey) + ' in :values ' ;
        }
        caseFilter += '))';

        caseQuery += caseFilter;

        System.debug('** Case Query ** ' + caseQuery);

        return Database.query(caseQuery);
    }
    
    /**
    * Method that will get a list of 'transactional' IVR Cases related to the selected Consignment
    * Note, some cases are with origin IVR but are not classed as 'transactional' so will not be displayed here.
    */
    public List<Case> getRelatedCasesIVR(){

        String caseQuery = 'SELECT ';
        String caseFilter = '';

        for(Schema.FieldSetMember f : SObjectType.Case.FieldSets.Consignment_Search_Results.getFields()){
            caseQuery += f.getFieldPath() + ',';
        }

        caseQuery = caseQuery.subString(0, caseQuery.length() - 1); //trim last comma
        caseQuery += ' FROM Case ';
        caseFilter += 'WHERE ' + filterType('ArticleTest__r.ArticleID__c', selectedArticle,map_searchCustomSettings.get(fieldName).Exact_Search__c);
        caseFilter += ' AND IsClosed = true ' ;
        caseFilter += ' AND Origin = \'IVR\' ' ;

        // make sure we exclude non 'transactional' IVR cases
        for(String fieldKey : StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.keySet()) {
            Set<String> values = StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get(fieldKey);
            caseFilter += ' AND ' + String.escapeSingleQuotes(fieldKey) + ' NOT in :values ' ;
        }

        caseQuery += caseFilter;

        System.debug('** Case Query ** ' + caseQuery);

        caseQuery += ' ORDER BY CreatedDate DESC ';

        return Database.query(caseQuery);
    }

    //Method to construct cases sub query and article query
    public list<sobject> query(){
        String articleFilter = '(SELECT articleTest__c FROM Case WHERE ' + filterType(map_searchCustomSettings.get(fieldName).Field_Name__c,searchString,map_searchCustomSettings.get(fieldName).Exact_Search__c) + ')';

        String query = 'SELECT Id, ArticleID__c, Freight_Amount__c, CID__c, Billing_Account__c';
        for(Schema.FieldSetMember f : SObjectType.Article__c.FieldSets.Consignment_Search_Results.getFields()){
            query += ',' + f.getFieldPath();
        }

        if (stSettings.SearchforSTConsignmentsOnly__c) {            
            query += ' FROM Article__c WHERE Source_System__c IN (\'TEAM\', \'TRACK & TRACE\') AND RecordType.Name = \'Consignment\' AND ';
        } else {
            query += ' FROM Article__c WHERE RecordType.Name = \'Consignment\' AND ';
        } 

        if(map_searchCustomSettings.get(fieldName).Article_Case_field__c){
            query += filterType(fieldName,searchString,map_searchCustomSettings.get(fieldName).Exact_Search__c);
        }
        else{
            query += 'ID IN ' + articleFilter;
        }

        if(map_searchCustomSettings.get(fieldName).Show_Suburb_Field__c){
            query += ' AND ' + filterType('Receiver_Suburb__c',suburb,true);
        }

        if(map_searchCustomSettings.get(fieldName).Show_Date_Field__c && map_searchCustomSettings.get(dateRange).Field_Name__c != 'Custom'){
            query += ' AND ' +  map_searchCustomSettings.get(dateType).Field_Name__c + '= LAST_N_DAYS:' + map_searchCustomSettings.get(dateRange).Field_Name__c;
        }

        if(StarTrack_Constants.CUSTOM.equals(map_searchCustomSettings.get(dateRange).Field_Name__c)){
            Date startdate = datesFilter.Closed_Date__c;
            Date enddate = datesFilter.Action_Date__c;
            query += ' AND ' +  map_searchCustomSettings.get(dateType).Field_Name__c + ' >=: startDate';
            query += ' AND ' +  map_searchCustomSettings.get(dateType).Field_Name__c + ' <=: endDate';
        }
        
        

        if (stSettings.SOQLLimitonArticle__c != null) {
            query += ' LIMIT ' + Integer.valueOf(stSettings.SOQLLimitonArticle__c);
        }

        System.debug('*** Query ***  ' + query);
        return Database.query(query);
    }

    //method to create query string for exact and fuzzy match
    private string filterType(String fieldname, String value, boolean type){
        String filter = '';
        if(type){
            filter = fieldname + '=\'' + value + '\'';
        }
        else{
            filter = fieldname + ' LIKE \'%' + value + '%\'';
        }
        return filter;
    }

    //Method to validate method search and return error if validation fails
    public boolean validate(){        
        Boolean result = true;
        if(StarTrack_Constants.CUSTOM.equals(map_searchCustomSettings.get(dateRange).Field_Name__c)){
            if(String.isEmpty(String.ValueOf(datesFilter.Closed_Date__c)) || String.isEmpty(String.ValueOf(datesFilter.Action_Date__c))){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ENTERDATES).Field_Name__c));
                result =  false;
            }
            else if(datesFilter.Closed_Date__c > datesFilter.Action_Date__c){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_DATEVALIDATION).Field_Name__c));
                result =  false;
            }
            else if(datesFilter.Closed_Date__c.daysBetween(datesFilter.Action_Date__c) > Integer.valueOf(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_DATEDIFFERENCE).Field_Name__c) ){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_DATEDURERROR).Field_Name__c));
                result =  false;
            }
        }
        if(String.isEmpty(searchString) || searchString.length() < Integer.valueOf(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOOFSEARCHCHAR).Field_Name__c)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOOFCHARERR).Field_Name__c));
            result  = false;
        }

        if(map_searchCustomSettings.get(fieldName).Show_Suburb_Field__c && String.isEmpty(suburb)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SUBURBERR).Field_Name__c));
            result =  false;
        }

        for(String s : (Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c).split(StarTrack_Constants.SPECIALCHARS)){
            if(searchString.contains(s)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_INVALIDCHARERR).Field_Name__c));
                result =  false;
                break;
            }
        }

        return result;
    }

    public String caseCreationStart {get; set;}
    //override case logic to set field on save and throw error if validation fails.
    public Continuation createCase() {
        caseCreationStart = StarTrackIntegrationLogging.timeNowFormatted();        
        try{
            // Consignment selected
            if(String.isNotBlank(selectedArticle)) {
                header = new wwwAuspostComAuSchemaCustomercarema.Header();
                DateTime nowDT = DateTime.now();
                header.TimeStamp = nowDT;
                header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format(StarTrack_Constants.DATETIMEFORMAT);
                header.SourceId = StarTrack_Constants.SOURCEID_SALESFORCE;
                header.Action = StarTrack_Constants.ACTION_SEARCH;

                request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
                request.Header = header;
                request.Type_x = StarTrack_Constants.TYPE_UNIQUEEXTERNALID;
                request.Value = map_article.get(selectedArticle).ArticleID__c;
                    
                if (isConsole) {
                    if(stSettings.Get_All_Consignment_Details__c){
                        request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                    } else {
                        request.Action = StarTrack_Constants.REQUEST_ACTION_SUMMARY;
                    }
                } else {
                    request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                }

                String endpoint = '';
                Map<String,String> httpHeaders = new Map<String,String>();
                String clientCert = '';

                // Basic Authentication
                if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                    endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                    httpHeaders.put(StarTrack_Constants.AUTHORIZATION, StarTrack_Constants.BASIC + stSettings.StarTrack_ConSearch_BA_Password__c);
                }
                // Client Certificate
                else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
                    endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                    clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                }

                if(stSettings.Use_Continuation_for_Consignment_Search__c){
                    emsAsyncStub.endpoint_x = endpoint;
                    if(!httpHeaders.isEmpty()){
                        emsAsyncStub.inputHttpHeaders_x = httpHeaders;
                    }
                    if(String.isNotBlank(clientCert)){
                        emsAsyncStub.clientCertName_x = clientCert;
                    }

                    Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
                    cont.continuationMethod = StarTrack_Constants.METHOD_PROCESSCREATECASE;
                    reqTimeStamp = String.valueOf(DateTime.now().format(StarTrack_Constants.DATETIMEFORMATTZ));
                    emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);

                    return cont;
                } else {
                    emsStub.endpoint_x = endpoint;
                    if(!httpHeaders.isEmpty()){
                        emsStub.inputHttpHeaders_x = httpHeaders;
                    }
                    if(String.isNotBlank(clientCert)){
                        emsStub.clientCertName_x = clientCert;
                    }

                    emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);
                    processCreateCase();
                }
            } else {
                // No Consignment selected
                if(String.isBlank(selectedArticle)){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOSELECTEDCONSIGN).Field_Name__c));
                }
            }
        }
        catch(System.DmlException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                StarTrack_Constants.METHOD_CREATECASE, '', StarTrack_Constants.DMLEXCEPTION, 
                e.getMessage(), String.valueOf(request), e, 0);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCREATECASE).Field_Name__c));
        }

        return null;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will process the callout response from a Case save using Continuation
    Inputs:
    Returns:
    History:
    January 21, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public Object processCreateCase(){
        try{

            StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap;

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('CASE CREATE (PROCEED) - START', 'CASE CREATE (PROCEED) - START', '', 'CASE CREATE (PROCEED) - START', caseCreationStart, null);
            }

            if(stSettings.Use_Continuation_for_Consignment_Search__c){
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsAsyncResponse.getValue());
                }

                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), isConsole);
            }
            else{
                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsResponse = emsStub.Search_x(request);
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();

                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsResponse);
                }

                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsResponse, isConsole);
            }

            Id articleId = null;
            String articleName = '';
            String uniqueArticleId = '';
            Decimal freightAmount = 0;
            Date cid = null;

            if (conwrap != null && !conWrap.articleList.isEmpty()) {
                savedConsignment = conWrap.articleList.get(0);
                if (savedConsignment != null) {
                    flag = true;
                }

                articleId = conWrap.articleList[0].Id;
                articleName = conWrap.articleList[0].Name;
                uniqueArticleId = conWrap.articleList[0].ArticleID__c;
                freightAmount = conWrap.articleList[0].Freight_Amount__c != null ? conWrap.articleList[0].Freight_Amount__c : 0;
                cid = getDateEquivalent(conWrap.articleList[0].CID__c, StarTrack_Constants.DATEFORMAT);

            } else if (!lst_article.isEmpty()) {
                flag = true;
                savedConsignment = lst_article[0];
                articleId = lst_article[0].Id;
                articleName = lst_article[0].Name;
                uniqueArticleId = lst_article[0].ArticleID__c;
                freightAmount = lst_article[0].Freight_Amount__c != null ? lst_article[0].Freight_Amount__c : 0;
                cid = getDateEquivalent(lst_article[0].CID__c, StarTrack_Constants.DATEFORMAT);
            }

            if (createCaseInd) {
                c.Callers_Data_Change__c = true;
                c.Caller_Data_Capture_DateTime__c = datetime.now() - 0.04152;
                c.Related_Billing_Account__c = map_article.get(selectedArticle).Billing_Account__c;
                c.ArticleTest__c = articleId;
                c.Consignment_Unique_External_ID__c = uniqueArticleId;
                c.Connote_number__c = articleName;
                c.Total_Amount_of_Claim__c = freightAmount;
                c.Delivery_Date__c = cid;
                c.Recent_Caller_Pref_Method_of_Contact__c = null;
                c.Initical_CallPreferred_method_of_contact__c = null;
                
                String startTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                INSERT c;
                String endTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();

                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-INSERT >> START - case', startTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-INSERT >> END - case', endTimeStamp, emsResponse);
                }
                flag = true;

                if (!isConsole) {
                    return new PageReference('/' + c.Id);
                }                
            }
            
        }
        catch(CalloutException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                StarTrack_Constants.METHOD_PROCESSCREATECASE, '', StarTrack_Constants.CALLOUTEXCEPTION, 
                e.getMessage(), '', e, 0);
            if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_CASECREATETIMEOUT).Field_Name__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            }
            else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
            }
            flag = false;

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, searchString, 'INT-REQ - consignmentSearch - ERROR', reqTimeStamp, request);
            }
        }
        catch(DmlException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSCREATECASE, '', StarTrack_Constants.DMLEXCEPTION, e.getMessage(), '', e, 0);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues('Error on Case create').Field_Name__c));
            flag = false;
        }
        catch (Exception e) {
            if (e.getMessage().contains(StarTrack_Constants.KEYWRD_SIGXSTRING)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, StarTrack_Constants.KEYWRD_SIGXSTRING));
            }
            flag = false;
        }

        return null;
    }

    public Date getDateEquivalent(String dateStr, String format) {
        Date dateValue = null;
        if (dateStr != null) {
            if (StarTrack_Constants.DATEFORMAT.equals(format) && dateStr.length() == 8) {
                String year = dateStr.subString(0, 4);
                String month = dateStr.subString(4,6);
                String day = dateStr.subString(6,8);
                dateValue = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));
            }
        }
        return dateValue;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will perform the assignment of a Consignment to a Case
    Inputs:
    Returns:       Continuation
    History:
    February 10, 2016 - Patrick James Franco - Created
    February 24, 2016 - Patrick James Franco - Added authentication to web callout
    ------------------------------------------------------------*/
    public Continuation assignToCase() {
        try{

            // Consignment selected
            if(String.isNotBlank(selectedArticle) && map_article.containsKey(selectedArticle)){

                // Not yet in Salesforce
                if(String.isBlank(map_article.get(selectedArticle).Id)){
                    header = new wwwAuspostComAuSchemaCustomercarema.Header();
                    DateTime nowDT = DateTime.now();
                    header.TimeStamp = nowDT;
                    header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format(StarTrack_Constants.DATETIMEFORMAT);
                    header.SourceId = StarTrack_Constants.SOURCEID_SALESFORCE;
                    header.Action = StarTrack_Constants.ACTION_SEARCH;

                    request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
                    request.Header = header;
                    request.Type_x = StarTrack_Constants.TYPE_UNIQUEEXTERNALID;
                    request.Value = map_article.get(selectedArticle).ArticleID__c;
                    
                    if (isConsole) {
                        if(stSettings.Get_All_Consignment_Details__c){
                            request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                        }
                        else{
                            request.Action = StarTrack_Constants.REQUEST_ACTION_SUMMARY;
                        }
                    } else {
                        request.Action = StarTrack_Constants.REQUEST_ACTION_FULL;
                    }

                    String endpoint = '';
                    Map<String,String> httpHeaders = new Map<String,String>();
                    String clientCert = '';

                    // Basic Authentication
                    if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                        endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                        httpHeaders.put(StarTrack_Constants.AUTHORIZATION, StarTrack_Constants.BASIC + stSettings.StarTrack_ConSearch_BA_Password__c);
                    }
                    // Client Certificate
                    else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
                        endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                        clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                    }

                    if(stSettings.Use_Continuation_for_Consignment_Search__c){
                        emsAsyncStub.endpoint_x = endpoint;
                        if(!httpHeaders.isEmpty()){
                            emsAsyncStub.inputHttpHeaders_x = httpHeaders;
                        }
                        if(String.isNotBlank(clientCert)){
                            emsAsyncStub.clientCertName_x = clientCert;
                        }

                        Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
                        cont.continuationMethod = StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE;
                        reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                        emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);

                        return cont;
                    }
                    else{
                        emsStub.endpoint_x = endpoint;
                        if(!httpHeaders.isEmpty()){
                            emsStub.inputHttpHeaders_x = httpHeaders;
                        }
                        if(String.isNotBlank(clientCert)){
                            emsStub.clientCertName_x = clientCert;
                        }
                        emsStub.timeout_x = Integer.valueOf(stSettings.Sync_Web_Service_Callout_Timeout__c * 1000);

                        processAssignToCase();
                    }
                }
                // Already in Salesforce
                else{
                    c.ArticleTest__c = map_article.get(selectedArticle).Id;
                    c.Consignment_Unique_External_ID__c = map_article.get(selectedArticle).ArticleID__c;
                    c.Connote_number__c = map_article.get(selectedArticle).Name;
                    //removed Total Amount of Claim assignment except for LDC - W-001451
                    if (StarTrack_Constants.CASE_ENQUIRY_LDC.equals(c.Enquiry_Type__c)) {
                        c.Total_Amount_of_Claim__c = map_article.get(selectedArticle).Freight_Amount__c != null ? map_article.get(selectedArticle).Freight_Amount__c : 0;
                    }
                    c.Delivery_Date__c = getDateEquivalent(map_article.get(selectedArticle).CID__c, StarTrack_Constants.DATEFORMAT);

                    UPDATE c;
                    flag = true;
                }
            }
            // No Consignment selected
            else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_NOSELECTEDCONSIGN).Field_Name__c));
                flag = false;
            }
        }
        catch(DmlException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH,
            StarTrack_Constants.METHOD_ASSIGNTOCASE, '', StarTrack_Constants.DMLEXCEPTION, 
            e.getMessage(), String.valueOf(request), e, 0);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues('Error on Case update').Field_Name__c));
            flag = false;
        }

        return null;
    }

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method that will process the callout response when assigning a Consignment to a Case
    Inputs:
    Returns:
    History:
    February 10, 2016 - Patrick James Franco - Created
    ------------------------------------------------------------*/
    public Object processAssignToCase(){
        try{

            StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap;

            if(stSettings.Use_Continuation_for_Consignment_Search__c){
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsAsyncResponse.getValue());
                }

                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), isConsole);
            }
            else{
                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsResponse = emsStub.Search_x(request);
                respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                
                // REQUEST/RESPONSE LOG
                if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, searchString, 'INT-REQ - consignmentSearch', reqTimeStamp, request);
                    StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, searchString, 'INT-RES - consignmentSearch', respTimeStamp, emsResponse);
                }

                conWrap = StarTrackConsignmentSearchUtil.processResponse(emsResponse, isConsole);
            }

            if(conWrap.isConsignmentSaved){
                c.ArticleTest__c = conWrap.articleList[0].Id;
                c.Consignment_Unique_External_ID__c = map_article.get(selectedArticle).ArticleID__c;
                c.Connote_number__c = map_article.get(selectedArticle).Name;
                //removed Total Amount of Claim assignment except for LDC - W-001451
                if (StarTrack_Constants.CASE_ENQUIRY_LDC.equals(c.Enquiry_Type__c)) {
                    c.Total_Amount_of_Claim__c = map_article.get(selectedArticle).Freight_Amount__c != null ? map_article.get(selectedArticle).Freight_Amount__c : 0;
                }
                c.Delivery_Date__c = getDateEquivalent(map_article.get(selectedArticle).CID__c, StarTrack_Constants.DATEFORMAT);

                UPDATE c;
                flag = true;
            }
        }
        catch(CalloutException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, 
                StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, '', StarTrack_Constants.CALLOUTEXCEPTION, 
                e.getMessage(), '', e, 0);
            if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ASSIGNCONTIMEOUT).Field_Name__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            }
            else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            }
            else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
            }
            flag = false;

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse(StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, searchString, 'INT-REQ - consignmentSearch - ERROR', reqTimeStamp, request);
            }
        }
        catch(DmlException e){
            GlobalUtility.logMessage(StarTrack_Constants.ERROR, StarTrack_Constants.CLASS_CONSIGNSEARCH, StarTrack_Constants.METHOD_PROCESSASSIGNTOCASE, '', StarTrack_Constants.DMLEXCEPTION, e.getMessage(), '', e, 0);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRUPDATECASE).Field_Name__c));
            flag = false;
        }
        return null;
    }
    
    public void logTime(){
        if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
            StarTrackIntegrationLogging.logRequestResponse('PAGE RENDER - END', 'PAGE RENDER - END', '', 'PAGE RENDER - END', StarTrackIntegrationLogging.timeNowFormatted(), null);
        }
    }

    /**
    * Get consignment from Article
    *
    */
    @auraenabled
    public  list<string> getConNotesFromArticles(){
        list<string> rtn = new list<string>();
        if(lst_article != null){
            for(Article__c art : lst_article ){
                if(!string.isBlank(art.Consignment__c) ){
                    rtn.add(art.Consignment__c);
                }
            }
        }
        return rtn;
    }

    /**
    * Check VF access, if yes display link to view Image page
    *
    */
    public boolean getShowImageLink(){
        boolean rtn = false;
        List < SetupEntityAccess> SEA =[SELECT Id, Parent.Name, Parent.Profile.Name, Parent.Profile.Id FROM SetupEntityAccess
        WHERE Parent.Profile.Id = :UserInfo.getProfileId()
        AND SetupEntityId in (SELECT Id FROM ApexPage WHERE Name = 'ConsignmentAttachment' AND NamespacePrefix = null)
        ];
        if(!SEA.isEmpty()){
            rtn = true;
        }
        return rtn; 
    }
}