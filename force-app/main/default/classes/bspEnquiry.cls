/**************************************************
Type:         Controller for visualforce page bspEnquiry
History:
NOTE:         Need to use without sharing: as Owner for the created case will be set to "Enterprise Inbound Queue"
NOTE:                                    : additional fields, objects won't be quieried successfully if without sharing is not used...
TODO            ^^ Refactor code to remove without sharing....Nathan Franklin - 2019-07
--------------------------------------------------
2014-04-17    Louis Wang (Bluewolf)        Created.
2015-09-15    Paul Stamer changed BSP Priority to Low
2015-10-06    Paul Stamer For general enquiry/mail redirection refered to custom setting for Product Category, Product Sub Category & Enquiry Sub Type
2016-14-04    Nathan Main / Kenny Liew - Modified controller to support My Post Business.
2016-08-03    Ramya Chintakula  - Added logic for custom setting fetch for 'StarTrack (Next Flight Premium & Express)'
2016-11-17    Jen Karen Tan - StarTrack - Updated Enquiry retrieval and
							  added creation of Delivery, General, and Pickup Booking Enquiries
2017-01-10    Jen Karen Tan - StarTrack - added bulk close and bulk update (add comment)
2017-02-01    David Catindoy (Accenture) - Amended case creation logic to separate StarTrack Case creation mechanism with AusPost
2017-02-06    David Catindoy (Accenture) - Added couple of StarTrack methods to cater ST BSP Case creation scenarios.
2017-02-28    David Catindoy (Accenture) - Added some filter to exclude MpbHspEnquiry from having unneccessary R5 changes.
2017-04-06    Andrew Judd (Salesforce)- B1647 - Changed setting of Contact Type to 'Sender' in StarTrack method createEnquiry
2018-04-27    SaiSwetha Pingali - REQ1408640 - Added logic in generateWhere to filter cases based on 'Exclude_case_types__c' in custom settings 'BSP Settings'
2018-07-24    Disha kariya (Accenture)- Changed submitPageMpbHsp to accept Enquiry Type Growing Global
2018-08-02    SaiSwetha Pingali - REQ1496210 - Added sorting for other fields and logic in generateWhere to filter cases based on 'Exclude_case_purpose__c' in custom settings 'BSP Settings'
2018-11-09    dilshan.egodawela@auspost.com.au added condition for Priority Customer
2018-11-02    disha.kariya@auspost.com.au   -   Exclude POD Request for AusPost Enquiry as generate certificate from BSPConsignmentSearch Page
2018-11-21    hasantha.liyanage@auspost.com.au   -   adding download all link to case list.
2019-02-11    saiswetha.pingali@auspost.com.au  -  INC1282994  set case originator as Sender for Missing Item and Disputed Delivery
2019-04-19    nathan.franklin@auspost.com.au - Large refactor to support the onboarding of BAM Self service portal
2019-05-04    Hasantha.liyanage@auspost.com.au embedded drag and drop component and the billing account dropdown changes on top of refactored changes
2019-08-26    saiswetha.pingali@auspost.com.au Null check for CCUEnquiryType__c
2019-12-06    gunith.devasurendra@auspost.com.au Fix CSV export to export the correct status (INC1511690)
2020-01-05    gunith.devasurendra@auspost.com.au All new AusPost BSP cases to have Sender has Originator (REQ2048088)
2019-09-04    gunith.devasurendra@auspost.com.au Remove check for Enterprise SLA type so that the Case would be always routed (INC1330896)
2020-04-22 - Nathan Franklin - Commented out unused code
2021-10-11 - Seth Heang - Uplift the SF API version to 52
2021-11-29 - PRERNA RAHANGDALE  Added the new Enquiry types and Enquiry sub types for MPB enquires and update to SubmitPageMpbHsp method.
**************************************************/
public without sharing class bspEnquiry extends bspBase {

    // This is used to store the SAP EM query results during validation before the case is created on the AP side
    public AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture trackResults {get; set;}

    public Case enq {get;set;}
    public Case dummyEnq1 {get;set;}
    public String section {get;set;}
    public String descript {get; set;}
    public String descofcontents {get;set;} // Description of Contents

    public String fromWhoRadio {get;set;}
    public String indOrgEnquiryFlag {get;set;}
    public Integer dynamicPageSize {get; set;}
    public String lastKey {get; set;}
    public Boolean bulkUpload {get; set;}
    public Blob csvBlob {get; set;}
    public Boolean dontSave {get; set;}
    public Integer bulkUploadCases {get; set;}

    // Unused - Can remove 2020-08
    //public Profile loggedInProfile { get; set;}

    public transient Boolean formSubmitted { get; set; }

    public String conSearch {get; set;}
    public static String sortBy {get; set;}
    public String columnDir {get; set;}
    public static String sortColumnDir {get; set;}

    // QAS
    public AddressExtension toAddress {get;set;}
    public AddressExtension fromAddress {get;set;}

    // attachment
    public boolean showAttachmentButtonFlag {get;set;}
    public String fileName {get;set;}
    public Blob fileBody {get;set;}
    public Decimal fileBodyLength {get;set;}
    public String fileContentType {get;set;}

    /**** START - following functions are for pagination ***/
    public Integer SEARCH_LIMIT {get;set;}
    public static Integer SIZE_PER_PAGE {get;set;}
    public Integer noOfRecordsReturned{ get; set;}
    public Pagination pageCon { get; set; }
    public String searchText { get; set; }

    public String multipleCaseError {get; set;}

    // relatedTo is a page filter where the user can limit the query to either only AP or ST cases
    public String relatedTo {get; set;}

    public String caseRecStatus {get; set;}
    private List<Authorization_Rule__c> BAList = new List <Authorization_Rule__c>();

    public Set<Id> recordTypes = new Set<Id>();

    public String consignmentNumber { get; set; }
    public String billingAccountNumber { get; set; }
    public boolean confirmCreation {get;set;}
    public boolean notFound {get;set;}
    public boolean duplicate {get;set;}

    public StarTrackConsignmentSearchUtil.ConsignmentWrapper searchedConsignment {get; set;}
    public StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();

    public boolean showSuccessMessage {get;set;}

    public Map<String, Id> caseNumbers {get; set;}
    public Article__c articleFromConsignSearch;
    public Article__c currentConsignment {get; set;}

    // Defines that the new case form should be displayed when a consignment id is passed from the consignment search page to this page
    public Boolean creationFromConsignSearch {get; set;}

    public Case newCase {get; set;}
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public List<Case> casesToUpdateBulk = new List<Case>();
    public String caseCommentBulk {get; set;}
    public String selectedEnquiryType {get; set;}
    public List<Case> myCaseList_Paginated { get; set; }
    public List<CaseContainer> myCaseListContainer_Paginated { get; set; }
    public List<CaseContainer> completeList_Paginated {get;set;}
    public Set<String> statusValuesList {get; set;}

    // Stores a list of StarTrack product id's that may be surfaced from SAP EM
    // This is used to indicate that the consignment should be searched using the ST .net search
    public transient Map<String, StarTrackConsignmentProductIDs__c> startrackProdIDs {
        get {
            return StarTrackConsignmentProductIDs__c.getAll();
        }
    }

    // Hasantha (30/01/2019) : holder for selected billing account
    public String selectedBillingAccount {get; set;}

    //hans 02/05/2019 embedded dropzone file upload -- start --
    public List<string> contentDocVersionIds {get
    {
        if(contentDocVersionIds == null) {
            contentDocVersionIds = new List<string>();
        }
        return contentDocVersionIds;
    } set;}

    public List<string> contentDocVersionNames {get
    {
        if(contentDocVersionNames == null) {
            contentDocVersionNames = new List<string>();
        }
        return contentDocVersionNames;
    } set;}

    //mapping file extensions and mime types used while converting attachment to files and vice versa
    public static final map<string,string> mimeTypeMapping = new map<string,string>{
            'png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'htm' => 'text/html', 'html' => 'text/html',
            'pdf' => 'application/pdf', 'doc' => 'application/msword', 'docx' => 'application/msword',
            'xls' => 'application/vnd.ms-excel', 'xlsx' => 'application/vnd.ms-excel', 'ppt' => 'application/vnd.ms-powerpoint',
            'pptx' => 'application/vnd.ms-powerpoint', 'txt' => 'text/plain'
    };

    public string fileBodyLengthdz {get; set;}
    public string fileContentTypedz {get; set;}
    public string fileNamedz {get; set;}
    public transient string fileBodydz {get; set;}
    public Object fileObjectList {get; set;}
    //hans 02/05/2019 embedded dropzone file upload -- end --

    // stores the continuation response from .net StarTrack consignment search
    public AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse;

    // prepare and store data to be downloaded for user by clicking "Download All" link
    public Object caseDetais {get; set;}

    public bspEnquiry() {
        super();

        // sets the default enquiry type to be used when creating a case
        setDefaultEnquiryType();

        //Set header for page rendering and security for IE8
        setPageHeaders();

        // Unused - Can remove 2020-08
        //loggedInProfile = [SELECT Id FROM Profile WHERE Name =: BspConstants.BSP_COMMUNITY_PROFILE_NAME];

        initialisePaginationParam();

        indOrgEnquiryFlag = BspConstants.SELECT_OPTION_VALUE_ALL_ORG_ENQ;
        if(isMpbHspFlag){
            section = BspConstants.PAGE_SECTION_LANDING;
            dynamicPageSize = Integer.valueOf(configSetting.EnquiriesPerPage__c);
            displayCaseList();
        } else {
            currentConsignment = null;
            retrieveRecordTypes();
            dummyEnq1 = new Case();
            dummyEnq1.End_Date__c = null;
            dummyEnq1.Start_Date__c = null;

            //start code changes for REQ1496210
            columnDir = '';
            //trackNumDir = '';
            //sendingToDir = '';
            //end code changes for REQ1496210

            statusValuesList = new Set<String>();

            //initialization for case creation from consignment search page
            String conId = Apexpages.currentPage().getParameters().get('conId');
            conSearch = Apexpages.currentPage().getParameters().get('conSearch');

            // check if we need to display the 'home page' or whether the new case form is required
            if (String.isBlank(conId)) {
                //assign initial values - case creation not from consignment search page
                creationFromConsignSearch = false;
                section = BspConstants.PAGE_SECTION_LANDING;
                dynamicPageSize = Integer.valueOf(configSetting.EnquiriesPerPage__c);
                displayCaseList();
                confirmCreation = false;
                notFound = false;
                duplicate = false;
                showSuccessMessage = false;
            } else {
                // a consignment id was passed into this page so we need to show the new case form.
                // should probably have been implemented in a separate class and a separate page!!

                //assign initial values - case creation from consignment search page
                section = BspConstants.PAGE_SECTION_ENQUIRY;
                enq = new Case();

                List<Article__c> articleList = new List<Article__c>([SELECT Id, Name, Billing_Account__c, Billing_Account__r.Source_System__c, Billing_Account__r.LEGACY_ID__c, ArticleID__c, ArticleLodgementDate__c, ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverCity__c,
                        ReceiverState__c, ReceiverPostcode__c, ReceiverCountry__c, ReceiverCountryName__c, ReceiverCompany__c, ReceiverName__c, SenderName__c, SenderCompany__c, SenderAddressLine1__c, SenderAddressLine2__c, SenderCity__c, SenderState__c,
                        SenderPostcode__c, SenderCountry__c, ProductCategory__c,Billing_Account__r.Organisation__c,
                (select ArticleLodgementDate__c, ProductCategory__c FROM Articles__r LIMIT 1)
                FROM Article__c
                WHERE Id =: conId]);

                // since the consignment is prepopulated as a querystring param,
                if(!articleList.isEmpty() && isArticleAccessible(articleList[0])) {

                    if((isBillingAccountAP(articleList[0].Billing_Account__r) && !hasAPBillingAccounts) || (isBillingAccountST(articleList[0].Billing_Account__r) && !hasSTBillingAccounts)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are not authorised to use this consignment.'));
                    } else {
                        if(BspConstants.AUTH_SCOPE_AP.equals(conSearch)) {
                            articleFromConsignSearch = articleList[0];
                            enq.CCUEnquiryType__c = BspConstants.CASE_CCU_ENQUIRY_TYPE_ITEM_SEARCH;
                            enq.ReferenceID__c = articleFromConsignSearch.ArticleID__c;

                            // Get Lodgement Date Child Article, if required
                            if(articleFromConsignSearch.ArticleLodgementDate__c != null) {
                                enq.BSPLodgementDate__c = articleFromConsignSearch.ArticleLodgementDate__c;
                            } else {
                                if(articleFromConsignSearch.Articles__r.size() > 0) enq.BSPLodgementDate__c = articleFromConsignSearch.Articles__r[0].ArticleLodgementDate__c;
                            }

                            // Get Sub Product from Child Article, if required
                            if(String.isNotBlank(articleFromConsignSearch.ProductCategory__c)) {
                                enq.CCUServiceUsed__c = articleFromConsignSearch.ProductCategory__c;
                            } else {
                                if(articleFromConsignSearch.Articles__r.size() > 0)  enq.CCUServiceUsed__c = articleFromConsignSearch.Articles__r[0].ProductCategory__c;
                            }

                            // Set Parcel as default for Article Type
                            enq.ArticleType__c = 'Parcel';
                            enq.ArticleTest__c = articleFromConsignSearch.Id;

                            List<String> receiverName = String.isNotBlank(articleFromConsignSearch.ReceiverName__c) ? articleFromConsignSearch.ReceiverName__c.split(' ') : new List<String>();
                            if(!receiverName.isEmpty()){
                                enq.SecondaryContactFirstName__c = receiverName[0];
                                enq.SecondaryContactLastName__c = receiverName.size() > 1 ? receiverName[1] : '';
                            }

                            enq.SecondaryAccount__c = articleFromConsignSearch.ReceiverCompany__c;
                            selectedEnquiryType = BspConstants.ENQUIRY_TYPE_AP;
                            creationFromConsignSearch = true;

                            // initialise From and To Block
                            initialiseFromBlock();
                            initialiseToBlock();
                        } else{
                            enq.CCUEnquiryType__c = BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY;
                            refreshPage();
                            articleFromConsignSearch = articleList[0];
                            consignmentNumber = articleFromConsignSearch.Name;
                            creationFromConsignSearch = true;
                            selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
                        }
                    }
                } else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are not authorised to use this consignment.'));
                }
            }
        }
    }

    public void retrieveRecordTypes() {
        for (BSPStarTrackCaseTypes__c cType : [SELECT Id, Name, RecordTypeId__c FROM BSPStarTrackCaseTypes__c WHERE Name LIKE 'StarTrack%']) {
            recordTypes.add(cType.RecordTypeId__c);
        }
    }

    //
    // 2016-03-23 CLIEW / NM: START -- New Methods for MyPost Business
    //
    public List<SelectOption> getMpbCaseType() {
        return getPicklistValues(BspConstants.FIELD_API_NAME_ENQUIRY_TYPE, true, BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT);
    }

    public List<SelectOption> getTechMpbCaseType() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('',BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_MPB_TECH_XHIST_ENQ, BspConstants.ENQUIRY_TYPE_MPB_TECH_XHIST_ENQ));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_MPB_TECH_ERROR_ENQ, BspConstants.ENQUIRY_TYPE_MPB_TECH_ERROR_ENQ));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_MPB_TECH_PLATINT_ENQ, BspConstants.ENQUIRY_TYPE_MPB_TECH_PLATINT_ENQ));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_MPB_TECH_SYSTEM_ENQ, BspConstants.ENQUIRY_TYPE_MPB_TECH_SYSTEM_ENQ));
        return options;
    }

    /** PB New Enquiry sub type picklist value START **/

    public List<SelectOption> getMPBLabelSubEnqPicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('',BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_LABEL_ENQ_REFUND, BspConstants.SELECT_OPTION_MPB_LABEL_ENQ_REFUND));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_LABEL_ENQ_LABEL_SUPPORT, BspConstants.SELECT_OPTION_MPB_LABEL_ENQ_LABEL_SUPPORT));
        return options;
    }

    public List<SelectOption> getMPBPickUpEnqPicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('',BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_PICKUP_FAILURE, BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_PICKUP_FAILURE));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_GENERAL, BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_GENERAL));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_CHANGE_REQUEST, BspConstants.SELECT_OPTION_MPB_PICKUP_ENQ_CHANGE_REQUEST));

        return options;
    }

    public List<SelectOption> getMPBPricEnqPicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('',BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_DISCOUNT, BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_DISCOUNT));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_SEND_VOL, BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_SEND_VOL));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_DISPUTED, BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_DISPUTED));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_MORE_INFO, BspConstants.SELECT_OPTION_MPB_PRICING_ENQ_MORE_INFO));

        return options;
    }

    public List<SelectOption> getMPBDelEnqPicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('',BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_DEL_ENQ_TRACKING, BspConstants.SELECT_OPTION_MPB_DEL_ENQ_TRACKING));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_DEL_ENQ_DISPUTE, BspConstants.SELECT_OPTION_MPB_DEL_ENQ_DISPUTE));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_DEL_ENQ_MISSING, BspConstants.SELECT_OPTION_MPB_DEL_ENQ_MISSING));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_DEL_ENQ_DAMAGED, BspConstants.SELECT_OPTION_MPB_DEL_ENQ_DAMAGED));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_MPB_DEL_ENQ_RETURN, BspConstants.SELECT_OPTION_MPB_DEL_ENQ_RETURN));
        return options;
    }


    /** PB New Enquiry sub type picklist value END **/


    //
    // 2016-03-23 CLIEW / NM: END of New Methods for MyPost Business
    //

    /**
     * Used to set the default enquiry type when a new case is being created.
     */
    private void setDefaultEnquiryType() {
        if(hasSTBillingAccounts) {
            selectedEnquiryType = BspConstants.ENQUIRY_TYPE_ST;
        } else {
            selectedEnquiryType = BspConstants.ENQUIRY_TYPE_AP;
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

    public List<SelectOption> getPicklistValues(String picklistFieldName, boolean blankEntryRequired, String blankEntryLabel) {
        // this function generates picklist values
        Schema.sObjectType sobject_type = Case.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();

        List<Schema.PicklistEntry> pick_list_values = field_map.get(picklistFieldName).getDescribe().getPickListValues();
        List<selectOption> options = new List<selectOption>();
        List<selectOption> STOptions = new List<selectOption>();
        if(blankEntryRequired == true) {
            options.add(new SelectOption('', blankEntryLabel));
        }
        System.debug('selectedEnquiryType--->'+selectedEnquiryType);
        if(!isMpbHspFlag && (userBillingAccountScope == BspConstants.AUTH_SCOPE_ST || BspConstants.ENQUIRY_TYPE_ST.equals(selectedEnquiryType))) {
            options.add(new SelectOption(BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY, BspConstants.ENQUIRY_TYPE_DELIVERY_ISSUE_LBL));
            options.add(new SelectOption(BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY, BspConstants.ENQUIRY_TYPE_PCKUP_BOOKING_LBL));
        } else {
            for (Schema.PicklistEntry a : pick_list_values) {
                // Added below check to exclude POD Request for AusPost Enquiry
                if(!(BspConstants.ENQUIRY_TYPE_POD_REQUEST.equalsIgnoreCase(a.getValue()) && BSPconstants.ENQUIRY_TYPE_AP.equalsIgnoreCase(selectedEnquiryType)))
                    options.add(new selectOption(a.getLabel(), a.getValue()));
            }
        }
        return options;

    }

    public List<SelectOption> getEnquiryType() {
        List<selectOption> options = new List<selectOption>();
        options.add(new SelectOption('', BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_AP, BspConstants.ENQUIRY_TYPE_AUPOST));
        options.add(new SelectOption(BspConstants.ENQUIRY_TYPE_ST, BspConstants.ENQUIRY_TYPE_STARTRACK));
        return options;
    }

    public List<SelectOption> getCaseType() {
        return getPicklistValues(BspConstants.FIELD_API_NAME_CCU_ENQUIRY_TYPE, true, BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT);
    }

    public List<SelectOption> getFromRadio() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_YOU, BspConstants.SELECT_OPTION_LABEL_YOU));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_DIFFERENT_SENDER,BspConstants.SELECT_OPTION_LABEL_DIFFERENT_SENDER));
        return options;
    }

    public List<SelectOption> getIndOrgPicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_ALL_ORG_ENQ, BspConstants.SELECT_OPTION_LABEL_ALL_ORG_ENQ));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_MY_ENQ, BspConstants.SELECT_OPTION_LABEL_MY_ENQ));
        return options;
    }

    public List<SelectOption> getdynamicPageSizePicklist() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_5_ENQ, BspConstants.SELECT_OPTION_LABEL_5_ENQ));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_10_ENQ, BspConstants.SELECT_OPTION_LABEL_10_ENQ));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_15_ENQ, BspConstants.SELECT_OPTION_LABEL_15_ENQ));
        options.add(new SelectOption(BspConstants.SELECT_OPTION_VALUE_20_ENQ, BspConstants.SELECT_OPTION_LABEL_20_ENQ));
        return options;
    }

    //Added by David Catindoy (March 22, 2017) - StarTrack method that creates a Related To filter on the fly.
    public List<SelectOption> getRelatedToList() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('', BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        options.add(new SelectOption(BspConstants.ACCOUNT_TYPE_STARTRACK, BspConstants.ACCOUNT_TYPE_STARTRACK));
        options.add(new SelectOption(BspConstants.ACCOUNT_TYPE_AUSPOST, BspConstants.ACCOUNT_TYPE_AUSPOST));
        return options;
    }

    //Added by David Catindoy (March 22, 2017) - Get all the list of BSP Case Status values and put it as an option in the filter.
    public List<SelectOption> getStatusList() {
        List<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('', BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT));
        if(String.isNotBlank(configSetting.BSPCaseStatusList__c)){
            for(String caseStat : configSetting.BSPCaseStatusList__c.split(',')){
                options.add(new SelectOption(caseStat, caseStat));
            }
        }
        return options;
    }

    public List<SelectOption> getArticleTypes() {
        return getPicklistValues(BspConstants.FIELD_API_NAME_ARTICLE_TYPE, false, null);
    }

    public List<SelectOption> getServiceUsed() {
        return getPicklistValues(BspConstants.FIELD_API_NAME_CCU_SERVICE_USED, true, BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT);
    }

    public List<SelectOption> getItemContents() {
        return getPicklistValues(BspConstants.FIELD_API_NAME_CCU_ITEM_CONTENTS, true, BspConstants.PICKLIST_VALUE_DEFAULT_PLEASE_SELECT);
    }

    public List<SelectOption> getStates() {
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', BspConstants.SELECT_OPTION_DEFAULT_SELECT));
        options.add(new selectOption(BspConstants.SELECT_OPTION_ACT, BspConstants.SELECT_OPTION_ACT));
        options.add(new selectOption(BspConstants.SELECT_OPTION_NSW, BspConstants.SELECT_OPTION_NSW));
        options.add(new selectOption(BspConstants.SELECT_OPTION_NT, BspConstants.SELECT_OPTION_NT));
        options.add(new selectOption(BspConstants.SELECT_OPTION_QLD, BspConstants.SELECT_OPTION_QLD));
        options.add(new selectOption(BspConstants.SELECT_OPTION_SA, BspConstants.SELECT_OPTION_SA));
        options.add(new selectOption(BspConstants.SELECT_OPTION_TAS, BspConstants.SELECT_OPTION_TAS));
        options.add(new selectOption(BspConstants.SELECT_OPTION_VIC, BspConstants.SELECT_OPTION_VIC));
        options.add(new selectOption(BspConstants.SELECT_OPTION_WA, BspConstants.SELECT_OPTION_WA));
        return options;
    }

    public PageReference enquiryTypeOnChange() {
        //clear CCUEnquiryType field on Enquiry Type field change
        enq.CCUEnquiryType__c = null;
        currentConsignment = null;
        //hans 02/05/2019 embedded dropzone file upload
        //delete the created files when enquiry type is changed
        convertFilesToAttachmentsAndDeleteFiles('', false);
        return null;
    }

    public PageReference refreshPage() {
        //hans 02/05/2019 embedded dropzone file upload
        //delete the created files when page is refreshed
      convertFilesToAttachmentsAndDeleteFiles('', false);
        notFound = false;
        duplicate = false;
        confirmCreation = false;
        creationFromConsignSearch = false;
        currentConsignment = null;
        if(contentDocVersionIds == null){
            contentDocVersionIds = new List<string>();
        }
        //set default values on refresh based on record type
        if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
            Id deliveryEnqRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_DELIVERY_ENQUIRY).getRecordTypeId();
            enq.RecordTypeId = deliveryEnqRT;
            enq.Subject = '';
            consignmentNumber = '';
            enq.Description = '';
            enq.Call_Purpose__c = null;
        } else if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
            Id pickupBookingEnqRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_PICKUP_BOOKING_ENQUIRY).getRecordTypeId();
            enq.RecordTypeId = pickupBookingEnqRT;
            enq.Subject = '';
            enq.Description = '';
            enq.Call_Purpose__c = null;
            enq.Pickup_Booking_Reference__c = '';

            // we only populate the default billing account if the primary billing account is a startrack billing account
            // if the primary is an AP billing then the user must enter the billing account the pickup booking is related to
            if(isSTUser) {
                billingAccountNumber = removeBillingAcctPrefix(primaryBillingAccountNumber);
            } else {
                billingAccountNumber = '';
            }

        }

        //Set header for page rendering and security for IE8
       setPageHeaders();

        //system.debug('xxx fromWhoRadio = ' + fromWhoRadio);
        return null;

    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that removes Billing Account prefix T or P for Billing Account display
    History:
    November 28, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public String removeBillingAcctPrefix(String billingAccount) {
        if (billingAccount.startsWith('T') || billingAccount.startsWith('P')) {
            billingAccount = billingAccount.substring(1, billingAccount.length());
        }
        return billingAccount;
    }

    public PageReference SF_DisplayAttachmentButton() {
        if(showAttachmentButtonFlag == true) {
            showAttachmentButtonFlag = false;
        } else {
            showAttachmentButtonFlag = true;
        }
        return null;
    }

