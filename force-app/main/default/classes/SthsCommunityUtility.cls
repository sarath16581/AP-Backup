/**
 * @File Name          : SthsCommunityUtility.cls
 * @Description        : Utility class for StarTrack Help and Support Community
 * @Author             : Mahesh Parvathaneni
 **/

public inherited sharing class SthsCommunityUtility {

    // case assignment rule to execute on case insert
    private static final AssignmentRule CASE_ASSIGNMENT_RULE {
        get {
            if (CASE_ASSIGNMENT_RULE == null) {
                List<AssignmentRule> assignmentRules = [select Id from AssignmentRule where SobjectType =:SthsConstants.CASE_OBJ and Active = true limit 1];
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

    public static void getCaseDefaultValues(Case caseObj) {
        caseObj.Auto_Email_Response_sent__c = true;
        caseObj.Status = SthsConstants.CASE_STATUS_NEW;
        caseObj.Priority = SthsConstants.CASE_PRIOIRITY_NORMAL;
        caseObj.Origin = SthsConstants.CASE_ORIGIN_WEB;

        // if there is an active case assignment rule set the DML Options to ensure assignment rule is executed on case insert
        if (CASE_ASSIGNMENT_RULE.Id != null) {
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.assignmentRuleHeader.assignmentRuleId = CASE_ASSIGNMENT_RULE.Id;
            caseObj.setOptions(dmlOptions);
        }
    }

    public static void getFormCaseData(Case caseObj, Map<Object,String> formData) {
        caseObj.Description = formData.get(SthsConstants.FORM_DATA_ENQUIRY);
        caseObj.SuppliedEmail = formData.get(SthsConstants.FORM_DATA_EMAIL);
    }

    public static void getFormRelatedContactData(AuthorisedContacts__c relContact, Map<Object,String> formData) {
        relContact.Contact_Email__c = formData.get(SthsConstants.FORM_DATA_EMAIL);
        String phNumber = formData.get(SthsConstants.FORM_DATA_PHONE);
        //check mobile or landline number
        if (isMobileNumber(phNumber)) {
            relContact.Contact_Mobile_Number__c = phNumber;
        } else {
            relContact.Contact_Phone_Number__c = phNumber;
        }
        relContact.First_Name__c = formData.get(SthsConstants.FORM_DATA_FNAME);
        relContact.Last_Name__c = formData.get(SthsConstants.FORM_DATA_LNAME);
        relContact.Initial_Contact__c = true;
        relContact.Notification_Required__c = true;
        relContact.RecordTypeId = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByDeveloperName().get(SthsConstants.REL_CONTACT_RECORDTYPE_ST).getRecordTypeId();
    }

    //function to check mobile number
    private static Boolean isMobileNumber(String phNumber){
        return (phNumber.startsWith('04') || phNumber.startsWith('05'));
    }
}
