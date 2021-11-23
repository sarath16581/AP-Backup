/**
 * @description BSP Consignment search controller
 * @author Jen Karen Tan
 * @date Feb 23, 2017
 * @group BSP
 * @changelog
 * Jan 22 2017 -   David Catindoy      Modified to add additional methods to cover AusPost Consignment Search logic
 * Jan 23 2017 -   David Catindoy      Modified to finalize Authorization rules and Permission access of the logged in user.
 * Nov 10 2018 -   Kalpita T           Modified to the event message queries to filter the delivered with Signature attachments
 *                                     also, get all eligible delivered scans which need to have the POD link using custom metadata type DeliveredScanTypes
 * 2019-04-28  nathan.franklin@auspost.com.au  Significant refactor to incorporate the new access rules for BAM
 * 2019-12-13  gunith.devasurendra@auspost.com.au  Fixed BSP Sender address fetching from Article (INC1509905)
 * 2020-06-18  saiswetha.pingali@auspost.com.au - INC1583984 - Fix to resolve SOQL error .Added SenderAddress information for consignment.
 * 2020-08-12 - Nathan Franklin - Bug fix after removing CaseArticleUtility
 */
public without sharing class BSPConsignmentSearch extends bspBase {

    /*********
     * Can be removed on next deployment... added due to deployment errors
     * https://success.salesforce.com/issues_view?id=a1p300000008YkUAAU
     **/
    public void searchAPConsignment() { }
    public Continuation searchConsignment() { return null; }
    public Boolean useAsyncForAPConSearch {get;set;}
    public Continuation searchAPAndSTConsignment() { return null; }
    public Continuation searchAPConsignmentAsync() { return null; }
    public String BAScope {get;set;}
    /*
     * END
     **********/

    public AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse {get; set;}
    public AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture trackResults {get; set;}
    public Article__c singleCon {get; set;}
    public StarTrack_Settings__c stSettings {get; set;}

    //List and Map variables
    public Map<String, Article__c> articleMap {get; set;}
    public Map<Id, Attachment> apConEventsAttachment {get; set;}
    public Map<String, Map<Id, EventMessage__c>> articleEventsMap {get; set;}
    public List<Proof_of_Delivery__c> relatedPODs {get; set;}
    public List<EventMessage__c> labelEvents {get; set;}
    public List<EventMessage__c> articleEvents {get; set;}
    public List<Article__c> childConsignments {get; set;}
    public List<EventMessage__c> consignmentEvents {get; set;}
    public List<Article__c> conList {get; set;}
    private Map <Id, Billing_Account__c> billingAccountsAssociatedWithCurrentUser;

    //Boolean variables
    public Boolean showConDetail {get; set;}

    public Boolean showCreateCaseButton {get; set;}

    // when an article/consignment is searched, we can either view it in 'authenticated' or 'unathenticated' view.
    // This is set on search results from either SAP-EM / .net based the users accessible billing accounts and whether they have the universal search flag
    public Boolean isConsignmentAuthenticated {get; set;}

    public Boolean showConList {get; set;}
    public Boolean autoClickSTButton {get; set;}
    public Boolean autoClickAPButton {get; set;}
    public Boolean authToRecallRedirect {get; set;}

    //Public String variables
    public String consignmentNumber { get; set; }
    public String selectedConsignmentSearchType {get; set;}
    public String selectedArticle {get; set;}
    public String selectedEventArticle {get; set;}
    public String destination {get; set;}
    public String APConsignmentSubProduct {get; set;}

    //Public Date Variables
    public Date APConsignmentLodgementDate {get; set;}
    public Date APConsignmentExpDeliveryDate {get; set;}

    // Address wrapper instance used for Recall/Redirect of articles
    public AddressExtension redirectAddress {get; set;}

    //varible to get values from DeliveredScanTypes custom metadata for the event codes of delivered scans
    public String emScanTypes {get;set;}

    // Stores a list of StarTrack product id's that may be surfaced from SAP EM
    // This is used to indicate that the consignment should be searched using the ST .net search
    public transient Map<String, StarTrackConsignmentProductIDs__c> startrackProdIDs {
        get {
            return StarTrackConsignmentProductIDs__c.getAll();
        }
    }

    public BSPConsignmentSearch() {

        //Set header for page rendering and security for IE8
        setPageHeaders();

        setDefaultValues();

        //Added by David Catindoy (Feb 6, 2017) to cater connection between enquiry detail page and consignment search page.
        //This allows the BSP user to automatically search consignment when the "Track Item" button was clicked on the detail page.
        String caseRT = Apexpages.currentPage().getParameters().get('caseRT');
        if(String.isNotBlank(caseRT)){
            consignmentNumber = Apexpages.currentPage().getParameters().get('consignmentNumber');
            // TODO: Substitiute with correct setup now we have remove this var
            //currentSearchType = BspConstants.CON_SEARCH_TYPE_CONSIGNMENT;
            if(BspConstants.AUTH_SCOPE_ST.equals(caseRT)){
                selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_STARTRACK;
                autoClickSTButton = true;
            } else{
                selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_AUPOST;
                autoClickAPButton = true;
            }
        }
    }

    //Added by David Catindoy to allow other methods reset all the containers by just calling this method.
    public void setDefaultValues() {
        stSettings = StarTrack_Settings__c.getOrgDefaults();
        articleEventsMap = new Map<String, Map<Id, EventMessage__c>>();
        articleMap = new Map<String, Article__c>();
        apConEventsAttachment = new Map<Id, Attachment>();
        relatedPODs = new List<Proof_of_Delivery__c>();
        conList = new List<Article__c>();
        labelEvents = new List<EventMessage__c>();
        articleEvents = new List<EventMessage__c>();
        childConsignments = new List<Article__c>();
        consignmentEvents = new List<EventMessage__c>();
        singleCon = new Article__c();
        consignmentNumber = '';
        selectedArticle = '';
        selectedEventArticle = '';
        isConsignmentAuthenticated = false;
        showCreateCaseButton = false;
        authToRecallRedirect = false;
        showConList = false;
        showConDetail = false;
        autoClickSTButton = false;
        autoClickAPButton = false;
        destination = '';
        redirectAddress = new AddressExtension();
        //query on the DeliveredScanTypes custom metadata type to get all the event types of type delivered
        for (DeliveredScanTypes__mdt dST : [Select Id,label, DeveloperName FROM DeliveredScanTypes__mdt]) {
            emScanTypes += dST.label + ';';
        }
    }

    private void setPageHeaders() {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');
    }

    public boolean isArticleElgibileForRedirect(Article__c art) {
        // If there's a recall in progress, it's automatically not eligible
        if (art.RecallTempLock__c || (art.Consignment__c != null && art.Consignment__r.RecallTempLock__c)) return false;

        // Eligibility flag is only available on the article level (and not on the consignment)
        // For MVP we're only going to check if at least one of the articles is eligible - in case it's a consignment

        // It's an article (and not consignment), we can check eligibility
        if (art.EligibleForRedirect__c == true) return true;

        // It's a consignment, we have to check the related articles
        List <Article__c> relatedArticles = [SELECT Id, EligibleForRedirect__c FROM Article__c WHERE Consignment__c = :art.Id LIMIT 1];
        if (relatedArticles.size() == 1 && relatedArticles[0].EligibleForRedirect__c == true) return true;

        return false;
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that validates if required fields are populated
    ------------------------------------------------------------*/
    public Boolean validateFields() {
        Boolean valid = true;
        String errorMessage = '';

        if (String.isBlank(consignmentNumber)) {
            errorMessage = 'Please enter Consignment Number.';
        } else {
            if (consignmentNumber.length() > configSetting.Max_Length_for_Consignment_Number__c) { //Check if the consignment number length is not greater than the maximum length.
                errorMessage = BspConstants.CON_NO_INVALID_SIZE_ERR + ' Max length is ' + Integer.valueOf(configSetting.Max_Length_for_Consignment_Number__c) + ' characters.';
            } else {
                String tempConNumber =  consignmentNumber.trim();
                consignmentNumber = tempConNumber;
                for(String s : (Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c).split(StarTrack_Constants.SPECIALCHARS)){
                    if(consignmentNumber.contains(s)){
                        errorMessage = BspConstants.CON_NO_INVALID_CHAR_ERR + Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c;
                        break;
                    }
                }
            }
        }

        if (!String.isBlank(errorMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, errorMessage));
            valid = false;
            setDefaultValues();
        }
        return valid;
    }

    /**
     * Action call when the Search button is clicked on the Visualforce UI.
     * This will orchestrate the best path for searching a consignment
     *
     * Scenarios:
     * 1. User has AP only billing accounts -> Only SAP-EM search is completed
     * 2. User has ST only billing accounts -> Only ST .net search is completed
     * 3. User has both AP and ST billing accounts -> SAP-EM search is completed first, if no results then ST .net search is completed
     */
    public Continuation search() {
        singleCon = new Article__c();

        //Validate if consignment number is valid before firing the callout request.
        if (!validateFields()) {
            return null;
        }

        // if the page was loaded and tracking details were passed in via querystring, the page will be loaded with the autoClick* buttons set and javascript will be used to trigger the search
        // here we validate the autoClick buttons ad trigger the correct search method if needed
        if(autoClickAPButton && (hasAPBillingAccounts || canSearchAllConsignments)) {
            autoClickAPButton = false;
            autoClickSTButton = false;

            return searchAPAsync();
        } else if(autoClickSTButton && (hasSTBillingAccounts || canSearchAllConsignments)) {
            autoClickAPButton = false;
            autoClickSTButton = false;

            return searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, consignmentNumber);
        } else {
            autoClickAPButton = false;
            autoClickSTButton = false;

            if((hasAPBillingAccounts || canSearchAllConsignments)) {
                return searchAPAsync();
            } else if((hasSTBillingAccounts || canSearchAllConsignments)) {
                return searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, consignmentNumber);
            }
        }

        return null;
    }

    /**
     * When an ST search is completed, if there are multiple consignments with the same number that are returned, then a list of consignments is presented to the user
     * After the use selects a consignment from the list, this method is used to search that particular consignment using its unique external id field
     * This process skips the 'AP' search and goes straight back to ST search
     */
    public Continuation searchSTConsignmentByUniqueExtId() {
        // make sure a value was selected
        if(String.isEmpty(selectedArticle)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Please enter Consignment Number.'));
            setDefaultValues();
            return null;
        } else {
            return searchSTAsync(BspConstants.CON_SEARCH_TYPE_UNIQEXTID, selectedArticle);
        }
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Description:   Searches AusPost Consignment using Asynchronous Callout.
    ------------------------------------------------------------*/
    public Continuation searchAPAsync() {

        // set the current search type
        selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_AUPOST;

        singleCon = new Article__c();

        try{
            // start a new async search
            AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 service = getAsyncSAPEMRequest(consignmentNumber);

            Continuation cont = new Continuation(Integer.valueOf(configSetting.AusPostAsyncWebServiceTimeout__c));//Set the callout timeout.
            cont.continuationMethod = 'processAPSearchResult';
            trackResults = service.beginQueryTrackEvents_v1(cont, new List<String>{consignmentNumber}, BspConstants.BSP_MERCHANT); //Execute the callout request.
            return cont;
        } catch(CalloutException e){
            if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c));
            } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            } else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
            }
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
        }

        return null;
    }

    /**
     * Process the continuation response from the AP search
     */
    public Object processAPSearchResult() {
        System.debug('>> processAPSearchResult:start');

        Boolean proceedWithSTConSearch = false;
        String apConsignmentId = '';

        destination = '';
        showCreateCaseButton = false;
        isConsignmentAuthenticated = false;
        authToRecallRedirect = false;
        showConDetail = false;

        System.debug(trackResults);

        //Validate if the response result description is a SUCCESS.
        // Checks if the item is found in SAP-EM
        if(BspConstants.SUCCESS.equals(trackResults.getValue().TrackingResult[0].ResultDescription)) {
            TIBCOSearchResult searchResult = new TIBCOSearchResult();

            AuspostMailProductSchema.Article article = trackResults.getValue().TrackingResult[0].ArticleDetails != null ? trackResults.getValue().TrackingResult[0].ArticleDetails.ArticleEnvelope.Article :
                    (trackResults.getValue().TrackingResult[0].ConsignmentDetails != null && !trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope.isEmpty() ? trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope[0].Article : null);

            // this check confirms if the article is actually a StarTrack consignment even though it's been surfaced in SAP-EM
            // if thats the case we proceed to the ST search and surface the correct ST specific details from .net
            if(article != null && startrackProdIDs.containsKey(article.ProductID)) {
                if(hasSTBillingAccounts || canSearchAllConsignments){
                    // user has access to ST billing accounts so the next step is to query ST .net search
                    proceedWithSTConSearch = true;
                } else{
                    // the user doesn't have access to ST billing accounts so there is no point in proceeding to the ST consignment search
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS)));
                }
            } else {
                for(AuspostQueryTrackEventsSchema.TrackingResults tr : trackResults.getValue().TrackingResult){
                    searchResult.trackResults.add(new TIBCOTrackingResultWrapper(tr));
                }
            }

            if(!proceedWithSTConSearch && searchResult.trackResults.size() > 0) {
                // save our search results to the database
                saveAPConsignmentResponse(searchResult);

                //Get the external consignment id of the returned result.
                apConsignmentId = searchResult.trackResults[0].trackingID;

                showConDetail = true;

                //Get the consignment details in SF.
                singleCon = [
                        SELECT Id, Name, RecordType.Name, ArticleID__c, SenderCompany__c, SenderName__c, SenderAddress__c,
                                ReceiverCompany__c, ReceiverName__c, ReceiverAddress__c, Receiver_Suburb__c, ReceiverState__c,
                                ReceiverPostcode__c, Billing_Account__c, ProductCategory__c, ServiceCode__c, ArticleLodgementDate__c,
                                ExpectedDeliveryDate__c, MLID__c, SubProduct__c, DeliveryInstructions__c, ReceiverAddressLine1__c,
                                ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c, ReceiverCountry__c, ExternalTrackingID__c,  ExternalTrackingURL__c,
                                Billing_Account__r.Organisation__c, Billing_Account__r.Source_System__c, RecallTempLock__c, EligibleForRedirect__c, Consignment__c, Consignment__r.RecallTempLock__c
                        FROM Article__c
                        WHERE ArticleID__c = :apConsignmentId
                ];

                //Search for child event messages associated to the consignment.
                searchLocalEventMessages();

                // check if the user is allowed to raise cases against the billing account linked to this consignment
                if (isArticleAccessible(singleCon)) {
                    // ensure the UI will be rendered view the 'authenticated' view
                    isConsignmentAuthenticated = true;

                    // since the user has access to the full details of the articles, also allow them to raise a case against the article
                    // We only allow a case to be created IF there user already has access to AP billing accounts....
                    // REMEMBER: access rules around searching can be bypass with the special 'Can Search All Consignments' options
                    if(hasAPBillingAccounts) {
                        showCreateCaseButton = true;
                    }

                    // Since the user has been granted access to the article (either by billing account or the 'universal search flag'), they may also be eligible for Merchant Recall functionality
                    // Check whether the item is eligible for redirect (Status)
                    if (isArticleElgibileForRedirect(singleCon)) {
                        authToRecallRedirect = true;
                    }
                } else {
                    isConsignmentAuthenticated = false;
                    showCreateCaseButton = false;

                    //Added by David Catindoy to format the destination output to "Suburb, State, Postcode"
                    destination = String.isNotBlank(singleCon.Receiver_Suburb__c) ? singleCon.Receiver_Suburb__c : '';
                    destination += String.isNotBlank(singleCon.ReceiverState__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverState__c : singleCon.ReceiverState__c) : '';
                    destination += String.isNotBlank(singleCon.ReceiverPostcode__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverPostcode__c : singleCon.ReceiverPostcode__c) : '';
                }

                // If a recall request has been sent to SAP but hasn't been processed, add an info message to the page
                // Check for both the article and the consignment record. In case where there's a parent consignment, the flag is set on the consignment record
                if (singleCon.RecallTempLock__c || (singleCon.Consignment__c != null && singleCon.Consignment__r.RecallTempLock__c)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Info, 'Item Recall is already in progress.'));
                }
            } else if(hasSTBillingAccounts || canSearchAllConsignments) {
                // since there were no search results found and the user also has access to startrack billing accounts, we proceed onto the next ST .net search
                proceedWithSTConSearch = true;
            } else {
                // nothing was found in the search result and the user doesn't have access to ST billing accounts
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error when there's no consignment found.
            }
        } else {
            if(hasSTBillingAccounts || canSearchAllConsignments) {
                // since there were no search results found and the user also has access to startrack billing accounts, we proceed onto the next ST .net search
                proceedWithSTConSearch = true;
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error when there's no consignment found.
            }

        }

        // if there were no consignment/article found or the consignment/article found points to a ST product then we need to proceed to search ST .net
        if(proceedWithSTConSearch) {
            System.debug('>> processAPSearchResult: Could not find any results, proceeding with ST search.');
            // proceed with the next search into ST .net.
            // this is the result of no valid article being found in SAP-EM and where the user hass access to both AP and ST billing accounts
            return searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, consignmentNumber);
        }

        return null;
    }

    public void saveAPConsignmentResponse(TIBCOSearchResult searchResult){
        try{
            if(foundArticle(searchResult)){
                TIBCODataTranslator translator = new TIBCODataTranslator(searchResult.trackResults);
                translator.save(true, false, true, false);
            }
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage())); //Display an error message when there's an error encountered while saving the consignment/article record.
        }
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Description:   Validate if there's a consignment/article record returned by the response.
    Inputs:        List of records wrapped by TIBCOSearchResult class.
    Returns:       Boolean
    History:
    March 16, 2017 - David Catindoy - Created
    ------------------------------------------------------------*/
    public static Boolean foundArticle(TIBCOSearchResult result){
        if(!result.success || result.trackResults.size() <= 0){
            return false;
        }

        for(TIBCOTrackingResultWrapper tr : result.trackResults){
            if (tr.articleDetails != null || tr.consignmentDetails != null) {
                return true;
            }
        }
        return false;
    }

    /**
     * Start an ASYNC search to query a ST consignment.
     */
    public Continuation searchSTAsync(String searchType, String searchSubject) {

        System.debug('>> searchSTAsync:start ' + searchType + ', ' + searchSubject);

        // set the current search type
        selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_STARTRACK;

        singleCon = new Article__c();

        wwwAuspostComAuSchemaCustomercarema.SearchRequest request = BSPConsignmentSearchUtil.generateSearchRequest(searchSubject, searchType, StarTrack_Constants.REQUEST_ACTION_FULL);
        AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = BSPConsignmentSearchUtil.generateAsyncStub();

        try {
            Continuation cont = new Continuation(Integer.valueOf(configSetting.StarTrackAsyncWebServiceTimeout__c));
            cont.continuationMethod = 'processSTSearchResult';
            emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);
            return cont;
        } catch (CalloutException e) {
            if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c));
            } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
            } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
            } else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
            }
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
        }

        return null;
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that process Consignment
    ------------------------------------------------------------*/
    public Object processSTSearchResult() {

        //process callout response
        StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);
        System.debug('>> emsAsyncResponse: ' + emsAsyncResponse.getValue());
        System.debug('>> processSTSearchResult: ' + conWrapper);

        articleMap = new Map<String, Article__c>();
        showConDetail = false;
        showConList = false;
        isConsignmentAuthenticated = false;
        showCreateCaseButton = false;

        //add searched consignment to map
        if (!conWrapper.articleList.isEmpty()) {
            for (Article__c art : conWrapper.articleList) {
                articleMap.put(art.ArticleID__c, art);
            }
        }

        // checks how many consignments were returned. in ST world consignments can be reused so if there are multiple results returned we need to prompt the user to select the correct one
        if (articleMap.values().size() == 1 && conWrapper.isConsignmentSaved) {
            // only a single consignment was found
            selectedArticle = articleMap.values()[0].ArticleID__c;

            // grab the details of the consignment
            selectSTConsignment();

        } else if (articleMap.values().size() > 1) {
            // multiple consignments were found so we prompt the user to select the correct consignment

            showConList = true;
            conList = articleMap.values();

        } else {
            selectedArticle = '';

            // some type of malformed error occurred.... display the error message if it's available
            if(!String.isEmpty(conWrapper.errorCode) && conWrapper.errorCode != '0') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, conWrapper.errorCode)); //Display an error message if there's no consignment found.
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error message if there's no consignment found.
            }
        }

        return null;
    }

    public void selectSTConsignment() {

        relatedPODs = new List<Proof_of_Delivery__c>(); //Initialize POD List Containers
        singleCon = [SELECT Id, Name, RecordType.Name, ArticleID__c, SenderCompany__c, SenderName__c, SenderAddress__c,
                Dispatch_Date_Str__c, STServiceType__c, Service_Type__c, DeliveryInstructions__c, ReceiverCompany__c,
                ReceiverName__c, ReceiverAddress__c, Receiver_Suburb__c,ReceiverState__c, ReceiverPostcode__c, ReceiverCountry__c,
                ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c,
                ExpectedDeliveryDate_Str__c, Unit_Type__c, ServiceCode__c, Network__c, Network__r.Name, Customer_Ref__c, Consignment__c,
                Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.Source_System__c, Billing_Account__r.Organisation__c, SubProduct__c, ArticleLodgementDate__c, ExpectedDeliveryDate__c, RecallTempLock__c, EligibleForRedirect__c
        FROM Article__c WHERE ArticleID__c =: articleMap.get(selectedArticle).ArticleID__c];

        //verify is user is authorized to the billing account
        //show PODs and create button if authorized
        if (String.isNotBlank(singleCon.Billing_Account__c) && isArticleAccessible(singleCon)) {
            // ensure the UI will be rendered view the 'authenticated' view
            isConsignmentAuthenticated = true;

            relatedPODs = [SELECT Signed_by__c, POD_Received_Date_Str__c, Delivery_Address__c, Article_Listing__c, QC_Status__c, AttachmentId__c,
            (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1)
            FROM Proof_of_Delivery__c
            WHERE Consignment__c = :singleCon.Id
            AND AttachmentId__c != null
            ORDER BY POD_Received_Date__c DESC];

            // since the user has access to the full details of the articles, also allow them to raise a case against the article
            // We only allow a case to be created IF there user already has access to ST billing accounts....
            // REMEMBER: access rules around searching can be bypass with the special 'Can Search All Consignments' options
            if(hasSTBillingAccounts) {
                showCreateCaseButton = true;
            }
        } else {
            showCreateCaseButton = false;
            isConsignmentAuthenticated = false;

            destination = String.isNotBlank(singleCon.Receiver_Suburb__c) ? singleCon.Receiver_Suburb__c : '';
            destination += String.isNotBlank(singleCon.ReceiverState__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverState__c : singleCon.ReceiverState__c) : '';
            destination += String.isNotBlank(singleCon.ReceiverPostcode__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverPostcode__c : singleCon.ReceiverPostcode__c) : '';
        }

        searchLocalEventMessages(); //Search for local event messages associated with the consignment.

        showConDetail = true;
        showConList = false;
    }

    public void searchLocalEventMessages(){
        labelEvents = new List<EventMessage__c>(); //List of latest event message of each article.
        articleEvents = new List<EventMessage__c>(); //List of all event messages of a particular article.

        APConsignmentSubProduct = singleCon.SubProduct__c;
        APConsignmentLodgementDate = singleCon.ArticleLodgementDate__c;
        APConsignmentExpDeliveryDate = singleCon.ExpectedDeliveryDate__c;

        selectedEventArticle = '';
        Set<Id> labelEventIds = new Set<Id>();
        Set<Id> articleEventIds = new Set<Id>();
        Boolean setConsignmentFieldsFromArticle = false;

        articleEventsMap = new Map<String, Map<Id,EventMessage__c>>(); //Contains all event messages of all child articles. It's using article id as a key.


        if(String.isNotBlank(singleCon.Id)){
            //The following query retrieves the child articles and their related event messages.
            //Execute child consignments query.
            childConsignments = [SELECT Id, Consignment__c, Name, Consignment__r.Last_Update_Received__c, SubProduct__c, ArticleLodgementDate__c, ExpectedDeliveryDate__c, (SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name, EventDescription__c, ExternalDescription__c, UserName__c, Article__r.Name, Depot_Code__c, Status__c, StatusText__c FROM Event_Messages__r WHERE ShowtoExternals__c = true ORDER BY ActualDateTime__c ASC)
            FROM Article__c WHERE Consignment__c = :singleCon.Id];
        }

        consignmentEvents = [SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c,Safe_Drop_GUID__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name,
                EventDescription__c, ExternalDescription__c, UserName__c, Article__r.Name, Depot_Code__c, Status__c, StatusText__c,
                EventType__c, (SELECT Id, ParentId, Title FROM NotesAndAttachments where Title Like 'Signature%' ORDER BY CreatedDate DESC LIMIT 1)
        FROM EventMessage__c
        WHERE ShowtoExternals__c = true
        AND Article__c = :singleCon.Id
        ORDER BY ActualDateTime__c ASC];
        if(!childConsignments.isEmpty()){
            Integer articleLastEvent;
            for(Article__c childCon : childConsignments){
                if(childCon.Event_Messages__r.size() > 0){

                    articleLastEvent = childCon.Event_Messages__r.size()-1;
                    labelEventIds.add(childCon.Event_Messages__r[articleLastEvent].Id);

                    if(BspConstants.CONSEARCH_TYPE_AUPOST.equals(selectedConsignmentSearchType)){ //This will validate if the consignment retrieved is an AP.
                        articleEventsMap.put(childCon.Id, new Map<Id, EventMessage__c>(childCon.Event_Messages__r));
                        articleEventIds.addAll((new Map<Id, EventMessage__c>(childCon.Event_Messages__r)).keyset());
                    } else{
                        articleEventIds.add(childCon.Event_Messages__r[articleLastEvent].Id);
                    }
                }
                if(!setConsignmentFieldsFromArticle) {
                    if(String.isBlank(APConsignmentSubProduct))
                        APConsignmentSubProduct = childCon.SubProduct__c;

                    if(APConsignmentLodgementDate == null)
                        APConsignmentLodgementDate=childCon.ArticleLodgementDate__c;

                    if(APConsignmentExpDeliveryDate == null)
                        APConsignmentExpDeliveryDate=childCon.ExpectedDeliveryDate__c;

                    setConsignmentFieldsFromArticle = true;
                }
            }

            if(!articleEventIds.isEmpty()){
                //Retrieve the event messages and their attachments.
                for(EventMessage__c eventMessage : [SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c,Safe_Drop_GUID__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name,EventType__c, EventDescription__c, ExternalDescription__c, UserName__c, Article__c, Article__r.Name, Depot_Code__c, Status__c, StatusText__c,
                (SELECT Id, ParentId, Title FROM NotesAndAttachments where Title Like 'Signature%' ORDER BY CreatedDate DESC LIMIT 1)
                FROM EventMessage__c WHERE Id IN :articleEventIds ORDER BY Article__r.Name]){
                    if(labelEventIds.contains(eventMessage.Id)){
                        labelEvents.add(eventMessage);
                    }

                    if(articleEventsMap.containsKey(eventMessage.Article__c) && articleEventsMap.get(eventMessage.Article__c).containsKey(eventMessage.Id)){
                        articleEventsMap.get(eventMessage.Article__c).put(eventMessage.Id, eventMessage);
                    }
                }
            }
        }
    }

    //Get all the event messages related to the selected article.
    //Created by David Catindoy - March 29, 2017
    public void retrieveArticleEvents(){
        articleEvents = new List<EventMessage__c>();
        if(articleEventsMap.containsKey(selectedEventArticle)){
            articleEvents = articleEventsMap.get(selectedEventArticle).values();
        }
    }

    /**
    * Redirects the user to bspEnquiry page when the Create Case button is clicked.
    */
    public PageReference createCaseFromConsignDetail() {
        PageReference createCase = null;
        if(BspConstants.CONSEARCH_TYPE_AUPOST.equals(selectedConsignmentSearchType)){
            createCase = new PageReference('/bsp/bspEnquiry?conId=' + singleCon.Id + '&conSearch=' + BspConstants.AUTH_SCOPE_AP); //Create case for AP consignment.
        } else{
            createCase = new PageReference('/bsp/bspEnquiry?conId=' + singleCon.Id + '&conSearch=' + BspConstants.AUTH_SCOPE_ST); //Create case for ST consignment.
        }
        return createCase;
    }

    @RemoteAction
    public static Object submitRedirect(Id articleId, Boolean isRecall, RedirectDetails redirectDetails) {
        User loginUser = getLoggedInUser();
        Contact loginContact = loginUser.Contact;
        Billing_Account__c loginBillingAccount = (loginContact != null ? loginContact.BillingAccount__r : null);
        String billingAccountSource = (loginBillingAccount != null ? loginBillingAccount.Source_System__c : '');

        //pingalis - INC1583984 - Fix to resolve SOQL error .Added SenderAddress information for consignment
        // Check whether the article is a consignment. If not, find the parent consignment and recall/redirect the whole consignment (might have multiple related articles)
        Article__c thisArticle = [SELECT Id, Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.LEGACY_ID__c, ProductCategory__c, SubProduct__c, Consignment__c, TrackingID__c,
                Consignment__r.Billing_Account__c, Consignment__r.Billing_Account__r.Id, Consignment__r.Billing_Account__r.LEGACY_ID__c, Consignment__r.ProductCategory__c, Consignment__r.SubProduct__c,
                SenderAddressLine1__c, SenderAddressLine2__c, SenderAddressLine3__c, SenderAddressLine4__c, SenderCity__c, SenderState__c, SenderPostcode__c, ArticleLodgementDate__c,
                Consignment__r.SenderAddressLine1__c,Consignment__r.SenderAddressLine2__c,Consignment__r.SenderAddressLine3__c,Consignment__r.SenderAddressLine4__c, Consignment__r.SenderCity__c, Consignment__r.SenderState__c, Consignment__r.SenderPostcode__c,
                Consignment__r.ArticleLodgementDate__c, Consignment__r.TrackingID__c
        FROM Article__c
        WHERE Id = :articleId];

        if (thisArticle.Consignment__c != null) {
            thisArticle = thisArticle.Consignment__r;
        }

        // Create a closed case and populate all the relevant fields
        Case caseRecord = new Case();
        caseRecord.ArticleTest__c = thisArticle.Id;
        caseRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'SSSWDelivery' LIMIT 1].Id;
        caseRecord.Description = BspConstants.ENQUIRY_SUBTYPE_RTS_REQUEST;
        caseRecord.Subject = isRecall ? BspConstants.ENQUIRY_SUBTYPE_RTS_REQUEST : 'Request to Update Address';
        caseRecord.CaseOriginator__c = 'Sender';
        caseRecord.ResolutionCode__c = BspConstants.CASE_RESOLUTION_CODE_CUSTOMER_SELF_SERVICE;
        caseRecord.Origin = BspConstants.CASE_ORIGIN_BSP;
        caseRecord.Status = BspConstants.CASE_STATUS_CLOSED;
        caseRecord.Permanent_Close__c = true;
        caseRecord.Bypass_Data_enforcement__c = true;
        caseRecord.Enquiry_Type__c = 'Feedback';
        caseRecord.Type = 'Feedback';

        // set the billing account to be linked to the case
        // this is used for case visible to other who have access to the set billing account based on the values in accessRoles.
        if(thisArticle.Billing_Account__r != null && String.isNotEmpty(thisArticle.Billing_Account__r.Id) && String.isNotEmpty(thisArticle.Billing_Account__r.LEGACY_ID__c)) {
            caseRecord.Related_Billing_Account__c = thisArticle.Billing_Account__r.Id;
            caseRecord.Billing_Number__c = thisArticle.Billing_Account__r.LEGACY_ID__c;
        } else if(BspConstants.SOURCE_SYSTEM_SAP_ERP.equalsIgnoreCase(billingAccountSource)) {
            // isAPUser means the primary billing account is from an AP ERP (most likely SAP ERP)
            caseRecord.Related_Billing_Account__c = loginBillingAccount.Id;
            caseRecord.Billing_Number__c = loginBillingAccount.LEGACY_ID__c;
        }

        // Populate the Category and Subcategory based on the mapping table
        String key = (String.isEmpty(thisArticle.ProductCategory__c) ? '' : thisArticle.ProductCategory__c.trim()) + (String.isEmpty(thisArticle.SubProduct__c) ? '' : thisArticle.SubProduct__c.trim());
        Boolean foundMappingMatch = false;
        if (!String.isEmpty(key)) {
            Map <Id, MiniCaseFieldMapping__c> mappings = EnquiryMappingsSelector.newInstance().selectBySAPKey(new Set<String>{
                    key
            });
            if (!mappings.isEmpty()) {
                foundMappingMatch = true;

                caseRecord.ProductCategory__c = mappings.values()[0].ProductCategory__c;
                caseRecord.ProductSubcategory__c = mappings.values()[0].ProductSubcategory__c;
                // caseRecord.Type = mappings.get(thisArticle.TrackingID__c).Type__c;
            }
        }

        if(!foundMappingMatch) {
            // No mapping found, perhaps it's a consignment (there are no category and subcategory populated)
            // Grab the first related article and find the category and subcategory based on the article
            Article__c relatedArticle;
            List <Article__c> articles = [SELECT Id, TrackingID__c, ProductCategory__c, SubProduct__c FROM Article__c WHERE Consignment__c = :thisArticle.Id LIMIT 1];

            if (articles.size() == 1) {
                relatedArticle = articles[0];
            }

            if (relatedArticle != null) {
                String relatedKey = (String.isEmpty(relatedArticle.ProductCategory__c) ? '' : relatedArticle.ProductCategory__c.trim()) + (String.isEmpty(relatedArticle.SubProduct__c) ? '' : relatedArticle.SubProduct__c.trim());
                if(!String.isEmpty(relatedKey)) {
                    Map <Id, MiniCaseFieldMapping__c> mappings = EnquiryMappingsSelector.newInstance().selectBySAPKey(new Set<String>{
                            relatedKey
                    });

                    if (!mappings.isEmpty()) {
                        caseRecord.ProductCategory__c = mappings.values()[0].ProductCategory__c;
                        caseRecord.ProductSubcategory__c = mappings.values()[0].ProductSubcategory__c;
                        // caseRecord.Type = mappings.get(relatedArticle.TrackingID__c).Type__c;
                    }
                }
            }
        }

        caseRecord.Type_and_Product__c = caseRecord.Enquiry_Type__c +
                (caseRecord.ProductCategory__c == null ? '' : '|' + caseRecord.ProductCategory__c) +
                (caseRecord.ProductSubCategory__c == null ? '' : '|' + caseRecord.ProductSubCategory__c);

        caseRecord.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_RTS_REQUEST;
        caseRecord.CCUServiceUsed__c = null;
        caseRecord.PrimaryContactFirstname__c = loginUser.Firstname;
        caseRecord.PrimaryContactLastname__c = loginUser.Lastname;
        caseRecord.BSP_Sender_Name__c = loginUser.Firstname + ' ' + loginUser.Lastname;
        caseRecord.BSP_Sender_Company__c =  loginUser.CompanyName;
        caseRecord.ContactId = loginUser.ContactId;
        caseRecord.BSP_Sender_Address__c = buildSenderAddress(thisArticle);
        caseRecord.Priority = BspConstants.CASE_PRIORITY_LOW;
        caseRecord.BSP_Addressee_Name__c = redirectDetails.Name;
        caseRecord.BSP_Addressee_Company__c = redirectDetails.Company;
        caseRecord.BSP_Addressee_Address__c = redirectDetails.AddressLine1.trim() + ', ' + redirectDetails.City + ' ' + redirectDetails.State + ' '+ redirectDetails.Country +' '+ redirectDetails.Postcode;
        caseRecord.Related_Billing_Account__c = thisArticle.Billing_Account__c;
        caseRecord.ArticleTest__c = thisArticle.Id;
        caseRecord.BSPLodgementDate__c = thisArticle.ArticleLodgementDate__c;
        caseRecord.OwnerId = loginUser.Id;
        caseRecord.ReferenceID__c = thisArticle.TrackingID__c;
        insert caseRecord;

        // If it's a recall, temporary lock the record from redirecting/recalling again until it's processed in SAP
        if (isRecall) {
            thisArticle.RecallTempLock__c = true;
            update thisArticle;
        }

        // Callout to SAP EM (through TIBCO) - Outbound message
        RedirectRequest__c redirectReq = new RedirectRequest__c();
        redirectReq.Article__c = thisArticle.Id;
        redirectReq.Name__c = redirectDetails.Name;
        redirectReq.Company__c = redirectDetails.Company;
        redirectReq.AddressLine1__c = redirectDetails.AddressLine1;
        redirectReq.AddressLine2__c = redirectDetails.AddressLine2;
        redirectReq.City__c = redirectDetails.City;
        redirectReq.State__c = redirectDetails.State;
        redirectReq.Postcode__c = redirectDetails.Postcode;
        redirectReq.Country__c = redirectDetails.Country;
        redirectReq.Type__c = isRecall ? 'Recall' : 'Redirect';
        insert redirectReq;

        caseRecord = [SELECT CaseNumber FROM Case WHERE Id = :caseRecord.Id];
        return new Map <String, Object> {
                'CaseNumber' => caseRecord.CaseNumber
        };
    }

    /**
     * Append all parts of Article Address so that the Address is correctly created
     *
     * @param thisArticle
     *
     * @return The Address String
     */
    @TestVisible
    private static String buildSenderAddress(Article__c thisArticle) {
        return thisArticle.SenderAddressLine1__c + ', ' +
                (thisArticle.SenderAddressLine2__c != null ? thisArticle.SenderAddressLine2__c + ', ' : '') +
                (thisArticle.SenderAddressLine3__c != null ? thisArticle.SenderAddressLine3__c + ', ' : '') +
                (thisArticle.SenderAddressLine4__c != null ? thisArticle.SenderAddressLine4__c + ', ' : '') +
                thisArticle.SenderCity__c + ' ' +
                thisArticle.SenderState__c + ' ' +
                thisArticle.SenderPostcode__c;
    }

    @RemoteAction
    public static Object getCurrentAddress(Id articleId) {
        return [SELECT SenderCompany__c, SenderName__c, SenderAddressLine1__c, SenderAddressLine2__c, SenderCity__c, SenderCountryName__c,
                SenderPostcode__c, SenderState__c, Consignment__r.SenderCompany__c, Consignment__r.SenderName__c,
                Consignment__r.SenderAddressLine1__c, Consignment__r.SenderAddressLine2__c, Consignment__r.SenderCity__c,
                Consignment__r.SenderCountryName__c, Consignment__r.SenderPostcode__c, Consignment__r.SenderState__c
        FROM Article__c
        WHERE Id = :articleId];
    }