//    public void setEnquiryTypeForBulkLoad(String enqType, Case enq) {
//        String generalRecordTypeId = configSetting.GeneralRecordTypeId__c;
//        String deliveryRecordTypeId = configSetting.DeliveryRecordTypeId__c;
//        enq.RecordTypeId = deliveryRecordTypeId;
//        enq.Type = BspConstants.CASE_TYPE_INVESTIGATION;
//        if(enqType == BspConstants.ENQUIRY_TYPE_ITEM_SEARCH || enqType == BspConstants.ENQUIRY_TYPE_CALL_FOR_RETURN) {
//            enq.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_MISSING_ITEM;
//        }
//        if(enqType == BspConstants.ENQUIRY_TYPE_DAMAGED_REPORT) {
//            enq.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_DAMAGED_MISSING_CONTENTS;
//        }
//        if(enqType == BspConstants.ENQUIRY_TYPE_DELIVERY_ISSUE) {
//            enq.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_DELIVERY_COMPLAINT;
//        }
//        if(enqType == BspConstants.ENQUIRY_TYPE_RTS) {
//            enq.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_RTS_REQUEST;
//        }
//        if(enqType == BspConstants.ENQUIRY_TYPE_POD_REQUEST) {
//            enq.EnquirySubType__c = BspConstants.ENQUIRY_SUBTYPE_DISPUTED_DELIVERY;
//        }
//    }

    /**
     * Method used to create a case if the enquiry is related to AusPost
     * this is the result of the apex:commandButton for AusPost enquiries
     */
    public PageReference createEnquiryAusPost() {
        //Set header for page rendering and security for IE8
        setPageHeaders();

        // grab settings from Custom Setting
        String generalRecordTypeId = configSetting.GeneralRecordTypeId__c;
        String deliveryRecordTypeId = configSetting.DeliveryRecordTypeId__c;

        //String enqType = enq.CCUEnquiryType__c.toLowerCase();
        String enqType = (string.isNotBlank(enq.CCUEnquiryType__c) ? enq.CCUEnquiryType__c.toLowerCase():'');
        Map<String,BSPMappings__c> bspMappings = BSPMappings__c.getAll();

        // validate our form fields
        // this is used to trigger error states on the create enquiry form for AP
        // NOTE: formSubmitted is transient so the value resets at the end of this call
        // TODO: FIX this rather dodgy workaround to trigger error states on the visualforce form fields
        formSubmitted = true;

        Boolean isError = false;

        if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY || enqType == BspConstants.ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD) {
            if(String.isEmpty(enq.Description)) isError = true;
        } else {
            if(String.isEmpty(enq.ReferenceID__c)) isError = true;
            if(String.isEmpty(String.valueOf(enq.BSPLodgementDate__c))) isError = true;
            if(String.isEmpty(enq.ArticleType__c)) isError = true;
            if(String.isEmpty(enq.CCUServiceUsed__c)) isError = true;
            //if(String.isEmpty(enq.CCUItemContents__c)) isError = true;
            if(String.isEmpty(descofcontents)) isError = true;
            if(String.isEmpty(descript)) isError = true;
            if(fromWhoRadio != 'you') {
                if(String.isEmpty(fromAddress.city)) isError = true;
                if(String.isEmpty(fromAddress.state)) isError = true;
                if(String.isEmpty(fromAddress.line1)) isError = true;
                if(String.isEmpty(fromAddress.postcode)) isError = true;
            }
            if(String.isEmpty(enq.SecondaryContactFirstName__c)) isError = true;
            if(String.isEmpty(enq.SecondaryContactLastName__c)) isError = true;
            if(String.isEmpty(toAddress.city)) isError = true;
            if(String.isEmpty(toAddress.line1)) isError = true;
            if(String.isEmpty(toAddress.postcode)) isError = true;
            if(String.isEmpty(toAddress.country)) isError = true;
            if(String.isEmpty(toAddress.state)) isError = true;
            //            if('Australia'.equalsIgnoreCase(toAddress.countryName) && String.isEmpty(toAddress.state)) {
            //                isError = true;
            //            }
        }

        if(isError) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please review the errors below'));
        }

        // check if user can create aus post enquiries
        // this should never happen, but is a fail safe incase
        if(!hasAPBillingAccounts && !canSearchAllConsignments) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to create an enquiry of this type'));
        }

        if(ApexPages.hasMessages()) {
            // Salesforce would load the attachment file. If it is larger than 10MB, it will reset every attachment variables
            //    and leaves an ApexMessage. Display it!
            //    "This file exceeds the maximum size limit of 10MB."
            return null;
        }

        if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY || enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD || enqType == BspConstants.ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD) {
            enq.RecordTypeId = generalRecordTypeId;
            enq.CCUServiceUsed__c = null;
        } else {
            enq.RecordTypeId = deliveryRecordTypeId;
        }
        if(!bspMappings.isEmpty()){
            enq.EnquirySubType__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseEnquirySubType__c;
            enq.Type = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseType__c;
            if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY || enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD || enqType == BspConstants.ENQUIRY_TYPE_MAIL_REDIRECTION_HOLD){
                enq.ProductCategory__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).CaseProductCategory__c; // INC0609073 ref Product Category to custom setting
                enq.ProductSubCategory__c = bspMappings.get(enq.CCUEnquiryType__c.toLowerCase()).caseProductSubCategory__c; // INC0609073 ref Product Sub Category to custom setting
            }
        }

        if(enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD) {
            enq.ResolutionCode__c = BspConstants.CASE_RESOLUTION_CODE_CUSTOMER_SELF_SERVICE;
        }

        enq.BSP_Sender_Name__c = (enq.PrimaryContactFirstname__c != null ? enq.PrimaryContactFirstname__c + ' ' : '') + (enq.PrimaryContactLastName__c != null ? enq.PrimaryContactLastName__c : '');
        enq.BSP_Sender_Company__c = (enq.PrimaryAccount__c != null ? enq.PrimaryAccount__c : '');

        if(fromWhoRadio == BspConstants.SELECT_OPTION_VALUE_YOU) {
            enq.PrimaryContactFirstname__c = loginUser.Firstname;
            enq.PrimaryContactLastname__c = loginUser.Lastname;
            enq.BSP_Sender_Name__c = loginUser.Firstname + ' ' + loginUser.Lastname;
            enq.BSP_Sender_Company__c =  loginUser.CompanyName;
        }
        enq.ContactId = loginContactId;

        // If user searched for COnsignment and tried to created General Enquiry, then null the Artilce and Type
        if(enqType == BspConstants.ENQUIRY_TYPE_GENERAL_ENQUIRY) {
            enq.ArticleType__c = null;
            enq.ArticleTest__c = null;
        }
        if(enq.ArticleType__c != null) {
            String serviceType = enq.ArticleType__c.toLowerCase();
            if(serviceType.contains(BspConstants.KEYWORD_PARCEL)) {
                if(enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECONOMY) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL)||enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI) ||enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_GLOBAL)) {
                    enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_PARCELS;
                } else {
                    enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_PARCELS;
                }
            } else if(serviceType.contains(BspConstants.KEYWORD_LETTER)) {
                if(enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI) || enq.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_GLOBAL)) {
                    enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_LETTERS;
                } else {
                    enq.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_LETTERS;
                }
            }
        }

       if(!String.isBlank(enq.CCUServiceUsed__c)){
            if(!bspMappings.isEmpty()){
                if(enq.CCUServiceUsed__c== BspConstants.NEXT_FLIGHT_PREM_EXPRESS) {
                    enq.ProductSubCategory__c = BspConstants.NEXT_FLIGHT_PREM_EXPRESS;
                } else {  
					enq.ProductSubCategory__c = bspMappings.get(enq.CCUServiceUsed__c.toLowerCase()).CaseProductSubcategory__c;
   		 		}
            }
       }
       
        enq.DescriptionOfContents__c = descofcontents;
        enq.Origin = BspConstants.CASE_ORIGIN_BSP;
        enq.Subject = enq.CCUEnquiryType__c;
        enq.CaseOriginator__c = 'Sender'; // REQ2048088: All new BSP cases to have Sender has Originator


        // grab data from qas component
        if(toAddress.countryName != 'Australia') {
            toAddress.state = ' ';
        }

        if (String.isNotBlank(fromAddress.line1)) {
            enq.BSP_Sender_Address__c = fromAddress.line1.trim() + ', ' + fromAddress.city + ' ' + fromAddress.state + ' ' + fromAddress.countryName + ' ' + fromAddress.postcode;
        }

        if(String.isNotBlank(toAddress.line1)) {
            enq.BSP_Addressee_Address__c = toAddress.line1.trim() + ', ' + toAddress.city + ' ' + toAddress.state + ' ' + toAddress.countryName + ' ' + toAddress.postcode;
        }
        enq.DatePosted__c = enq.BSPLodgementDate__c;
        enq.Description = String.isBlank(descript)?enq.Description:descript;
        enq.Priority = BspConstants.CASE_PRIORITY_LOW;    //REQ0661196 changed to low
        enq.BSP_Addressee_Name__c = (enq.SecondaryContactFirstName__c != null ? enq.SecondaryContactFirstName__c + ' ' : '') + (enq.SecondaryContactLastname__c != null ? enq.SecondaryContactLastname__c : '');
        enq.BSP_Addressee_Company__c = (enq.SecondaryAccount__c != null ? enq.SecondaryAccount__c : '');

        // Gunith: When a Case is created from BSP, the Case should always be routed
        enq.AllocateToQueue__c = true;

        dontSave = false;


