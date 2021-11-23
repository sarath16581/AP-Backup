/**************************************************
Description:    Controller class for myNetworkRedirectCasePDFGenerator.vfp (redirect page)
This allows a list of case ids for multi print functionality
History:
--------------------------------------------------
12/05/2020 - Hara Sahoo Created
06/08/2020 - Disha Kariya Added a method to get delivered addresses from AME api
18/08/2020 - Disha Kariya Changes to consider attempted delivery scan if present
21/08/2020 - Disha Kariya Updated to allow mocking in test class
25/08/2020 - Disha Kariya Changes to update flag in enqueue job
27/08/2020 - Neha Mehta Updated getCaseFields() - Added ArticleTest__r.Name
28/08/2020 - Disha Kariya Changes to display 3 static map when Attempted Delivery location available
01/09/2020 - Disha Kariya Consolidated Article and Consignment map methods
15/03/2021 - Naveen Rajanna -REQ2408232 Add getter method to return caseList count to add blank page if multiple cases
22/06/2021 - Ranjeewa Silva - Added support to include event message attachments in the PDF.
01/10/2021 - Seth Heang - Uplift SF API Version to 52
**************************************************/
public with sharing class CasePDFContentGenerator {
    
    //Loop variable
    public String caseIds {get;set;}
    public List<Case> caseList {get; set;}
    public Map<Id,sObject> caseContactMap{get;set;}
    public String generatedTime{get;set;}
    public List<String> lstCaseIds;
    public Set<Id> setCaseIds;
    public Set<Id> caseArticleIds = new Set<Id>();
    public List<String> lstCaseReferenceIds;
    public Map<String, String> addresseeAddress;
    
    //Integration variables
    public transient TIBCOArticleWrapper articleDetails {get; set;}
    //public transient TIBCOEventMessageWrapper articleDetailsMessages {get; set;}
    public transient Map<String,TIBCOArticleWrapper> articleDetailsMap {get; set;}
    public transient List<TIBCOArticleWrapper> articleWrapperList {get; set;} 
    public transient List<TIBCOEventMessageWrapper> articleWrapperMessages {get; set;} 
    public transient TIBCOConsignmentWrapper consignmentDetails {get; set;}
    public transient List<TIBCOConsignmentWrapper> consignmentWrapperList {get; set;} 
    public transient Map<String,TIBCOConsignmentWrapper> consignmentDetailsMap {get; set;}
    public transient TIBCOSearchResult searchResult {get; private set;}
    
    //Other page variables
    public CasePDFContentGenerator printInstance {get{return this;}set;}
    public transient List<String> casetoEventDelivered{get;set;}
    public transient Map<String,EventMessage__c> casetoEventGeoMap {get;set;}
    public transient Map<String,EventMessage__c> casetoEventMessageMap {get;set;}
    public transient Map<String,EventMessage__c> casetoDriverContractMap {get;set;}
    public transient Map<String,EventMessage__c> casetoDriverLogonMap {get;set;}
    public transient Map<String,EventMessage__c> casetoDriverRoundMap {get;set;}
    public transient Map<String,EventMessage__c> casetoAttemptedDelivery {get;set;}
    public transient Map<String,EventMessage__c> casetoDeliveredDelivery {get;set;}
    public transient Map<Id,EventMessage__c> eventToArticleMap {get;set;}
    public transient List<Id> caseswithsafedropGUID{get;set;}
    public transient Set<String> caseswithMessages{get;set;}
    public transient Map<String,String> caseToDeliveredAddressMap {get; set;}
    public transient Map<String,Boolean> attemptedDeliveryFound {get;set;}
    public transient Map<String,Boolean> deliveredDeliveryFound {get;set;}
    public transient Map<String, ArticleEventMessageAttachments> caseArticleToEventMessageAttachmentsMap {get; set;}

    //getter method to return caseList count
    public Integer getCaseCount(){
        return caseList.size();
    }

    public CasePDFContentGenerator(){
        GeneratedTime = System.Now().format('d MMMM yy hh:mm a');
        caseIds = System.currentPageReference().getParameters().get('selectedIds'); 
        lstCaseIds = caseIds.split(',');
        setCaseIds = new Set<Id>(((Set<Id>) JSON.deserialize(JSON.serialize(lstCaseIds), Set<Id>.class)));
        lstCaseReferenceIds = new List<String>();
        addresseeAddress = new Map<String, String>();
        Set<Id> setContactIds = new Set<Id>();
        caseswithsafedropGUID = new List<Id>();
        caseswithMessages=new Set<String>();
        casetoEventDelivered = new List<String>();
        casetoEventMessageMap = new Map<String,EventMessage__c>();
        casetoEventGeoMap = new Map<String,EventMessage__c>();
        casetoDriverContractMap = new Map<String,EventMessage__c>();
        casetoDriverLogonMap = new Map<String,EventMessage__c>();
        casetoDriverRoundMap = new Map<String,EventMessage__c>();
        articleDetailsMap = new Map<String,TIBCOArticleWrapper>();
        consignmentDetailsMap = new Map<String,TIBCOConsignmentWrapper>();
        caseToDeliveredAddressMap = new Map<String, String>();
        attemptedDeliveryFound = new Map<String, Boolean>();
        deliveredDeliveryFound = new Map<String, Boolean>();
        casetoDeliveredDelivery = new Map<String, EventMessage__c>();
        casetoAttemptedDelivery = new Map<String, EventMessage__c>();
        eventToArticleMap = new Map<Id, EventMessage__c>();
        caseArticleToEventMessageAttachmentsMap = new Map<String, ArticleEventMessageAttachments>();

        //Extract the List and the Maps before further processing
        if(!lstCaseIds.isEmpty())
        {
//            caseList = getCase(lstCaseIds);
//            caseList = SSSWCasesSelector.newInstance(1).selectById(new Set<String>(lstCaseIds),new Set<Object>{CasesSelector.Options.WITH_CONTACT, CasesSelector.Options.WITH_NETWORK}).values();
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());    // get dynamic query row limit
            caseList = SSSWCasesSelector.newInstance(rowLimit, overrideFields).selectById(setCaseIds, new Set<Object>{CasesSelector.Options.WITH_NETWORK, SSSWCasesSelector.Options.WITH_NETWORK_RESPONSE, CasesSelector.Options.WITH_ARTICLE}).values();
            System.debug('caseList--->'+caseList);
        }
        if(!caseList.isEmpty())
        {
            for(Case cs : caseList)
            {
                //Generate contact list and article list
                setContactIds.add(cs.ContactId);
                if (cs.ArticleTest__c != null) {
                    caseArticleIds.add(cs.ArticleTest__c);
                }
                lstCaseReferenceIds.add(cs.ReferenceID__c);
                //Added below for Addressee address to get geo location
                if(cs.ArticleTest__c!=null && String.isNotBlank(cs.Address2__c)) {
                    addresseeAddress.put(cs.ArticleTest__c, cs.Address2__c);
                }
            }
            //Moved below out of for loop Disha
            //Get the list of event messages related to the cases
            casetoEventMessageMap = getcasetoEventMessageMap();
            caseArticleToEventMessageAttachmentsMap = getCaseArticleToEventMessageAttachmentsMap();
        }
        //Get contact map
        if(!setContactIds.isEmpty())
        {
            caseContactMap = getContactsMap(setContactIds);
        }
        //Get consignment map
//        consignmentDetailsMap = getConsignmentMap(caseList);
        //Get  article and consignmentMapmap
        getArticleConsignmentMap(caseList);
        //Get delivered addresses based on geo location from AME
        if(casetoEventGeoMap.size() > 0) {
            caseToDeliveredAddressMap = getcaseToDeliveredAddressMap();
            System.debug('caseToDeliveredAddressMap--->' + caseToDeliveredAddressMap);
        }
    }
    
    //Method to get the Article to Case mapping
    public void getArticleConsignmentMap(List<Case> caseList)
    {
        Map<String,TIBCOArticleWrapper> articleMap = new Map<String,TIBCOArticleWrapper>();
        Map<String,TIBCOConsignmentWrapper> consignmentMap = new Map<String,TIBCOConsignmentWrapper>();
        articleWrapperList = new List<TIBCOArticleWrapper>();
        consignmentWrapperList = new List<TIBCOConsignmentWrapper>();
        searchResult = TIBCOArticleService.searchArticlesInSFDC(lstCaseReferenceIds);
        if (searchResult.trackResults.size() > 0) {
            for (TIBCOTrackingResultWrapper results : searchResult.trackResults)
            {
                articleWrapperList.add(results.articleDetails);
                consignmentWrapperList.add(results.consignmentDetails);
                
            }
        }
        if(!articleWrapperList.isEmpty()) {
            for (TIBCOArticleWrapper wrap : articleWrapperList) {
                if (wrap != Null) {
                    articleMap.put(wrap.proxyArticle.ArticleID__c, wrap);
                }
            }
            articleDetailsMap = articleMap;
        }
        if(!consignmentWrapperList.isEmpty())
        {
            for(TIBCOConsignmentWrapper wrap:consignmentWrapperList)
            {
                if(wrap != Null)
                {
                    consignmentMap.put(wrap.proxyConsignment.ArticleID__c,wrap);
                }

            }
            consignmentDetailsMap = consignmentMap;
        }
    }
    //Consolidated Consignment Map method in Article Map method
    //Method to get the Consignment to Case mapping
