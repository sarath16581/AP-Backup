/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 12/09/2016
  * @description  : Controller class for page exposed to SSSW Admin to retreieve cases based on condition and send bulk emails
--------------------------------------- History --------------------------------------------------                      
07.03.17      kalpita.talwadekar@auspost.com.au     updated code for fixing the last contacted customer - task query
12.06.1018    kalpita.talwadekar@auspost.com.au     updated code for coding standard follow - TDO-236
12.05.2020    swati.mogadala@auspost.com.au         INC1579297 Reduced the query limit for cases to 5000, modified line 192 to check tasquery based on caseid's always
12.05.2020    swati.mogadala@auspost.com.au         INC1579297 Upadted methods Type(), ProdCat(),ProdSubCat(), EnqySubType(),Queu0eNames(),Status() to transient to avoid view state error 
22.10.2020    neha.mehta@auspost.com.au             REQ2286193 SSSW - Expose the Case originator field as a filter in the Bulk send email tool
**/
public class SSSW_SendBulkEmailContr {
    //class variables
    //case query for dynamic case retrieve    
    private String query = 'Select Id, CaseNumber, Subject, Owner.Name, Status from Case where ';
    //list of case relevant record types 
    private List<String> recIds = new List<String>();
    
    //list of case for bulk email sends
    public List<Case> caseList { get; set; }
    //list of case with no task for bulk email sends
    public List<Case> caseList2 { get; set; }
    //variable for template id to be sent on bulk emails
    public String templateId { get; set; }
    
    //wrapper to inner class to set the fields and allow range selection of dates
    public List<fieldOperator> fOpList { get; set; }
    public List<fieldOperator> fOpList_selList { get; set; }
    
    public Case cse { get; set; }
    public Case Rangecse { get; set; }
    //boolean for identification of customers with email address
    public boolean custWIthEmail { get; set; }
    public Date contactedDate { get; set; }
    
    //list variables for picklists on form for case queries
    public List<String> typList { get; set; }
    public List<String> prdCtList { get; set; }
    public List<String> prdSubCtList { get; set; }
    public List<String> enqSubCtList { get; set; }
    public List<String> queueList { get; set; }
    public List<String> statusList { get; set; }
    private List<String> contAddress { get; set; }
    private List<String> contNames { get; set; }
    public List<String> caseOriginatorList { get; set; } //Added by Neha Mehta
    
        
    //boolean for successful case list retreieval
    public Boolean isSuccess { get; set; }  
    //boolean for deciding if cases with task or not to be retrieved
    public Boolean showNoTask { get; set; }
    /**
      * @description       Constructor for setting the onload variables of class
      * @param             ApexPages.StandardController stdCtr 
      * @return            NA
      * @throws            NA
      */
    public SSSW_SendBulkEmailContr(ApexPages.StandardController stdCtr) {
        //initialize case lists
        caseList = new List<Case>();
        caseList2 = new List<Case>();
        isSuccess = false;
        //query for SSSW Case record types
        for (RecordType rec : [
                                Select Id
                                FROM 
                                    RecordType
                                WHERE 
                                    SObjectType = :SSSWConstants.CASE_OBJ 
                                AND
                                    DeveloperName like :SSSWConstants.CASE_RECTYPE_LIKE
                              ]) {
            recIds.add(rec.id);
        }
        
    }
    
