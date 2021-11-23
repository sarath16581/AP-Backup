/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 15/09/2015
  * @description  : This Class is controller class for RetailFaxTemplate component to send accross the new fax template
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
    
*******************************  History ************************************************/
public with sharing class RetailFaxTemplateCompCont {

    //transient variables
    public transient Case myCase { get; private set; }
    public transient Contact myContact { get; private set; }

    public transient TIBCOArticleWrapper articleDetails {get; set;}
    public transient TIBCOConsignmentWrapper consignmentDetails {get; set;}
    public transient TIBCOSearchResult searchResult {get; private set;}
    //added by for retail fax template headers
    public String tempTitle { set;}
    public String networkName {get;set;}
    private Static final STring itemTranString = 'Item Transfer';
    private Static final STring itemTranTitle = 'Article Transfer Request';
    private Static final STring missItemString = 'Missing Item';
    private Static final STring missItemTitle = 'Missing Item Investigation';
    private Static final STring RTSReqString = 'RTS Request';
    private Static final STring RTSReqTitle = 'Return to Sender request';
    private Static final STring disputedDelString = 'Disputed Delivery';
    private Static final STring disputedDelTitle = 'Disputed Delivery Investigation';
    private Static final STring remRecString = 'Remmitance not recieved';
    private Static final STring delComplString = 'Delivery Complaint';
    
    private static final string CLASS_NAME = 'RetailFaxTemplateCompCont';
    private static final string METHOD_NAME1 = 'getCase';
    private static final string METHOD_NAME2 = 'getContact';
    
    public RetailFaxTemplateCompCont () {}

    /**
      * @description       constructor for class to set the record
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
   public RetailFaxTemplateCompCont(ApexPages.StandardController controller) {
        caseId = controller.getId();
    }

    /**
      * @description       getter method to set the template title based on sub enquiry type
      * @param             NA 
      * @return            String
      * @throws            NA
      */
    public String getTempTitle () {
        String tempTitle = '';
        //retrive the case based on current record
        Case cse = getCase();
        //check the enquiry type and set the header value for fax
        if(itemTranString.equalsIgnoreCase(cse.EnquirySubType__c)){
            tempTitle =  itemTranTitle;         
        }
        else if(String.isBlank(tempTitle) && missItemString.equalsIgnoreCase(cse.EnquirySubType__c) ) {
             tempTitle =  missItemTitle; 
        }
        else if(String.isBlank(tempTitle) && RTSReqString.equalsIgnoreCase(cse.EnquirySubType__c)) {
             tempTitle =  RTSReqTitle; 
        }
        else if(String.isBlank(tempTitle) && disputedDelString.equalsIgnoreCase(cse.EnquirySubType__c)) {
             tempTitle = disputedDelTitle  ; 
        }
        else if(String.isBlank(tempTitle) && remRecString.equalsIgnoreCase(cse.EnquirySubType__c)) {
             tempTitle = remRecString ; 
        }
        else if(String.isBlank(tempTitle) && delComplString.equalsIgnoreCase(cse.EnquirySubType__c)) {
             tempTitle =  delComplString; 
        }
        else if(String.isBlank(tempTitle)){
            tempTitle =  cse.EnquirySubType__c ;         
        }
        return tempTitle ;
    }

    /**
      * @description       getter and setter for getting case record idgetter method to set the template title based on sub enquiry type
      * @param             NA 
      * @return            Id
      * @throws            NA
      */
    public Id caseId {
        get;
        set {
            caseId = value;
            
            myCase = getCase();
            myContact = getContact(myCase.ContactId);
            
            if(!String.isBlank(myCase.ReferenceID__c)) {
                searchResult = TIBCOArticleService.searchArticlesInSFDC(new String[] {myCase.ReferenceID__c});
                if (searchResult.trackResults.size() > 0) { 
                    articleDetails = searchResult.trackResults[0].articleDetails;
                    
                }
            }

        }
    }
    
    /**
      * @description       getter to put the current time stamp on the fax
      * @param             NA 
      * @return            String
      * @throws            NA
      */
    public String timaestamp {
        get {
            return System.now().format('dd/MM/yyyy h:00 a');
        }
    }
    
    /**
      * @description       getter method to get the case record
      * @param             NA 
      * @return            Case
      * @throws            NA
      */
    private Case getCase() {
        try {
            String query = 'SELECT ';
            for(String disfield : this.getCaseFields()) {
                query += disfield + ', ';
            }
            query += 'Id, account.serviceSLA__c FROM Case WHERE Id = :caseId LIMIT 1';
                return Database.query(query);
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CLASS_NAME, METHOD_NAME1, 
                                                    null, LoggingLevel.ERROR);
        }
        return null;
    }
    
    /**
      * @description       getter method to get the contact record
      * @param             Id 
      * @return            Contact
      * @throws            NA
      */
    private Contact getContact(Id contactId) {
        List<Contact> obj = new List<Contact>();
        try {
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : this.getItemSearchContactFields()) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id, DoNotDisclose__c FROM Contact WHERE Id = :contactId LIMIT 1';
            
            obj = Database.query(query); 
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CLASS_NAME, METHOD_NAME2, 
                                                    null, LoggingLevel.ERROR);
        }
        return obj.size() > 0 ? obj[0] : null;
    }
    
    /**
      * @description       getter to get the set of fields from case
      * @param             NA 
      * @return            Set<String>
      * @throws            NA
      */
    public Set<String> getCaseFields() {
        Set<String> distinctFields = new Set<String>();
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkInvestigation.getFields()) {
            distinctFields.add(fm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkFeedback.getFields()) {
            distinctFields.add(fm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkGeneralEnquiry.getFields()) {
            distinctFields.add(fm.getFieldPath());
        }
        
        //Snigdha Start Change
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.PON_Investigation.getFields()) {
            distinctFields.add(fm.getFieldPath());
        }       
        
        //Snigdha End Change     
        
        distinctFields.add('CaseNumber');
        distinctFields.add('Type');
        distinctFields.add('ArticleTest__c');
        distinctFields.add('ContactId');
        distinctFields.add('Network__r.Contact_Facility__c');
        distinctFields.add('Network__r.Name');
        distinctFields.add('Network__r.Fax_Number__c');
        distinctFields.add('NetworkComments__c');
        distinctFields.add('EmailThreadID__c');
        distinctFields.add('OwnerId');      
        distinctFields.add('Customer_Type__c');
        distinctFields.add('Description');
        distinctFields.add('ReferenceID__c');
        //Snigdha Start Change
        distinctFields.add('CreatedDate');
        distinctFields.add('SLATargetDate__c');
        distinctFields.add('Type');
        distinctFields.add('Instructions__c');
        //Snigdha End Change
        
        return distinctFields;
    }
    
    /**
      * @description       getter to get the contact fields from fieldset
      * @param             NA 
      * @return            List<Schema.FieldSetMember>
      * @throws            NA
      */
    public List<Schema.FieldSetMember> getItemSearchContactFields() {
        return SObjectType.Contact.FieldSets.ContactItemSearch.getFields();
    }

    /**
      * @description       getter to get the article fields from fieldset
      * @param             NA 
      * @return            List<Schema.FieldSetMember>
      * @throws            NA
      */
    public List<Schema.FieldSetMember> getItemSearchArticleFields() {
        return SObjectType.Article__c.FieldSets.RetailFaxDisplayArticleData.getFields();
    }
    
    /**
      * @description       getter to get the event fields from fieldset
      * @param             NA 
      * @return            List<Schema.FieldSetMember>
      * @throws            NA
      */
    public List<Schema.FieldSetMember> getItemSearchEventMessagesFields() {
        return SObjectType.EventMessage__c.FieldSets.EventMessageItemSearch.getFields();
    }
    
}