//    public Map<String,TIBCOConsignmentWrapper> getConsignmentMap(List<Case> caseList)
//    {
//        Map<String,TIBCOConsignmentWrapper> conMap = new Map<String,TIBCOConsignmentWrapper>();
//        consignmentWrapperList = new List<TIBCOConsignmentWrapper>();
//        searchResult = TIBCOArticleService.searchArticlesInSFDC(lstCaseReferenceIds);
//        if (searchResult.trackResults.size() > 0) {
//            for (TIBCOTrackingResultWrapper results : searchResult.trackResults)
//            {
//                consignmentWrapperList.add(results.consignmentDetails);
//
//            }
//        }
//        if(!consignmentWrapperList.isEmpty())
//        {
//            for(TIBCOConsignmentWrapper wrap:consignmentWrapperList)
//            {
//                if(wrap != Null)
//                {
//                    conMap.put(wrap.proxyConsignment.ArticleID__c,wrap);
//                }
//
//            }
//        }
//
//        return conMap;
//    }
    
    //Method to get the event to case mapping.This map is used to get the 3 images on the print document.Safe drop, Google maps and Signature
    
    
    public Map<String,EventMessage__c> getcasetoEventMessageMap() {
        Map<String,EventMessage__c> casetoEvent = new Map<String,EventMessage__c>();
        Set<String> eventTypes = new Set<String>();
        Set<String> attemptedEventTypes = new Set<String>();
        String uniqueId = '';
        for(EventMessageTypeMapping__mdt evType: [Select MasterLabel, Category__c From EventMessageTypeMapping__mdt Where Category__c IN ('AttemptedDelivery','Delivered')]){
            eventTypes.add(evType.MasterLabel);
            //Create a set of string for attempted delivery scan
            if(evType.Category__c.equalsIgnoreCase('AttemptedDelivery')){
                attemptedEventTypes.add(evType.MasterLabel);
            }
        }
        //Event type check is necessary for all other event mappings on the UI like geo location, driver contract,driver roundNo, driver logon id and images
//        Map<Id,EventMessage__c> casetoEventMessageMap = new Map<Id,EventMessage__c>([Select Id,DriverContract__c,RoundNo__c,UserName__c,SignatoryName__c,Safe_Drop_GUID__c,Article__r.Name,Article__r.Case__r.Address2__c,Article__r.Case__c,Article__c,EventGeoLocation__Latitude__s,EventGeoLocation__Longitude__s, EventType__c,
//                                                                                     (SELECT Id, ParentId, Name FROM Attachments order by Createddate desc LIMIT 1)
//                                                                                     FROM EventMessage__c
//                                                                                     WHERE Article__c = :lstCaseArticleIds AND EventType__c IN: eventTypes order by ActualDateTime__c ]);
        Map<Id,EventMessage__c> casetoEventMessageMap = EventMessagesSelector.newInstance().selectByArticleId(caseArticleIds, eventTypes, new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE, EventMessagesSelector.Options.WITH_ATTACHMENT});
        for(EventMessage__c event : casetoEventMessageMap.values() )
        {

            uniqueId = event.Article__c ;
            //Set default value
            if(!deliveredDeliveryFound.containsKey(uniqueId) && !attemptedDeliveryFound.containsKey(uniqueId)) {
                deliveredDeliveryFound.put(uniqueId, false);
                attemptedDeliveryFound.put(uniqueId, false);
            }
            //Retrive the map for driver contract mapping
            if(event.DriverContract__c != Null )
            {
                casetoDriverContractMap.put(uniqueId,event);
            }
            //Retrive the login id for driver username mapping
            if(event.UserName__c != Null )
            {
                casetoDriverLogonMap.put(uniqueId,event);
            }//Retrive the round no for driver roundNo mapping
            if(event.RoundNo__c != Null )
            {
                casetoDriverRoundMap.put(uniqueId,event);
            }
            //Retrive the list for safedrops GUID
            if(event.Safe_Drop_GUID__c != Null)
            {
                caseswithsafedropGUID.add(event.Id);
            }
            //Retrive the map for delivered event geo mapping
            if(event.EventGeoLocation__Latitude__s != Null && event.EventGeoLocation__Longitude__s != Null)
            {
                //Attempted delivery takes precedence over delivered event. Check if attempted delivery event is already added in map
//                if(!(casetoEventGeoMap.containsKey(uniqueId) && attemptedDeliveryFound.containsKey(uniqueId) && attemptedDeliveryFound.get(uniqueId))) {
                    casetoEventGeoMap.put(uniqueId, event);
                    eventToArticleMap.put(event.Id, event);
                    //Map to check if attempted delivery event found
                    if(attemptedEventTypes.contains(event.EventType__c)){
                        attemptedDeliveryFound.put(uniqueId, true);
                        casetoAttemptedDelivery.put(uniqueId, event);
                    }else {
                        //set default attempted delivery to false
                        deliveredDeliveryFound.put(uniqueId, true);
                        casetoDeliveredDelivery.put(uniqueId, event);
                    }
//                }
            }
            caseswithMessages.add(event.Id);
            casetoEvent.put(uniqueId,event);

        }
        return (casetoEvent.isEmpty() ? null : casetoEvent);
    }

    //Method to update print flag on case as a queueable job
    public void updatePrintFlag(){
        List<Case> toUpdate = new List<Case>();
        for(Case cs : caseList){
            if(!cs.Checkbox__c){
                toUpdate.add(cs);
            }
        }
        if (toUpdate.size() > 0) {
            System.enqueueJob(new UpdateCasePrintFlagFuture(toUpdate));
        }
    }
    
    //Action method in the VF page to mark the if Printed(Checkbox__c) flag
    public class UpdateCasePrintFlagFuture implements System.Queueable {
        private List<Case> caseList;
        public UpdateCasePrintFlagFuture(List<Case> caseList) {
            this.caseList = caseList;
        }
        public void execute(QueueableContext qc) {
            try {
                List<Case> updateCase = new List<Case>();
//            String queryStr = 'SELECT Id,Checkbox__c FROM CASE WHERE Id=:lstCaseIds';
                System.debug('caseList--->' + caseList);
                for (Case cs : caseList) {
                    //Check if the flag is already set to true, no action needed
                    if (cs.Checkbox__c == false) {
                        cs.Checkbox__c = true;
                        updateCase.add(cs);
                    }
                }
                Database.update(updateCase);
            }catch (Exception exp){
                // Added exception to track any error
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW','CasePDFContentGenerator', 'UpdateCasePrintFlagFuture', null, LoggingLevel.ERROR);
            }
        }
    }
    
    
    //Method to get the contacts map
    public Map<Id,sObject> getContactsMap( Set<Id> contactIds) {
        Map<Id,sObject> contactMap = new Map<Id,sObject>();
//        String query = 'SELECT Id,FirstName,LastName';
//        query += ' FROM Contact WHERE Id = :contacts';
//        List<sObject> conList = Database.query(query);
        List<sObject> conList = ContactsSelector.newInstance().selectById(contactIds).values();
        for(SObject con: conList)
        {
            contactMap.put(con.Id,con);
        }
        return contactMap;
    }
    
    //Method to get the case details
