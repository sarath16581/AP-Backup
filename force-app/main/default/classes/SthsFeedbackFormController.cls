/**
 * @File Name          : SthsFeedbackFormController.cls
 * @Description        : Controller class for StarTrack Feedback form
 * @Author             : Mahesh Parvathaneni
 **/

public without sharing class SthsFeedbackFormController {

	@AuraEnabled
	public static String createFeedbackFormCase(Map<Object,String> formData) {
		try {
			//build case object
			Case caseObj = new Case();
			//get feedback form case default values
			getFeedbackCaseDefaultValues(caseObj);
			//get case default values
			SthsCommunityUtility.getCaseDefaultValues(caseObj);
			//get case data from form
			SthsCommunityUtility.getFormCaseData(caseObj, formData);
			//insert case
			ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{caseObj});
			//return case number
			String caseNumber = CasesSelector.newInstance().selectById(new Set<Id> {caseObj.Id}).get(caseObj.Id).CaseNumber;
			return caseNumber;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	private static void getFeedbackCaseDefaultValues(Case caseObj) {
        caseObj.Subject = caseObj.Call_Purpose__c = caseObj.Initial_Call_Purpose__c = SthsConstants.CASE_SUBJECT_FEEDBACK_ENQUIRY;
		caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SthsConstants.CASE_RECORDTYPE_VOC_ENQUIRY).getRecordTypeId();
    }
}