    /**
      * @description       method on page load to initialize all variables and make relevant settings
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void initialize() {
        //setup case status for case to be viewed on screen
        cse = new Case(Status = SSSWConstants.CASE_STATUS);
        Rangecse = new Case();
        //setup list variables for picklists on form for case queries
        typList = new List<String>();
        prdCtList = new List<String>();
        prdSubCtList = new List<String>();
        enqSubCtList = new List<String>();
        statusList = new List<String>();
        queueList = new List<String>();
        caseOriginatorList= new List<String>(); //Added by Neha Mehta
        //boolean for identification of customers with email address
        custWIthEmail = false;
        //boolean for deciding if cases with task or not to be retrieved
        showNoTask = false;
        caseList = new List<Case>();
        caseList2 = new List<Case>();
        //wrapper to inner class to set the fields and allow range selection of dates.
        fOpList = new List<fieldOperator>();
        fOpList.add(new fieldOperator('=', 'CreatedDate', 'Date/Time Open  ', '', null, false, new List<String>(), new List<Selectoption>()));
        fOpList.add(new fieldOperator('=', 'CreatedDate', 'Date/Time Open  ', '', null, true, new List<String>(), new List<Selectoption>()));
        fOpList.add(new fieldOperator('=', 'SLATargetDate__c', 'Service SLA  ', '', null, false, new List<String>(), new List<Selectoption>()));
        fOpList.add(new fieldOperator('=', 'SLATargetDate__c', 'Service SLA  ', '', null, true, new List<String>(), new List<Selectoption>()));
        fOpList.add(new fieldOperator('=', 'LastStatusUpdate__c', 'Last Contacted Customer', '', null, false, new List<String>(), new List<Selectoption>()));
        fOpList.add(new fieldOperator('=', 'LastStatusUpdate__c', 'Last Contacted Customer', '', null, true, new List<String>(), new List<Selectoption>()));
    }
    
    /**
      * @description       method called from page to form a dynamic query based on user selection and get cases matching
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void getCases() {
        try {
            //initialize all previous list every time user hits search
            Set<Id> casesWithActivities = new Set<Id>();
            String taskQuery = '';
            isSuccess = false;
            caseList = new List<Case>();
            caseList2 = new List<Case>();
            contAddress = new List<String>();
            contNames = new List<String>();
            //forming query based on user selections
            query = 'Select Id, CaseNumber,Contact.Name,Contact.Id, Case.Contact.Email, Subject, Owner.Name, Status ';
            //concatenate the query for contact with emails only and SSSW record types
            query = query + 'from Case where Contact.Email != null and recordTypeid in :recIds ';
            
            
            //if user has selected specific status to be filtered on
            query = !statusList.isEmpty() ? query + 'and Status in :statusList ' : query ;
            
            //if user has selected specific case types to be filtered on
            query = !typList.isEmpty() ? query + 'and Type in :typList  ' : query ;
            
            //if user has selected specific product categories and sub categories to be filtered on
            query = !prdCtList.isEmpty() ? query + ' and  ProductCategory__c in :prdCtList ' : query ;
            query = !prdSubCtList.isEmpty() ? query + ' and ProductSubCategory__c in :prdSubCtList' : query ;
            query = !enqSubCtList.isEmpty() ? query + ' and EnquirySubType__c in :enqSubCtList ' : query ;
            //updated by Neha Mehta Start
            query = !caseOriginatorList.isEmpty() ? query + ' and caseOriginator__c in :caseOriginatorList ' : query ;
            //updated by Neha Mehta End
            //if user has selected specific queues to be filtered on
            query = !queueList.isEmpty() ? query + ' and OwnerId in :queueList ' : query ;
            //looping through the wrapper list to get the relevant cases matching the criteria
            for (fieldOperator fop: fOpList) {
                if (!fop.fieldCheck && cse.get(fop.fieldName) != null && !'LastStatusUpdate__c'.equalsIgnoreCase(fop.FieldName)) {
                    //if its last updated field - then query based on last modified lower range
                    query = query + ' and ' + fop.fieldName + ' ' + fop.operator + +DateTime.valueOf(cse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'') ;
                } else if (fop.fieldCheck && Rangecse.get(fop.fieldName) != null && !'LastStatusUpdate__c'.equalsIgnoreCase(fop.FieldName)) {
                    //if its last updated field - then query based on last modified higher range
                    query = query + ' and ' + fop.fieldName + ' ' + fop.operator + +DateTime.valueOf(Rangecse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'') ;
                } else if (!fop.fieldCheck && cse.get(fop.fieldName) != null && Rangecse.get(fop.fieldName) == null) { //based on last contacted date, get the activity records for email and phone and get caseid's
                    //if we need to filter cases with tasks lower range
                    taskQuery = 'Select WhatId from Task where Type in (\'Email\',\'Phone Call\') and WhatId != null and Status = \'Completed\' and createdDate '
                            + fop.operator + DateTime.valueOf(cse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
                } else if (fop.fieldCheck && Rangecse.get(fop.fieldName) != null && cse.get(fop.fieldName) == null) { //based on last contacted date, get the activity records for email and phone and get caseid's
                    //if we need to filter cases with tasks higher range
                    taskQuery = 'Select WhatId from Task where Type in (\'Email\',\'Phone Call\') and WhatId != null and Status = \'Completed\' and createdDate '
                            + fop.operator + DateTime.valueOf(Rangecse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
                } else if (!fop.fieldCheck && cse.get(fop.fieldName) == null && Rangecse.get(fop.fieldName) == null) {
                    //if we need to filter cases with tasks completed
                    taskQuery = 'Select WhatId from Task where Type in (\'Email\',\'Phone Call\') and WhatId != null and Status = \'Completed\'  ';
                } else if (!fop.fieldCheck && cse.get(fop.fieldName) != null && Rangecse.get(fop.fieldName) != null) {
                    //if we need to filter cases with tasks completed higher range
                    taskQuery = 'Select WhatId from Task where Type in (\'Email\',\'Phone Call\') and WhatId != null and Status = \'Completed\' and createdDate '
                            + fop.operator + DateTime.valueOf(Rangecse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'') + ' and createdDate '
                            + fop.operator + DateTime.valueOf(cse.get(fop.fieldName)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'')  ;
                }
            }
            //limit the number of cases - changed from 10K to 5k for INC1579297
            query = query + ' limit 5000';
            System.debug('query in getCases:' + query);
            //query the cases 
            caseList = (List<Case>) database.query(query);
            
            //create new lists for cases with and without tasks
            List<String> caseIds = new List<String>();
            List<case> caseWActivities = new list<Case>();
            List<case> caseWOActivities = new list<Case>();
            
            //loop through queried cases and get the case id's
            for (Case cse: caseList) {
                caseIds.add(cse.Id);
            }
            
            //get the task query for cases ith tasks
            //removed check for caseid's, the taskQuery always checks for related caseid's only-INC1579297
            // if (!caseIds.isEmpty() && !String.isBlank(taskQuery)){
            if (!String.isBlank(taskQuery)) {
                taskQuery = taskQuery + ' and whatId in :caseIds';
            }
            system.debug('--' + taskQuery);
            
            if (!String.isBlank(taskQuery)) {
                //quering the task for getting the last activity
                for (Task tsk: (List<Task>) database.query(taskQuery)) {
                    casesWithActivities.add(tsk.WhatId);
                }
            }
            
            //for reduction of remaining cases without activities 
            List<Case> caseWActvty = new List<Case>();
            List<Case> caseWOActvty = new List<Case>();
            for (case cse: caseList) {
                if (!casesWithActivities.isEmpty() && casesWithActivities.contains(cse.Id)) {
                    caseWActvty.add(cse);
                } else {
                    caseWOActvty.add(cse);
                }
            }
            //get the final case list of cases with and without activity after reduction from original list
            for (integer i = 0; i < 5; i++) {
                //if no task is required to be considered
                if (!showNoTask && (cse.LastStatusUpdate__c == null && RangeCse.LastStatusUpdate__c == null) 
                     && caseList.size() > i) {
                    caseList2.add(caseList[i]);
                } else if ((cse.LastStatusUpdate__c != null || RangeCse.LastStatusUpdate__c != null) &&
                            !caseWActvty.isEmpty() && caseWActvty.size() > i && !showNoTask) {
                    //if last updated activity is to be considered with activitty
                    caseList2.add(caseWActvty[i]);
                } else if (!caseWOActvty.isEmpty() && caseWOActvty.size() > i && showNoTask) {
                    //if no activity cases to be displayed
                    caseList2.add(caseWOActvty[i]);
                } 
            }
            
            //based tasks are to be considered then feed in caselist
            if (!showNoTask && (cse.LastStatusUpdate__c == null && RangeCse.LastStatusUpdate__c == null)) {
                caseList = caseList;
            } else if (!showNoTask && (cse.LastStatusUpdate__c != null || RangeCse.LastStatusUpdate__c != null)) {
                caseList = caseWActvty;
            } else if (showNoTask) {
                caseList = caseWOActvty;
            } 
        } catch (Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    SSSW_SendBulkEmailContr.class.getName(), 'getCases', '', LoggingLevel.ERROR);
        }
    }
    
    /**
      * @description       method called from page to send bulk emails to customers from ExactTarget
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public void sendEmail() {
        //check if users has selected a template
        if (String.isBlank(templateId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Select Template to Send Emails'));
        } else {
            //Sending in batches of 10 to avoid hitting governor limits.
            Database.executeBatch(new SSSW_SendBulkEmailBatch(caseList, templateId),10);
            isSuccess = true;
            initialize();
        }
    }
     /**
      * @description       This method gets all the product categories for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //Changed the method to transient to avoid view state error INC1579297
   //Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> Type{
        get{
            if(Type == null){
                List<SelectOption> options = new List<SelectOption>();
        
                //get all product categories on UI
                options.add(new SelectOption(SSSWConstants.GENERAL_ENQUIRY, SSSWConstants.GENERAL_ENQUIRY));
                options.add(new SelectOption(SSSWConstants.Investigation, SSSWConstants.Investigation));
                options.add(new SelectOption(SSSWConstants.Feedback, SSSWConstants.Feedback));
                Type = options;
            }
            return Type;
        }
        private set;
    }
     
     /**
      * @description       This method gets relevant case status values
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //12.05.2020 Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> Status {
        get{
            if(Status == null){
                List<SelectOption> options = new List<SelectOption>();
        
                //get all case status values
                for (Schema.PicklistEntry p : Case.Status.getDescribe().getPicklistValues()) {
                    if (!p.getValue().containsignoreCase(SSSWConstants.CLOSE)) {
                    options.add(new SelectOption(p.getValue(), p.getValue()));
                    }
            }
            Status = options;
        }
        return Status;
    }
    private set;
}
     
     /**
      * @description       This method gets all SSSW Queues
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //12.05.2020 Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> QueueNames {
        get{
            if(QueueNames == null){
            List<SelectOption> options = new List<SelectOption>();
            //query all queues of SSSW type
            for (Group grp: [
                            Select id, Name 
                            FROM 
                                Group 
                            WHERE 
                                Type = :SSSWConstants.Queue 
                            AND 
                             Name like :SSSWConstants.CASE_RECTYPE_LIKE]) {
                options.add(new SelectOption(grp.Id, grp.Name));
            }
            QueueNames = options;
        }
        return QueueNames;
    }
    private set;
}
     
     /**
      * @description       This method gets all the email templates
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    public List<SelectOption> getEmailTemplates() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            //get the folder for email template
            String folderId = [
                                Select Id 
                                FROM 
                                    Folder 
                                WHERE 
                                    DeveloperName = 'SSSW_CCC_Bulk_Email_Template' 
                                LIMIT 1].Id;
            options.add(new SelectOption(SSSWConstants.EMPTY_SPACE, SSSWConstants.NONE));
            //get the email templates
            for (EmailTemplate grp: [Select id, Name from EmailTemplate where FolderId = :folderId]) {
                options.add(new SelectOption(grp.Id, grp.Name));
            }
            
        } catch (Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    SSSW_SendBulkEmailContr.class.getName(), 'getEmailTemplates', '', LoggingLevel.ERROR);
        }
        return options;
    }
     
     /**
      * @description       This method gets all the product categories for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //12.05.2020 Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> ProdCat {
        get{
            if(ProdCat == null){
            List<SelectOption> options = new List<SelectOption>();
        
            //get all product categories on UI
            for (Schema.PicklistEntry p : Case.ProductCategory__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(p.getValue(), p.getValue()));
            }
            ProdCat = options;
        }
        return ProdCat; 
    }
    private set;
}
     
     /**
      * @description       This method gets all the product sub categories for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //12.05.2020 Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> ProdSubCat {
        get{
            if(ProdSubCat == null){
                List<SelectOption> options = new List<SelectOption>();
        
                //get all product  sub categories on UI
                for (Schema.PicklistEntry p : Case.ProductSubCategory__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(p.getValue(), p.getValue()));
            }
            ProdSubCat = options;
        }
        return ProdSubCat;
    }
    private set;
}
     
     /**
      * @description       This method gets all the enquiry types for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
      //12.05.2020 Changed the method to transient to avoid view state error INC1579297
    public transient List<SelectOption> EnqySubType {
        get{
            if(EnqySubType == null){
            List<SelectOption> options = new List<SelectOption>();
        
            //get all with no tasks completed on UI
            for (Schema.PicklistEntry p : Case.EnquirySubType__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(p.getValue(), p.getValue()));
            }
            EnqySubType = options;
        }
        return EnqySubType;
    }
    private set;
}
     
    /**
      * @author       : kalpita.talwadekar@auspost.com.au
      * @date         : 12/09/2016
      * @description  : Wrapper class for holding the date fields and operator and values for each.
      **/
    public class fieldOperator {
        //for the criteria selection operators and fields
        public String operator { get; set; }
        public String fieldValue { get; set; }
        public List<String> fieldValueList { get; set; }
        public List<SelectOption> optList { get; set; }
        public DateTime dtime { get; set; }
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean fieldCheck { get; set; }
        /**
          * @description       Constructor for setting the fields, operator and values
          * @param             NA 
          * @return            NA
          * @throws            NA
          */
        public fieldOperator(String operator, String fieldName, String fieldlabel, String fieldValue,
                DateTime dtime, Boolean fieldCheck, List<String> fieldValueList, List<SelectOption> optList) {
            //set the field, value and criteria operator to be used for filtering
            this.operator = operator;
            this.fieldValue = fieldValue;
            this.dtime = dtime;
            this.fieldName = fieldName;
            this.fieldCheck = fieldCheck ;
            this.fieldValueList = fieldValueList ;
            this.fieldLabel = fieldLabel;
            this.optList = optList;
        }
    }
    
    /**
      * @description       This method gets all the case originator for case object
      * @param             NA
      * @return            List<SelectOption>
      * @throws            NA
      */
    //changes done w.r.t. REQ2286193
    public transient List<SelectOption> CaseOriginator {
        get{
            if(CaseOriginator == null){
            List<SelectOption> options = new List<SelectOption>();
            //get all product categories on UI
            for (Schema.PicklistEntry p : Case.CaseOriginator__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(p.getValue(), p.getValue()));
            }
            CaseOriginator = options;
        }
        return CaseOriginator; 
    }
    private set;
    }
}