//    public List<Case> getCase( List<String> caseNos) {
//        String query = 'SELECT ';
//        for(String disfield : getCaseFields()) {
//            query += disfield + ', ';
//        }
//        query += 'Id,ContactDoNotDisclose__c, (SELECT  to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC) FROM Case WHERE Id = :caseNos';
//        return Database.query(query);
//    }
//    //Method to get the case fields, used in getCase()
//    public static Set<String> getCaseFields() {
//        Set<String> distinctFields = new Set<String>();
//
//        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkInvestigation.getFields())
//        {
//            distinctFields.add(fm.getFieldPath());
//        }
//
//        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkFeedback.getFields())
//        {
//            distinctFields.add(fm.getFieldPath());
//        }
//
//        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkGeneralEnquiry.getFields())
//        {
//            distinctFields.add(fm.getFieldPath());
//        }
//
//        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.PON_Investigation.getFields())
//        {
//            distinctFields.add(fm.getFieldPath());
//        }
//
//
//        distinctFields.add('CaseNumber');
//        distinctFields.add('Type');
//        distinctFields.add('ArticleTest__c');
//        distinctFields.add('ArticleTest__r.Recordtype.Name');
//        distinctFields.add('ArticleTest__r.Name');
//        distinctFields.add('Address2DPID__c');
//        distinctFields.add('ContactId');
//        distinctFields.add('Network__r.Contact_Facility__c');
//        distinctFields.add('Network__r.Name');
//        distinctFields.add('Network__r.Fax_Number__c');
//        distinctFields.add('NetworkComments__c');
//        distinctFields.add('EmailThreadID__c');
//        distinctFields.add('OwnerId');
//        distinctFields.add('Customer_Type__c');
//        distinctFields.add('Description');
//        distinctFields.add('ReferenceID__c');
//        distinctFields.add('CreatedDate');
//        distinctFields.add('SLATargetDate__c');
//        distinctFields.add('Type');
//        distinctFields.add('Instructions__c');
//
//        return distinctFields;
//    }

    //Method to get the case fields, used in getCase()
    public static Map<SObjectType, Set<SObjectField>> overrideFields {
        get {
            if(overrideFields == null) {
                overrideFields = new Map<SObjectType, Set<SObjectField>>();
                Set<SObjectField> caseFields = new Set<SObjectField>{
                        Case.Id, Case.ContactId, Case.CaseNumber, Case.OwnerId, Case.CreatedDate,
                        Case.RecordTypeId, Case.Description, Case.ReferenceID__c, Case.Type, Case.Customer_Type__c, Case.ProductCategory__c, Case.ProductSubCategory__c,
                        Case.EnquirySubType__c, Case.Address2DPID__c, Case.Instructions__c, Case.Primary_Company__c, Case.Primary_Name__c,
                        Case.Address1__c, Case.Secondary_Companry__c, Case.Network__c, Case.ArticleTest__c, Case.EmailThreadID__c,
                        Case.Secondary_Contact__c, Case.Address2__c, Case.IssuePreviouslyReported__c, Case.DatePosted__c, Case.PONUser__c,
                        Case.NetworkTierSLA__c, Case.ContactDoNotDisclose__c, Case.NetworkComments__c, Case.SLATargetDate__c, Case.Checkbox__c
                };
                Set<SObjectField> networkFields = new Set<SObjectField>{
                        Network__c.Contact_Facility__c, Network__c.Name, Network__c.Fax_Number__c
                };
                Set<SObjectField> networkResponseFields = new Set<SObjectField>{
                        Network_Response__c.to_Reassign_Network__c
                };
                Set<SObjectField> articleFields = new Set<SObjectField>{
                        Article__c.Id, Article__c.Name
                };
                overrideFields.put(Case.SObjectType, caseFields);
                overrideFields.put(Network__c.SObjectType, networkFields);
                overrideFields.put(Network_Response__c.SObjectType, networkResponseFields);
                overrideFields.put(Article__c.SObjectType, articleFields);
            }
            return overrideFields;
        }
        private set;
    }

    /**
	 * Method to get delivered address using AME
	 */
    public Map<String, String> getcaseToDeliveredAddressMap(){
        Map<String, String> articleGeoStrings = new Map<String, String>();
        for(Id event : eventToArticleMap.keySet()){
            //articleId to be used as unique identifier in AME request -- GTA is for Geolocation To Address
            articleGeoStrings.put(event+'-GTA' , eventToArticleMap.get(event).EventGeoLocation__Latitude__s+','+eventToArticleMap.get(event).EventGeoLocation__Longitude__s);
        }
        for(String article : addresseeAddress.keySet()){
            //Check if the article has a delivered address from casetoEventGeoMap -- ATG is for Address To Geolocation
            if(casetoEventGeoMap.containsKey(article)){
                articleGeoStrings.put(article+'-ATG' , addresseeAddress.get(article));
            }
        }
        System.debug('articleGeoStrings--->'+articleGeoStrings);
        Map<String,String> results = AMEAddressValidationController1.searchAddressOrGeoLocation(articleGeoStrings);
        //If no geocoords returned for atg then manually add the addressee address
        for(String key : results.keySet()){
            if(key.containsIgnoreCase('-atg') && String.isBlank(results.get(key))){
                results.put(key, articleGeoStrings.get(key));
            }
        }
        //Get delivered address from AME, use article Id as unique identifier
        return results;
    }

    /**
     * Get the event message attachments related to selected cases.
     *
     * @return Map of event message attachments, Key = Article__c (Salesforce Id of Article)
     */
    @TestVisible private Map<String, ArticleEventMessageAttachments> getCaseArticleToEventMessageAttachmentsMap() {
        Map<String, ArticleEventMessageAttachments> eventMessageAttachments = new Map<String, ArticleEventMessageAttachments>();

        // retrieve event messages where AttachmentGUID__c is not blank. also include child Attachment records related to event messages.
        Map<Id,EventMessage__c> eventMessagesMap = EventMessagesSelector.newInstance().selectByArticleId(caseArticleIds, new Set<Object>{EventMessagesSelector.Options.FILTER_ATTACHMENT_GUID, EventMessagesSelector.Options.WITH_ATTACHMENT});

        // grab the list of attachment types to be included in generated PDF based on configuration.
        Map<String, EventMessageAttachmentTypeMapping__mdt> attachmentTypeDefinitions = getAttachmentTypesForCasePDF();

        for (EventMessage__c event: eventMessagesMap.values()) {

            // check if attachment type is to be included in PDF. exclude safe drop attachments as they are included separately.
            if (String.isEmpty(event.Safe_Drop_GUID__c)
                    && String.isNotEmpty(event.AttachmentGUID__c)
                    && attachmentTypeDefinitions.containsKey(event.AttachmentType__c)) {


                ArticleEventMessageAttachments attachments = eventMessageAttachments.get(event.Article__c);

                for (Attachment attachment: event.Attachments) {

                    if (String.isNotBlank(attachment.Name) && attachment.Name.contains(EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX)) {

                        if (attachments == null) {
                            attachments = new ArticleEventMessageAttachments();
                            eventMessageAttachments.put(event.Article__c, attachments);
                        }

                        attachments.addAttachment(new EventMessageAttachment(attachment.Id, attachmentTypeDefinitions.get(event.AttachmentType__c).Label, attachment.name, event.EventType__c, event.EventDescription__c));
                    }
                }
            }
        }

        return eventMessageAttachments;
    }

    /**
     * Retrieve the attachment types configured to be included in Case PDF
     *
     * @return Map of EventMessageAttachmentTypeMapping indexed by attachment type.
     */
    private Map<String, EventMessageAttachmentTypeMapping__mdt> getAttachmentTypesForCasePDF() {
        Map<String, EventMessageAttachmentTypeMapping__mdt> output = new Map<String, EventMessageAttachmentTypeMapping__mdt>();
        for(EventMessageAttachmentTypeMapping__mdt mapping : EventMessageUtil.getEventMessageAttachmentTypes().values()) {
            if(mapping.IsIncludedOnCasePrintOut__c) {
                output.put(mapping.DeveloperName, mapping);
            }
        }
        return output;
    }

    /**
     * Wrapper containing all event message attachments related to an Article.
     * This allow the Visualforce components to render conditionally based on number of attachments. i.e. if single attachment
     * render center aligned, else render 2 images in each row.
     */
    public class ArticleEventMessageAttachments {
        public List<EventMessageAttachment> attachments {get; set;}

        public void addAttachment(EventMessageAttachment attachment) {
            this.attachments.add(attachment);
        }

        public ArticleEventMessageAttachments() {
            this.attachments = new List<EventMessageAttachment>();
        }
    }

    /**
     * Event Message attachment with attributes for display
     */
    public class EventMessageAttachment {
        public Id attachmentId {get;set;}
        public String attachmentType {get;set;}
        public String name {get;set;}
        public String label {get;set;}
        public EventMessageAttachment(Id attachmentId, String attachmentType, String name, String eventType, String eventDescription) {
            this.attachmentId = attachmentId;
            this.attachmentType = attachmentType;
            this.name = name;
            if (String.isNotBlank(eventType)) {
                this.label = eventType + (String.isNotBlank(eventDescription) ? (' - ' + eventDescription) : '');
            } else {
                this.label = attachmentType;
            }
        }
    }

}