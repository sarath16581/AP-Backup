/*------------------------------------------------------------
Author:        Jen Karen Tan
Description:   Contoller class for StarTrack Task Search page
Inputs:
Test Class:    
History
July 21, 2016 - Jen Karen Tan - Created
------------------------------------------------------------*/

public class StarTrackTasksRenderPDF_ControllerX {
	public List<Task> taskList {get; set;}
	public Integer listSize {get; set;}

	public StarTrackTasksRenderPDF_ControllerX() {
		String ids = ApexPages.currentPage().getParameters().get('id');

		List<String> idList = ids.split(',');
		Set<Id> taskIds = new Set<Id>();

		for (String s : idList) {
			taskIds.add(Id.valueOf(s));
		}

	    List<String> taskDetailPrintFields = new List<String>();

		for(Schema.FieldSetMember fsm : SObjectType.Task.FieldSets.getMap().get('Task_Printed_View').getFields()){
            taskDetailPrintFields.add(fsm.getFieldPath());
        }

		String taskQuery = 'SELECT ' + String.join(taskDetailPrintFields, ',') + ', Primary_Capture_Details__c, CaseObject__r.ArticleTest__c, CaseObject__r.ArticleTest__r.Barcode__C, Subject, Description FROM Task WHERE Id IN :taskIds';
        taskList = Database.query(taskQuery);
        listSize = taskList.size();
	}
}