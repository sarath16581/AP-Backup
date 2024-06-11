/**
 * @description BSP Consignment search controller for LWC
 * @author Ankur
 * @date Sept 2020
 * @group BSP
 * @changelog
 * 2020-09-21 - Jansi, Ankur, Victor - BSP Uplift:
 *  migrated to LWC, therefore needed static + AuraEnabled
 *  Continuation + callouts need a Continuation.State to preserve context (context is lost when using static)
 *  Continuation + callouts need a wrapper method with NO arguments for Test Coverage. Test.InvokeContinuation only
 *  allows for a continuation method with no arguments.
 *  2022-09-12 - prerna.rahangdale@auspost.com.au Change to update the eventMessages with the safe drop guid for events of
 *  safe drop type.
 *	2024-05-22 - Seth Heang - refactor starTrackProdIds custom setting into StarTrack_Constants class
 */
public without sharing class BSPConsignmentSearchUplift {


    public static AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse { get; set; }
    public static AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture trackResults { get; set; }
    public static Article__c singleCon { get; set; }
    //[Jansi] made the below to static
    public static StarTrack_Settings__c stSettings { get; set; }

    //List and Map variables
    public static Map<String, Article__c> articleMap { get; set; }
    public static Map<Id, Attachment> apConEventsAttachment { get; set; }
    public static Map<String, Map<Id, EventMessage__c>> articleEventsMap { get; set; }
    public static List<Proof_of_Delivery__c> relatedPODs { get; set; }
    public static List<EventMessage__c> labelEvents { get; set; }
    public static List<EventMessage__c> articleEvents { get; set; }
    public static List<Article__c> childConsignments { get; set; }
    public static List<EventMessage__c> consignmentEvents { get; set; }
    public static List<Article__c> conList { get; set; }
    private Map <Id, Billing_Account__c> billingAccountsAssociatedWithCurrentUser;

    //Boolean variables
    public static Boolean showConDetail { get; set; }

    public static Boolean showCreateCaseButton { get; set; }

    // when an article/consignment is searched, we can either view it in 'authenticated' or 'unathenticated' view.
    // This is set on search results from either SAP-EM / .net based the users accessible billing accounts and whether they have the universal search flag
    public static Boolean isConsignmentAuthenticated { get; set; }

    public static Boolean showConList { get; set; }
    public static Boolean autoClickSTButton { get; set; }
    public static Boolean autoClickAPButton { get; set; }
    public static Boolean authToRecallRedirect { get; set; }

    //Public String variables
    public static String consignmentNumber { get; set; }
    public static String selectedConsignmentSearchType { get; set; }
    public static String selectedArticle { get; set; }
    public static String selectedEventArticle { get; set; }
    public static String destination { get; set; }
    public static String APConsignmentSubProduct { get; set; }
    public static Boolean recallInProgress { get; set; }
    public static Set<String> errorMessages = new Set<String>();

    //Public Date Variables
    public static Date APConsignmentLodgementDate { get; set; }
    public static Date APConsignmentExpDeliveryDate { get; set; }

    // Address wrapper instance used for Recall/Redirect of articles
    public static AddressExtension redirectAddress { get; set; }

    //varible to get values from DeliveredScanTypes custom metadata for the event codes of delivered scans
    public static String emScanTypes { get; set; }


    //Added by David Catindoy to allow other methods reset all the containers by just calling this method.
    public static void setDefaultValues() {
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
        /*for (DeliveredScanTypes__mdt dST : [Select Id,label, DeveloperName FROM DeliveredScanTypes__mdt]) {
            emScanTypes += dST.label + ';';
        }*/
    }


    public static boolean isArticleElgibileForRedirect(Article__c art) {
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


    /**
     * Action call when the Search button is clicked on the Visualforce UI.
     * This will orchestrate the best path for searching a consignment
     *
     * Scenarios:
     * 1. User has AP only billing accounts -> Only SAP-EM search is completed
     * 2. User has ST only billing accounts -> Only ST .net search is completed
     * 3. User has both AP and ST billing accounts -> SAP-EM search is completed first, if no results then ST .net search is completed
     */
    @AuraEnabled(continuation=true)
    public static Object search(String consignNumber) {
        System.debug('search----START ---');
        consignmentNumber = consignNumber;
        singleCon = new Article__c();

        //[Jansi: added]
        if ((bspBaseUplift.hasAPBillingAccounts || bspBaseUplift.canSearchAllConsignments)) {
            System.debug('Search AP..');
            return searchAPAsync();
        } else if ((bspBaseUplift.hasSTBillingAccounts || bspBaseUplift.canSearchAllConsignments)) {
            System.debug('Search ST..');
            return searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, consignmentNumber);
        }

        //[Jansi:]Added below
        return null;
    }

    /**
     * A wrapper class as best practice to return data to Lwc
     * @return Wrapper object for LWC to consume
     */
    public static ConsignmentSerchResultsWrapper buildWrapperToSendToLWC() {

        ConsignmentSerchResultsWrapper csr = new ConsignmentSerchResultsWrapper();
        csr.showConList = showConList ;
        csr.showConDetail = showConDetail;
        csr.consignmentNumber = consignmentNumber ;
        csr.conList = conList;
        csr.selectedConsignmentSearchType = selectedConsignmentSearchType;
        csr.isConsignmentAuthenticated = isConsignmentAuthenticated;
        csr.consignmentEvents = consignmentEvents;
        csr.showCreateCaseButton = showCreateCaseButton;
        csr.errorMessages = new List<String>(errorMessages);
        csr.singleCon = singleCon;
        csr.APConsignmentLodgementDate = APConsignmentLodgementDate;
        csr.APConsignmentExpDeliveryDate = APConsignmentExpDeliveryDate;
        csr.APConsignmentSubProduct = APConsignmentSubProduct;
        csr.destination = destination;
        csr.recallInProgress = recallInProgress;
        csr.authToRecallRedirect = authToRecallRedirect;
        csr.selectedArticle = selectedArticle ;
        //If Aupost with single Aticle then showing all the events onload of LWC along with latest one in header section
        if (selectedConsignmentSearchType == 'AusPost' && labelEvents != null && labelEvents.size() == 1) {
            selectedEventArticle = labelEvents.get(0).Article__c;
            retrieveArticleEvents();
        }
        csr.labelEvents = labelEvents;
        csr.selectedEventArticle = selectedEventArticle;
        csr.articleEvents = articleEvents;
        csr.articleEventsMap = articleEventsMap;
        csr.relatedPODs = relatedPODs;

        String scanTypes = '';
        for (DeliveredScanTypes__mdt dST : [Select Id, label, DeveloperName FROM DeliveredScanTypes__mdt]) {
            scanTypes += dST.label + ';';
        }
        csr.emScanTypes = scanTypes;

        //This method is used to set the values blank if it is unauthenticated access.
        if (isConsignmentAuthenticated == false && csr.singleCon != null) {
            setUnAuthenticatedValues(csr);
        }

        return csr;
    }

    //This method is used to set the values blank if it is unauthenticated access.
    @TestVisible
    private static void setUnAuthenticatedValues(ConsignmentSerchResultsWrapper csrw) {
        csrw.APConsignmentSubProduct = '';
        if (csrw.singleCon != null) {
            csrw.singleCon.SenderCompany__c = '';
            csrw.singleCon.SenderName__c = '';
            csrw.singleCon.SenderAddress__c = '';
            csrw.singleCon.SenderAddressLine1__c = '';
            csrw.singleCon.SenderAddressLine2__c = '';
            csrw.singleCon.SenderCity__c = '';
            csrw.singleCon.SenderState__c = '';
            csrw.singleCon.SenderPostcode__c = '';
            csrw.singleCon.SenderCountry__c = '';
            csrw.singleCon.ReceiverCompany__c = '';
            csrw.singleCon.ReceiverName__c = '';
            csrw.singleCon.ReceiverAddress__c = '';
            csrw.singleCon.ReceiverAddressLine1__c = '';
            csrw.singleCon.ReceiverAddressLine2__c = '';
            csrw.singleCon.ReceiverCity__c = '';
            csrw.singleCon.ReceiverState__c = '';
            csrw.singleCon.ReceiverPostcode__c = '';
            csrw.singleCon.ReceiverCountry__c = '';
            csrw.singleCon.DeliveryInstructions__c = '';
        }

        if (csrw.labelEvents != null) {
            for (EventMessage__c le : csrw.labelEvents) {
                le.NotesAndAttachments.clear();
                le.Safe_Drop_GUID__c = '';
            }
        }

        if (csrw.relatedPODs != null) csrw.relatedPODs.clear();
    }

    /**
     * When an ST search is completed, if there are multiple consignments with the same number that are returned, then a list of consignments is presented to the user
     * After the use selects a consignment from the list, this method is used to search that particular consignment using its unique external id field
     * This process skips the 'AP' search and goes straight back to ST search
     */
    @AuraEnabled(continuation=true)
    public static Object searchSTConsignmentByUniqueExtId(String selectedArticle) {
        return searchSTAsync(BspConstants.CON_SEARCH_TYPE_UNIQEXTID, selectedArticle);
    }

    //[Jansi] Added
    /**
     * A wrapper class as best practice to store the state for Continuation callout
     */
    public class StateInfo {
        String consignmentNumber { get; set; }
        String selectedConsignmentSearchType { get; set; }
        AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture response { get; set; }
        AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture stResponse { get; set; }

        //AP StateInfo
        public StateInfo(AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture response, String cNumber, String selectedConsignmentSearchType) {
            this.response = response;
            this.consignmentNumber = cNumber;
            this.selectedConsignmentSearchType = selectedConsignmentSearchType;
        }

        //ST StateInfo
        public StateInfo(AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture response, String cNumber, String selectedConsignmentSearchType) {
            this.stResponse = response;
            this.consignmentNumber = cNumber;
            this.selectedConsignmentSearchType = selectedConsignmentSearchType;
        }


    }

    /**
    * A wrapper class as best practice to return data to Lwc
    * @return Wrapper object for LWC to consume
    */
    public Class ConsignmentSerchResultsWrapper {
        @AuraEnabled public Boolean showConList { get; set; }
        @AuraEnabled public Boolean showConDetail { get; set; }
        @AuraEnabled public String consignmentNumber { get; set; }
        @AuraEnabled public List<Article__c> conList { get; set; }
        @AuraEnabled public String selectedConsignmentSearchType { get; set; }
        @AuraEnabled public Boolean isConsignmentAuthenticated { get; set; }
        @AuraEnabled public List<EventMessage__c> consignmentEvents { get; set; }
        @AuraEnabled public List<EventMessage__c> labelEvents { get; set; }
        @AuraEnabled public List<EventMessage__c> articleEvents { get; set; }
        @AuraEnabled public Boolean showCreateCaseButton { get; set; }
        @AuraEnabled public String selectedArticle { get; set; }
        @AuraEnabled public List<String> errorMessages { get; set; }
        @AuraEnabled public Article__c singleCon { get; set; }
        @AuraEnabled public Date APConsignmentLodgementDate { get; set; }
        @AuraEnabled public Date APConsignmentExpDeliveryDate { get; set; }
        @AuraEnabled public String APConsignmentSubProduct { get; set; }
        @AuraEnabled public String destination { get; set; }
        @AuraEnabled public Map<String, Map<Id, EventMessage__c>> articleEventsMap { get; set; }
        @AuraEnabled public String emScanTypes { get; set; }
        @AuraEnabled public Boolean recallInProgress { get; set; }
        @AuraEnabled public Boolean authToRecallRedirect { get; set; }
        @AuraEnabled public String selectedEventArticle { get; set; }
        @AuraEnabled public List<Proof_of_Delivery__c> relatedPODs { get; set; }

    }


    /*------------------------------------------------------------
    Author:        David Catindoy
    Description:   Searches AusPost Consignment using Asynchronous Callout.
    ------------------------------------------------------------*/
    @AuraEnabled(continuation=true)
    public static Continuation searchAPAsync() {
        System.debug('searchAPAsync>>>>>>>>');
        // set the current search type
        selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_AUPOST;

        try {
            // start a new async search
            AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 service = bspBaseUplift.getAsyncSAPEMRequest(consignmentNumber);

            Continuation cont = new Continuation(Integer.valueOf(bspBaseUplift.configSetting.AusPostAsyncWebServiceTimeout__c));//Set the callout timeout.
            cont.continuationMethod = 'processAPSearchResult';
            dummyContState = new StateInfo(service.beginQueryTrackEvents_v1(cont, new List<String>{
                    consignmentNumber
            }, BspConstants.BSP_MERCHANT), consignmentNumber, selectedConsignmentSearchType);
            cont.state = dummyContState;
            return cont;
        } catch (CalloutException e) {
            if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)) {
                throw new ErrorException(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c);
            } else if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)) {
                throw new ErrorException(stSettings.StarTrack_ConSearch_Authentication_Error__c);
            } else if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)) {
                throw new ErrorException(stSettings.StarTrack_ConSearch_Client_Cert_Error__c);
            } else {
                throw new ErrorException(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c);
            }
        } catch (Exception ex) {
            throw new ErrorException(ex.getMessage());
        }
    }

    // needed for test code coverage
    // Static Continuation Methods require a state object, but Test.invokeContinuation cannot pass in arguments,
    // therefore, store the state to pass in when testing.
    // The following methods are used for test injection.
    private static StateInfo dummyContState;
    public static Object processAPSearchResult() {
        return processAPSearchResult(dummyContState);
    }
    public static Object processSTSearchResult() {
        return processSTSearchResult(dummyContState);
    }

    /**
     * Process the continuation response from the AP search
     * In production, the state object is passed in as the Continutation.State argument.
     * In Testing, this is the dummyContState passed in via the no-argument methods above
     */
    @AuraEnabled(Continuation=true)
    public static Object processAPSearchResult(Object state) {
        System.debug('>>>>>>>>>>>>>>>>>>>> processAPSearchResul >>>>>>>>>>>>>>>>>>>> tstate:' + state);

        //[Jansi] Added below to get from stateInfo
        StateInfo stInfo = (StateInfo) state;
        trackResults = stInfo.response;
        consignmentNumber = stInfo.consignmentNumber;
        selectedConsignmentSearchType = stInfo.selectedConsignmentSearchType;

        singleCon = new Article__c();

        Boolean proceedWithSTConSearch = false;
        String apConsignmentId = '';

        destination = '';
        showCreateCaseButton = false;
        isConsignmentAuthenticated = false;
        authToRecallRedirect = false;
        showConDetail = false;
        recallInProgress = false;

        System.debug(trackResults);

        //Validate if the response result description is a SUCCESS.
        // Checks if the item is found in SAP-EM
        if (BspConstants.SUCCESS.equals(trackResults.getValue().TrackingResult[0].ResultDescription)) {

            TIBCOSearchResult searchResult = new TIBCOSearchResult();
            AuspostMailProductSchema.Article article = trackResults.getValue().TrackingResult[0].ArticleDetails != null ?
                    trackResults.getValue().TrackingResult[0].ArticleDetails.ArticleEnvelope.Article :
                    (trackResults.getValue().TrackingResult[0].ConsignmentDetails != null && !trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope.isEmpty() ?
                            trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope[0].Article : null);

            System.debug('>>>>>>>>>>>>>>>>>>>> article: ' + article);

            // this check confirms if the article is actually a StarTrack consignment even though it's been surfaced in SAP-EM
            // if thats the case we proceed to the ST search and surface the correct ST specific details from .net
            if (article != null && StarTrack_Constants.startrackProdIDs.containsKey(article.ProductID)) {
                if (bspBaseUplift.hasSTBillingAccounts || bspBaseUplift.canSearchAllConsignments) {
                    // user has access to ST billing accounts so the next step is to query ST .net search
                    proceedWithSTConSearch = true;
                } else {
                    // the user doesn't have access to ST billing accounts so there is no point in proceeding to the ST consignment search
                    //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS)));
                    errorMessages.add(bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS));
                }
            } else {
                for (AuspostQueryTrackEventsSchema.TrackingResults tr : trackResults.getValue().TrackingResult) {
                    TIBCOTrackingResultWrapper trackingResultWrapper = new TIBCOTrackingResultWrapper(tr);
                    searchResult.trackResults.add(trackingResultWrapper);

                    Id billingAccount = null;
                    if (trackingResultWrapper.articleDetails != null) {
                        billingAccount = trackingResultWrapper.articleDetails.proxyArticle.Billing_Account__c;
                    }
                    if (trackingResultWrapper.consignmentDetails != null) {
                        billingAccount = trackingResultWrapper.consignmentDetails.proxyConsignment.Billing_Account__c;
                    }
                    if (billingAccount != null && bspBaseUplift.accessibleBillingAccounts.containsKey(billingAccount)) {
                        updateGuidInEventMessages(trackingResultWrapper);
                    }
                }
            }


            if (!proceedWithSTConSearch && searchResult.trackResults.size() > 0) {

                // save our search results to the database
                saveAPConsignmentResponse(searchResult);

                //Get the external consignment id of the returned result.
                apConsignmentId = searchResult.trackResults[0].trackingID;

                showConDetail = true;

                //Get the consignment details in SF.
                singleCon = [
                        SELECT Id, Name, RecordType.Name, ArticleID__c,
                                SenderCompany__c, SenderName__c, SenderAddress__c,
                                SenderAddressLine1__c, SenderAddressLine2__c, SenderState__c, SenderCity__c, SenderPostcode__c, Sender_Suburb__c, SenderCountry__c,
                                ReceiverCompany__c, ReceiverName__c, ReceiverAddress__c,
                                ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c,
                                ReceiverCity__c, ReceiverCountry__c, Receiver_Suburb__c, ReceiverState__c, ReceiverPostcode__c,
                                Billing_Account__c, ProductCategory__c, ServiceCode__c, ArticleLodgementDate__c,
                                ExpectedDeliveryDate__c, MLID__c, SubProduct__c, DeliveryInstructions__c, ExternalTrackingID__c, ExternalTrackingURL__c,
                                Billing_Account__r.Organisation__c, Billing_Account__r.Source_System__c, RecallTempLock__c, EligibleForRedirect__c, Consignment__c,
                                Consignment__r.RecallTempLock__c, Service_Type__c, SenderCountryName__c, ReceiverCountryName__c //Added 09.11.2020
                        FROM Article__c
                        WHERE ArticleID__c = :apConsignmentId
                ];

                System.debug('>>>>>>>>>>>>>>>>>>>> singleCon: ' + singleCon);

                //Search for child event messages associated to the consignment.
                searchLocalEventMessages();

                // check if the user is allowed to raise cases against the billing account linked to this consignment
                if (bspBaseUplift.isArticleAccessible(singleCon)) {
                    System.debug('>>>>>>>>>>>>>>>>>>>> isArticleAccessible = true');
                    // ensure the UI will be rendered view the 'authenticated' view
                    isConsignmentAuthenticated = true;

                    // since the user has access to the full details of the articles, also allow them to raise a case against the article
                    // We only allow a case to be created IF there user already has access to AP billing accounts....
                    // REMEMBER: access rules around searching can be bypass with the special 'Can Search All Consignments' options
                    if (bspBaseUplift.hasAPBillingAccounts) {
                        showCreateCaseButton = true;
                    }

                    // Since the user has been granted access to the article (either by billing account or the 'universal search flag'), they may also be eligible for Merchant Recall functionality
                    // Check whether the item is eligible for redirect (Status)
                    if (isArticleElgibileForRedirect(singleCon)) {
                        authToRecallRedirect = true;
                    }

                    // If a recall request has been sent to SAP but hasn't been processed, add an info message to the page
                    // Check for both the article and the consignment record. In case where there's a parent consignment, the flag is set on the consignment record
                    if (singleCon.RecallTempLock__c || (singleCon.Consignment__c != null && singleCon.Consignment__r.RecallTempLock__c)) {
                        errorMessages.add('Item Recall is already in progress.');
                        recallInProgress = true;
                    }
                } else {
                    System.debug('>>>>>>>>>>>>>>>>>>>> isArticleAccessible = flase');
                    isConsignmentAuthenticated = false;
                    showCreateCaseButton = false;

                    //Added by David Catindoy to format the destination output to "Suburb, State, Postcode"
                    destination = String.isNotBlank(singleCon.Receiver_Suburb__c) ? singleCon.Receiver_Suburb__c : '';
                    destination += String.isNotBlank(singleCon.ReceiverState__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverState__c : singleCon.ReceiverState__c) : '';
                    destination += String.isNotBlank(singleCon.ReceiverPostcode__c) ? (String.isNotBlank(destination) ? ', ' + singleCon.ReceiverPostcode__c : singleCon.ReceiverPostcode__c) : '';
                }

            } else if (bspBaseUplift.hasSTBillingAccounts || bspBaseUplift.canSearchAllConsignments) {
                System.debug('>>>>>>>>>>>>>>>>>>>> since there were no search results found and the user also has access to startrack billing accounts, we proceed onto the next ST');
                // since there were no search results found and the user also has access to startrack billing accounts, we proceed onto the next ST .net search
                proceedWithSTConSearch = true;
            } else {
                System.debug('>>>>>>>>>>>>>>>>>>>> ERROR_NO_RESULTS 11');
                // nothing was found in the search result and the user doesn't have access to ST billing accounts
                //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error when there's no consignment found.
                errorMessages.add(bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS));
            }
        } else {
            if (bspBaseUplift.hasSTBillingAccounts || bspBaseUplift.canSearchAllConsignments) {
                // since there were no search results found and the user also has access to startrack billing accounts, we proceed onto the next ST .net search
                proceedWithSTConSearch = true;
            } else {
                //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error when there's no consignment found.
                errorMessages.add(bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS));
            }

        }

        // if there were no consignment/article found or the consignment/article found points to a ST product then we need to proceed to search ST .net
        if (proceedWithSTConSearch) {
            System.debug('>>>>>>>>>>>>>>>>>>>> processAPSearchResult: Could not find any results, proceeding with ST search.');
            // proceed with the next search into ST .net.
            // this is the result of no valid article being found in SAP-EM and where the user hass access to both AP and ST billing accounts
            return searchSTAsync(BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, consignmentNumber);
        }

        // return null;
        return buildWrapperToSendToLWC();
    }


    public static void saveAPConsignmentResponse(TIBCOSearchResult searchResult) {
        System.debug('saveAPConsignmentResponse');
        try {
            if (foundArticle(searchResult)) {
                System.debug('foundArticle');
                TIBCODataTranslator translator = new TIBCODataTranslator(searchResult.trackResults);
                translator.save(true, false, true, false);
            }
        } catch (Exception e) {
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage())); //Display an error message when there's an error encountered while saving the consignment/article record.
            errorMessages.add(e.getMessage());
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
    public static Boolean foundArticle(TIBCOSearchResult result) {
        if (!result.success || result.trackResults.size() <= 0) {
            return false;
        }

        for (TIBCOTrackingResultWrapper tr : result.trackResults) {
            if (tr.articleDetails != null || tr.consignmentDetails != null) {
                return true;
            }
        }
        return false;
    }

    /**
     * Start an ASYNC search to query a ST consignment.
     */
    @AuraEnabled(continuation=true)
    public static Continuation searchSTAsync(String searchType, String searchSubject) {

        System.debug('>> searchSTAsync:start ' + searchType + ', ' + searchSubject);

        // set the current search type
        selectedConsignmentSearchType = BspConstants.CONSEARCH_TYPE_STARTRACK;

        singleCon = new Article__c();

        wwwAuspostComAuSchemaCustomercarema.SearchRequest request = BSPConsignmentSearchUtil.generateSearchRequest(searchSubject, searchType, StarTrack_Constants.REQUEST_ACTION_FULL);
        AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = BSPConsignmentSearchUtil.generateAsyncStub();

        try {
            Continuation cont = new Continuation(Integer.valueOf(bspBaseUplift.configSetting.StarTrackAsyncWebServiceTimeout__c));
            cont.continuationMethod = 'processSTSearchResult';
            // emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);
            dummyContState = new StateInfo(emsAsyncStub.beginSearch_x(cont, request), consignmentNumber, selectedConsignmentSearchType);
            cont.state = dummyContState;
            return cont;
        } catch (CalloutException e) {
            if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)) {
                errorMessages.add(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c);
            } else if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)) {
                errorMessages.add(stSettings.StarTrack_ConSearch_Authentication_Error__c);
            } else if (e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)) {
                errorMessages.add(stSettings.StarTrack_ConSearch_Client_Cert_Error__c);
            } else {
                errorMessages.add(Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c);
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
        }

        return null;

    }


    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that process Consignment
    ------------------------------------------------------------*/
    @AuraEnabled(continuation=true)
    public static Object processSTSearchResult(Object state) {

        StateInfo stInfo = (StateInfo) State;
        emsAsyncResponse = stInfo.stResponse;
        consignmentNumber = stInfo.consignmentNumber;
        selectedConsignmentSearchType = stInfo.selectedConsignmentSearchType;

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
        System.debug('>> articleMap.values().size(): ' + articleMap.values().size());
        System.debug('>> articleMap: ' + articleMap);
        System.debug('Is Multiple Consignment >>> ' + bspEnquiryUplift.isMultipleConsignment(conWrapper));
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
            if (!String.isEmpty(conWrapper.errorCode) && conWrapper.errorCode != '0') {
                // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, conWrapper.errorCode)); //Display an error message if there's no consignment found.
                errorMessages.add(conWrapper.errorCode);
            } else {
                //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS))); //Display an error message if there's no consignment found.
                errorMessages.add(bspBaseUplift.getErrorMessage(BspConstants.ERROR_NO_RESULTS));
            }
        }

        //return null;
        return buildWrapperToSendToLWC();
    }

    public static void selectSTConsignment() {

        relatedPODs = new List<Proof_of_Delivery__c>(); //Initialize POD List Containers
        singleCon = [
                SELECT Id, Name, RecordType.Name, ArticleID__c, SenderCompany__c, SenderName__c, SenderAddress__c,
                        Dispatch_Date_Str__c, STServiceType__c, Service_Type__c, DeliveryInstructions__c, ReceiverCompany__c,
                        ReceiverName__c, ReceiverAddress__c, Receiver_Suburb__c, ReceiverState__c, ReceiverPostcode__c, ReceiverCountry__c,
                        ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c,
                        ExpectedDeliveryDate_Str__c, Unit_Type__c, ServiceCode__c, Network__c, Network__r.Name, Customer_Ref__c, Consignment__c,
                        Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.Source_System__c, Billing_Account__r.Organisation__c, SubProduct__c, ArticleLodgementDate__c, ExpectedDeliveryDate__c, RecallTempLock__c, EligibleForRedirect__c
                FROM Article__c
                WHERE ArticleID__c = :articleMap.get(selectedArticle).ArticleID__c
        ];

        //verify is user is authorized to the billing account
        //show PODs and create button if authorized
        if (String.isNotBlank(singleCon.Billing_Account__c) && bspBaseUplift.isArticleAccessible(singleCon)) {
            // ensure the UI will be rendered view the 'authenticated' view
            isConsignmentAuthenticated = true;

            relatedPODs = [
                    SELECT Signed_by__c, POD_Received_Date_Str__c, Delivery_Address__c, Article_Listing__c, QC_Status__c, AttachmentId__c, (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1)
                    FROM Proof_of_Delivery__c
                    WHERE Consignment__c = :singleCon.Id
                    AND AttachmentId__c != null
                    ORDER BY POD_Received_Date__c DESC
            ];

            // since the user has access to the full details of the articles, also allow them to raise a case against the article
            // We only allow a case to be created IF there user already has access to ST billing accounts....
            // REMEMBER: access rules around searching can be bypass with the special 'Can Search All Consignments' options
            if (bspBaseUplift.hasSTBillingAccounts) {
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

    public static void searchLocalEventMessages() {
        System.debug('>>>>>>>>>>>>>>>>>>>> START searchLocalEventMessages');
        labelEvents = new List<EventMessage__c>(); //List of latest event message of each article.
        articleEvents = new List<EventMessage__c>(); //List of all event messages of a particular article.

        APConsignmentSubProduct = singleCon.SubProduct__c;
        APConsignmentLodgementDate = singleCon.ArticleLodgementDate__c;
        APConsignmentExpDeliveryDate = singleCon.ExpectedDeliveryDate__c;

        selectedEventArticle = '';
        Set<Id> labelEventIds = new Set<Id>();
        Set<Id> articleEventIds = new Set<Id>();
        Boolean setConsignmentFieldsFromArticle = false;

        articleEventsMap = new Map<String, Map<Id, EventMessage__c>>(); //Contains all event messages of all child articles. It's using article id as a key.

        if (String.isNotBlank(singleCon.Id)) {
            //The following query retrieves the child articles and their related event messages.
            //Execute child consignments query.
            childConsignments = [
                    SELECT Id, Consignment__c, Name, Consignment__r.Last_Update_Received__c, SubProduct__c, ArticleLodgementDate__c, ExpectedDeliveryDate__c, (
                            SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name, EventDescription__c,
                                    ExternalDescription__c, UserName__c, Article__r.Name, Depot_Code__c, Status__c, StatusText__c
                            FROM Event_Messages__r
                            WHERE ShowtoExternals__c = true
                            ORDER BY ActualDateTime__c DESC
                    )
                    FROM Article__c
                    WHERE Consignment__c = :singleCon.Id
            ];
        }

        System.debug('>>>>>>>>>>>>>>>>>>>> Child Consignments: ' + childConsignments);

        consignmentEvents = [
                SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c, Safe_Drop_GUID__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name,
                        EventDescription__c, ExternalDescription__c, UserName__c, Article__r.Name, Depot_Code__c, Status__c, StatusText__c,
                        EventType__c, (SELECT Id, ParentId, Title FROM NotesAndAttachments where Title Like 'Signature%' ORDER BY CreatedDate DESC LIMIT 1)
                FROM EventMessage__c
                WHERE ShowtoExternals__c = true AND Article__c = :singleCon.Id
                ORDER BY ActualDateTime__c DESC
        ];

        System.debug('>>>>>>>>>>>>>>>>>>>> Consignment Events: ' + consignmentEvents);
        if (!childConsignments.isEmpty()) {
            Integer articleLastEvent;
            for (Article__c childCon : childConsignments) {
                if (childCon.Event_Messages__r.size() > 0) {
                    articleLastEvent = childCon.Event_Messages__r.size() - 1;
                    labelEventIds.add(childCon.Event_Messages__r[0].Id);

                    articleEventsMap.put(childCon.Id, new Map<Id, EventMessage__c>(childCon.Event_Messages__r));
                    articleEventIds.addAll((new Map<Id, EventMessage__c>(childCon.Event_Messages__r)).keyset());
                    /*
                    if(BspConstants.CONSEARCH_TYPE_AUPOST.equals(selectedConsignmentSearchType)){ //This will validate if the consignment retrieved is an AP.
                        articleEventsMap.put(childCon.Id, new Map<Id, EventMessage__c>(childCon.Event_Messages__r));
                        articleEventIds.addAll((new Map<Id, EventMessage__c>(childCon.Event_Messages__r)).keyset());
                    } else{
                        articleEventIds.add(childCon.Event_Messages__r[0].Id);
                    }*/
                }
                if (!setConsignmentFieldsFromArticle) {
                    if (String.isBlank(APConsignmentSubProduct))
                        APConsignmentSubProduct = childCon.SubProduct__c;

                    if (APConsignmentLodgementDate == null)
                        APConsignmentLodgementDate = childCon.ArticleLodgementDate__c;

                    if (APConsignmentExpDeliveryDate == null)
                        APConsignmentExpDeliveryDate = childCon.ExpectedDeliveryDate__c;

                    setConsignmentFieldsFromArticle = true;
                }
            }

            if (!articleEventIds.isEmpty()) {
                //Retrieve the event messages and their attachments.
                for (EventMessage__c eventMessage : [
                        SELECT Id, ActualDateTime_Timestamp__c, ActualDateTime__c,
                                Safe_Drop_GUID__c, WorkCentreText__c, Depot_Name__c, Facility__r.Name, EventType__c,
                                EventDescription__c, ExternalDescription__c, UserName__c, Article__c, Article__r.Name,
                                Depot_Code__c, Status__c, StatusText__c, (
                                SELECT Id, ParentId, Title
                                FROM NotesAndAttachments
                                WHERE Title Like 'Signature%'
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                        )
                        FROM EventMessage__c
                        WHERE Id IN :articleEventIds
                        ORDER BY ActualDateTime__c DESC
                ]) {

                    if (labelEventIds.contains(eventMessage.Id)) {
                        labelEvents.add(eventMessage);
                    }

                    if (articleEventsMap.containsKey(eventMessage.Article__c) && articleEventsMap.get(eventMessage.Article__c).containsKey(eventMessage.Id)) {
                        articleEventsMap.get(eventMessage.Article__c).put(eventMessage.Id, eventMessage);
                    }
                }
            }
        }
        System.debug('searchLocalEventMessages -- END');
    }

    //Get all the event messages related to the selected article.
    //Created by David Catindoy - March 29, 2017
    public static void retrieveArticleEvents() {
        articleEvents = new List<EventMessage__c>();
        if (articleEventsMap.containsKey(selectedEventArticle)) {
            articleEvents = articleEventsMap.get(selectedEventArticle).values();
        }
    }

    /*
     * This method is used to update the GUID in the event message of the article or consignments.
     * The safe drop guid is not returned for merchant profile , hence needs to do explicit call to SAPEM and get the
     * safedrop guid for safe drop event types and update the particluar event messages or articles or consignments and update the guid.
     *
     */
    private static void updateGuidInEventMessages(TIBCOTrackingResultWrapper tr) {
        List<TIBCOEventMessageWrapper> eventMessages = null;
        Integer eventCount = null;
        Set<String> safeDropSigEventTypes = new Set<String>();

        // Get the Safe drop or is Signature on Delivery Event Types.
        for (EventMessageTypeMapping__mdt eventType : EventMessageUtil.getEventMessageTypes().values()) {
            if (('Delivered').equalsIgnoreCase(eventType.Category__c) && (eventType.IsSafeDrop__c || eventType.IsSignatureOnDelivery__c)) {
                safeDropSigEventTypes.add(eventType.Label);
            }
        }

        // get event Message or article or consignment.
        If (tr.articleDetails != null) {
            eventMessages = tr.articleDetails.eventMessages;
        } else if (tr.consignmentDetails != null) {
            eventMessages = tr.consignmentDetails.eventMessages;
        }

        if (eventMessages != null) {
            for (Integer i = 0; i < eventMessages.size(); i++) {
                if (safeDropSigEventTypes.contains(eventMessages[i].proxyEM.EventType__c)) {
                    eventCount = i;
                    // populate the safe drop guid in the latest scanned delivered event, the EventMessages are sorted
                    // with ActualDateTime__c.
                    break;
                }
            }
            // There is an event of safe drop or signature on delivery.
            if (eventCount != null)
                eventMessages[eventCount].proxyEM.Safe_Drop_GUID__c = DeliveryProofService.getSafeDropGuidHttpRequest(tr.trackingID);
        }
    }

    /**
    * Redirects the user to bspEnquiry page when the Create Case button is clicked.
    */
    public PageReference createCaseFromConsignDetail() {
        PageReference createCase = null;
        if (BspConstants.CONSEARCH_TYPE_AUPOST.equals(selectedConsignmentSearchType)) {
            createCase = new PageReference('/bsp/bspEnquiry?conId=' + singleCon.Id + '&conSearch=' + BspConstants.AUTH_SCOPE_AP); //Create case for AP consignment.
        } else {
            createCase = new PageReference('/bsp/bspEnquiry?conId=' + singleCon.Id + '&conSearch=' + BspConstants.AUTH_SCOPE_ST); //Create case for ST consignment.
        }
        return createCase;
    }

    /**
     * @param articleId Consignment Article Id
     * @param isRecall recall or redirect
     * @param redirectDetails a wrapper object with details of where to redirect the article to
     *
     * This is called by the BspAPConsignmentDetails lwc, logic is preserved from existing BSP community
     * @return
     */
    @AuraEnabled
    public static Object submitRedirect(Id articleId, Boolean isRecall, RedirectDetails redirectDetails) {
        User loginUser = bspBaseUplift.getLoggedInUser();
        Contact loginContact = loginUser.Contact;
        Billing_Account__c loginBillingAccount = (loginContact != null ? loginContact.BillingAccount__r : null);
        String billingAccountSource = (loginBillingAccount != null ? loginBillingAccount.Source_System__c : '');

        //pingalis - INC1583984 - Fix to resolve SOQL error .Added SenderAddress information for consignment
        // Check whether the article is a consignment. If not, find the parent consignment and recall/redirect the whole consignment (might have multiple related articles)
        Article__c thisArticle = [
                SELECT Id, Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.LEGACY_ID__c, ProductCategory__c, SubProduct__c, Consignment__c, TrackingID__c,
                        Consignment__r.Billing_Account__c, Consignment__r.Billing_Account__r.Id, Consignment__r.Billing_Account__r.LEGACY_ID__c, Consignment__r.ProductCategory__c, Consignment__r.SubProduct__c,
                        SenderAddressLine1__c, SenderAddressLine2__c, SenderAddressLine3__c, SenderAddressLine4__c, SenderCity__c, SenderState__c, SenderPostcode__c, ArticleLodgementDate__c,
                        Consignment__r.SenderAddressLine1__c, Consignment__r.SenderAddressLine2__c, Consignment__r.SenderAddressLine3__c, Consignment__r.SenderAddressLine4__c, Consignment__r.SenderCity__c, Consignment__r.SenderState__c, Consignment__r.SenderPostcode__c,
                        Consignment__r.ArticleLodgementDate__c, Consignment__r.TrackingID__c
                FROM Article__c
                WHERE Id = :articleId
        ];

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
        caseRecord.CCUEnquiryType__c = 'Feedback';
        caseRecord.Type = 'Feedback';

        // set the billing account to be linked to the case
        // this is used for case visible to other who have access to the set billing account based on the values in accessRoles.
        if (thisArticle.Billing_Account__r != null && String.isNotEmpty(thisArticle.Billing_Account__r.Id) && String.isNotEmpty(thisArticle.Billing_Account__r.LEGACY_ID__c)) {
            caseRecord.Related_Billing_Account__c = thisArticle.Billing_Account__r.Id;
            caseRecord.Billing_Number__c = thisArticle.Billing_Account__r.LEGACY_ID__c;
        } else if (BspConstants.SOURCE_SYSTEM_SAP_ERP.equalsIgnoreCase(billingAccountSource)) {
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

        if (!foundMappingMatch) {
            // No mapping found, perhaps it's a consignment (there are no category and subcategory populated)
            // Grab the first related article and find the category and subcategory based on the article
            Article__c relatedArticle;
            List <Article__c> articles = [SELECT Id, TrackingID__c, ProductCategory__c, SubProduct__c FROM Article__c WHERE Consignment__c = :thisArticle.Id LIMIT 1];

            if (articles.size() == 1) {
                relatedArticle = articles[0];
            }

            if (relatedArticle != null) {
                String relatedKey = (String.isEmpty(relatedArticle.ProductCategory__c) ? '' : relatedArticle.ProductCategory__c.trim()) + (String.isEmpty(relatedArticle.SubProduct__c) ? '' : relatedArticle.SubProduct__c.trim());
                if (!String.isEmpty(relatedKey)) {
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
        caseRecord.BSP_Sender_Company__c = loginUser.CompanyName;
        caseRecord.ContactId = loginUser.ContactId;
        caseRecord.BSP_Sender_Address__c = buildSenderAddress(thisArticle);
        caseRecord.Priority = BspConstants.CASE_PRIORITY_LOW;
        caseRecord.BSP_Addressee_Name__c = redirectDetails.Name;
        caseRecord.BSP_Addressee_Company__c = redirectDetails.Company;
        caseRecord.BSP_Addressee_Address__c = redirectDetails.AddressLine1.trim() + ', ' + redirectDetails.City + ' ' + redirectDetails.State + ' ' + redirectDetails.Country + ' ' + redirectDetails.Postcode;
        caseRecord.Related_Billing_Account__c = thisArticle.Billing_Account__c;
        caseRecord.ArticleTest__c = thisArticle.Id;
        caseRecord.BSPLodgementDate__c = thisArticle.ArticleLodgementDate__c;
        caseRecord.OwnerId = loginUser.Id;
        caseRecord.ReferenceID__c = thisArticle.TrackingID__c;
        try {
            insert caseRecord;
        } catch (System.DmlException ex) {
            throw new ErrorException(ex.getDmlMessage(0));
        }


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
        redirectReq.TimestampLocalTimezone__c = getTimestampLocalTimezone();
        insert redirectReq;

        caseRecord = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseRecord.Id];

        CaseCreationResultWrapper resultWrapper = new CaseCreationResultWrapper();
        resultWrapper.Enquiry = caseRecord;
        resultWrapper.RedirectRequest = redirectReq;
        return resultWrapper;
    }

    /**
     * This function returns the timezone offset in hours string for Recall / Redirect.
     */
    private static string getTimestampLocalTimezone() {
        try {
            string strOffset = System.now().format('Z');
            string hours = strOffset.substring(0, 3);
            strOffset = strOffset.replace(hours, hours + ':');
            return strOffset;
        } catch (Exception e) {
            return '+11:00';
        }
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
        return [
                SELECT SenderCompany__c, SenderName__c, SenderAddressLine1__c, SenderAddressLine2__c, SenderCity__c, SenderCountryName__c,
                        SenderPostcode__c, SenderState__c, Consignment__r.SenderCompany__c, Consignment__r.SenderName__c,
                        Consignment__r.SenderAddressLine1__c, Consignment__r.SenderAddressLine2__c, Consignment__r.SenderCity__c,
                        Consignment__r.SenderCountryName__c, Consignment__r.SenderPostcode__c, Consignment__r.SenderState__c
                FROM Article__c
                WHERE Id = :articleId
        ];
    }


    // VF Remoting methods used for Recall/Redirect functionality
    /**
     * Wrapper object for simpler parsing of Redirect/Recall details, used by BspAPConsignmentDetails LWC
     */
    public class RedirectDetails {
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Company { get; set; }
        @AuraEnabled public String AddressLine1 { get; set; }
        @AuraEnabled public String AddressLine2 { get; set; }
        @AuraEnabled public String City { get; set; }
        @AuraEnabled public String State { get; set; }
        @AuraEnabled public String Postcode { get; set; }
        @AuraEnabled public String Country { get; set; }
    }

    /**
     * Wrapper object to return to LWC on Case Creation.
     */
    public class CaseCreationResultWrapper {
        @AuraEnabled public Case Enquiry { get; set; }
        @AuraEnabled public RedirectRequest__c RedirectRequest { get; set; }
    }

    /** 
    * Custom Exception
    * */
    class ErrorException extends Exception {
    }
}