/**
 * @File Name          : STHSCommunityService.cls
 * @Description        : Service class for StarTrack Help and Support Community
 * @Author             : Mahesh Parvathaneni
 * @Modified           : Jacob Isaac - REQ2995236 - Commented out Calc_Email_Address field
 **/

public inherited sharing class STHSCommunityService {

    // case assignment rule to execute on case insert
    private static final AssignmentRule CASE_ASSIGNMENT_RULE {
        get {
            if (CASE_ASSIGNMENT_RULE == null) {
                List<AssignmentRule> assignmentRules = AssignmentRulesSelector.newInstance(1).selectActiveRulesBySObjectType(STHSConstants.CASE_OBJ).values();
                if (assignmentRules.size() == 1) {
                    CASE_ASSIGNMENT_RULE = assignmentRules[0];
                } else {
                    CASE_ASSIGNMENT_RULE = new AssignmentRule();
                }
            }
            return CASE_ASSIGNMENT_RULE;
        }
        private set;
    }

    /**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static STHSCommunityService getInstance() {
		return (STHSCommunityService)Application.Utilities.getInstance(STHSCommunityService.class);
	}

    /**
     * Assign default values for Startrack related cases
     */
    public void getCaseDefaultValues(Case caseObj) {
        caseObj.Status = STHSConstants.CASE_STATUS_NEW;
        caseObj.Priority = STHSConstants.CASE_PRIOIRITY_NORMAL;
        caseObj.Origin = STHSConstants.CASE_ORIGIN_WEB;
        caseObj.Direction__c = STHSConstants.CASE_DIRECTION_INBOUND;
        caseObj.Notification_Required__c = true;
        caseObj.Recent_Caller_Pref_Method_of_Contact__c = caseObj.Initical_CallPreferred_method_of_contact__c = STHSConstants.PREF_CONTACT_METHOD_EMAIL;
        caseObj.Recent_Caller_Type__c = STHSConstants.CASE_CONTYPE_SENDER;
        //caseObj.StarTrack_Calc_Email_Address__c = StarTrackUtil.getCaseSTCalcEmailAddress(String.valueOf(caseObj.SuppliedEmail)); //REQ2995236 - Commented out this line

        // if there is an active case assignment rule set the DML Options to ensure assignment rule is executed on case insert
        if (CASE_ASSIGNMENT_RULE.Id != null) {
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.assignmentRuleHeader.assignmentRuleId = CASE_ASSIGNMENT_RULE.Id;
            caseObj.setOptions(dmlOptions);
        }
    }

    /**
     * Assign case values based on the form data
     */
    public void getFormCaseData(Case caseObj, Map<Object,String> formData) {
        caseObj.Description = formData.get(STHSConstants.FORM_DATA_ENQUIRY);
        caseObj.SuppliedEmail = formData.get(STHSConstants.FORM_DATA_EMAIL);
        caseObj.Recent_Caller_First_Name__c = formData.get(STHSConstants.FORM_DATA_FNAME);
        caseObj.Recent_Caller_Last_Name__c = formData.get(STHSConstants.FORM_DATA_LNAME);
        String phNumber = formData.get(STHSConstants.FORM_DATA_PHONE);
        phNumber = phNumber.replaceAll('[^0-9]', ''); //replace all characters other than numbers
        //check mobile or landline number
        if (isMobileNumber(phNumber)) {
            caseObj.Recent_Contact_Mobile_Number__c = phNumber;
        } else {
            caseObj.Recent_Caller_Phone_Number__c = phNumber;
        }
        caseObj.Recent_Caller_Email__c = caseObj.Initial_Caller_Email__c = formData.get(STHSConstants.FORM_DATA_EMAIL);
    }

    //function to check mobile number
    private Boolean isMobileNumber(String phNumber){
        return (phNumber.startsWith('04') || phNumber.startsWith('05') || phNumber.startsWith('614') || phNumber.startsWith('615'));
    }

    /**
     * Insert list of sObject records
     */
    public void insertRecords(List<SObject> recordList) {
        ElevatedSharingContext context = new ElevatedSharingContext();
        context.insertRecords(recordList);
    }

    /**
     * get the case number by querying case
     */
    public String getCaseNumber(Id caseId){
        ElevatedSharingContext context = new ElevatedSharingContext();
        return context.getCasesById(new Set<Id> {caseId}).get(caseId).CaseNumber;
    }
    
    /**
     * Build the case comments from the form data
     */
    public String buildCaseCommentsWithFormData(String commentBody, Map<Object,String> formData) {
        commentBody += '\n' + 'What does it relate to ? - ' + formData.get(STHSConstants.FORM_DATA_ENQUIRY_TYPE);
        if (formData.get(STHSConstants.FORM_DATA_REFERENCE) != null) {
            commentBody += '\n' + 'Reference - ' + formData.get(STHSConstants.FORM_DATA_REFERENCE);
        }
        commentBody += '\n' + 'First Name - ' + formData.get(STHSConstants.FORM_DATA_FNAME);
        commentBody += '\n' + 'Phone no - ' + formData.get(STHSConstants.FORM_DATA_PHONE);
        commentBody += '\n' + 'Email - ' + formData.get(STHSConstants.FORM_DATA_EMAIL);
        commentBody += '\n' + 'Your feedback - ' + formData.get(STHSConstants.FORM_DATA_ENQUIRY);
        return commentBody;
    }

    /**
	* Private inner class that elevates access/edit privileges of the current user to edit data without being limited by
	* sharing settings.
	*/
    private without sharing class ElevatedSharingContext {

        /**
		 * Insert a list of sObject records in system mode
		 * @param List<sObject>
		*/
		private void insertRecords(List<sObject> recordList) {
			ApplicationDatabase.getInstance().dmlInsert(recordList);
		}

        /**
         * Returns cases by ids
         * @param Set<Id>
         */
        private Map<Id, Case> getCasesById(Set<Id> ids) {
            return CasesSelector.newInstance().selectById(ids);
        }
    }
}