//        // TODO: Re-implement bulk upload capability when there is a need to reactivate
//        // create all the records on submit
//        if(enqType == BspConstants.ENQUIRY_TYPE_BULK_UPLOAD) {
//            upload();
//        } else {
//          DO SINGLE CASE CREATION HERE
//        }
//        if(isDmlError == false && !dontSave) {
//            if(csvBlob != null) {
//                Attachment att = new attachment();
//                att.Name = BspConstants.ATTACHMENT_NAME_BULK_UPLOAD_CSV;
//                att.ContentType = BspConstants.ATTACHMENT_CONTENT_TYPE_CSV;
//                att.Body = csvBlob;
//                att.OwnerId = loginUser.Id;
//                att.ParentId = enq.Id;
//                att.IsPrivate = false;
//
//                try {
//                    insert att;
//                    enq.Status = BspConstants.CASE_STATUS_CLOSED;
//                    //enq.Permanent_Close__c = true;
//                    update enq;
//                } catch(Exception ex) {
//                    System.debug('xxx ex = ' + ex);
//                    isDmlError = true;
//                    ApexPages.addMessages(ex);
//                    System.debug('xxx Exception caught - insert attachment');
//                    Database.rollback(sp);
//                } finally {
//                    att = new attachment();
//                }
//            }
//        }

        createEnquiryAusPostFinalise();
        return null;

//          TODO REQUIREMENT REMOVED... Code can be removed before a production deployment
//        // whenever a reference ID is passed into the case we need to validate that this user can actually create the case
//        // this requires us to query SAP-EM to retrieve the billing account and validate it againsts the user's accessible billing account
//        // start a new async search
//        if(!String.isEmpty(enq.ReferenceID__c)) {
//            AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 service = getAsyncSAPEMRequest(enq.ReferenceID__c);
//
//            Continuation cont = new Continuation(Integer.valueOf(configSetting.AusPostAsyncWebServiceTimeout__c));//Set the callout timeout.
//            cont.continuationMethod = 'createEnquiryAusPostSearchCallback';
//            trackResults = service.beginQueryTrackEvents_v1(cont, new List<String>{enq.ReferenceID__c}, BspConstants.BSP_MERCHANT); //Execute the callout request.
//            return cont;
//        } else {
//            createEnquiryAusPostFinalise();
//        }
//
//        return null;
    }

