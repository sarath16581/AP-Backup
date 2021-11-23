/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-01
* @domain Field Service 
* @description Controller for Edit Job Page accessed from Edit Job Action on FSL Gantt
*               Main function is to connect related collect or deliver jobs, and update requested qualities.
*
* @changelog 
* 2020-07-01 - Andrew Judd - Created 
* 2020-09-01 - Andrew Judd - Change to performSearch to support legacy assigned to only a driver scenario
*/
public class TDF_EditJobController {

    public String selectedSAId{get;set;} 
    public List<WorkOrderLineItem> woliCFList{get;set;}
    public List<WorkOrderLineItem> woliDTList{get;set;}
    public List<WorkOrderLineItem> woliDeleteList{get;set;}
    public Integer selectedWOLIDTIndex{get;set;}
    public Integer selectedWOLICFIndex{get;set;}
    public Boolean renderWOLIs{get;set;}
    public String woId{get;set;}
    public WorkOrder objWO{get;set;}
    public string searchString{get;set;}
    public List<Schema.WorkOrder> relatedWOList{get;set;}
    public Set<Id> woliIdsOnLoadSet{get;set;}

    //Constuctor
    public TDF_EditJobController(){

        //Initialisation
        //Get the id of the selected SA
        selectedSAId = Apexpages.currentPage().getParameters().get('id');
      
        //get Search String from field that launches custom lookup page
        //searchString = System.currentPageReference().getParameters().get('lksrch');
        //Choosing not to get search value from the source field - want to display all 
        
        selectedWOLIDTIndex = 0;
        selectedWOLICFIndex = 0;
        renderWOLIs = false;

        woliDeleteList = new List<WorkOrderLineItem>();
        
        //If no single SA selected
        if(selectedSAId == null){
            //Display message and close
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select a single job to edit'));
        }
        else{
            //Get the related WO
            objWO = [SELECT Id, WorkOrderNumber, Subject, Location.Name, Activity_Type__c, Primary_SA__r.SchedStartTime, 
                        RecordType.DeveloperName, IsRestBreak__c 
                     FROM WorkOrder 
                     WHERE Primary_SA__c = :selectedSAId LIMIT 1];

            //If wo found
            if(objWO != null){
                //Get work order record values    
                woId = objWO.Id;
                    
                //If WO is a collect deliver (i.e. standard and not restbreak)
                if(objWO.RecordType.DeveloperName == 'Standard' & objWO.IsRestBreak__c == false){
                    //set flag
                    renderWOLIs = true;
                    //Get list of Deliver WOLIs
                    woliDTList = getWOLIDTList(woId);
                    //Get list of Collect WOLIs
                    woliCFList = getWOLICFList(woId);
                }
            }
        }
    }

    //Used by the custom lookup visualforce page TDF_CustomRelateWOLookup to send the link to the right dom element
    public string getFormTag() {
        return System.currentPageReference().getParameters().get('frm');
    }

    //Used by the custom lookup visualforce page TDF_CustomRelateWOLookup to send the link to the right dom element for the text box
    public string getTextBox() {
        return System.currentPageReference().getParameters().get('txt');
    }       

    //method to add a row for Deliver To WOLI
    public pagereference addWOLIDT(){
        woliDTList.add(new WorkOrderLineItem());
        return null;
    }
    
    //method to add a row for Collect From WOLI
    public pagereference addWOLICF(){
        woliCFList.add(new WorkOrderLineItem());
        return null;
    }

    //method to remove the deliver to element from WOLI list
    public Pagereference deleteDTWOLI(){       
        //if index passed is not null
        if(selectedWOLIDTIndex != null){
            //If Id not null
            if(woliDTList[selectedWOLIDTIndex].Id != null){    
                //Then add a record to the delete list
                woliDeleteList.add(new WorkOrderLineItem(Id = woliDTList[selectedWOLIDTIndex].Id));
            }
            //Remove record from display list
            woliDTList.remove(selectedWOLIDTIndex);
        }
        return null;
    }

    //method to remove the collect from element from WOLI list
    public Pagereference deleteCFWOLI(){       
        //if index passed is not null
        if(selectedWOLICFIndex != null){
            //If Id not null
            if(woliCFList[selectedWOLICFIndex].Id != null){    
                //Then add a record to the delete list
                woliDeleteList.add(new WorkOrderLineItem(Id = woliCFList[selectedWOLICFIndex].Id));
            }
            //Remove record from display list
            woliCFList.remove(selectedWOLICFIndex);
        }
        return null;
    }    

