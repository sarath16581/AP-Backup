/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description  Controller for TDF_MessageFeed and TDF_MessageFeedPost pages, available for selection from the FSL Gantt chart
*                   Determines the record the page launched from
*                   -If the record is a Service Appointment, then it allows post or comment against the Work Order related to the selected record
*                   -If the record is a Service Resource, then it retrieves the current FFD job for the Driver to post against
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
*/
public class TDF_MessageFeedController {
    
    public String recId{get;set;}
    public String woId{get;set;}
    
    public TDF_MessageFeedController(){
        
        Datetime currentDateTime = System.now();
        List<AssignedResource> assResList = new List<AssignedResource>();

        recId = Apexpages.currentPage().getParameters().get('id');
        
        //If selected record is an SA
        if (recId.left(3) == '08p'){
            
            //get the Work Order of the selected SA to post directly against
            woId = [SELECT ParentRecordId FROM ServiceAppointment WHERE Id = :recId LIMIT 1].ParentRecordId;
            
            //If no record found
            if(woId == null){
                //Display message
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'No work order found against the selected service appointment.'));
            }
        }
        //else if the selected record is an SR
        else if(recId.left(3) == '0Hn'){
            
            //Get the Completed FFD job for the duty 
            //-scheduled within 1 hr into the future and up to 15 hrs in the past (i.e. the FFD for their current activity)
            assResList = [SELECT ServiceAppointment.ParentRecordId, ServiceResource.ResourceType    
                            FROM AssignedResource 
                            WHERE ServiceResourceId = :recId 
                            AND Work_Order_Record_Type__c = 'Fit_For_Duty' 
                            AND ServiceAppointment.Status = 'Completed' 
                            AND ServiceAppointment.SchedStartTime > :currentDateTime.addHours(-15) 
                            AND ServiceAppointment.SchedStartTime < :currentDateTime.addHours(1) 
                            LIMIT 2];
   
            for(AssignedResource assRes : assResList){
                //Get the work order Id
                woId = assRes.ServiceAppointment.ParentRecordId;
            }
            
            //If no record found
            if(woId == null){
                //Display message 
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'No current completed Fit For Duty job could be found for this driver'));
            }
        }  
    }
}