//          TODO REQUIREMENT REMOVED... Code can be removed before a production deployment
//    /**
//     * Process the continuation response from the AP search when creating a new enquiry
//     */
//    public Object createEnquiryAusPostSearchCallback() {
//        System.debug('>> createEnquiryAusPostSearchCallback:start');
//        System.debug(trackResults);
//
//        //Validate if the response result description is a SUCCESS.
//        // Checks if the item is found in SAP-EM
//        if(BspConstants.SUCCESS.equals(trackResults.getValue().TrackingResult[0].ResultDescription)) {
//            TIBCOSearchResult searchResult = new TIBCOSearchResult();
//
//            AuspostMailProductSchema.Article article = trackResults.getValue().TrackingResult[0].ArticleDetails != null ? trackResults.getValue().TrackingResult[0].ArticleDetails.ArticleEnvelope.Article :
//                    (trackResults.getValue().TrackingResult[0].ConsignmentDetails != null && !trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope.isEmpty() ? trackResults.getValue().TrackingResult[0].ConsignmentDetails.ConsignmentEnvelope.ArticleEnvelope[0].Article : null);
//
//            // populate the search results for all returned consignments (if any)
//            for (AuspostQueryTrackEventsSchema.TrackingResults tr : trackResults.getValue().TrackingResult) {
//                searchResult.trackResults.add(new TIBCOTrackingResultWrapper(tr));
//            }
//
//            if (!foundArticleInSAPEM(searchResult)) {
//                // no results found in SAP EM
//                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS_TRACKING_DETAILS)));
//                return null;
//            } else if (article != null && startrackProdIDs.containsKey(article.ProductID)) {
//                // this check confirms if the article is actually a StarTrack consignment even though it's been surfaced in SAP-EM
//                // if thats the case we proceed to the ST search and surface the correct ST specific details from .net
//                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, bspBase.getErrorMessage(BspConstants.ERROR_CREATE_ENQUIRY_INVALID_TRACKING_ENQUIRY_COMBO)));
//                return null;
//            } else {
//                // article was found in SAPEM
//                try {
//                    TIBCODataTranslator translator = new TIBCODataTranslator(searchResult.trackResults);
//                    translator.save(true, false, true, false);
//                } catch (Exception e) {
//                    //Display an error message when there's an error encountered while saving the consignment/article record.
//                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
//                    return null;
//                }
//
////               // NO LONGER USED TO VALIDATE BILLING ACCOUNT... This deals with a scenario where there is no billing account link on registered post articles or unmanifested articles. Cases should still be able to be created
////                Get the consignment details in SF.
////				                Article__c sapArticle = [
////				                        SELECT Id, Name, RecordType.Name, ArticleID__c, SenderCompany__c, SenderName__c, SenderAddress__c,
////				                                ReceiverCompany__c, ReceiverName__c, ReceiverAddress__c, Receiver_Suburb__c, ReceiverState__c,
////				                                ReceiverPostcode__c, Billing_Account__c, ProductCategory__c, ServiceCode__c, ArticleLodgementDate__c,
////				                                ExpectedDeliveryDate__c, MLID__c, SubProduct__c, DeliveryInstructions__c, ReceiverAddressLine1__c,
////				                                ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c, ReceiverCountry__c,
////				                                Billing_Account__r.Id, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Organisation__c,
////				                                RecallTempLock__c, EligibleForRedirect__c, Consignment__c, Consignment__r.RecallTempLock__c
////				                        FROM Article__c
////				                        WHERE ArticleID__c = :searchResult.trackResults[0].trackingID
////				                ];
////              if(isArticleAccessible(sapArticle)) {
//
//                    // the user has access to the article so we can now finally create the new enquiry
//                    createEnquiryAusPostFinalise();
//
////                } else {
////                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, bspBase.getErrorMessage(BspConstants.ERROR_CREATE_ENQUIRY_NOT_AUTHORISED)));
////                    return null;
////                }
//            }
//        } else {
//            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NO_RESULTS_TRACKING_DETAILS))); //Display an error when there's no consignment found.
//        }
//
//        return null;
//    }
//
//    /**
//    * Validate if there's a consignment/article record returned by the response.
//    */
//    public static Boolean foundArticleInSAPEM(TIBCOSearchResult result){
//        if(!result.success || result.trackResults.size() <= 0){
//            return false;
//        }
//
//        for(TIBCOTrackingResultWrapper tr : result.trackResults){
//            if (tr.articleDetails != null || tr.consignmentDetails != null) {
//                return true;
//            }
//        }
//        return false;
//    }

    /**
     * This method is used to finally create a new case for an Aus Post enquiry.
     * This will be called direct from createEnquiryAusPost if no reference ID was entered when creating the enquiry
     *      or after the SAP EM search concludes when a reference ID was passed in. (Only if the search was successful and the user has access to create the enquiry
     */
    public void createEnquiryAusPostFinalise() {
        SavePoint sp = Database.setSavepoint();
        Boolean isDmlError = false;

        try {
            insert enq;

            if(!String.isEmpty(enq.Description)) {
                CaseComment myComment = new CaseComment(ParentId=enq.Id, CommentBody=enq.Description,  IsPublished=true);
                insert myComment;
            }
            //hans 02/05/2019 embedded dropzone file upload
            //convert files to attachments saved from dropzone and link to the created case
            convertFilesToAttachmentsAndDeleteFiles(enq.Id, true);
        } catch(Exception ex) {
            isDmlError = true;
            ApexPages.addMessages(ex);
            System.debug('xxx Exception caught - insert enq '+ex.getMessage()+' at line '+ex.getstacktraceString());
            Database.rollback(sp);
        }

        /* if(isDmlError == false && !dontSave) {
			 System.debug('xxx fileSizeLimit = ' + fileSizeLimit);
			 if(fileBodyLength > 0) {
				 if((fileBodyLength/1048576) > fileSizeLimit) {
					 String msgString = 'This file exceeds the maximum size limit of ' + fileSizeLimitInteger + 'MB.';
					 ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, msgString);
					 Apexpages.addmessage(msg);

					 // clear fileBody to blank to avoid viewstate error
					 fileBody = null;
					 fileBodyLength = 0;

					 isDmlError = true;
					 Database.rollback(sp);
				 } else {
					 // create attachment if it is uploaded
					 Attachment att  = new Attachment();
					 att.Body = fileBody;
					 att.Name = fileName;
					 att.ContentType = fileContentType;
					 att.OwnerId = loginUser.Id;
					 att.ParentId = enq.Id;
					 att.IsPrivate = false;

					 try {
						 insert att;
					 } catch(Exception ex) {
						 System.debug('xxx ex = ' + ex);
						 // clear fileBody to blank to avoid viewstate error
						 fileBody = null;
						 fileBodyLength = 0;
						 isDmlError = true;
						 ApexPages.addMessages(ex);
						 System.debug('xxx Exception caught - insert attachment');
						 Database.rollback(sp);
					 }
				 }
			 }
		 }*/

        if(!isDmlError) {
            showSuccessMessage = true;
            section = BspConstants.PAGE_SECTION_THANK_YOU;
        } else {
            showSuccessMessage = false;
        }
    }

    /**
     * After querying an article, we use this to retrieve the billing account that should be associated with the case that is being created
     */
    private List<String> matchBillingAccount(Article__c article) {
        if(article != null && article.Billing_Account__r != null && String.isNotEmpty(article.Billing_Account__r.Id) && String.isNotEmpty(article.Billing_Account__r.LEGACY_ID__c)) {
            return new List<String>{article.Billing_Account__r.Id, article.Billing_Account__r.LEGACY_ID__c};
        } else {
            return null;
        }
    }

    /*------------------------------------------------------------
    Author:        Nathan Main & Kenny Liew
    Company:       Salesforce.com
    Description:   Modified SubmitPage Method used for MyPostBusiness
    Date:          21/04/16
    Inputs:        none
    Returns:       none
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    ------------------------------------------------------------*/
    public PageReference submitPageMpbHsp() {
        //Set header for page rendering and security for IE8
        SavePoint sp = Database.setSavepoint();
        setPageHeaders();
        if(ApexPages.hasMessages()) {
            // Salesforce would load the attachment file. If it is larger than 10MB, it will reset every attachment variables
            //    and leaves an ApexMessage. Display it!
            //    "This file exceeds the maximum size limit of 10MB."
            return null;
        }

        // grab settings from Custom Setting
        String generalRecordTypeId = configSetting.GeneralRecordTypeId__c;
        String deliveryRecordTypeId = configSetting.DeliveryRecordTypeId__c;

        enq.CaseOriginator__c = 'Sender';
        String enqType = enq.MPB_BSP_Enquiry_Type__c.toLowerCase();
        String enqSubType = '';
        if(enqType == BspConstants.ENQUIRY_TYPE_MPB_OTHER_ENQ){
            enqSubType = enq.MPB_BSP_Enquiry_Type__c.toLowerCase();
            enq.MPB_BSP_Tech_Enquiry_Type__c = enq.MPB_BSP_Enquiry_Type__c;
        } else {
            enqSubType = enq.MPB_BSP_Tech_Enquiry_Type__c.toLowerCase();
        }

        if(enqType == BspConstants.ENQUIRY_TYPE_MPB_PICKUP_ENQ || enqType == BspConstants.ENQUIRY_TYPE_MPB_LABEL_ENQ
                || enqType ==  BspConstants.ENQUIRY_TYPE_MPB_PRICING_ENQ || enqType == BspConstants.ENQUIRY_TYPE_MPB_OTHER_ENQ
                || enqType == BspConstants.ENQUIRY_TYPE_TECHNICAL_ENQUIRY || (BspConstants.ENQUIRY_TYPE_MPB_DEL_ENQ.equalsIgnoreCase(enqType) && enqSubType == BspConstants.SELECT_OPTION_MPB_DEL_ENQ_TRACKING)) {

            enq.RecordTypeId = generalRecordTypeId;
            // if enquiry type = general enquiry, then clear out the ServiceUsed default value
            enq.CCUServiceUsed__c = null;
        } else {
            enq.RecordTypeId = deliveryRecordTypeId;
        }


            Map<String, MpbHsp_Mappings__c> mpbHspMappings = MpbHsp_Mappings__c.getAll();
            if (!mpbHspMappings.isEmpty()) {

                MpbHsp_Mappings__c mpbHspMap = MpbHsp_Mappings__c.getInstance(enqSubType);
                if (mpbHspMap != null) {
                    enq.Type = mpbHspMap.Case_Type__c;
                    enq.EnquirySubType__c = mpbHspMap.Case_Enquiry_Sub_Type__c;
                    enq.ProductCategory__c = mpbHspMap.Case_Product_Category__c;
                    enq.ProductSubCategory__c = mpbHspMap.Case_Product_Sub_Category__c;
                } else {
                    System.debug('submitPageMpbHsp() - No mapping exists in the custom setting for enqType=' + enqType);
                }
            }

        // These fields map to the Sender (from fields) on the page - we may not be using this.
        enq.BSP_Sender_Name__c = (enq.PrimaryContactFirstname__c != null ? enq.PrimaryContactFirstname__c + ' ' : '') + (enq.PrimaryContactLastName__c != null ? enq.PrimaryContactLastName__c : '');
        enq.BSP_Sender_Company__c = (enq.PrimaryAccount__c != null ? enq.PrimaryAccount__c : '');

        if(fromWhoRadio == BspConstants.SELECT_OPTION_VALUE_YOU) {
            enq.PrimaryContactFirstname__c = loginUser.Firstname;
            enq.PrimaryContactLastname__c = loginUser.Lastname;

            enq.BSP_Sender_Name__c = loginUser.Firstname + ' ' + loginUser.Lastname;
            enq.BSP_Sender_Company__c =  loginUser.CompanyName;

        }
        enq.ContactId = loginContactId;

        enq.Origin = BspConstants.CASE_ORIGIN_MYPOST_BUSINESS;
        enq.Subject = enq.MPB_BSP_Enquiry_Type__c;

        // grab data from qas component
        if(toAddress.countryName != 'Australia') {
            toAddress.state = ' ';
        }

        if (!String.isBlank(fromAddress.line1)) {
            enq.BSP_Sender_Address__c = fromAddress.line1.trim() + ', ' + fromAddress.city + ' ' + fromAddress.state + ' ' + fromAddress.countryName + ' ' + fromAddress.postcode;
        }

        if(!String.isBlank(toAddress.line1)) {
            enq.BSP_Addressee_Address__c = toAddress.line1.trim() + ', ' + toAddress.city + ' ' + toAddress.state + ' ' + toAddress.countryName + ' ' + toAddress.postcode;
        }

        enq.DatePosted__c = enq.BSPLodgementDate__c;
        enq.Description = String.isBlank(descript)?enq.Description:descript;
        enq.Priority = BspConstants.CASE_PRIORITY_LOW;    //REQ0661196 changed to low
        enq.BSP_Addressee_Name__c = (enq.SecondaryContactFirstName__c != null ? enq.SecondaryContactFirstName__c + ' ' : '') + (enq.SecondaryContactLastname__c != null ? enq.SecondaryContactLastname__c : '');
        enq.BSP_Addressee_Company__c = (enq.SecondaryAccount__c != null ? enq.SecondaryAccount__c : '');

        if(!isEnterprise) {
            enq.AllocateToQueue__c = true;
        }

        dontSave = false;
        boolean isDmlError = false;

        if(!dontSave) {
            try {
                insert enq;
                if(enq.Description != null && enq.Description != '') {
                    CaseComment myComment = new CaseComment(ParentId=enq.Id, CommentBody=enq.Description,  Ispublished=true);
                    insert myComment;
                }
            } catch(exception ex) {
                isDmlError = true;
                ApexPages.addMessages(ex);
                System.debug('xxx Exception caught - insert enq');
                Database.rollback(sp);
            }
        }

        if(isDmlError == false && !dontSave) {
            // Added a condition to make Attachment mandatory if Enquiry Type is delivery Enquiry and Sub Case type is not equal to Tracking Status
            /* If(enqType == BspConstants.ENQUIRY_TYPE_MPB_DEL_ENQ &&
                enqSubType == BspConstants.SELECT_OPTION_MPB_DEL_ENQ_MISSING && fileBody == null || fileBodyLength == 0){
                String msgString = 'Please attach document is required for delivery enquiry of missing item type.';
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, msgString);
                Apexpages.addmessage(msg);

                // clear fileBody to blank to avoid viewstate error
                fileBody = null;
                fileBodyLength = 0;

                isDmlError = true;
                Database.rollback(sp);
            } */
            if(fileBodyLength > 0) {
                if ((fileBodyLength / 1048576) > fileSizeLimit) {
                    String msgString = 'This file exceeds the maximum size limit of ' + fileSizeLimitInteger + 'MB.';
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, msgString);
                    Apexpages.addmessage(msg);

                    // clear fileBody to blank to avoid viewstate error
                    fileBody = null;
                    fileBodyLength = 0;

                    isDmlError = true;
                    Database.rollback(sp);
                } else {
                    // create attachment if it is uploaded
                    Attachment att  = new Attachment();
                    att.Body = fileBody;
                    att.Name = fileName;
                    att.ContentType = fileContentType;
                    att.OwnerId = loginUser.Id;
                    att.ParentId = enq.id;
                    att.IsPrivate = false;

                    try {
                        insert att;
                    } catch(Exception ex) {
                        System.debug('xxx ex = ' + ex);
                        // clear fileBody to blank to avoid viewstate error
                        fileBody = null;
                        fileBodyLength = 0;
                        isDmlError = true;
                        ApexPages.addMessages(ex);
                        System.debug('xxx Exception caught - insert attachment');
                        Database.rollback(sp);
                    }
                } // Added else to make attachment mandatory for Delivery Enquiry
            }
        }

        if(isDmlError == false && !dontSave) {
            section = BspConstants.PAGE_SECTION_THANK_YOU;
            return null;
        } else {
            return null;
        }
    }

    /**
     * Action when the user clicks the button to show the create case form from the homepage
     */
    public PageReference createCase() {
        //Set header for page rendering and security for IE8
        setPageHeaders();

        section = BspConstants.PAGE_SECTION_ENQUIRY;

        // create new case
        enq = new Case();
        enq.CCUEnquiryType__c = null;

        // NM 07/04 - MyPostBusiness
        if (isMpbHspFlag == true)
            enq.CCUServiceUsed__c = BspConstants.CASE_CCU_SERVICE_USED_EPARCEL;


        // initialise attachment param
        showAttachmentButtonFlag = false;

        // initialise From and To Block
        initialiseFromBlock();
        initialiseToBlock();

        return null;
    }

    public string defaultFromString {get;set;}

    public PageReference setFirstNameLastName() {
        if(articleFromConsignSearch != null){
            List<String> senderName = String.isNotBlank(articleFromConsignSearch.SenderName__c) ? articleFromConsignSearch.SenderName__c.split(' ') : new List<String>();

            if(!senderName.isEmpty()){
                enq.PrimaryContactFirstname__c = senderName[0];
                enq.PrimaryContactLastname__c = senderName.size() > 1 ? senderName[1] : '';
            }

            enq.PrimaryAccount__c = articleFromConsignSearch.SenderCompany__c;
            fromAddress = new AddressExtension(articleFromConsignSearch.SenderAddressLine1__c, articleFromConsignSearch.SenderAddressLine2__c, articleFromConsignSearch.SenderCity__c, articleFromConsignSearch.SenderState__c,
                    articleFromConsignSearch.SenderPostcode__c, '', articleFromConsignSearch.SenderCountry__c);
        } else{
            enq.PrimaryContactFirstname__c = '';
            enq.PrimaryContactLastname__c = '';
        }

        return null;
    }

    private void initialiseFromBlock() {
        // initialise from you flag
        fromWhoRadio = BspConstants.SELECT_OPTION_VALUE_YOU;


        if(loginUser != null) {
            enq.PrimaryAccount__c = loginUser.CompanyName;
            enq.PrimaryContactFirstname__c = loginUser.Firstname;
            enq.PrimaryContactLastname__c = loginUser.Lastname;

            // 15/04 (NM) - Fix for From Address for MyPost Business
            if (isMpbHspFlag == false) {
                fromAddress = new AddressExtension(loginUser.Street, '', loginUser.City, loginUser.State, loginUser.PostalCode, loginUser.DPID__c, loginUser.Country);
            } else {
                fromAddress = new AddressExtension(null, null, null, null, null, null, 'Australia');
            }
/*
            enq.Address1__c = loginUser.Street;
            enq.Address1Suburb__c = loginUser.City;
            enq.Address1State__c = loginUser.State;
            enq.Address1Postcode__c = loginUser.PostalCode;
*/
            string companyString = null;
            if(enq.PrimaryAccount__c!=null || enq.PrimaryAccount__c!='') {
                companyString = String.isNotBlank(enq.PrimaryAccount__c) ? ' / ' + enq.PrimaryAccount__c : '';
            }

            defaultFromString = enq.PrimaryContactFirstname__c + ' ' + enq.PrimaryContactLastname__c + companyString + '<br/>'
                    + loginUser.Street + '<br/>'
                    + loginUser.City + ' ' + loginUser.State + ' ' + loginUser.Country + ' ' + loginUser.PostalCode + '<br/>';

        }
    }

    private void initialiseToBlock() {
        if(articleFromConsignSearch != null){
            toAddress = new AddressExtension(articleFromConsignSearch.ReceiverAddressLine1__c, articleFromConsignSearch.ReceiverAddressLine2__c, articleFromConsignSearch.ReceiverCity__c, articleFromConsignSearch.ReceiverState__c,
                    articleFromConsignSearch.ReceiverPostcode__c, '', articleFromConsignSearch.ReceiverCountryName__c);
        } else{
            toAddress = new AddressExtension(null, null, null, null, null, null, 'Australia');
        }
    }

    public string getCaseNo() {
        string output = '';
        Case newCase = [SELECT CaseNumber, CCUEnquiryType__c FROM Case WHERE Id = : enq.Id LIMIT 1];
        output = newCase.CaseNumber;
        bulkUpload = newCase.CCUEnquiryType__c == BspConstants.CASE_CCU_ENQUIRY_TYPE_BULK_UPLOAD ? true : false;
        return output;
    }

