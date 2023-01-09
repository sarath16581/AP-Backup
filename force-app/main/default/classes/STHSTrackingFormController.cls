/**
 * @File Name          : STHSTrackingFormController.cls
 * @Description        : Controller class for StarTrack Tracking form
 * @Author             : Mahesh Parvathaneni
 **/

public with sharing class STHSTrackingFormController {

	/**
	 * This will create a case from the tracking form data.
	 * StarTrack Related contact is created from the case trigger.
	 */
	@AuraEnabled
	public static String createTrackingFormCase(Map<Object,String> formData) {
		try {
			//build case object
			Case caseObj = new Case();
			//get tracking form case default values
			getTrackingCaseDefaultValues(caseObj, formData);
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
			String commentBody = getTrackingCaseComments();
			//build case comments from form data
			commentBody = service.buildCaseCommentsWithFormData(commentBody, formData);
			comment.CommentBody = commentBody;
			comment.IsPublished = true;
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
	 * Assign the tracking form case default values 
	 */
	private static void getTrackingCaseDefaultValues(Case caseObj, Map<Object,String> formData) {
        caseObj.Subject = STHSConstants.CASE_SUBJECT_TRACKING_ENQUIRY;
		caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(STHSConstants.CASE_RECORDTYPE_DELIVERY_ENQUIRY).getRecordTypeId();
		caseObj.Send_Auto_Response_Email__c = true;
		caseObj.Description_of_contents__c = formData.get(STHSConstants.FORM_DATA_DESCRIPTION_CONTENTS);
    }

	/**
	 * Assign the tracking form case default comments 
	 */
	private static String getTrackingCaseComments() {
		String commentBody = '---Enquiry Details---';
		commentBody += '\n' + 'Enquiry type : ' + STHSConstants.CASE_SUBJECT_TRACKING_ENQUIRY;
        return commentBody;
    }
}