/*****************************************************************
Description:    Wrapper Class for NPS Voice functions
History:
15-02-2019  disha.kariya@auspost.com.au Removed Case contact context 
and passing Task's Contact details instead of Case's Contact details
------------------------------------------------------------------
******************************************************************/
public class NPSVoiceSurveyWrapper {
    public Task taskObj {get;set;}
    public Case caseObj {get;set;}
    public Contact taskContact {get;set;}
    
    public NPSVoiceSurveyWrapper(Task pTask, Case pCase, Contact tContact) {
        this.taskObj = pTask;
        this.caseObj = pCase;
        this.taskContact = tContact;
    }
    
    public class NPSVoiceSurveyRequest {
        public String case_number;
        public String case_last_modified_date;
        public String task_created_date;
        public String case_id;
        public String task_contact_id;
        public String apcn;
        public String first_name;
        public String last_name;
        public String email;
        public String product_category;
        public String product_sub_category;
        public String status;
        public String case_owner_id;
        public String origin;
        public String case_record_type_id;
        public String task_created_by_alias;
        public String task_created_by_lastname;
        public String task_created_by_firstname;
        public String agent_id;
        public String closed_date;
        public String case_type;
        public String enquiry_sub_type;
        public String product_type;
        public String case_originator;
        public String root_cause;
        public String task_segment;
        public String cti_integration_id;
        public String case_contact_id;
        public String case_created_date;
        public String reference_id;
        public String resolution_code;
        public String is_complaint;
        public String is_cr;
        public String is_hlc;
        public String task_created_by_email;
        
        public NPSVoiceSurveyRequest(Task tRec, Case cRec, Contact tContact) {
            this.case_number = cRec.CaseNumber;
            this.case_last_modified_date = String.valueOf(cRec.LastModifiedDate);
            this.task_created_date = String.valueOf(tRec.CreatedDate);
            this.case_id = cRec.Id;
            this.task_contact_id = tRec.Contact__c;
            this.apcn = tContact.APCN__c;
            this.first_name = tContact.FirstName;
            this.last_name = tContact.LastName;
            this.email   = tContact.Email;
            this.product_category = cRec.ProductCategory__c;
            this.product_sub_category = cRec.ProductSubCategory__c;
            this.status  = cRec.Status;
            this.case_owner_id = cRec.OwnerId;
            this.origin  = cRec.Origin;
            this.case_record_type_id = cRec.RecordtypeId;
            this.task_created_by_alias = tRec.CreatedBy.Alias;
            this.task_created_by_lastname = tRec.CreatedBy.LastName;
            this.task_created_by_firstname = tRec.CreatedBy.FirstName;
            this.agent_id = tRec.Agent__c;
            this.closed_date = String.valueOf(cRec.Closed_Date__c);
            this.case_type = cRec.Type;
            this.enquiry_sub_type = cRec.EnquirySubType__c;
            this.product_type = cRec.Product_Type__c;
            this.case_originator = cRec.CaseOriginator__c;
            this.root_cause = cRec.Root_cause__c;
            this.task_segment = tRec.Segment__c;
            this.cti_integration_id = tRec.CTIInteractionID__c;
            this.case_contact_id = '';
            this.case_created_date = String.valueOf(cRec.CreatedDate);
            this.reference_id = cRec.ReferenceID__c;
            this.resolution_code = cRec.ResolutionCode__c;
            this.is_complaint = String.valueOf(cRec.Is_Complaint__c);
            this.is_cr = String.valueOf(cRec.IsCR__c);
            this.is_hlc = String.valueOf(cRec.IsHLC__c);
            this.task_created_by_email = tRec.CreatedBy.Email;
        }
    }

    public class NPSVoiceSurveyResponse {
        public String taskId {get;set;}
        public Boolean success {get;set;}
        public String errMsg {get;set;}

        public NPSVoiceSurveyResponse(String pTaskId, Boolean pSuccess, String pErrMsg){
            this.taskId = pTaskId;
            this.success = pSuccess;
            this.errMsg = pErrMsg;
        }
    }
}