//        // TODO: Re-implement bulk upload capability when there is a need to reactivate
//    public void upload() {
//        Map<String, BSPErrorMessages__c > errors = BSPErrorMessages__c.getAll();
//        try {
//            System.debug('---csvBlob:' + csvBlob.toString());
//            Case proxyCase = new Case();
//            proxyCase.CCUEnquiryType__c = BspConstants.CASE_CCU_ENQUIRY_TYPE_ITEM_SEARCH;
//            proxyCase.OwnerId = UserInfo.getUserId();
//            proxyCase.Type = BspConstants.CASE_TYPE_INVESTIGATION;
//            proxyCase.Origin = BspConstants.CASE_ORIGIN_BSP_BULK_UPLOAD;
//            proxyCase.RecordTypeId = configSetting.DeliveryRecordTypeId__c;
//
//            List<Case> cases = CaseMassUploadManager.createCases(proxyCase, csvBlob.toString());
//            System.debug('**size:'+cases.size());
//            if(cases.size()>configSetting.BulkUploadLimit__c) {
//                enq.Description = errors.get(BspConstants.LIMIT_ERROR).Message__c;
//                // dontSave = true;
//            } else if (cases.size() > 0) {
//                try {
//                    List<CaseComment> caseComments = new List<CaseComment>();
//                    Map<String,BSPMappings__c> bspMappings = BSPMappings__c.getAll();
//                    for(Case c: cases) {
//                        //For behavior to be similar to enquiries created via UI
//                        String serviceType =c.ArticleType__c.toLowerCase();
//                        if(!isEnterprise) {
//                            c.AllocateToQueue__c=true;
//                        }
//                        c.ContactId = loginContactId;
//                        setEnquiryTypeForBulkLoad(c.CCUEnquiryType__c.toLowerCase(),c);
//                        if(serviceType.contains(BspConstants.KEYWORD_PARCEL)) {
//                            if(c.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL)||c.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI)) {
//                                c.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_PARCELS;
//                            } else {
//                                c.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_PARCELS;
//                            }
//                        } else if(serviceType.contains(BspConstants.KEYWORD_LETTER)) {
//                            if(c.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_INTERNATIONAL)||c.CCUServiceUsed__c.toLowerCase().contains(BspConstants.KEYWORD_ECI)) {
//                                c.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_INT_LETTERS;
//                            } else {
//                                c.ProductCategory__c = BspConstants.CASE_PRODUCT_CATEGORY_DOM_LETTERS;
//                            }
//                        } else {
//                            throw new BulkUploadException();
//                        }
//
//                        if (String.isEmpty(c.Subject)) {
//                            c.Subject = configSetting.BulkUploadSubject__c;
//                        }
//                        if(!String.isBlank(c.CCUServiceUsed__c)){
//
//                            if(!bspMappings.isEmpty()){
//                                try {
//                                    if(bspMappings.get(c.CCUServiceUsed__c.toLowerCase()).BSPServiceUsed__c.toLowerCase() == c.CCUServiceUsed__c.toLowerCase())
//                                        c.ProductSubCategory__c = bspMappings.get(c.CCUServiceUsed__c.toLowerCase()).CaseProductSubcategory__c;
//                                }
//                                catch(Exception e) {
//                                    throw new BulkUploadException();
//                                }
//                            }
//                        }
//                        c.DescriptionOfContents__c = c.CCUItemContents__c;
//                        c.BSP_Sender_Name__c = (c.PrimaryContactFirstname__c != null ? c.PrimaryContactFirstname__c + ' ' : '') + (c.PrimaryContactLastName__c != null ? c.PrimaryContactLastName__c : '');
//                        c.BSP_Sender_Address__c = c.Address1__c.trim() + ', ' + c.Address1Suburb__c + ' ' + c.Address1State__c + ' ' + c.Address1Postcode__c;
//                        c.Address1__c = '';
//                        c.BSP_Addressee_Name__c = (c.SecondaryContactFirstName__c != null ? c.SecondaryContactFirstName__c + ' ' : '') + (c.SecondaryContactLastname__c != null ? c.SecondaryContactLastname__c : '');
//                        c.BSP_Addressee_Address__c = c.Address2__c.trim() + ', ' + c.Address2Suburb__c + ' ' + c.Address2State__c + ' ' + c.Address2Postcode__c;
//                        c.Address2__c = '';
//                        //For the behavior to create comment from Description
//                        CaseComment com = new CaseComment(Ispublished=true, CommentBody = c.Description);
//                        caseComments.add(com);
//                    }
//                    insert cases;
//                    for(Integer i = 0 ; i<caseComments.size() ; i++) {
//                        caseComments[i].ParentId=cases[i].Id;
//                    }
//                    for(Integer i = 0 ; i<caseComments.size() ; i++) {
//                        if(caseComments[i].CommentBody == null || caseComments[i].CommentBody == '') {
//                            CaseComment removed = caseComments.remove(i);
//                        }
//                    }
//                    insert caseComments;
//                    bulkUploadCases = cases.size();
//                    enq.Description = 'Number of Cases created via Bulk Upload : ' + cases.size();
//                } catch(Exception e) {
//                    System.debug('Tech Exception:'+e);
//                    enq.Description = errors.get(BspConstants.TECH_ERROR).Message__c;
//                }
//            } else {
//                enq.Description= errors.get(BspConstants.COLUMN_ERROR).Message__c;
//                // dontSave = true;
//            }
//
//        } catch(BulkUploadException e) {
//            enq.Description = errors.get(BspConstants.CSV_ERROR).Message__c+e;
//            //dontSave = true;
//        } catch(NullPointerException e) {
//            dontSave = true;
//            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, errors.get(BspConstants.NOFILE_ERROR).Message__c);
//            ApexPages.addMessage(msg);
//        } catch (Exception e) {
//            enq.Description = errors.get(BspConstants.FILE_ERROR).Message__c;
//            System.debug(e);
//            //dontSave = true;
//        }
//    }

    public PageReference cancelCase()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();
        section='landing';
        return null;
    }

    /**
     * Returns a list of cases for the logged in user based on the level of access they have
     * This covers both MPB and BSP.
     *
     * Access Roles breakdown for BSP users
     * 1. Role of Admin will gain visibility over billing accounts assigned to that Role
     * 2. Role of Super Admin will gain visibility over all billing accounts
     * 3. Role of User / Super User is not considered in case visibilitiy
     *
     * NOTE: it's important to note that the only roles we need to consider for case visibility for admin based roles
	 *          by default, when a user role is applied to BSP, it simply implies access to 'my cases' which is the default behaviour of a basic BSP user irrespective of role
     */
    public void displayCaseList() {
        Map<Id, Case> searchedCaseMap = new Map<Id, Case>();
        List<Case> searchedCaseList = new List<Case>();

        if(loginContactId != null) {
            Boolean soslHasError = false;

            if(isMpbHspFlag) {
                // my post business does nothave any access roles so a basic soql select is retruned for the user
                List<Case> cases = [
                        Select Id, CaseNumber, CreatedDate, ArticleTest__r.Name, ArticleTest__r.ArticleID__c, RecordType.DeveloperName, Status, CaseDetails__c, Subject, Permanent_Close__c, Secondary_Contact__c, Article_Receiver_Name__c, StarTrack_RecordType__c,
                                BSP_Addressee_Name__c, Contact.Account.Name, Billing_Number__c, Related_Billing_Account__c, Related_Billing_Account__r.LEGACY_ID__c
                        From Case
                        WHERE ParentId = null AND ContactId = :loginContactId AND RecordType.Name LIKE :onlyRecordTypes AND Subject <> :excludeSubject
                ];
                searchedCaseMap.putAll(cases);

                System.debug('>> onlyRecordTypes: ' + onlyRecordTypes);
                System.debug('>> excludeSubject: ' + excludeSubject);
            } else {

                List<String> queries = new List<String>();

                // use this to grab the accessible entities in their respective role
                // these are used to determine the cases that are returned in the query
                Map<String, Set<Id>> mappedEntities = getLinkedEntitiesByRole(accessRules);
                System.debug('>> mappedEntities: ' + mappedEntities);

                // Hasantha : 28/02/2019 this is to filter based on the billing account filter
                String billingAccountSelected = '';
                if(!String.isEmpty(selectedBillingAccount)) {
                    String [] billingAccount = selectedBillingAccount.split('&');
                    billingAccountSelected = ' AND Related_Billing_Account__c = \'' + billingAccount[0] + '\' ';
                }

                // query all the ST cases based on the roles and access of the logged in user
                // always run this query since there may be instances where cases have been raised by the current logged in user outside of what their accessible billing account scope is
                if(relatedTo != BSPConstants.ACCOUNT_TYPE_AUSPOST) {
                    // retrieiving startrack cases
                    System.debug('DOING STARTRACK ENQUIRY');
                    String roleWhere = '';

                    if(mappedEntities.get('Super Admin') != null) {
                        // this role determines that a user has entire access to the org...
                        Set<Id> stSUperAdminEntities = mappedEntities.get('Super Admin');
                        roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( AccountId in :stSUperAdminEntities ) ';
                    }
                    if(mappedEntities.get('Admin') != null) {
                        // this role determines that a user has full access to specific billing accounts
                        // NOTE: the Related_Billing_Account__c != null which forces a billing account to exist as a failsafe incase the entities collection has a null value
                        Set<Id> stAdminEntities = mappedEntities.get('Admin');
                        roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( (Related_Billing_Account__c != null And Related_Billing_Account__c IN :stAdminEntities) ' +
                                ' Or (Contact.BillingAccount__c != null And Contact.BillingAccount__c In :stAdminEntities) ) ';
                    }

                    // additionally we need to give the user access to their own cases irrespective of the roles applied
                    roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( CreatedById = :loginUserId OR ContactId = :loginContactId ) ';

                    // note we only want to surface cases that originated from BSP to begin with
                    // Origin = \'' + String.escapeSingleQuotes(BspConstants.CASE_ORIGIN_BSP) + '\' And
                    String queryWhere = 'WHERE ParentId = null AND RecordTypeId IN :recordTypes AND Enquiry_Type__c NOT IN :excludecaseTypeslist AND call_purpose__c NOT IN :excludecasePurposelist ' +
                            ' AND ( ' + roleWhere + ' ) ' + billingAccountSelected;

                    // force the selection of only cases from the the current logged in users account only
                    // this is due to WITHOUT SHARING being used.... without sharing should be removed since it could lead to vulnerabilities if code is incorrectly written
                    queryWhere += ' AND AccountId = :loginAccountId ';

                    System.debug('>> recordTypes: ' + recordTypes);
                    System.debug('>> excludecaseTypeslist: ' + excludecaseTypeslist);
                    System.debug('>> excludecasePurposelist: ' + excludecasePurposelist);
                    System.debug('>> loginAccountId: ' + loginAccountId);
                    System.debug('>> loginContactId: ' + loginContactId);
                    System.debug('>> loginUserId: ' + loginUserId);

                    queries.add(queryWhere);
                }

                // query all the AP cases based on the roles and access of the logged in user
                // always run this query since there may be instances where cases have been raised by the current logged in user outside of what their accessible billing account scope is
                // NOTE: It's important we always use all the accessible billing accounts in the query below since the user that raised the case may have a ST primary billing account but still be able to raise a case to AP containct centre if they have access to an AP billing account.
                //       AP checks against the Contact primary billing account to determine billing account level access... the StarTrack method of using Related_Billing_Account__c is more accurate.
                if(relatedTo != BSPConstants.ACCOUNT_TYPE_STARTRACK) {
                    // retrieving AusPost cases
                    System.debug('DOING AUSPOST ENQUIRY');

                    String roleWhere = '';

                    if(mappedEntities.get('Super Admin') != null) {
                        // this role determines that a user has entire access to the org...
                        // NOTE!: irrespective of the configuration defined in the role tables, accessRules removes any Organisation that is not the logged in users current organisation
                        //          This is a fail safe for BSP to ensure that we are only surfacing case data for the correct org
                        Set<Id> apSuperAdminEntities = mappedEntities.get('Super Admin');
                        roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( AccountId in :apSuperAdminEntities ) ';
                    }

                    if(mappedEntities.get('Admin') != null) {
                        // this role determines that a user has full access to specific billing accounts
                        // NOTE: the Related_Billing_Account__c != null which forces a billing account to exist as a failsafe incase the entities collection has a null value
                        // NOTE: Updated 2019-07-29 - The billing account of the user raising the case will now be factored in as to whether a case should be shown to a current user.
                        //                              This requirement has been identified as an AP only requirement so it has only been implemented when searching AP billing accounts
                        //                              Example: if primary billing account of user creating case is 1234 and the article linked to that case is linked to billing account 5678
                        //                                          the case will be accessible to admins of 1234 and also 5678
                        Set<Id> apAdminEntities = mappedEntities.get('Admin');

                        //NOTE: Related_Billing_Account__c is set in CaseArticleUtility for SSSW cases
                        roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( (Related_Billing_Account__c != null And Related_Billing_Account__c IN :apAdminEntities) ' +
                                ' Or (Contact.BillingAccount__c != null And Contact.BillingAccount__c In :apAdminEntities) ) ';
                    }

                    // additionally we need to give the user access to their own cases irrespective of the roles applied
                    roleWhere += (String.isNotEmpty(roleWhere) ? ' OR ' : '') + ' ( CreatedById = :loginUserId OR ContactId = :loginContactId ) ';

                    // note we only want to surface cases that originated from BSP to begin with
                    //Origin = \'' + String.escapeSingleQuotes(BspConstants.CASE_ORIGIN_BSP) + '\' And
                    String queryWhere = 'WHERE ParentId = null AND Subject <> :excludeSubject AND RecordType.Name LIKE :onlyRecordTypes ' +
                            ' AND ( ' + roleWhere + ' ) ' + billingAccountSelected;

                    // force the selection of only cases from the the current logged in users account only
                    // this is due to WITHOUT SHARING being used.... without sharing should be removed since it could lead to vulnerabilities if code is incorrectly written
                    queryWhere += ' AND AccountId = :loginAccountId ';

                    System.debug('>> excludeSubject: ' + excludeSubject);
                    System.debug('>> onlyRecordTypes: ' + onlyRecordTypes);

                    queries.add(queryWhere);

                }

                List<String> fields = new List<String>{
                        'Id', 'CaseNumber', 'CreatedDate', 'ArticleTest__r.Name', 'ArticleTest__r.ArticleID__c', 'RecordType.DeveloperName', 'Status',
                        'CaseDetails__c', 'Subject', 'Permanent_Close__c', 'Secondary_Contact__c', 'Article_Receiver_Name__c', 'StarTrack_RecordType__c',
                        'BSP_Addressee_Name__c', 'Contact.Account.Name', 'Billing_Number__c', 'Related_Billing_Account__c', 'Related_Billing_Account__r.LEGACY_ID__c'
                };

                // loop through each where query and generate a list of cases
                for(String whereQuery : queries) {
                    // add FILTERS that have been set on the page
                    whereQuery += generateFilterCriteria();

                    System.debug('>> SEARCHTEXT: ' + searchText);

                    if(String.isNotEmpty(searchText)) {
                        String query = 'Find \'' + String.escapeSingleQuotes(searchText) + '\' ' +
                                'Returning Case (' + String.join(fields, ', ') + ' ' + whereQuery + ' Order By CaseNumber Desc)';

                        System.debug('Running Search Query: ' + query);

                        try {
                            searchedCaseMap.putAll((List<Case>)Search.query(query)[0]);
                        } catch(Exception ex) {
                            // when entered less than 2 characters, SOSL will through error.
                            soslHasError = true;
                            System.debug('SOSL Error: ' + ex);
                        }
                    } else {
                        String query = 'Select ' + String.join(fields, ', ') + ' ' +
                                'From Case ' +
                                whereQuery + ' ' +
                                'Order By CaseNumber Desc LIMIT 400';
                        // TODO ^^ Limitation of 400+400 cases (AP/ST) because of viewstate.... need to make the pagination class's internal caselist transient to fix this.

                        System.debug('Running SOQL Query: ' + query);

                        searchedCaseMap.putAll((List<Case>)Database.query(query));
                    }
                }

            }

            searchedCaseList = searchedCaseMap.values();
            if(soslHasError) {
                // display no result whenever there is SOSL error
                searchedCaseList = new List<Case>();
            } else {
                searchedCaseList = populateStarTrackCaseFields(searchedCaseList);
            }

        }
        System.debug('xxx a SIZE_PER_PAGE = ' + SIZE_PER_PAGE);

        if(!isMpbHspFlag && BspConstants.SELECT_OPTION_VALUE_ALL_ORG_ENQ.equals(indOrgEnquiryFlag) && String.isBlank(searchText) && String.isBlank(relatedTo) && String.isBlank(String.valueOf(dummyEnq1.Start_Date__c)) && String.isBlank(String.valueOf(dummyEnq1.End_Date__c)) && String.isBlank(caseRecStatus)){
            statusValuesList = new Set<String>();
            for(Case caseRec : searchedCaseList){
                statusValuesList.add(caseRec.Status); //Add case status value inside a set container.
            }
        }

        //        // postback will lose the variable value so need to re-initialise
        //        initialisePaginationParam();
        //        pageCon = new Pagination(SIZE_PER_PAGE, searchedCaseList);
        //        noOfRecordsReturned = pageCon.getResultSize();
        //        myCaseList_Paginated = pageCon.getRecords();
        //        myCaseListContainer_Paginated = putListToContainer(myCaseList_Paginated);
        completeList_Paginated = putListToContainer(searchedCaseList);

        // set the default sort order to be sorted by createddate
        sortBy = 'CreatedDate';
        sortColumnDir = 'DESC';
        columnDir = 'DESC';
        sortRecords();

        List<Object> caseDetailsrecords = new List<Object>();
        // prepare the data transfer object mapping to be accessible by the VF page,
        // below mapping is to provide more readability to the code, and
        // some fields needs to be determined based on AP/ST user, and
        // value displayed for some fields such as Status needs to be determined based on the actual values
        for(Case cse : searchedCaseList){
            CaseDetails caseDetail = new CaseDetails();
            // common fields to display/download for bot ST and AP users
            caseDetail.EnquiryNo = cse.CaseNumber;
            caseDetail.DateCreated = String.valueOf(cse.CreatedDate);
            caseDetail.Details = cse.Subject;
            caseDetail.SendingTo =  cse.BSP_Addressee_Name__c != null ? cse.BSP_Addressee_Name__c: cse.Secondary_Contact__c;
            caseDetail.Status = readStatus(cse);
            caseDetail.TrackingNo = cse.ArticleTest__r != null ? cse.ArticleTest__r.Name : '';
            // decide what to display based on the user type
            // AP customers
            if(isAPUser) {
                caseDetail.ArticleID = cse.ArticleTest__r != null ? cse.ArticleTest__r.ArticleID__c : '';
            }

            caseDetailsrecords.add(caseDetail);
        }
        this.caseDetais = String.escapeSingleQuotes(JSON.serialize(caseDetailsrecords)) ;

        //start code changes for REQ1496210
        columnDir = '';
        //trackNumDir = '';
        //sendingToDir = '';
        //end code changes for REQ1496210

    }

    /**
     * This will add to an existing where clause and surface all the additional soql criteria required for the selected parameters in the UI
     */
    private String generateFilterCriteria() {

        String output = '';

        // use the user filters down to their own Cases only
        if(BspConstants.SELECT_OPTION_VALUE_MY_ENQ.equals(indOrgEnquiryFlag)) {
            output += ' AND ( CreatedById = :loginUserId OR ContactId = :loginContactId ) ';
        }

        //Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Created Date From filter.
        if(String.isNotBlank(String.valueOf(dummyEnq1.Start_Date__c))){
            startDate = dummyEnq1.Start_Date__c;
            output += ' AND DAY_ONLY(convertTimezone(CreatedDate)) >= :startDate ';
        }

        //Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Created Date To filter.
        if(String.isNotBlank(String.valueOf(dummyEnq1.End_Date__c))){

            endDate = dummyEnq1.End_Date__c;
            output += ' AND DAY_ONLY(convertTimezone(CreatedDate)) <= :endDate ';
        }

        //hans TODO relatedBilling account field on case

        //Added by David Catindoy (March 22, 2017) - Used to add additional query clause for Status filter.
        if(String.isNotBlank(caseRecStatus)){
            if(BspConstants.CASE_STATUS_ACTION.equals(caseRecStatus)){ //Validate if the status selected is "Action Required".
                output += ' AND (Status = \'Waiting on customer\' OR Status = \'Awaiting Customer Response\') ';
            } else if(BspConstants.CASE_STATUS_RESOLVED.equals(caseRecStatus)){ //Validate if the status selected is "Resolved".
                output += ' AND Status = \'Closed\' AND Permanent_Close__c = false ';
            } else if(BspConstants.CASE_STATUS_CLOSED.equals(caseRecStatus)){ //Validate if the status selected is "Closed".
                output += ' AND ((Status = \'Closed\' AND Permanent_Close__c = true) OR Subject = \'Bulk Upload\') ';
            } else if(BspConstants.CASE_STATUS_INPROGRESS.equals(caseRecStatus)){ //Validate if the status selected is "In Progress".
                String result = buildStatusInProgressClause(); //Call a method to generate dynamic clause based on the distinct case status values.
                output += String.isNotBlank(result) ? result : '';
            }
        }


        return output;
    }

    /**
     * read the status based on the criterias for display purposes,
     * this logic is on the bspEnquiry Visual Force page as-well
     *
     * @param Case c
     */
    private static String readStatus(Case c){
        if ('awaiting customer response'.equalsIgnoreCase(c.Status) || 'waiting on customer'.equalsIgnoreCase(c.Status)) {
            return 'Action Required';
        } else if ((c.status == 'closed' && c.Permanent_Close__c) || c.subject == 'Bulk Upload') {
            return c.status;
        } else if (c.status == 'closed' && !c.Permanent_Close__c) {
            return  'Resolved';
        } else {
            return 'In Progress';
        }
    }


    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that populates Case's Billing_Number__c if blank.
                   Value is retrieved from Related_Billing_Account__r.LEGACY_ID__c
    Inputs:        List<Case>
    Returns:       List<Case>
    History:
    November 23, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    private List<Case> populateStarTrackCaseFields(List<Case> caseList) {
        for (Case c : caseList) {
            if (String.isBlank(c.Billing_Number__c)
                    && c.Related_Billing_Account__c != null
                    && !String.isBlank(c.Related_Billing_Account__r.LEGACY_ID__c)) {
                c.Billing_Number__c = c.Related_Billing_Account__r.LEGACY_ID__c;
            }
            if (c.StarTrack_RecordType__c) {
                c.BSP_Addressee_Name__c = c.Article_Receiver_Name__c;
            }
        }
        return caseList;
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Description:   StarTrack method that generates additional clause for "In Progress" bsp case status filter.
    Inputs:        None
    Returns:       The string clause generated.
    History:
    March 22, 2017 - David Catindoy - Created
    ------------------------------------------------------------*/
    public String buildStatusInProgressClause(){
        String output = '';
        if(!statusValuesList.isEmpty()){
            List<String> validStatList = new List<String>();
            for(String caseStat : statusValuesList){
                if(!(BspConstants.CASE_STATUS_WAITINGONCUST.equalsIgnoreCase(caseStat) ||
                        BspConstants.CASE_STATUS_AWAITINGCUSTRES.equalsIgnoreCase(caseStat) ||
                        BspConstants.CASE_STATUS_CLOSED.equalsIgnoreCase(caseStat))){
                    validStatList.add('\''+caseStat+'\'');
                }
            }

            if(!validStatList.isEmpty()){
                output += ' AND Status IN (' + String.join(validStatList, ', ') + ') ';
            } else output += ' AND Status = null ';
        }
        return output;
    }

    public void initialisePaginationParam() {
        SIZE_PER_PAGE = 10;
        SEARCH_LIMIT = 100;

        // obtain parameters from Custom Setting. If not available, use default values above.

        Decimal enquiresPerPage = dynamicPageSize;
        Decimal maxEnquiryRecords = configSetting.MaxEnquiryRecords__c;

        if(enquiresPerPage != null) {
            SIZE_PER_PAGE = integer.valueOf(enquiresPerPage);
        }

        if(maxEnquiryRecords != null) {
            SEARCH_LIMIT = integer.valueOf(maxEnquiryRecords);
        }

    }


    /**** START - following functions are for pagination ***/
    public boolean getMaxResultsFound() {
        boolean output = false;

        if(noOfRecordsReturned == SEARCH_LIMIT) {
            output = true;
        }
        return output;
    }

    public String getMaxResultsFoundMessage() {
        String output = 'You may only search within the parameters of the most recent ' + SEARCH_LIMIT + ' enquiries.<br/><br/>';
        return output;
    }

    public Boolean getHasNext() {
        return pageCon.getHasNext();
    }
    public Boolean getHasPrevious() {
        return pageCon.getHasPrevious();
    }
    public Integer getPageNumber() {
        return pageCon.getPageNumber();
    }

    public void previous() {
        pageCon.previous();
        myCaseList_Paginated = pageCon.getRecords();
        myCaseListContainer_Paginated = putListToContainer(myCaseList_Paginated);
    }

    public void next() {
        pageCon.next();
        myCaseList_Paginated = pageCon.getRecords();
        myCaseListContainer_Paginated = putListToContainer(myCaseList_Paginated);
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that will put Case List retrieved to a CaseContainer list
    Inputs:        List<Case>
    Returns:       List<CaseContainer>
    History:
    January 9, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public List<CaseContainer> putListToContainer(List<Case> cases) {
        List<CaseContainer> caseContainerList = new List<CaseContainer>();

        for (Case c : cases) {
            caseContainerList.add(new CaseContainer(c));
        }
        return caseContainerList;
    }

    public String getSearchResultMessage() {
        Integer fromNumber = pageCon.getStartIndex();
        Integer toNumber = pageCon.getEndIndex();
        String output = '';
        if(toNumber > noOfRecordsReturned) {
            toNumber = noOfRecordsReturned;
        }

        String searchTextString = '';
        if(!((searchText == null) || (searchText == ''))) {
            searchTextString = ' for <b>' + searchText.escapeHtml4() + '</b>';
        }

        if (noOfRecordsReturned > 0) {
            output += 'Showing ';
            output += '<b>' + fromNumber + '</b> - ';
            output += '<b>' + toNumber + '</b> of ';
            output += '<b>' + noOfRecordsReturned + '</b> ';
        } else {
            output += 'Your search did not find any results' + searchTextString + '. Please try another search.';
        }
        return output;
    }
    public void refreshCreateEnquiryPage() {
        consignmentNumber = '';
        confirmCreation = false;
        notFound = false;
        duplicate = false;
    }
    public void createEnquiryWithoutArticle() {
        createEnquiry(null);
        confirmCreation = false;
        notFound = false;
        duplicate = false;
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that creates Enquiry
    History:
    October 12, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public void createEnquiry(Article__c currentArticle) {
        newCase = new Case();
        newCase.Status = StarTrack_Constants.CASE_STATUS_NEW;
        newCase.Priority = StarTrack_Constants.PRIORITY_NORMAL;
        newCase.Origin = BspConstants.CASE_ORIGIN_BSP;
        newCase.Call_Purpose__c = enq.Call_Purpose__c;
        newCase.Description = enq.Description;
        newCase.Subject = enq.Subject;

        //StarTrack Delivery Enquiry Case
        if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
            Id deliveryEnqRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_DELIVERY_ENQUIRY).getRecordTypeId();
            newCase.RecordTypeId = deliveryEnqRT;
            if (notFound) {
                newCase.Subject = enq.Subject + ' ' + consignmentNumber + ' ( NOT FOUND )';
            } else if (duplicate) {
                newCase.Subject = enq.Subject + ' ' + consignmentNumber + ' ( DUPLICATE FOUND )';
            }

            // an article is not passed in when the consignment is not found or if a duplicate is found
            List<String> matchedBillingAccount = matchBillingAccount(currentArticle);
            if (currentArticle != null) {
                newCase.Subject = enq.Subject + ' - ' + currentArticle.Name;

                // find correct billing account to attach to the case which determines case visibility within BSP for other users
                if(matchedBillingAccount != null) {
                    newCase.Related_Billing_Account__c = matchedBillingAccount[0];
                    newCase.Billing_Number__c = matchedBillingAccount[1];
                }

                newCase.Related_Billing_Account__c = currentArticle.Billing_Account__c;
                newCase.ArticleTest__c = currentArticle.Id;
                newCase.Consignment_Unique_External_ID__c = currentArticle.ArticleID__c;

                currentConsignment = null;
            }
        } else if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)){
            //StarTrack Pickup Booking Enquiry Case
            newCase.Pickup_Booking_Reference__c = enq.Pickup_Booking_Reference__c;
            Id pickupBookingRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BspConstants.CASE_RECORD_TYPE_PICKUP_BOOKING_ENQUIRY).getRecordTypeId();
            newCase.RecordTypeId = pickupBookingRT;
            List<Group> pckupBookingGroup = new List<Group>([SELECT Id, Name FROM Group WHERE Name =: BspConstants.PICKUP_BOOKING_QUEUE_NAME AND Type =: BspConstants.TYPE_QUEUE]);
            if (!pckupBookingGroup.isEmpty()) {
                newCase.OwnerId = pckupBookingGroup[0].Id;
            }

            newCase.ContactId = loginContactId;

            // grab the billing account id of the number that was entered
            // the billing account number is only found if the current user has access to it.
            Billing_Account__c matchedBillingAccount = accessibleBillingAccounts.get(getBillingAccountFromMap(billingAccountNumber));
            if (matchedBillingAccount != null) {
                newCase.Related_Billing_Account__c = matchedBillingAccount.Id;
                newCase.Billing_Number__c = matchedBillingAccount.LEGACY_ID__c;
            }
        }

        newCase.Recent_Caller_Email__c = loginContact.Email;
        newCase.Recent_Caller_First_Name__c = loginContact.FirstName;
        newCase.Recent_Caller_Last_Name__c = loginContact.LastName;
        newCase.Recent_Contact_Mobile_Number__c = loginContact.MobilePhone;
        newCase.Recent_Caller_Phone_Number__c = loginContact.Phone;
        newCase.Recent_Caller_Type__c = StarTrack_Constants.CASE_CONTACT_TYPE_SENDER;
        newCase.Recent_Caller_Pref_Method_of_Contact__c = loginContact.Pref_Method_of_Contact__c;

        //set Assignment Rules for StarTrack Delivery Enquiry
        if (!BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
            //Fetching the assignment rules on case
            AssignmentRule ar = [SELECT Id from AssignmentRule where SobjectType =: BspConstants.OBJ_CASE and Active = true limit 1];

            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= ar.id;

            //Setting the DMLOption on Case instance
            newCase.setOptions(dmlOpts);
        }

        try {
            Database.insert(newCase);

            // WHY IS THIS HERE!??
            calculateTransferCaseRule(newCase);
            //hans 02/05/2019 embedded dropzone file upload
            //convert files to attachments saved from dropzone and link to the created case
            convertFilesToAttachmentsAndDeleteFiles(newCase.Id, true);
            showSuccessMessage = true;
            section = BspConstants.PAGE_SECTION_THANK_YOU;
        } catch (DmlException e) {
            showSuccessMessage = false;
        }

        newCase = [SELECT Id, CaseNumber FROM Case WHERE Id =: newCase.Id LIMIT 1];

    }

    /**
     * StarTrack method that gets Billing Account with prefix P, T, or none from the map
     * When checking for accessible billing account we search in order of the prefix'd account numbers just incase of collision's with non-prefixed billing account numbers
     */
    public Id getBillingAccountFromMap(String billingAcctNo) {
        Id billAcct = null;
        if (accessibleBillingAccNumbers.get('P' + billingAcctNo) != null) {
            billAcct = accessibleBillingAccNumbers.get('P' + billingAcctNo);
        } else if (accessibleBillingAccNumbers.get('T' + billingAcctNo) != null) {
            billAcct = accessibleBillingAccNumbers.get('T' + billingAcctNo);
        } else if (accessibleBillingAccNumbers.get(billingAcctNo) != null) {
            billAcct = accessibleBillingAccNumbers.get(billingAcctNo);
        }
        return billAcct;
    }

    public boolean isSingleConsignment(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
        return StarTrack_Constants.ERR_CODE_0.equals(wrapper.errorCode) && wrapper.articleList.size() == 1 && wrapper.isConsignmentSaved;
    }

    public boolean isMultipleConsignment(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
        return StarTrack_Constants.ERR_CODE_0.equals(wrapper.errorCode) && wrapper.articleList.size() > 1;
    }

    public boolean articleNotFound(StarTrackConsignmentSearchUtil.ConsignmentWrapper wrapper) {
        return wrapper != null && wrapper.articleList.isEmpty() && StarTrack_Constants.ERR_CODE_ART_NOT_FOUND.equals(wrapper.errorCode);
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that validates if required fields are populated
    Inputs:        None
    Returns:       boolean
    History:
    October 12, 2016 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public boolean validateFields() {
        boolean valid = true;
        String errorMessage = '';
        List<String> fields = new List<String>();
        if (String.isBlank(enq.Subject)) {
            fields.add(BspConstants.ENQ_FLD_SUBJECT);
        }
        if (String.isBlank(enq.Description)) {
            fields.add(BspConstants.ENQ_FLD_DESC);
        }
        if (String.isBlank(enq.Call_Purpose__c)) {
            fields.add(BspConstants.ENQ_FLD_PURPOSE);
        }

        if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
            if (String.isBlank(consignmentNumber)) {
                fields.add(BspConstants.ENQ_FLD_CON_NUM);
            } else {
                if (consignmentNumber.length() > configSetting.Max_Length_for_Consignment_Number__c) {
                    errorMessage = BspConstants.CON_NO_INVALID_SIZE_ERR + ' Max length is ' + Integer.valueOf(configSetting.Max_Length_for_Consignment_Number__c) + ' characters.';
                } else {
                    for(String s : (Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c).split(StarTrack_Constants.SPECIALCHARS)){
                        if(consignmentNumber.contains(s)){
                            errorMessage = BspConstants.CON_NO_INVALID_CHAR_ERR + Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SPECIALCHARS).Field_Name__c;
                            break;
                        }
                    }
                }
            }
        } else if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)){

            if (String.isBlank(billingAccountNumber)) {
                fields.add(BspConstants.ENQ_FLD_BILL_ACC_NO);
            }

            if (String.isBlank(enq.Pickup_Booking_Reference__c)) {
                fields.add(BspConstants.ENQ_FLD_PCKUP_BKNG_REF_NO);
            } else if(enq.Pickup_Booking_Reference__c.length() > configSetting.Pickup_Booking_Ref_Number_Max_Length__c || enq.Pickup_Booking_Reference__c.length() < configSetting.Pickup_Booking_Ref_Number_Min_Length__c || !enq.Pickup_Booking_Reference__c.isNumeric()){
                String errorMsg =  BSPErrorMessages__c.getValues('StarTrack-Invalid Pickup Ref Number') != null ? BSPErrorMessages__c.getValues('StarTrack-Invalid Pickup Ref Number').Message__c : '';
                errorMessage =  String.isNotBlank(errorMsg) ? errorMsg : BspConstants.PICKUPREFNUM_ERROR;
            }
        }

        if (!fields.isEmpty()) {
            if (String.isNotBlank(errorMessage)) {
                errorMessage += '\n';
            }
            errorMessage = 'Please provide ';
            errorMessage += String.join(fields, ', ') + '.';
        }

        if (String.isNotBlank(errorMessage)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            valid = false;
        }
        return valid;
    }

    /**
    * StarTrack method that validates the Case creation and continues with the creation if valid
    * This is called when the Create/Submit Enquiry button is pressed and the enquiry is StarTrack
    */
    public Continuation createEnquiryStarTrack() {
        confirmCreation = false;
        notFound = false;
        duplicate = false;
        currentConsignment = null;
        //check required fields
        if (enq.CCUEnquiryType__c.startsWith('StarTrack') && validateFields()) {

            bspEnquiry.CaseCreationResponse response = new bspEnquiry.CaseCreationResponse();
            response.isCaseCreationValid = false;

            if (BspConstants.CASE_RECORD_TYPE_STARTRACK_DELIVERY_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
                if (creationFromConsignSearch && articleFromConsignSearch != null && articleFromConsignSearch.Name.equals(consignmentNumber)) {
                    if(retrieveConCases(articleFromConsignSearch)){
                        currentConsignment = articleFromConsignSearch;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, caseQueryResult));
                    } else{
                        createEnquiry(articleFromConsignSearch);
                    }
                } else {
                    try {
                        wwwAuspostComAuSchemaCustomercarema.SearchRequest request = BSPConsignmentSearchUtil.generateSearchRequest(consignmentNumber, BspConstants.CON_SEARCH_TYPE_CONSIGNMENT, StarTrack_Constants.REQUEST_ACTION_FULL);
                        AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = BSPConsignmentSearchUtil.generateAsyncStub();
                        Continuation cont = new Continuation(Integer.valueOf(configSetting.StarTrackAsyncWebServiceTimeout__c));
                        cont.continuationMethod = BspConstants.METHOD_PROCESS_DELIVERY_ENQ;
                        //search for the consignment
                        emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);
                        return cont;
                    } catch (CalloutException e) {
                        if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_TIMEOUT)){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_SEARCHCONSIGNTIMEOUT).Field_Name__c));
                        } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_FAILEDTOGETELEM) || e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_POLICYFALSIFIED)){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Authentication_Error__c));
                        } else if(e.getMessage().contains(StarTrack_Constants.ERR_KEYWRD_COULDNOTFINDCLIENTCERT)){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning, stSettings.StarTrack_ConSearch_Client_Cert_Error__c));
                        } else{
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Consignment_Search_Settings__c.getValues(StarTrack_Constants.KEYWRD_ERRCONSIGNSEARCH).Field_Name__c));
                        }
                    } catch (Exception ex){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                    }
                }

            } else if (BspConstants.CASE_RECORD_TYPE_STARTRACK_PICKUP_BOOKING_ENQUIRY.equals(enq.CCUEnquiryType__c)) {
                // check to see if the billing account number that was entered is accessible to the current user
                // the expected input from the user is the billing account without the 'T' or 'P' however we still support a billing account entered with a 'T' or 'P'
                // when checking for accessible billing account we search in order of the prefix'd account numbers just incase of collision's with non-prefixed billing account numbers
                Billing_Account__c matchedBillingAccount = accessibleBillingAccounts.get(getBillingAccountFromMap(billingAccountNumber));
                if (matchedBillingAccount != null) {
                    // only allow startrack billing accounts to be connected to Pickup booking cases
                    if(isBillingAccountST(matchedBillingAccount)) {
                        createEnquiry(null);
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, BSPErrorMessages__c.getValues('Invalid Case Billing Account') != null ? BSPErrorMessages__c.getValues('Invalid Case Billing Account').Message__c : 'The Billing Account entered is not applicable for this type of case.'));
                    }
                } else {
                    // either the billing account doesn't exist or the user does not have access to it
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Billing Account ' + billingAccountNumber + ' is not valid.'));
                }
            }
        }
        return null;
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that process Case creation (Delivery Enquiry) after Consignment search
    January 13, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public Object processDeliveryEnquiryCreation() {
        Map<String, BSPErrorMessages__c > errors = BSPErrorMessages__c.getAll();
        searchedConsignment = StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), false);
        String err = '';
        if (searchedConsignment != null) {
            // if consignment number provided is valid but is not found or multiple consignment found,
            // provide error message and ask if user wants to proceed creating case
            if (articleNotFound(searchedConsignment)) {
                confirmCreation = true;
                notFound = true;
                err = errors.get(BspConstants.CREATE_ENQ_MSG_CON_NOT_FOUND).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, consignmentNumber.escapeHtml4());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));
            } else if (isMultipleConsignment(searchedConsignment)) {
                confirmCreation = true;
                duplicate = true;
                err = errors.get(BspConstants.CREATE_ENQ_MSG_MULT_CON).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, consignmentNumber.escapeHtml4());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));
            } else {
                //if single consignment found
                // reselect the data out to include the billing account record to verify whether it's accessible to the current user
                List<Article__c> artList = [SELECT Id, Name, Billing_Account__c, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Id, Billing_Account__r.Organisation__c, ArticleID__c FROM Article__c WHERE Id =: searchedConsignment.articleList[0].Id];

                //validate if user is authorized on consignment's billing account
                // proceed creation if valid, return error if not
                if (isSingleConsignment(searchedConsignment) && !artList.isEmpty() && isArticleAccessible(artList[0])) {
                    if(retrieveConCases(artList[0])){
                        currentConsignment = artList[0];
                        // TODO: Why was this commented out??!!
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, caseQueryResult));
                    } else{
                        createEnquiry(artList[0]);
                    }
                } else {
                    err = errors.get(BspConstants.CREATE_ENQ_MSG_NOT_AUTH).Message__c.replace(BspConstants.MSG_KEY_CON_NUM, consignmentNumber.escapeHtml4());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));
                }
            }
        }

        return null;
    }


    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that will close bulk cases
    January 9, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public void bulkCloseCase() {
        Map<Id, Case> casesToClose = new Map<Id, Case>(retrieveSelectedCases());
        Map<Id, Boolean> inApproval = Approval.isLocked(new List<Id>(casesToClose.keySet()));
        List<CaseComment> caseComments = new List<CaseComment>();
        List<Id> casesToUnlock = new List<Id>();
        if (!casesToClose.isEmpty()) {
            for (Case c : casesToClose.values()) {
                if(inApproval.containsKey(c.Id) && inApproval.get(c.Id)){
                    caseComments.add(new CaseComment(CommentBody = 'BSP User closed this case while still pending for approval process.', ParentId = c.Id));
                    casesToUnlock.add(c.Id);
                }
                c.Status = BspConstants.CASE_STATUS_CLOSED;
                c.ResolutionCode__c = BspConstants.CASE_RESOLUTION_CODE_CUSTOMER_SELF_SERVICE;
            }
            try {
                Database.update(casesToClose.values());
                if(!caseComments.isEmpty()){
                    Database.insert(caseComments);
                    List<Approval.UnlockResult> results = Approval.unlock(casesToUnlock, false);
                }
                displayCaseList();
            } catch(Exception ex) {
                ApexPages.addMessages(ex);
            }
        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, BspConstants.CASE_CLOSE_SELECT_MSG);
            Apexpages.addmessage(msg);
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that will validate cases to update
    January 10, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public void validateCasesToUpdate() {
        casesToUpdateBulk = retrieveSelectedCases();
        if (!casesToUpdateBulk.isEmpty()) {
            section = BspConstants.PAGE_SECTION_BULK_CASE_UPDATE;
        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, BspConstants.CASE_UPDATE_SELECT_MSG);
            Apexpages.addmessage(msg);
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that will update cases in bulk
    January 10, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public void bulkUpdateCases() {

        if (caseCommentBulk.trim() != null && !String.isBlank(caseCommentBulk.trim())) {
            List<CaseComment> caseComments = new List<CaseComment>();
            CaseComment caseComment = null;
            for (Case c : casesToUpdateBulk) {
                caseComment = new CaseComment();
                caseComment.IsPublished = true;
                caseComment.ParentId = c.Id;
                caseComment.CommentBody = caseCommentBulk.trim();
                caseComments.add(caseComment);

                c.Case_Update__c = StarTrack_Constants.CASE_UPDATE_CUSTOMERRESP;
                c.Case_Update_Time__c = System.now();
                if (StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER.equals(c.Status)) {
                    c.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
                }
            }
            try {
                insert caseComments;
                caseCommentBulk = '';
                update casesToUpdateBulk;
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, BspConstants.CASE_ADDCOMMENT_SUCCESS_MSG);
                Apexpages.addmessage(msg);
            } catch(Exception ex) {
                ApexPages.addMessages(ex);
            }
        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, BspConstants.CASE_ADDCOMMENT_MSG);
            Apexpages.addmessage(msg);
        }
    }

    /*------------------------------------------------------------
    Author:        Jen Karen Tan
    Description:   StarTrack method that will get cases to update
    Inputs:
    Returns:       void
    History:
    January 10, 2017 - Jen Karen Tan - Created
    ------------------------------------------------------------*/
    public List<Case> retrieveSelectedCases() {
        List<Case> selectedCases = new List<Case>();
        for (CaseContainer cc : myCaseListContainer_Paginated) {
            if (cc.isSelected && !BspConstants.CASE_STATUS_CLOSED.equals(cc.caseObj.Status)) {
                selectedCases.add(cc.caseObj);
            }
        }
        return selectedCases;
    }

    /*------------------------------------------------------------
    Author:        David Catindoy
    Description:   StarTrack method that sort case records based on the sortBy variable.
    Inputs:
    Returns:       void
    History:
    March 21, 2017 - David Catindoy - Created
    ------------------------------------------------------------*/
    public void sortRecords() {


        this.completeList_Paginated.sort(); //Sort case records inside a list of wrapper container.

        List<Case> sortedList = new List<Case>();
        for(CaseContainer caseCon : completeList_Paginated){ //Get the sorted list and put the case record inside sortedList container.
            sortedList.add(caseCon.caseObj);
        }

        initialisePaginationParam(); //Call this method to initialize pagination parameters.
        pageCon = new Pagination(SIZE_PER_PAGE, sortedList); //Initialize a new pagination.
        noOfRecordsReturned = pageCon.getResultSize();
        myCaseList_Paginated = pageCon.getRecords(); //Get all the case records included in the current page of the pagination.
        myCaseListContainer_Paginated = putListToContainer(myCaseList_Paginated); //Put the sorted case records in another wrapper list container to display in the table.

        //start code changes for REQ1496210
        columnDir = sortColumnDir;
        //trackNumDir = sortTrackingNumberDir;
        //sendingToDir = sortSendingToDir;
        //end code changes for REQ1496210

    }

    public Boolean retrieveConCases(Article__c consignment){
        caseNumbers = new Map<String, Id>();
        lastKey = '';
        multipleCaseError = '';
        List<Case> listOfCases = new List<Case>([SELECT Id, CaseNumber FROM Case WHERE ArticleTest__r.Id = :consignment.Id AND RecordType.Name = :StarTrack_Constants.CASE_DELIVERY_RT AND IsClosed = false]);
        if(!listOfCases.isEmpty()){
            multipleCaseError = listOfCases.size() > 1 ? (BSPErrorMessages__c.getValues('Multiple Case Under Consignment') != null ? BSPErrorMessages__c.getValues('Multiple Case Under Consignment').Message__c : 'There are open enquiries associated to this consignment:') :
                    (BSPErrorMessages__c.getValues('Single Case Under Consignment') != null ? BSPErrorMessages__c.getValues('Single Case Under Consignment').Message__c : 'There is an open enquiry associated to this consignment:');
            for(Case caseRec : listOfCases){
                caseNumbers.put(caseRec.CaseNumber, caseRec.Id);
            }
            lastKey = new List<String>(caseNumbers.keySet())[caseNumbers.size()-1];
            return true;
        }
        return false;
    }

    public void createCaseUnderConsign(){
        createEnquiry(currentConsignment);
    }

    public void calculateTransferCaseRule(Case caseRecord){
        Case c = [SELECT Id, Call_Purpose__c, RecordTypeId, RecordType.Name, Enquiry_Type__c, Network__r.OwnerId, Business_Solutions_Customer__c, Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c, Network__r.Name, Initial_Caller_Type__c,
                Status, OwnerId, Article_Service_Type__c, ArticleTest__r.Product_Group__c, Account.StarTrack_Customer_Stream__c , Related_Billing_Account__r.StarTrack_Priority_Customer__c  FROM Case WHERE Id =: caseRecord.Id];

        List<StarTrack_Transfer_Case_Rule__c> tc_rules = [SELECT Id, Business_Solutions_Customer__c, Case_Purpose__c, Case_RecordType__c, Case_Type__c, Customer_Stream__c, Initial_Caller_Type__c, Order__c, Product_Group__c,BSP_Rule__c, Queue_Name__c, Priority_Customer__c
        FROM StarTrack_Transfer_Case_Rule__c ORDER BY Order__c];

        Boolean ruleSatisfied = false;
        Boolean caseOwnerChanged = false;
        for(StarTrack_Transfer_Case_Rule__c tc_rule : tc_rules){
            if((String.isNotBlank(tc_rule.Case_Purpose__c) ? tc_rule.Case_Purpose__c.equals(c.Call_Purpose__c) : true) && (String.isNotBlank(tc_rule.Case_RecordType__c) ? tc_rule.Case_RecordType__c.equals(c.RecordType.Name) : true) &&
                    (String.isNotBlank(tc_rule.Case_Type__c) ? tc_rule.Case_Type__c.equals(c.Enquiry_Type__c) : true) && (String.isNotBlank(tc_rule.Customer_Stream__c) ? tc_rule.Customer_Stream__c.equals(c.Account.StarTrack_Customer_Stream__c) : true) &&
                    (String.isNotBlank(tc_rule.Initial_Caller_Type__c) ? tc_rule.Initial_Caller_Type__c.equals(c.Initial_Caller_Type__c) : true) && (String.isNotBlank(tc_rule.Product_Group__c) ? tc_rule.Product_Group__c.equals(c.ArticleTest__r.Product_Group__c) : true) &&
                    (tc_rule.Business_Solutions_Customer__c ? c.Business_Solutions_Customer__c == tc_rule.Business_Solutions_Customer__c : true) &&
                    (tc_rule.Priority_Customer__c ? c.Related_Billing_Account__r.StarTrack_Priority_Customer__c == tc_rule.Priority_Customer__c : true) && String.isNotBlank(tc_rule.Queue_Name__c) && tc_rule.BSP_Rule__c){

                if(StarTrack_Constants.TRANSFER_QUEUE.equals(tc_rule.Queue_Name__c) && String.isNotBlank(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c)){
                    Id queueId = queryQueue(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c);
                    if(String.isNotBlank(queueId)){
                        c.OwnerId = queueId;
                        caseOwnerChanged = true;
                    }
                    ruleSatisfied = true;
                    break;
                } else{
                    Id queueId = queryQueue(tc_rule.Queue_Name__c);
                    if(String.isNotBlank(queueId)){
                        c.OwnerId = queueId;
                        caseOwnerChanged = true;
                    }
                    ruleSatisfied = true;
                    break;
                }
            }
        }

        if(!ruleSatisfied && String.isNotBlank(c.Network__r.OwnerId)){
            c.OwnerId = c.Network__r.OwnerId;
            caseOwnerChanged = true;
        } else if(!caseOwnerChanged && c.Business_Solutions_Customer__c && StarTrack_Constants.CASE_DELIVERY_RT.equals(c.RecordType.Name)){
            AssignmentRule ar = [SELECT Id FROM AssignmentRule WHERE SobjectType =: BspConstants.OBJ_CASE AND Active = true LIMIT 1];

            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= ar.Id;

            //Setting the DMLOption on Case instance
            c.setOptions(dmlOpts);
            caseOwnerChanged = true;
        }

        if(caseOwnerChanged){
            Database.update(c);
        }
    }

    public Id queryQueue(String queueName){
        try{
            return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :queueName].Id;
        }catch(QueryException e){
            return null;
        }
    }

    /**
     * method to get files uploaded in vf into dropzone, store as
     * files in salesforce and collect contentversion ids
     * @return PageReference
     */
    public PageReference submitEnquiryFileUpload() {
        //initialize content doc version lists in case they are not
        system.debug('fileObjectList '+JSON.serialize(fileObjectList));

        if(ApexPages.hasMessages())
        {
            // Salesforce would load the attachment file. If it is larger than 10MB, it will reset every attachment variables
            //    and leaves an ApexMessage. Display it!
            //    "This file exceeds the maximum size limit of 10MB."
            return null;
        }
        Decimal fileBodyLengthDeimal = Decimal.valueOf(fileBodyLengthdz);
        if(fileBodyLengthDeimal > 0) {
            if((fileBodyLengthDeimal/1048576) > fileSizeLimit) {
                string msgString = 'This file exceeds the maximum size limit of ' + fileSizeLimitInteger + 'MB.';
                apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, msgString);
                apexpages.addmessage(msg);

                // clear fileBody to blank to avoid viewstate error
                fileBodydz = null;
                fileBodyLengthDeimal = 0;
                return null;
            } else {
                try {
                    //save uploaded docs as files in salesforce
                    ContentVersion fileRec = new ContentVersion();
                    //Assign network id to the contentversion record in test class context because network id will be null
                    //in test class context and community user can't create files without specifying network id
                    if(Test.isRunningTest()){
                        List<NetworkMember> memList = [SELECT Id, NetWorkId FROM NetworkMember WHERE MemberId = :UserInfo.getUserId()];
                        fileRec.NetworkId = memList[0].NetworkId;
                    }
                    fileRec.VersionData = EncodingUtil.base64Decode(fileBodydz);
                    fileRec.pathonClient = fileContentTypedz; // why this was NULL, why do we need mimeTypeMapping??
                    fileRec.Title = fileNamedz;
                    for(string filext :mimeTypeMapping.keySet()){
                        if(mimeTypeMapping.get(filext) == fileContentTypedz){
                            fileRec.pathonClient = fileNamedz.substringBefore('.')+'.'+filext;
                        }
                    }
                    Database.SaveResult insertResults = Database.insert(fileRec);
                    contentDocVersionIds.add(fileRec.Id);
                    contentDocVersionNames.add(fileNamedz);
                    system.debug('HASANTHA contentDocVersionNames '+contentDocVersionNames);
                } catch(Exception ex) {
                    // clear fileBody to blank to avoid viewstate error
                    fileBody = null;
                    fileBodyLengthdz = '0';
                    system.debug('xxx ex.message = ' + ex.getMessage()+' at line '+ex.getStacktraceString());
                    ApexPages.addMessages(ex);
                    return null;
                }
            }
        }
        return null;
    }


    /**
     * While creating case get the contentversoin ids, convert the
     * files to attachments, attach it to case and delete the files
     * @param parentId
     * @param createAttachments
     */
    public void convertFilesToAttachmentsAndDeleteFiles(String parentId, boolean createAttachments){
        try{
            //convert files to attachments saved from dropzone and link to the created case
            if(createAttachments){
                List<Attachment> attacmentToInsert = new List<Attachment>();
                for(ContentVersion cv :[SELECT Id, Pathonclient, VersionData, FileExtension, Title FROM ContentVersion WHERE Id =: contentDocVersionIds]){
                    Attachment att = new Attachment();
                    att.Body = cv.VersionData;
                    att.Name = cv.Title;
                    att.ParentId = parentId;
                    if(mimeTypeMapping.containsKey(cv.FileExtension)){
                        att.ContentType = mimeTypeMapping.get(cv.FileExtension);
                    }
                    attacmentToInsert.add(att);
                }
                system.debug('attacmentToInsert '+attacmentToInsert);
                if(attacmentToInsert != null && attacmentToInsert.size() >0){
                    insert attacmentToInsert;
                }
            }
            //query content document from the contentversion and delete the records after
            //inserting attachments
            /*set<Id> contentDocumentId = new set<Id>();
            for(ContentVersion cv :[SELECT Id, contentDocumentId FROM ContentVersion WHERE Title LIKE :fileKeyCompareString ]){
                contentDocumentId.add(cv.contentDocumentId);
            }*/
            delete [SELECT Id FROM ContentDocument WHERE Id =:contentDocVersionIds];

        }
        catch(exception ex){
            system.debug('exception in converting file to attachment '+ex.getMessage()+' at line '+ex.getstacktraceString());
        }
    }

    /**
    * get valid billing accounts for filter picklist,
    * preparing and fill in the billing accounts based on the billing accounts retrieved from getBillingAccountsByContact()
    * Hasantha.liyanage@auspost.com.au (03/05/2019)
    * @return
    */
    public transient List<SelectOption> billingAccounts {
        get {
            List<SelectOption> options = new list<SelectOption>();
            options.add(new SelectOption('', BspConstants.SELECT_OPTION_LABEL_ALL_BILL_ACCOUNT));


            for (Integer i = 0; i < accessibleBillingAccounts.values().size(); i++) {
                Billing_Account__c billingAccount = accessibleBillingAccounts.values()[i];

                // assign the value with a separator, so that we can use the values for the SOQL (SF ID and Legacy ID)
                options.add(new SelectOption(billingAccount.id + '&' + billingAccount.LEGACY_ID__c, billingAccount.LEGACY_ID__c + ' (' + billingAccount.Name + ')'));

                if (i >= 998) {
                    break;
                }
            }

            return options;
        }
    }

    /**
     * Data Transfer Object Model class to map download data
     */
    public class CaseDetails {
        public String EnquiryNo;
        public String DateCreated;
        public String TrackingNo;
        public String Details;
        public String SendingTo;
        public String Status;
        public String ArticleID;
    }

    public class CaseCreationResponse {
        public boolean isCaseCreationValid {get; set;}
        public String errorCode {get; set;}
        public String message {get;set;}
    }

    //Case container for Case display list
    public class CaseContainer implements Comparable{
        public Boolean isSelected {get; set;}
        public Boolean isST {get; set;}
        public Case caseObj {get; set;}
        public String sendingTo {get; set;}

        public CaseContainer(Case c) {
            this.caseObj = c;
            this.isSelected = false;
            this.isST = c.RecordType.DeveloperName.startsWith('StarTrack') ? true : false;
            this.sendingTo = String.isNotBlank(c.BSP_Addressee_Name__c) ? c.BSP_Addressee_Name__c : c.Secondary_Contact__c;
        }

        public Integer compareTo(Object compareTo) {
            CaseContainer compareToCase = (CaseContainer)compareTo; //Get the record to be compare.

            //comparing with sortColumnDir for sorting in part of code changes for REQ1496210.

            if (BspConstants.SORTBY_SENDINGTO.equals(sortBy)) { //Validate if sortBy is equal to 'SendingTo'
                if(BspConstants.ASC_DIR.equals(sortColumnDir)){ //Check if the sort direction is ascending.
                    if (this.sendingTo > compareToCase.sendingTo) {
                        return 1;
                    } else if (this.sendingTo < compareToCase.sendingTo) {
                        return -1;
                    }
                } else{
                    if (this.sendingTo > compareToCase.sendingTo) {
                        return -1;
                    } else if (this.sendingTo < compareToCase.sendingTo) {
                        return 1;
                    }
                }
            } else if(BspConstants.SORTBY_ARTNAME.equals(sortBy)){ //Validate if sortBy is equal to 'ArticleName'
                if(BspConstants.ASC_DIR.equals(sortColumnDir)){ //Check if the sort direction is ascending.
                    if (this.caseObj.ArticleTest__r.Name > compareToCase.caseObj.ArticleTest__r.Name) {
                        return 1;
                    } else if (this.caseObj.ArticleTest__r.Name < compareToCase.caseObj.ArticleTest__r.Name) {
                        return -1;
                    }
                } else{
                    if (this.caseObj.ArticleTest__r.Name > compareToCase.caseObj.ArticleTest__r.Name) {
                        return -1;
                    } else if (this.caseObj.ArticleTest__r.Name < compareToCase.caseObj.ArticleTest__r.Name) {
                        return 1;
                    }
                }
            }
            else if (BspConstants.SORTBY_STATUS.equals(sortBy)) { //Validate if sortBy is equal to 'Status'
                if(BspConstants.ASC_DIR.equals(sortColumnDir)){ //Check if the sort direction is ascending.
                    if (this.caseObj.Status > compareToCase.caseObj.Status) {
                        return 1;
                    } else if (this.caseObj.Status < compareToCase.caseObj.Status) {
                        return -1;
                    }
                } else{
                    if (this.caseObj.Status > compareToCase.caseObj.Status) {
                        return -1;
                    } else if (this.caseObj.Status < compareToCase.caseObj.Status) {
                        return 1;
                    }
                }
            }
            else if (BspConstants.SORTBY_CREATEDDATE.equals(sortBy)) { //Validate if sortBy is equal to 'CreatedDate'
                if(BspConstants.ASC_DIR.equals(sortColumnDir)){ //Check if the sort direction is ascending.
                    if (this.caseObj.CreatedDate > compareToCase.caseObj.CreatedDate) {
                        return 1;
                    } else if (this.caseObj.CreatedDate < compareToCase.caseObj.CreatedDate) {
                        return -1;
                    }
                } else{
                    if (this.caseObj.CreatedDate > compareToCase.caseObj.CreatedDate) {
                        return -1;
                    } else if (this.caseObj.CreatedDate < compareToCase.caseObj.CreatedDate) {
                        return 1;
                    }
                }
            }
            else if (BspConstants.SORTBY_ENQUIRY.equals(sortBy)) { //Validate if sortBy is equal to 'Enquiry'
                if(BspConstants.ASC_DIR.equals(sortColumnDir)){ //Check if the sort direction is ascending.
                    if (this.caseObj.CaseNumber > compareToCase.caseObj.CaseNumber) {
                        return 1;
                    } else if (this.caseObj.CaseNumber < compareToCase.caseObj.CaseNumber) {
                        return -1;
                    }
                } else{
                    if (this.caseObj.CaseNumber > compareToCase.caseObj.CaseNumber) {
                        return -1;
                    } else if (this.caseObj.CaseNumber < compareToCase.caseObj.CaseNumber) {
                        return 1;
                    }
                }
            }
            // If we don't have a know sort by, let's just return that they are all equal.
            return 0;
        }
    }

    public class Pagination {
        // 2013-10-24 Louis Wang (Bluewolf)
        // this class will act as StandardSetController
        //  StandardSetController has limitation
        //    - it only accepts SObject
        //    - it will apply SFDC security to prevent ChatterPlus user from accessing Internal__kav
        private Integer currentPage = 1;
        private Integer totalItems;
        private Integer itemsPerPage;

        private Integer totalPages = 0;

        private List<Case> internalCaseList;

        public Pagination (Integer itemsPerPage, List<Case> caseList) {
            this.internalCaseList = caseList;
            this.totalItems = caseList.size();
            this.itemsPerPage = itemsPerPage;
            if (this.itemsPerPage < 1) {
                this.itemsPerPage = 1;
            }

            System.debug('xxx this.totalItems = ' + this.totalItems);
            System.debug('xxx this.itemsPerPage = ' + this.itemsPerPage);
            System.debug('xxx SIZE_PER_PAGE = ' + SIZE_PER_PAGE);
            this.totalPages = this.totalItems / this.itemsPerPage;
            if (math.mod(this.totalItems, this.itemsPerPage) > 0) {
                this.totalPages = this.totalPages + 1;
            }

        }

        public Integer getPageNumber() {
            return currentPage;
        }

        public void setPageNumber(integer currentPage) {
            if (currentPage > totalPages) {
                currentPage = totalPages;
            }
            if (currentPage < 1) {
                currentPage = 1;
            }
            this.currentPage = currentPage;
        }

        public void next() {
            setPageNumber(getNextPage());
        }

        public void previous() {
            setPageNumber(getPreviousPage());
        }

        public Integer getTotalPages() {
            return this.totalPages;
        }

        public boolean getHasPrevious() {
            return currentPage > 1;
        }

        public boolean getHasNext() {
            return currentPage < totalPages;
        }

        public Integer getPreviousPage() {
            if (getHasPrevious()) {
                return currentPage - 1;
            } else {
                return 1;
            }
        }

        public Integer getNextPage() {
            if (getHasNext()) {
                return currentPage + 1;
            } else {
                return totalPages;
            }
        }

        public Integer getStartIndex() {
            return (this.currentPage - 1) * this.itemsPerPage + 1;
        }

        public Integer getEndIndex() {
            Integer endIndex = this.currentPage * this.itemsPerPage;
            if (endIndex > this.totalItems) {
                endIndex = this.totalItems;
            }
            return endIndex;
        }

        public List<Case> getRecords() {
            List<Case> output = new List<Case>();

            Integer startRecord = getStartIndex();
            Integer endRecord = getEndIndex();

            for(Integer counter = startRecord; counter <= endRecord; counter++) {
                // first record in list is 0, so need to minus 1
                output.add(internalCaseList[counter-1]);
            }

            System.debug('>> output.size(): ' + output.size());

            return output;
        }

        public Integer getResultSize() {
            return totalItems;
        }

    }
    /**** END - pagination ***/

    /*********
	 * Can be removed on next deployment... added due to deployment errors
	 * https://success.salesforce.com/issues_view?id=a1p300000008YkUAAU
	 */
	public System.Continuation validateCaseCreation() { return null; }
	public System.PageReference submitPage() { return null; }
	public Boolean hideSSCR5 { get; set; }
	public List<System.SelectOption> getBillingAccounts() { return null; }
	public String BAScope { get; set; }
	/*
	 * END
	 **********/

}