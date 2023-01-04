/**************************************************
Description:  Utility class for the startrack ID search module, this will hold all the validation and the detail logics for functionality
History:
--------------------------------------------------
2022-11-24 - H Liyanage - Created
2022-12-05 - Prerna Rahangdale Added a new TransferCaseQueuable and added Transfer Case feature.
**************************************************/
public with sharing class StarTrackTrackingIDSearchUtil {

    public static void getTrackingDetails(List<SObject> records) {
        List<Case> selectedCases = new List<Case>();
        for(Case cse:(List<Case>)records) {
            System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate  cse '+cse);
            // if the reference has been changed
            if(cse.ReferenceID__c != null) {
                selectedCases.add(cse);
            }
        }

        System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate selectedCases '+selectedCases.size());

        if(!selectedCases.isEmpty()) {
            System.enqueueJob(new TrackingSearchQueueable(selectedCases[0]));
        }
    }


    private without sharing class TrackingSearchQueueable implements Queueable, Database.AllowsCallouts {
        Case cse;
        //TODO : Hasantha move strings to constants or custom metadata
        Set<Id> caseRecordTypes = new Set<Id>{
                SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId()
                , SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_General_Enquiry').getRecordTypeId()
                , SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_Voice_of_Customer').getRecordTypeId()};

        public TrackingSearchQueueable(Case record) {
            this.cse = record;
        }

        public void execute(QueueableContext context) {
            try {
                System.debug('HASANTHA TEST MODULE 1 IN queable');
                if(this.cse.ArticleTest__c == null && this.cse.ReferenceID__c != null && caseRecordTypes.contains(this.cse.RecordTypeId)) {
                    System.debug('HASANTHA TEST MODULE 2 :this.cse '+this.cse.Id);
                    System.debug('HASANTHA TEST MODULE 3 :this.cse.ReferenceID__c'+ this.cse.ReferenceID__c);
                    StarTrackTrackingIDSearchService cont = StarTrackTrackingIDSearchService.newInstance();
                    cont.dateRange = '1';
                    cont.searchString = this.cse.ReferenceID__c;
                    cont.isConsole = false;
                    cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
                    cont.searchConsignment();
                    System.debug('HASANTHA TEST MODULE 3 :cont.lst_article[0]'+ cont.lst_article[0]);
                    if(validate(cont.lst_article[0])) {
                        System.debug('HASANTHA TEST MODULE 3 VALIDATED GOOD ');
                        assignAndUpdateCase(cont.lst_article[0],this.cse);
                    }
                }
            } catch (Exception ex) {
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(
                        ex
                        , UserInfo.getOrganizationId()
                        , StarTrack_Constants.STARTRACK
                        , TrackingSearchQueueable.class.getName()
                        , 'TrackingSearchQueueable'
                        , StarTrack_Constants.ASYNC_QUEUEABLE
                        , LoggingLevel.ERROR);
            }
        }
    }

    /**
         * validate and assign the found article details
         * @param article
         * @param cse
         */
    public static void assignAndUpdateCase(Article__c article, Case cse) {
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
            System.debug('HASANTHA TEST MODULE 4  IN queable cse ' + caseToBeUpdated);

            ElevatedSharingContext sharedContext = new ElevatedSharingContext();
            sharedContext.updateRecords(new List<Case>{caseToBeUpdated});
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

    private without sharing class TransferCaseQueueable implements Queueable{
        Case cse;
        Set<Id> caseRecordTypes = new Set<Id>{
                SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId()
        };

        public  TransferCaseQueueable(Case record) {
            this.cse = record;
        }

        public void execute(QueueableContext context) {
            try {
                if(this.cse.ArticleTest__c != null && this.cse.ReferenceID__c != null && caseRecordTypes.contains(this.cse.RecordTypeId) && 'Web'.equalsIgnoreCase(this.cse.Origin)) {
                    Case caseToBeUpdated = new Case();
                    caseToBeUpdated.Id = cse.Id;
                    caseToBeUpdated.OwnerId = transferCase(this.cse);
                    ElevatedSharingContext sharedContext = new ElevatedSharingContext();
                    sharedContext.updateRecords(new List<Case>{caseToBeUpdated});
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
    public static Boolean validate(Article__c article) {
        // TODO multiple consignments check
        return validateAddressFields(article);
    }

    /**
     * Validating nominated address fields to check wheter a value is exists in one of those defined fields in the article record,
     * if a value exists return true as a valid address
     * @param article
     *
     * @return
     */
    public static Boolean validateAddressFields(Article__c article) {
        for(String field: StarTrack_Constants.ARTICLE_ADDRESS_FIELDS) {
            if(article.get(field) != null || String.isNotBlank(String.valueOf(article.get(field)))) {
                return true;
            }
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
                            ruleSatisfied = true;
                            break;
                        }
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
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'transferCase', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
            ruleSatisfied = false;
        }
        System.debug('The Owner Id of the case is '+ownerId);
        return ownerId;
    }

    /**
    * Custom Exception
    * */
    class ErrorException extends Exception{}

}