    //method to save the Job Tempalte and Task Template
    public PageReference saveTemplates(){
        
        //Decalre savepoint
        Savepoint sp;
        
        //Get the woliList
        System.debug('woliCFList = ' + woliCFList);
        System.debug('woliDTList = ' + woliDTList);
        
        try{
            //Set save point
            sp = Database.setSavepoint();

            //loop thru the deliver to WOLIs
            for(WorkOrderLineItem woListLI : woliDTList){

                //If product or quantity not set
                if(woListLI.Product__c == null || woListLI.Requested_Quantity__c == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please set Product and Requested Quantity values'));
                    return null;
                }

                //If parent woli is not set
                if(woListLI.WorkOrderId == null){

                    //Set parent and deliver to the wo selected
                    woListLI.WorkOrderId = woId;
                    woListLI.Deliver_To_Work_Order__c = woId;
                    //woListLI.Task__c = 'Deliver Product';
                }
            }

            //loop thru the collect from WOLIs
            for(WorkOrderLineItem woListLI : woliCFList){

                //If product or quantity not set
                if(woListLI.Product__c == null || woListLI.Requested_Quantity__c == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please set Product and Requested Quantity values'));
                    return null;
                }                

                //If parent woli is not set
                if(woListLI.WorkOrderId == null){
                    //Set parent and collect from the wo selected
                    woListLI.WorkOrderId = woId;
                    woListLI.Collect_From_Work_Order__c = woId;
                    //woListLI.Task__c = 'Collect Product';
                }
            }

            //update changes (inserts and updates) to wolis
            upsert woliDTList;
            upsert woliCFList;

            //If records to delete
            if(woliDeleteList.size() > 0){
                //delete
                delete woliDeleteList;
                //clear the delete list
                woliDeleteList.clear();
            }

            //Referesh lists
            woliDTList = getWOLIDTList(woId);
            woliCFList = getWOLICFList(woId);
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Work Order Line Items updated successfully!'));

                 
        }catch(Exception e){
            System.debug('Error Message ->'+e.getMessage());
            System.debug('Error Line Number ->'+e.getLineNumber());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
            Database.rollback(sp);
            return null;
        }

        return null;
    }

    //Function to return Deliver To Work Order Line Item list
    public List<WorkOrderLineItem> getWOLIDTList(Id woId){

        woliDTList = [  SELECT Id, WorkOrderId, Task__c, Product__c, Requested_Quantity__c, Deliver_To_Work_Order__c, Deliver_To_Dock_Number__c, 
                        Collect_From_Work_Order__c, Collect_From_Work_Order__r.Location.Name, Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime 
                        FROM WorkOrderLineItem  
                        WHERE Deliver_To_Work_Order__c = :woId 
                        ORDER BY Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime];
        
        return woliDTList;
    }

    //Function to return Collect From Work Order Line Item list
    public List<WorkOrderLineItem> getWOLICFList(Id woId){

        woliCFList = [  SELECT Id, WorkOrderId, Task__c, Product__c, Requested_Quantity__c, Collect_From_Work_Order__c, Collect_From_Dock_Number__c, 
                        Deliver_To_Work_Order__c, Deliver_To_Work_Order__r.Location.Name, Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime 
                        FROM WorkOrderLineItem  
                        WHERE Collect_From_Work_Order__c = :woId 
                        ORDER BY Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime];
        
        return woliCFList;
    }    
    
    //performs the keyword search
    public PageReference search() {
        runSearch();
        return null;
    }

    public void runSearch() {    
        relatedWOList = performSearch(searchString);
    } 
    