//    //Sort event messages
//    //Implements the sorting for event messages.
//    public class SortWrapper implements Comparable {
//
//        public EventMessage__c ev {get; set;}
//        public String sortBy {get; set;}
//        public String sortOrder {get; set;}
//
//        public SortWrapper(EventMessage__c ev, String sortBy, String sortOrder) {
//            this.ev = ev;
//            this.sortBy = sortBy;
//            this.sortOrder = sortOrder;
//        }
//
//        public Integer compareTo(Object compareTo) {
//            SortWrapper compareToEvent = (SortWrapper)compareTo;
//
//            // The return value of 0 indicates that both elements are equal.
//            Integer returnValue = 0;
//            if (String.valueOf(ev.get(''+sortBy)) < String.valueOf(compareToEvent.ev.get(''+sortBy))) {
//                if(sortOrder == 'DESC'){
//                    returnValue = 1;
//                } else {
//                    returnValue = -1;
//                }
//            } else if (String.valueOf(ev.get(''+sortBy)) > String.valueOf(compareToEvent.ev.get(''+sortBy))) {
//                if(sortOrder == 'ASC'){
//                    returnValue = -1;
//                } else {
//                    returnValue = 1;
//                }
//            }
//            return returnValue;
//        }
//    }
//
//    public class CaseCreationResponse {
//        public Boolean isCaseCreationValid {get; set;}
//        public String errorCode {get; set;}
//        public String message {get;set;}
//    }

    // VF Remoting methods used for Recall/Redirect functionality
    public class RedirectDetails {
        public String Name {get; set;}
        public String Company {get; set;}
        public String AddressLine1 {get; set;}
        public String AddressLine2 {get; set;}
        public String City {get; set;}
        public String State {get; set;}
        public String Postcode {get; set;}
        public String Country {get; set;}
    }
}