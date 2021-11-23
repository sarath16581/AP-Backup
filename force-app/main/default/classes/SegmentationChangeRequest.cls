/**************************************************
Type:       Apex Batch Job Class for Segmentation Change Request
Purpose:    Provides the ability to automatically process a request to change segmentation-related attribute values at a specified date
Used By:    
History:
--------------------------------------------------
26.06.2012	M. Isidro (Cloud Sherpas)		Created
02.08.2012  Richard Enojas (Salesforce.com) Removed Proposed Tier/Sector/Subsector as per CR 23
21.08.2012	Richard Enojas (Salesforce.com) Replaced Proposed_Sales_Segment__c to Proposed_Sales_Team__c
**************************************************/
global with sharing class SegmentationChangeRequest implements Schedulable {

    global void execute(SchedulableContext sc) {
		updateSegmentation(); 
    }
    
    global static void updateSegmentation() {
    	Date dateToday = Date.today();	
    	
    	// Query current day only
		List<Segmentation_Change_Request__c> scrList = 
		[Select Id, Proposed_Sales_Team__c, Proposed_Account_Manager__c, Organisation__r.ShippingPostalCode, Organisation__c, Date_Request_Sent__c 
		From Segmentation_Change_Request__c
		Where Approval_Status__c='Approved'
		And Effective_Date_of_Change__c = :dateToday];
		
		system.debug('***scrList: ' + scrList);
		
		// Execute the method to update the Sales Segment
		if (!scrList.isEmpty()) {
			SegmentationUtil.updateSegmentationChangeRequest(scrList);
		}
    }
    	
}