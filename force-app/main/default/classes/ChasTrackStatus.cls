/**
*
* Help and support : this class is used to determine the final status of the missing items,
* there are more status check could be added, and this is being called from the ChasApexController, and
* helps generate the display messages for the tracking searches.
*
* History :
* --------------------------------------------------
* 2019-08-30 hasantha.liyanage@auspost.com.au Created
* 2019-11-04 nathan.franklin@auspost.com.au Small refactor to remove variables and to add additional logic
* 2020-08-10 hara.sahoo@auspost.com.au Modified - Change made for roll out of Safe Drop feature on Missing Items form
* 2020-09-14 haraprasad.sahoo@auspost.com.au Modified : Change made for roll out of Safe Drop feature on Missing Items form to cater for both consignment and article search in the missing item form.
* 2020-10-06 haraprasad.sahoo@auspost.com.au Modified : Change made for roll out of Safe Drop feature - Implements the consignment search API
* 2020-10-25 haraprasad.sahoo@auspost.com.au Modified : Change made for delivery issue automation. Added hasDeliveredScanEvent and hasAttemptedDeliveryScanEvent
* 2021-04-19 hara.sahoo@auspost.com.au Added date calculations for EDD tracking and related contextual thank you pages
* 2021-09-01 hara.sahoo@auspost.com.au: Added isWithinEDD method which includes additional considerations for ranged EDD pattern
* 2021-11-02 phap.mai@auspost.com.au: DDS-7977 - Added methods to determine if all articles are successed
* 2021-12-06 alex.volkov@auspost.com.au: Added newInstance() method, minor refactoring
* 2022-01-24 alex.volkov@auspost.com.au: Updated isEligibleForMyNetworkAssignment flag to consider all consignment articles statuses
* 2022-01-25 hasantha.liyanage@auspost.com.au DDS-9011 refactor of the constructor ChasTrackStatus(ChasOneTrackResponse,trackingId) to handle multiple articles
*/

