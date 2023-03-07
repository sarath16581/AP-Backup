/**
 * @File Name          : STHSFeedbackFormController.cls
 * @Description        : Controller class for StarTrack Feedback form
 * @Author             : Mahesh Parvathaneni
 * 					   : Jacob Isaac - REQ2995236 To remove defaulting StarTrack_Calc_Email_Address__c
 * 					   : 2023-03-02 Thang Nguyen - DDS-14900 - Set the comment to private 
 **/

public with sharing class STHSFeedbackFormController {

	/**
	 * This will create a case from the feedback form data.
	 * StarTrack Related contact is created from the case trigger.
	 */
	@AuraEnabled
	public static String createFeedbackFormCase(Map<Object,String> formData) {
		try {
			//build case object
			Case caseObj = new Case();
			//get feedback form case default values
			getFeedbackCaseDefaultValues(caseObj);
			//get instance of STHS community service
			STHSCommunityService service = STHSCommunityService.getInstance();
			//get case data from form
			service.getFormCaseData(caseObj, formData);
			//get case default values
			service.getCaseDefaultValues(caseObj);
			//insert case
			service.insertRecords(new List<SObject>{caseObj});
			//get case comments
			CaseComment comment = new CaseComment();
			String commentBody = getFeedbackCaseComments();
			//build case comments from form data
			commentBody = service.buildCaseCommentsWithFormData(commentBody, formData);
			comment.CommentBody = commentBody;
			comment.IsPublished = false;
			comment.ParentId = caseObj.Id;
			//insert case comments
			service.insertRecords(new List<SObject>{comment});
			//return case number
			return service.getCaseNumber(caseObj.Id);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Assign the feedback form case default values 
	 */
	private static void getFeedbackCaseDefaultValues(Case caseObj) {
        caseObj.Subject = caseObj.Call_Purpose__c = caseObj.Initial_Call_Purpose__c = STHSConstants.CASE_SUBJECT_FEEDBACK_ENQUIRY;
		caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(STHSConstants.CASE_RECORDTYPE_VOC_ENQUIRY).getRecordTypeId();
		caseObj.Auto_Email_Response_sent__c = true;
        StarTrack_Settings__c starTrackSettings = StarTrack_Settings__c.getOrgDefaults();
        caseObj.StarTrack_Calc_Email_Address__c = starTrackSettings.VOC_From_Email__c; 
    }

	/**
	 * Assign the feedback form case default comments 
	 */
	private static String getFeedbackCaseComments() {
		String commentBody = '---Enquiry Details---';
		commentBody += '\n' + 'Enquiry type : ' + STHSConstants.CASE_SUBJECT_FEEDBACK_ENQUIRY;
        return commentBody;
    }
}