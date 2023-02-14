/**************************************************
Description:  Utility class for the startrack ID search module, this will hold all the validation and the detail logics for functionality
History:
--------------------------------------------------
2022-11-24 - H Liyanage - Created
2022-12-05 - Prerna Rahangdale Added a new TransferCaseQueuable and added Transfer Case feature.
**************************************************/
public inherited sharing class StarTrackTrackingIDSearchUtil {
    public static StarTrackTrackingIDSearchUtil getInstance() {

        return (StarTrackTrackingIDSearchUtil) Application.Utilities.getInstance(StarTrackTrackingIDSearchUtil.class);

    }

    @TestVisible
    static final Id communityUserProfileId {
        get {
            if(communityUserProfileId == null) {
                communityUserProfileId = ProfilesSelector.newInstance().selectByName(new Set<String>{'StarTrack Help and Support Profile'}).values()[0].Id;
            }
            return communityUserProfileId;
        }
        private set;
    }
    public static void getTrackingDetails(List<SObject> records) {
        List<Case> selectedCases = new List<Case>();
        for(Case cse:(List<Case>)records) {
            // if the reference has been changed
            if(cse.ReferenceID__c != null) {
                selectedCases.add(cse);
            }
        }

        if(!selectedCases.isEmpty()) {
            System.enqueueJob(new TrackingSearchQueueable(selectedCases[0]));
        }
    }

    @TestVisible
    private without sharing class TrackingSearchQueueable implements Queueable, Database.AllowsCallouts {
        Case cse;
        Set<Id> caseRecordTypes = new Set<Id>{
                SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId()
                , SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_VOC_RT_DEV).getRecordTypeId()};
        public TrackingSearchQueueable(Case record) {
            Set<SObjectField> objectFields = new Set<SObjectField>{
                    Case.Id,
                    Case.RecordTypeId,
                    Case.ArticleTest__c,
                    Case.ReferenceID__c,
                    Case.Origin,
                    Case.Enquiry_Type__c};
            this.cse = CasesSelector.newInstance(objectFields).selectById(new Set<Id>{Id.valueOf(record.Id)}).values()[0];
        }

        public void execute(QueueableContext context) {
            try {
                if((UserInfo.getProfileId() == communityUserProfileId || Test.isRunningTest())// only execute for startrack community
                        && this.cse.ArticleTest__c == null // if no article record is linked
                        && this.cse.ReferenceID__c != null // and there's a reference ID
                        && StarTrack_Constants.CASE_ORIGIN_WEB.equalsIgnoreCase(this.cse.Origin) // origin is web only
                        && caseRecordTypes.contains(this.cse.RecordTypeId)) { // only startrack record types created via STHS
                    StarTrackTrackingIDSearchService idSearchService = StarTrackTrackingIDSearchService.newInstance();
                    idSearchService.dateRange = '1';
                    idSearchService.searchString = this.cse.ReferenceID__c;
                    idSearchService.isConsole = false;
                    idSearchService.map_searchCustomSettings.get(idSearchService.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
                    StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap = idSearchService.searchConsignment();
                    StarTrackTrackingIDSearchUtil thisUtil = StarTrackTrackingIDSearchUtil.getInstance();
                    if(thisUtil.validate(idSearchService.lst_article, cse.Id, conWrap)) {
                        thisUtil.assignAndUpdateCase(idSearchService.lst_article[0],this.cse);
                    }
                }
            } catch (Exception ex) {
                createCaseComment(System.Label.STHSIDSearchCommentsTimeoutTechError, cse.Id);
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(
                        ex
                        , UserInfo.getOrganizationId()
                        , StarTrack_Constants.STARTRACK
                        , TrackingSearchQueueable.class.getName()
                        , 'TrackingSearchQueueable'
                        , StarTrack_Constants.ASYNC_QUEUEABLE
                        , LoggingLevel.ERROR);
                throw ex;
            }
        }
    }

    /**
         * validate and assign the found article details to the case
         * @param article
         * @param cse
         */
    public void assignAndUpdateCase(Article__c article, Case cse) {
        try {
            case caseToBeUpdated = new Case();
            caseToBeUpdated.Id = cse.Id;
            caseToBeUpdated.ArticleTest__c = article.Id;
            caseToBeUpdated.Consignment_Unique_External_ID__c = article.ArticleID__c ;
            caseToBeUpdated.Connote_number__c  = article.Name ;
            // Only if Case’s Enquiry Type is LDC
            if (StarTrack_Constants.CASE_ENQUIRY_LDC.equalsIgnoreCase(cse.Enquiry_Type__c)) {
                caseToBeUpdated.Total_Amount_of_Claim__c = article.Freight_Amount__c;
            }

            caseToBeUpdated.Delivery_Date__c = String.isNotBlank(article.CID__c) ? Date.valueOf(article.CID__c.left(4) + '-' + article.CID__c.mid(4, 2) + '-' + article.CID__c.right(2)) : null;
            // access the update records via shared context since the update happens from community
            ElevatedSharingContext sharedContext = new ElevatedSharingContext();
            sharedContext.updateRecords(new List<Case>{caseToBeUpdated});
            //process the case transfer
            System.enqueueJob(new TransferCaseQueueable(caseToBeUpdated));
        } catch (Exception e) {
            UTIL_LoggingService.logHandledException(
                    e
                    , UserInfo.getOrganizationId()
                    , StarTrack_Constants.STARTRACK
                    , StarTrackTrackingIDSearchUtil.class.getName()
                    , 'AssignAndUpdateCaseQueueable'
                    , StarTrack_Constants.ASYNC_QUEUEABLE
                    , LoggingLevel.ERROR
            );
        }
    }

    @TestVisible
    private without sharing class TransferCaseQueueable implements Queueable{
        Case cse;
        Set<Id> caseRecordTypes = new Set<Id>{
                SObjectType.Case.getRecordTypeInfosByDeveloperName().get(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT).getRecordTypeId()
        };

        public  TransferCaseQueueable(Case record) {
            Map<SObjectType, Set<SObjectField>> overrideFields = new Map<SObjectType, Set<SObjectField>>();
            Set<SObjectField> caseFields = new Set<SObjectField>{
                    Case.Id,
                    Case.Call_Purpose__c,
                    Case.RecordTypeId,
                    Case.Enquiry_Type__c,
                    Case.Business_Solutions_Customer__c,
                    Case.Initial_Caller_Type__c,
                    Case.Status,
                    Case.OwnerId,
                    Case.Article_Service_Type__c,
                    Case.ReferenceID__c,
                    Case.Origin,
                    Case.ArticleTest__c,
					Case.CHASEnquiryType__c,
					Case.Recent_Caller_Type__c	
            };
            Set<SObjectField> articleFields = new Set<SObjectField>{
                    Article__c.Product_Group__c
            };
            Set<SObjectField> recordTypeFields = new Set<SObjectField>{
                    RecordType.Name
            };
            Set<SObjectField> networkFields = new Set<SObjectField>{
                    Network__c.OwnerId, Network__c.Name
            };
            Set<SObjectField> billingAccountFields = new Set<SObjectField>{
                    Billing_Account__c.BSC_Calc_Transfer_Queue__c
            };
            Set<SObjectField> accountFields = new Set<SObjectField>{
                    Account.StarTrack_Customer_Stream__c
            };
            overrideFields.put(Case.SObjectType, caseFields);
            overrideFields.put(Article__c.SObjectType, articleFields);
            overrideFields.put(Network__c.SObjectType, networkFields);
            overrideFields.put(Billing_Account__c.SObjectType, billingAccountFields);
            overrideFields.put(Account.SObjectType, accountFields);

            this.cse = CasesSelector.newInstance(0, overrideFields).selectById(
                    new Set<Id>{Id.valueOf(record.Id)},
                    new Set<Object>{CasesSelector.Options.WITH_ARTICLE, CasesSelector.Options.WITH_RECORDTYPE, CasesSelector.Options.WITH_NETWORK, CasesSelector.Options.WITH_BILLINGACCOUNT, CasesSelector.Options.WITH_ACCOUNT}
            ).values()[0];

        }

        public void execute(QueueableContext context) {
            try {
                if(this.cse.ArticleTest__c != null // if article record is linked
                        && this.cse.ReferenceID__c != null // and there's a reference ID
                        && StarTrack_Constants.CASE_ORIGIN_WEB.equalsIgnoreCase(this.cse.Origin) // origin is web only
                        && caseRecordTypes.contains(this.cse.RecordTypeId)  // only startrack delivery enquiry record type
						&& STHSConstants.TRACKING_ENQUIRY_TRACK_TRACE.equalsIgnoreCase(this.cse.CHASEnquiryType__c) // Enquriy type should be only Tracking Enquiry|Track & Trace
						&& STHSConstants.CASE_CONTYPE_SENDER.equalsIgnoreCase(this.cse.Recent_Caller_Type__c) // only Caller Type sender 					
					) {
                    //get transfer owner Id
                    Id transferOwnerId = transferCase(this.cse);
                    if (transferOwnerId !=null && this.cse.OwnerId != transferOwnerId){
                        Case caseToBeUpdated = new Case();
                        caseToBeUpdated.Id = cse.Id;
                        caseToBeUpdated.OwnerId = transferOwnerId;
                        ElevatedSharingContext sharedContext = new ElevatedSharingContext();
                        sharedContext.updateRecords(new List<Case>{caseToBeUpdated});
                    }
                }

            } catch (Exception ex) {
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(
                        ex
                        , UserInfo.getOrganizationId()
                        , StarTrack_Constants.STARTRACK
                        , TransferCaseQueueable.class.getName()
                        , 'TransferCaseQueueable'
                        , StarTrack_Constants.ASYNC_QUEUEABLE
                        , LoggingLevel.ERROR);
            }
        }

    }

    /**
     * We can add more validations here if required
     * @param article
     *
     * @return
     */
    public Boolean validate(List<Article__c> articles, Id caseId, StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap) {
        Boolean isValid = true;
        String comments = '';
        Boolean isDuplicate = isDuplicateConsignments(articles);
        Boolean isValidReference = isValidReference(articles);
        Boolean isError = isError(conWrap);

        // no consignment found
        if(isError) {
            // service returned error
            comments = '\n' + System.Label.STHSIDSearchCommentsTimeoutTechError;
            isValid = false;
        } else if((articles == null || articles.size() == 0) || StarTrack_Constants.ERR_CODE_ART_NOT_FOUND.equalsIgnoreCase(conWrap.errorCode)) {
            comments = '\n' + System.Label.STHSIDSearchCommentsNoConsignment;
            isValid = false;
        } else if(!isValidReference) {
            // no articles returned
            return false;
        } else if(isDuplicate) {
            // duplicate consignments found
            comments = '\n' + System.Label.STHSIDSearchCommentsDuplicateConsignment;
            isValid = false;
        }

        if(!isValid) {
            createCaseComment(comments, caseId);
        }

        return isValid;
    }

    /**
     * utility method to create case comments
     * @param comments
     * @param caseId
     */
    private static void createCaseComment(String comments, Id caseId) {
        ElevatedSharingContext context = new ElevatedSharingContext();
        CaseComment comment = new CaseComment();
        comment.CommentBody = comments;
        comment.IsPublished = true;
        comment.ParentId = caseId;
        //insert case comments
        context.insertRecords(new List<SObject>{
                comment
        });
    }

    public static Boolean isValidReference(List<Article__c> articles) {
        if(articles == null || articles.size() <= 0) {
            return true;
        }

        return false;
    }

    public static Boolean isDuplicateConsignments(List<Article__c> articles) {
        if(articles != null && articles.size() > 1) {
            return true;
        }

        return false;
    }

    public static Boolean isError(StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrap) {
        if(conWrap == null || (conWrap.errorCode != '0' && !'Article Not Found'.equalsIgnoreCase(conWrap.errorCode))) {
            return true;
        }

        return false;
    }

    private without sharing class ElevatedSharingContext {

        /**
		 * Insert a list of sObject records in system mode
		 * @param List<sObject>
		*/
        private void updateRecords(List<sObject> recordList) {
            ApplicationDatabase.getInstance().dmlUpdate(recordList);
        }

        private void insertRecords(List<sObject> recordList) {
            ApplicationDatabase.getInstance().dmlInsert(recordList);
        }
    }

    /**
   * @description : This method is used to transfer the Startrack Cases created from the form and assign to valid queue
   * as per StarTrack_Transfer_Case_Rule__c.
   * @param Case whose Owner needs to be transferred.
   */
    public static Id transferCase(Case c){
        StartTrackTransferCaseRulesSelector selector = StartTrackTransferCaseRulesSelector.newInstance();
        Boolean ruleSatisfied = false;
        String queueName = null;
        Id ownerId = c.OwnerId;

        List<StarTrack_Transfer_Case_Rule__c> tc_rules = selector.selectAll(new Set<Object>{
                StartTrackTransferCaseRulesSelector.Options.ORDER_BY_ORDERFIELD,ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER});
        try{
            for(StarTrack_Transfer_Case_Rule__c tc_rule : tc_rules){
                if((String.isNotBlank(tc_rule.Case_Purpose__c) ? c.Call_Purpose__c == tc_rule.Case_Purpose__c : true) && (String.isNotBlank(tc_rule.Case_RecordType__c) ? c.RecordType.Name == tc_rule.Case_RecordType__c : true) &&
                        (String.isNotBlank(tc_rule.Case_Type__c) ? c.Enquiry_Type__c == tc_rule.Case_Type__c : true) && (String.isNotBlank(tc_rule.Customer_Stream__c) ? c.Account.StarTrack_Customer_Stream__c == tc_rule.Customer_Stream__c : true) &&
                        (String.isNotBlank(tc_rule.Initial_Caller_Type__c) ? c.Initial_Caller_Type__c == tc_rule.Initial_Caller_Type__c : true) && (String.isNotBlank(tc_rule.Product_Group__c) ? c.ArticleTest__r.Product_Group__c == tc_rule.Product_Group__c : true) &&
                        (tc_rule.Business_Solutions_Customer__c ? c.Business_Solutions_Customer__c == tc_rule.Business_Solutions_Customer__c : true) && tc_rule.Service_Cloud_Rule__c){
                    if(tc_rule.Queue_Name__c == StarTrack_Constants.TRANSFER_QUEUE) {
                        if (!String.isBlank(c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c)) {
                            queueName = c.Related_Billing_Account__r.BSC_Calc_Transfer_Queue__c;
                        }
                        ruleSatisfied = true;
                        break;
                    } else if(tc_rule.Queue_Name__c == StarTrack_Constants.ST_NETWORK_CUST_NOTIF && !StarTrack_Constants.CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK) {
                        ruleSatisfied = false;
                        continue;
                    } else{
                        // c.OwnerId = queryQueue(tc_rule.Queue_Name__c);
                        queueName = tc_rule.Queue_Name__c;
                        ruleSatisfied = true;
                        break;
                    }
                }
            }

            if(!ruleSatisfied && String.isNotBlank(c.Network__r.OwnerId)){
                ownerId = c.Network__r.OwnerId;
            }

            if(queueName != null) {
                GroupsSelector groupsSelector = GroupsSelector.newInstance();
                Map<Id,Group> queue = groupsSelector.selectByGroupTypeAndName(new Set<String>{'Queue'},new Set<String>{queueName});

                if(queue != null && !queue.isEmpty()){
                    // c.OwnerId = queue.keySet().iterator().next();
                    ownerId = queue.keySet().iterator().next();
                } else{
                    // c.OwnerId = null;
                    ownerId = null;
                    throw new ErrorException(StarTrack_Error_Messages__c.getValues('Queue not found') != null ?
                            StarTrack_Error_Messages__c.getValues('Queue not found').Value__c :
                            'Queue not found. Please make sure to reference the correct queue name.');
                }

            }
        }catch (Exception e) {
            System.debug('Error in transferring the Case'+e.getCause());
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchUtil.class.getName(), 'transferCase', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
            ruleSatisfied = false;
        }
        return ownerId;
    }

    /**
    * Custom Exception
    * */
    class ErrorException extends Exception{}

}