public without sharing class ChasTrackStatus {
    public ChasOneTrackResponse.Errors error;
    //public Boolean isWithinEDD;
    public Boolean allArticlesSuccessed;                        // DDS-7977: flag for all articles are either delivered or safe dropped
    public ChasOneTrackResponse response;
    public Integer responseCode;
    public List<ArticleDetailsWrapper> articleDetailsWrappers;  // DDS-9011: list of articles to be held up on parsing the response.
    public class ArticleStatusException extends Exception {}


    /**
    * Initialise must be called as a part of using this class,
    * this method is responsible for preparation of required data for the other methods available to use in this class
    *
    * @param response
    */
    public ChasTrackStatus(ChasOneTrackResponse response, String trackingId) {
        if (response == null) {
            throw new ArticleStatusException('Article could not be found.');
        } else {
            if (response.errors.size() > 0) {
                error = response.errors[0];
                responseCode = error.responseCode;
            }
            //-- take the first article in the response, the tracking id sent could be a consignment id or an article id
            else if (response.articles.size() > 0) {
                // DDS-7977
                // calculate the flag for consignment handling optimization
                // this optimization should not be a show stopper
                // log an exception record for audit purpose
                try {
                    Map<String, Boolean> lArticleFlags = this.getArticlesSuccessFlags(response.articles);
                    this.allArticlesSuccessed = lArticleFlags.get('allSuccess');
                } catch (Exception e) {
                    // set to this value so that the pre-optimization logic will apply
                    this.allArticlesSuccessed = true;

                    // log exception record
                    try {
                        UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'CHAS_LOMI', 'ChasTrackStatus', 'ChasTrackStatus', '', LoggingLevel.ERROR);
                    } catch (Exception loggingException) {
                        // fail silent
                    }
                }
                // DDS-7977: END
                responseCode = 200;
            }
            articleDetailsWrappers = new List<ArticleDetailsWrapper>();
            if (responseCode == 200) {
                // iterate through each article found to prepare the response
                for (ChasOneTrackResponse.Articles article : response.articles) {
                    ArticleDetailsWrapper articleDetailsWrapper = new ArticleDetailsWrapper();
                    articleDetailsWrapper.article = article;
                    articleDetailsWrapper.articleId = article.Id;
                    articleDetailsWrapper.destinationAddress = article.destinationAddress;
                    articleDetailsWrapper.deliverySummary = article.deliverySummary;

                    // grab the safedrop delivered datetime
                    if (articleDetailsWrapper.deliverySummary != null) {
                        if (articleDetailsWrapper.deliverySummary.safeDrop != null) {
                            articleDetailsWrapper.safedropDeliveredDateTime = Datetime.valueOf(articleDetailsWrapper.deliverySummary.safeDrop.eventDateTime.substring(0, 19).replace('T', ' '));
                        }
                    }
                    // grab the dpid
                    if (articleDetailsWrapper.destinationAddress != null) {
                        if (articleDetailsWrapper.destinationAddress.deliveryPoint != null) {
                            articleDetailsWrapper.dpid = String.valueOf(articleDetailsWrapper.destinationAddress.deliveryPoint.id);
                        }
                        // grab the receiver postcode
                        articleDetailsWrapper.receiverPostCode = !String.isEmpty(articleDetailsWrapper.destinationAddress.postcode) ? articleDetailsWrapper.destinationAddress.postcode : null;
                    }

                    // grab the articleType or serviceType
                    if (article.service != null) {
                        articleDetailsWrapper.articleType = String.valueOf(article.service.productType);

                    }
                    // grab the subProductId from the service
                    if (article.service != null) {
                        articleDetailsWrapper.subProductId = String.valueOf(article.service.subProductId);
                    }
                    // grab the trackstatus value from milestone
                    if (article.milestone != null) {
                        articleDetailsWrapper.trackStatusValue = String.valueOf(article.milestone.name);
                    }
                    // grab the hasSignature from deliverySummary
                    if (article.deliverySummary != null && article.deliverySummary.signedFor != null) {
                        articleDetailsWrapper.hasSignature = article.deliverySummary.signedFor;
                    }
                    // get the EDD here so that we can use in later steps of the checks
                    if (article.expectedDelivery != null) {
                        //String parsedDate = response.expectedDelivery.eventDateTime.substring(0,10) + ' ' + ;
                        String eDDStr = ChasUtil.convertToDateWithTimezoneFormat(article.expectedDelivery.eventDateTime);
                        if (eDDStr != null) {
                            articleDetailsWrapper.deliveredByDate = Date.valueOf(eDDStr);
                            // grab the custom setting value for nextUpdateInForLateItems__c, which is basically the no of business days for contact center to monitor the late item
                            articleDetailsWrapper.deliveredByDatePlusBusinessDays = ChasUtil.calculateNextBusinessDay(Date.valueOf(eDDStr), Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c) : 0);
                            // Below block can be removed after 31-12-2021. Not relevant anymore
                            // replacing the below block, with a public method which handles the isWithinEDD check.
                            /*if(Date.Today() <= deliveredByDate)
                            {
                                isWithinEDD = true;
                            }*/
                        }
                    }
                    // get the EDD fromTime and toTime to give an datetime range between which the delivery can be expected
                    if (article.expectedDelivery != null && article.expectedDelivery.between != null) {
                        String eDDStrFrom = ChasUtil.convertToDateWithTimezoneFormat(article.expectedDelivery.between.fromDateTime);
                        String eDDStrTo = ChasUtil.convertToDateWithTimezoneFormat(article.expectedDelivery.between.to);
                        if (eDDStrFrom != null) {
                            articleDetailsWrapper.deliveredByDateFrom = Date.valueOf(eDDStrFrom);
                        }
                        if (eDDStrTo != null) {
                            articleDetailsWrapper.deliveredByDateTo = Date.valueOf(eDDStrTo);
                            // calculate the date until which contact center will monitor the track and communicate with the customer
                            articleDetailsWrapper.deliveredByDateToUntil = ChasUtil.calculateNextBusinessDay(Date.valueOf(eDDStrTo), Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c) : 0);
                        }
                    }
                    //Extract all the events in the response and sort it to get the latest event
                    // events come through the response could contain multiple types of event includes which aren't relevant to our logic,
                    // those events has to be removed and only the relevant once are collected to
                    if (article.trackingEvents != null) {
                        List<ChasOneTrackResponse.Items> relatedEvents = new List<ChasOneTrackResponse.Items>();
                        List<ChasOneTrackResponse.Items> events = article.TrackingEvents.Items;
                        for (Integer i = 0; events.size() > i; i++) {
                            // check the event codes against the delivered event codes as defined in the EVENT_STATUS_ALL
                            if (ChasConstants.EVENT_STATUS_ALL.contains(events[i].code)) {
                                // exclude the Duplicate Case events
                                if (ChasConstants.EVENT_STATUS_CUSTOMER_ENQUIRY_LODGED.equals(events[i].code)) {
                                    articleDetailsWrapper.duplicateCase = events[i].code;
                                    continue;
                                }
                                relatedEvents.add(events[i]);
                            }

                        }
                        // sorting required if events found
                        if (relatedEvents.size() > 0) {
                            // hold the dateTime of every event for comparrision, once a bigger date found it will stored here
                            Datetime storedEventDatetime;
                            for (Integer i = 0; relatedEvents.size() > i; i++) {
                                // the date stored is bigger than
                                if (articleDetailsWrapper.latestEvent == null || storedEventDatetime < Datetime.valueOf(relatedEvents[i].eventDateTime)) {
                                    // store the selected bigger latest dateTime to compare with the next value
                                    System.debug(relatedEvents[i]);
                                    storedEventDatetime = Datetime.valueOf(relatedEvents[i].eventDateTime.substring(0, 19).replace('T', ' '));
                                    articleDetailsWrapper.latestEvent = relatedEvents[i];
                                    // update to the latest WCID if there is one
                                    if (articleDetailsWrapper.latestEvent.workCentreId != null && articleDetailsWrapper.latestEvent.workCentreId != '') {
                                        articleDetailsWrapper.wcid = articleDetailsWrapper.latestEvent.workCentreId;
                                    }
                                    // update to the latest eventCode, message and other values
                                    if (articleDetailsWrapper.latestEvent.code != null && articleDetailsWrapper.latestEvent.code != '') {
                                        articleDetailsWrapper.eventCode = articleDetailsWrapper.latestEvent.code;
                                        //eventCodeMessage = latestEvent.message;
                                        articleDetailsWrapper.eventCodeisAwaitingCollection = articleDetailsWrapper.isAwaitingCollection;
                                    }
                                }
                            }
                            // get the latest event code
                            articleDetailsWrapper.latestEventCode = articleDetailsWrapper.latestEvent.code;
                        }
                    }
                    articleDetailsWrappers.add(articleDetailsWrapper);
                }
            }
        }
    }

    public static ChasTrackStatus newInstance() {
        return (ChasTrackStatus) Application.Utilities.newInstance(ChasTrackStatus.class);
    }

    /**
     * check if all articles are either delivered or safe dropped
     * @author phap.mai@auspost.com.au
     * @param articles: target articles
     * @return true if target article(s) are safe dropped or delivered
     */
    private Map<String, Boolean> getArticlesSuccessFlags(List<ChasOneTrackResponse.Articles> articles) {
        Map<String, Boolean> vArticleSuccessMap = new Map<String, Boolean>();
        vArticleSuccessMap.put('allSuccess', true);
        vArticleSuccessMap.put('allFailed', true);
        // if there is no article, conclude negative and quit early
        if (articles == null || articles.size() == 0) {
            return vArticleSuccessMap;
        }

        for (ChasOneTrackResponse.Articles article : articles) {
            // if any of the articles having no event code, can conclude negative and quit early
            if (article.trackingEvents == null || article.trackingEvents.items == null || article.trackingEvents.items.size() == 0) {
                vArticleSuccessMap.put('allSuccess', false);
                return vArticleSuccessMap;
            } else {
                ChasOneTrackResponse.Items latestEvent = this.getLatestEvent(article.trackingEvents.items);

                // if latest event is null, conclude negative and quit early
                if (latestEvent == null || latestEvent.code == null || String.isEmpty(latestEvent.code)) {
                    vArticleSuccessMap.put('allSuccess', false);
                    return vArticleSuccessMap;
                }

                // if latest event is not safe dropped or delivered, at least 1 article isn't successful
                if (!ChasConstants.EVENT_STATUS_DELIVERED_SAFE_DROP.contains(latestEvent.code) && !ChasConstants.EVENT_STATUS_DELIVERED.contains(latestEvent.code)) {
                    vArticleSuccessMap.put('allSuccess', false);
                }

                // if latest event is safe dropped or delivered, at least 1 article is successful
                if (ChasConstants.EVENT_STATUS_DELIVERED_SAFE_DROP.contains(latestEvent.code) || ChasConstants.EVENT_STATUS_DELIVERED.contains(latestEvent.code)) {
                    vArticleSuccessMap.put('allFailed', false);
                }
            }
            //if it's a partial delivery, return straight away
            if (!vArticleSuccessMap.get('allSuccess') && !vArticleSuccessMap.get('allFailed')) {
                return vArticleSuccessMap;
            }
        }
        return vArticleSuccessMap;
    }

    /**
     * get latest event by comparing event date time
     * @author phap.mai@auspost.com.au
     * @param events: target events
     * @return latest event
     */
    private ChasOneTrackResponse.Items getLatestEvent(List<ChasOneTrackResponse.Items> events) {
        ChasOneTrackResponse.Items latestEvent;
        Datetime latestEventDatetime;

        for (ChasOneTrackResponse.Items event : events) {
            // skip event without code
            if (event.code == null || String.isEmpty(event.code)) continue;

            // skip non-relevant event
            if (!ChasConstants.EVENT_STATUS_ALL.contains(event.code)) continue;

            // skip duplicate case event
            if (ChasConstants.EVENT_STATUS_CUSTOMER_ENQUIRY_LODGED.equals(event.code)) continue;

            // compare and store latest event of this article
            if (latestEventDatetime == null || latestEventDatetime < Datetime.valueOf(event.eventDateTime)) {
                latestEvent = event;
                latestEventDatetime = Datetime.valueOf(event.eventDateTime.substring(0, 19).replace('T', ' '));
            }
        }

        return latestEvent;
    }

    /**
     * DDS-9011 Update ssWizard data structures to store details of articles in consignment
     * Wrapping up individual article details after processing, this will allow us to pass it to the aura
     */
    public class ArticleDetailsWrapper {
        public String wcid = '';
        public String articleId = '';
        public String latestDeliveredScanWcid = '';
        public String previousDeliveredScanWcid = '';
        public String receiverPostCode = '';
        public String eventCode = '';
        public String eventCodeMessage = '';
        public String subProductId = '';
        //public Integer responseCode;
        public Boolean hasSignature = false;
        public Boolean eventCodeisAwaitingCollection = false;
        public Boolean hasDeliveredScan = false;
        public ChasOneTrackResponse.Articles article;
        public ChasOneTrackResponse.Items latestEvent;
        public ChasOneTrackResponse.Items latestDeliveredScanEvent;
        public ChasOneTrackResponse.Items latestAttemptedDeliveredScanEvent;
        public ChasOneTrackResponse.DestinationAddress destinationAddress;
        public ChasOneTrackResponse.DeliverySummary deliverySummary;
        public Date deliveredByDate;
        public Date deliveredByDateFrom;
        public Date deliveredByDateTo;
        public Date deliveredByDatePlusBusinessDays;
        public Date deliveredByDateToUntil;

        // awaiting at the collection point, the location has to be displaYed in the ui at this status
        public Boolean isAwaitingCollection {
            get {
                if (String.isNotEmpty(eventCode) && ChasConstants.EVENT_STATUS_AWAITING_COLLECTION.contains(eventCode)) {
                    return true;
                }
                return false;
            }
            set;
        }
        // it's on board, it's coming today message will be displayed based on this
        public Boolean isOnBoardForDelivery {
            get {
                if (String.isNotEmpty(latestEventCode) && ChasConstants.EVENT_STATUS_ONBOARD_FOR_DELIVERY.contains(latestEventCode)) {
                    return true;
                }
                return false;
            }
            set;
        }
        // when no EDD returned
        public Boolean isNoEDDReturned {
            get {
                if (deliveredByDate == null && !trackStatusValue.equalsIgnoreCase('Pending') &&
                        String.isNotEmpty(latestEventCode) &&
                        !ChasConstants.EVENT_STATUS_ALL.contains(latestEventCode)) {
                    return true;
                }
                return false;
            }
            set;
        }

        // check if current date is within EDD- Added 01/09/2021
        // additional considerations: if there is a EDD date range available, consier the higher date range "deliveredByDateTo"
        // if no date range available, safe assumption, EDD is equal to the one returned in deliveredByDate
        public Boolean isWithinEDD {
            get {
                return deliveredByDateTo != null ? Date.Today() <= deliveredByDateTo : (deliveredByDate != null ? Date.Today() <= deliveredByDate : false);
            }

        }
        // check if current date is within EDD Plus Business days
        public Boolean isEnquiryDateWithinEDDPlusBusinessdays {
            get {
                return deliveredByDateTo != null ? ChasUtil.isTheDateWithinEDDPlusBusinessdays(deliveredByDateTo) : (deliveredByDate != null ? ChasUtil.isTheDateWithinEDDPlusBusinessdays(deliveredByDate) : false);
            }
            set;
        }
        // check if current date is past EDD Plus Business days
        public Boolean isEnquiryDatePastEDDPlusBusinessdays {
            get {
                return deliveredByDateTo != null ? ChasUtil.isTheDatePastEDDPlusBusinessdays(deliveredByDateTo) : (deliveredByDate != null ? ChasUtil.isTheDatePastEDDPlusBusinessdays(deliveredByDate) : false);
            }
            set;
        }
        /**
    * item will be delivered on time
    * if the EDD available , and
    * if the EDD is before Today's date, and
    * if the latest event code not in EVENT_STATUS_ALL (see the constatnt for all the codes) , and
    * if tracking status is not 'Pending' (pending : when there are no events)
    *
    * if all the bnove satisfies this will be considered as delivery is going to happen on time
    */
        public Boolean isDeliveryOnTime {
            get {
                if (deliveredByDate != null &&
                        ChasUtil.isTheDateIsBefore(deliveredByDate) && (latestEvent == null ||
                        !ChasConstants.EVENT_STATUS_ALL.contains(latestEventCode)) &&
                        !trackStatusValue.equalsIgnoreCase('Pending')) {
                    return true;
                }
                return false;
            }
            set;
        }
        /**
    * item will be delivered on time
    * if the EDD available , and
    * if the EDD is after Today's date, and
    * if the latest event code not in EVENT_STATUS_ALL (see the constatnt for all the codes) , and
    * if tracking status is not 'Pending'
    *
    * if all the bnove satisfies this will be considered as delivery is going to happen on time
    */
        public Boolean isDeliveringLate {
            get {

                if (deliveredByDate != null && ChasUtil.isTheDateIsPast(deliveredByDate) &&
                        (String.isEmpty(latestEventCode) ||
                                !ChasConstants.EVENT_STATUS_ALL.contains(latestEventCode)) &&
                        !trackStatusValue.equalsIgnoreCase('Pending')) {
                    return true;
                }
                return false;
            }
            set;
        }

        // is delivered, siply cehck for the delivered codes
        public Boolean isDelivered {
            get {
                if (String.isNotEmpty(latestEventCode) && ChasConstants.EVENT_STATUS_DELIVERED.contains(latestEventCode)) {
                    return true;
                }
                return false;
            }
            set;
        }

        //No scan events found and the tracking Status is always Pending meand the item is not scanned yet
        public Boolean isNotScannedYet {
            get {
                if (latestEvent == null && trackStatusValue.equalsIgnoreCase('Pending')) {
                    return true;
                }
                return false;
            }
            set;
        }

        // delivered left in a safe place
        public Boolean isDeliveredLeftInASafePlace {
            get {
                if (String.isNotEmpty(latestEventCode) && ChasConstants.EVENT_STATUS_DELIVERED_SAFE_DROP.contains(latestEventCode)) {
                    return true;
                }
                return false;
            }
            set;
        }

        public String duplicateCase {
            get {
                if (duplicateCase == null) {
                    return '';
                }
                return duplicateCase;
            }
            set;
        }
        public DateTime safedropDeliveredDateTime {
            get {
                if (safedropDeliveredDateTime == null) {
                    return null;
                }

                return safedropDeliveredDateTime;
            }
            set;
        }
        public String latestEventCode {
            get {
                if (latestEventCode == null) {
                    return '';
                }
                return latestEventCode;
            }
            set;
        }
        public String dpid {
            get {
                if (dpid == null) {
                    return '';
                }
                return dpid;
            }
            set;
        }
        public String articleType {
            get {
                if (articleType == null) {
                    return '';
                }
                return articleType;
            }
            set;
        }
        public String trackStatusValue {
            get {
                if (trackStatusValue == null) {
                    return '';
                }
                return trackStatusValue;
            }
            set;
        }
        /**
    * Determines whether a inflight redirection is applied
    */

        public Boolean isRedirectApplied {
            get {
                Boolean isRedirectApplied = false;
                if (article.deliveryInstructions != null && article.deliveryInstructions.redirect.status != null) {
                    if (ChasConstants.SAFE_DROP_REDIRECT_ELIG_CODES.contains(article.deliveryInstructions.redirect.status)) {
                        isRedirectApplied = false;
                    } else {
                        isRedirectApplied = true;
                    }
                }
                return isRedirectApplied;

            }
        }
        public Boolean isReturnToSender {
            get {


                if (isReturnToSender == null) {
                    Set<String> clonedCodes = eventCodes.clone();

                    // remove all of the RTS event codes from the event codes list and compare the size
                    // if the size differs then an RTS code was removed and we know the article has RTS scans on it.
                    clonedCodes.removeAll(new Set<String>{
                            'DOM-0028',
                            'DOM-0029',
                            'NT-ER20',
                            'TTP-ER2',
                            'TTP-ER20',
                            'TTP-ER21',
                            'TTP-ER22',
                            'TTP-ER23',
                            'TTP-ER24',
                            'TTP-ER25',
                            'TTP-ER3',
                            'INT-2020',
                            'INT-2042',
                            'INT-2123',
                            'INT-2155'
                    });
                    isReturnToSender = (clonedCodes.size() != eventCodes.size());
                }
                return isReturnToSender;
            }
            private set;
        }
        /**
    * Stores a list of event codes scanned for the article for easy comparisons
    */
        public Set<String> eventCodes {
            get {
                if (eventCodes == null) {
                    eventCodes = new Set<String>();
                    if (article != null && article.TrackingEvents.Items != null) {
                        for (ChasOneTrackResponse.Items event : article.TrackingEvents.Items) {
                            eventCodes.add(event.code);
                        }
                    }
                }
                return eventCodes;
            }
            private set;
        }
        /* Check if the response contains a safedrop ineligibility code as part of the delivery instructions*/
        public Boolean deliveryChoicesSafeDropIneligibilityCode {
            get {
                Boolean isEligibleForNetwork = true;
                if (deliveryChoicesSafeDropIneligibilityCode == null) {
                    if (article.deliveryInstructions != null && article.deliveryInstructions.safeDrop.locationChange.reasonCode != null) {
                        // check for the codes, if it applies disqualify it from network eligibility
                        if (ChasConstants.SAFE_DROP_INELIG_SIG_CODES.contains(article.deliveryInstructions.safeDrop.locationChange.reasonCode)) {
                            isEligibleForNetwork = false;
                        }
                    }
                }
                return isEligibleForNetwork;
            }
            private set;
        }
        // Cases can be assigned to MyNetwork directly if:
        // 1. isDelivered , isDeliveredLeftInASafePlace : There is a delivered scan and it's not safe drop
        // 2. isReturnToSender : Is does not have a return to sender scan
        // 3. hasCustomerSignedFor : This is a boolean returned from the service to suggest is customer has signed for the consignment, if yes dont send to network
        // 4.  duplicateCase : No existing case
        // 5. if part of a consignment: all articles are in the consignment are delivered
        public Boolean isEligibleForMyNetworkAssignment {
            get {
                if (isEligibleForMyNetworkAssignment == null) {
                    isEligibleForMyNetworkAssignment = false;
                    //-- Commenting the piece of code with the hasCustomerSignedFor till SAP-EM deliver the fix
                    //if(String.isEmpty(duplicateCase) && !isReturnToSender && isDelivered && !isDeliveredLeftInASafePlace && (! hasCustomerSignedFor)) {
                    if (String.isEmpty(duplicateCase) && !isReturnToSender && isDelivered && !isDeliveredLeftInASafePlace) {
                        isEligibleForMyNetworkAssignment = true;
                    }
                }
                return isEligibleForMyNetworkAssignment;
            }
            private set;
        }
        /**
    * Checks if there is a delivered scan event
    */
        public String hasDeliveredScanEvent {
            get {
                if (hasDeliveredScanEvent == null) {
                    List<ChasOneTrackResponse.Items> events = article.TrackingEvents.Items;
                    List<ChasOneTrackResponse.Items> allEvents = new List<ChasOneTrackResponse.Items>();
                    Set<String> allEventTypes = new Set<String>();
                    allEventTypes = ChasConstants.DELIVERED_EVENT_TYPES_ALL.keyset();
                    //-- fetch the events from the response and look for a delivered scan
                    if (article.trackingEvents != null) {
                        for (Integer i = 0; events.size() > i; i++) {
                            if (allEventTypes.contains(events[i].code)) {
                                allEvents.add(events[i]);
                            }
                        }
                    }

                    if (allEvents.size() > 0) {
                        hasDeliveredScan = true;
                        Datetime storedEventDatetime;
                        for (Integer i = 0; i < allEvents.size(); i++) {
                            if (latestDeliveredScanEvent == null || storedEventDatetime < Datetime.valueOf(allEvents[i].eventDateTime)) {
                                storedEventDatetime = Datetime.valueOf(allEvents[i].eventDateTime.substring(0, 19).replace('T', ' '));
                                latestDeliveredScanEvent = allEvents[i];
                                //-- update to the latest WCID if there is one
                                if (latestDeliveredScanEvent.workCentreId != null && latestDeliveredScanEvent.workCentreId != '') {
                                    //-- latest delivered scan event work center id
                                    latestDeliveredScanWcid = latestDeliveredScanEvent.workCentreId;
                                }
                            }
                        }

                        if (latestDeliveredScanEvent.code != null && latestDeliveredScanEvent.code != '') {
                            //-- keeps a record of the delivered scan wcid
                            previousDeliveredScanWcid = latestDeliveredScanEvent.workCentreId;
                            //-- check if the latest event code is awaiting collection, then check if there was an attempted delivery scan
                            if (String.isNotEmpty(latestDeliveredScanEvent.code) && ChasConstants.EVENT_STATUS_AWAITING_COLLECTION.contains(latestDeliveredScanEvent.code)) {
                                latestDeliveredScanWcid = hasAttemptedDeliveryScanEvent;
                            }
                        }
                    }
                }
                return latestDeliveredScanWcid;
            }
            private set;
        }
        /**
    * Checks if there is an attempted delivery scan event and returns the wcid associated with the latest attempted delivery scan event
    As there could be multiple delivery attempts made, we need to loop over the events, assuming there could be multiple event codes
    */
        public String hasAttemptedDeliveryScanEvent {
            get {
                if (hasAttemptedDeliveryScanEvent == null) {
                    List<ChasOneTrackResponse.Items> events = article.TrackingEvents.Items;
                    List<ChasOneTrackResponse.Items> allAttemptedDeliveryEvents = new List<ChasOneTrackResponse.Items>();
                    Set<String> allEventTypes = new Set<String>();
                    Set<String> validEventCodes = new Set<String>();
                    Map<String, String> allEventTypeMap = new Map<String, String>();
                    allEventTypeMap = ChasConstants.DELIVERED_EVENT_TYPES_ALL;
                    allEventTypes = ChasConstants.DELIVERED_EVENT_TYPES_ALL.keyset();
                    //-- fetch the attempted delivery events codes
                    if (allEventTypes.size() > 0) {
                        for (String eventCode : allEventTypes) {
                            if (allEventTypeMap.get(eventCode) == 'AttemptedDelivery') {
                                validEventCodes.add(eventCode);
                            }
                        }
                    }


                    //-- fetch the events from the response and look for a delivered scan
                    if (article.trackingEvents != null) {
                        for (Integer i = 0; events.size() > i; i++) {
                            if (validEventCodes.contains(events[i].code)) {
                                allAttemptedDeliveryEvents.add(events[i]);
                            }
                        }
                    }
                    if (allAttemptedDeliveryEvents.size() > 0) {
                        Datetime storedEventDatetime;
                        for (Integer i = 0; i < allAttemptedDeliveryEvents.size(); i++) {
                            if (latestAttemptedDeliveredScanEvent == null || storedEventDatetime < Datetime.valueOf(allAttemptedDeliveryEvents[i].eventDateTime)) {
                                storedEventDatetime = Datetime.valueOf(allAttemptedDeliveryEvents[i].eventDateTime.substring(0, 19).replace('T', ' '));
                                latestAttemptedDeliveredScanEvent = allAttemptedDeliveryEvents[i];
                                //--update to the latest WCID if there is one
                                if (latestAttemptedDeliveredScanEvent.workCentreId != null && latestAttemptedDeliveredScanEvent.workCentreId != '') {
                                    //-- latest delivered scan event work center id. If attempted delivery scan exists, assign to the network that created this scan.
                                    latestDeliveredScanWcid = latestAttemptedDeliveredScanEvent.workCentreId;
                                }
                                //-- If attempted delivery scan does not exist (only awaiting collection scan does) this case is not eligible for network assignment.
                                else {
                                    latestDeliveredScanWcid = null;
                                }
                            }
                        }
                    }
                    //-- If attempted delivery scan does not exist (only awaiting collection scan does) this case is not eligible for network assignment.
                    else {
                        latestDeliveredScanWcid = null;
                    }

                }
                return latestDeliveredScanWcid;
            }
            private set;
        }
    }
}