    //Run the search and return a list of collect and deliver work orders for the current duty run segment
    public List<Schema.WorkOrder> performSearch(string searchString) {
        
        System.debug('searchString = ' + searchString);
        
        String taskType;
        Set<String> saIdAllSet;
        Set<String> saIdSet;
        ServiceAppointment objSA;
        List<AssignedResource> assResList;
        Id assResSRId;
        List<AssignedResource> assSAList;
        List<WorkOrder> dutyWOList;
        Datetime saStartDateTime; 
        Datetime startDateTime;
        Datetime endDateTime;
        
        saIdSet = new Set<String>();
        saIdAllSet = new Set<String>();
        
        //Get the Service Appointment Id passed from the Edit Job page and the task type (i.e. Collect or Deliver)
        selectedSAId = Apexpages.currentPage().getParameters().get('said');
        taskType = Apexpages.currentPage().getParameters().get('task');
        System.debug('selectedSAId = '+ selectedSAId);
        
        //If an SA passed
        if(selectedSAId != null){
            
            objSA = [SELECT Id, SchedStartTime, Work_Order__c FROM ServiceAppointment WHERE Id = :selectedSAId];
           	
           	//Get the selected SA start time
            saStartDateTime = objSA.SchedStartTime;
            
            //Start start time range to get SAs either side of selected record
            startDateTime = saStartDateTime.addHours(-15);  
            endDateTime = saStartDateTime.addHours(15);  
            
            //Get all resources assigned to the SA
            assResList = [SELECT ServiceResourceId, ServiceResource.DutyStartTime__c, ServiceResource.ResourceType  
                            FROM AssignedResource 
                            WHERE ServiceAppointmentId = :selectedSAId];
            
            //Loop through the assigned resources
            for(AssignedResource assRes : assResList){
                //If one of the assigned resources is a Crew (i.e a Duty SR)
                if(assRes.ServiceResource.ResourceType == 'C'){
                    //Then use this and end
                    assResSRId = assRes.ServiceResourceId;
                    break;
                }
                //else use the driver assigned
                assResSRId = assRes.ServiceResourceId;
            }
			
            //Get list of WOs for the selected Duty (or Driver if only assigned) to display as options to select as either a collect from or deliver to
            //Get within a rough time range to ensure all retrieved for entire duty period
            assSAList = [SELECT ServiceAppointmentId, ServiceAppointment.SchedStartTime, ServiceAppointment.Work_Order__r.Id, 
                         ServiceAppointment.Work_Order__r.Subject, ServiceAppointment.Work_Order__r.RecordType.DeveloperName, 
                         ServiceAppointment.Work_Order__r.IsRestBreak__c 
                        FROM AssignedResource 
                        WHERE ServiceResourceId = :assResSRId 
                        AND ServiceAppointment.SchedStartTime > :startDateTime 
                        AND ServiceAppointment.SchedStartTime < :endDateTime 
                        ORDER BY ServiceAppointment.SchedStartTime ASC];
            
            //loop thru list and get only SAs for 'run' for duty day  (i.e. all between the FFD or RV* prior to the selected SA and the RV after )
            	//*e.g. for a duty with RV midway through
            Boolean encounteredSelected = false;
            Boolean runStarted = false;
            String recordTypeString;
            for(AssignedResource assSA : assSAList){
                
                recordTypeString = assSA.ServiceAppointment.Work_Order__r.RecordType.DeveloperName;
                
                //If FFD and encounteredSelected false - then clear saSet and set flag runStarted to true (i.e. may now be at start of run)
                if(recordTypeString == 'Fit_For_Duty' && encounteredSelected == false){
                    runStarted = true;
                }
                //IF RV and encounteredSelected false - then clear saIdSet and set flag runStarted to false (i.e. at end of run that finished before the selected SA - so reset)
                else if(recordTypeString == 'Return_Vehicle' && encounteredSelected == false){
                    saIdSet.clear();
                    runStarted = false;
                }
                //If RV and encounteredSelected true - then end (i.e. reached the end of the run)
                else if(recordTypeString == 'Return_Vehicle' && encounteredSelected == true){
                    break;
                }
                //If Standard WO and not a restbreak (i.e. a collect or deliver)
                else if(recordTypeString == 'Standard' && assSA.ServiceAppointment.Work_Order__r.IsRestBreak__c == false){
                                       
                    //If the task is collect for and we have encountered the selected record, or if its a Deliver and we have not encountered the selected job
                    if((taskType == 'CF' && encounteredSelected == true) || (taskType == 'DT' && encounteredSelected == false)){
                            //Add to All set as a fallback in case Duty has no FFD scheduled 
                    		saIdAllSet.add(assSA.ServiceAppointmentId);
                    }
                    
                    //If runStarted
                    if(runStarted == true){
                        //If its a Collect and we have encountered the selected job (i.e collect tasks can only deliver to jobs after themselves), OR
                        //If its a Deliver and we have not encountered the selected job (i.e deliver tasks can only collect from jobs prior)
                        if((taskType == 'CF' && encounteredSelected == true) || (taskType == 'DT' && encounteredSelected == false)){
                            //Then add to saSet	
                            saIdSet.add(assSA.ServiceAppointmentId);
                        }
                    }
                    
                    //If is selected SA then set flag encounteredSelected to true 
                    if(assSA.ServiceAppointmentId == selectedSAId){
                        encounteredSelected = true;
                    }
                }
            }
            
            //If no records in set, then duty probably has not FFD, so just return all collect delivers to display
            if(saIdSet.size() == 0){
                saIdSet.addAll(saIdAllSet);
            }

            //Could add search condition here if required. Would need to:
            //-expose the search section on the custom lookup page 
            //-change the dutyWOList build below using queryString
            
            //Now get all WO for these COL/DEL WORK ORDERS
            dutyWOList = [SELECT Id, WorkOrderNumber, Location.Name, Activity_Type__c, Subject, StartDate, Primary_SA__r.SchedStartTime 
                          FROM WorkOrder WHERE Primary_SA__c IN :saIdSet AND ID != :objSA.Work_Order__c 
                         ORDER BY StartDate ASC];

        }
        
        //Return list for display in lookup
		return dutyWOList;
    }

}