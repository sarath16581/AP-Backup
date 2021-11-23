/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-06-29
* @domain Field Service 
* @description  Controller for the Scheduled to Duty VFP, called as a mass action from the FSL Gantt
*
* @changelog 
* 2020-06-29 - Andrew Judd - Created 
* 2020-09-05 - Andrew Judd - Added support to call from gantt action (selecting service appointments in the gantt)
*/
public class TDF_ScheduleToDutyController {

    public Id selectedDutyId{get;set;}
    public Id territoryId{get;set;}
    
    public String selectedDutyForAssignment{get;set;}
    public List<SelectOption> dutyToAssignSelectList{get;set;}
    public List<SelectOption> dutySelectList{get;set;}

    public String selectedSAIds{get;set;}
    public String selectedSAId{get;set;}

    public List<ServiceAppointment> saList{get;set;}
    
    public TDF_ScheduleToDutyController(){
        
        //Initialization
        selectedSAIds = Apexpages.currentPage().getParameters().get('services');
        selectedSAId = Apexpages.currentPage().getParameters().get('id');
        System.System.debug('selectedSAIds = ' + selectedSAIds);
        System.System.debug('selectedSAId = ' + selectedSAId);

        Map<String, String> srMap = new Map<String, String>(); 
        selectedDutyForAssignment = '';
        dutyToAssignSelectList = new List<SelectOption>(); 
        dutyToAssignSelectList.add(new SelectOption('','--- None ---'));
        dutySelectList = new List<SelectOption>(); 

        String[] selectedSAIdsArray = new List<String>();

        System.debug('selectedSAIds = ' + selectedSAIds);

        //If no SAs checked
        if(selectedSAId == null && selectedSAIds == ''){
            //Display message and close
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No Service Appointments selected for assignment.'));
        }
        //else if single checked
        else if(selectedSAId != null){
            //add single id to the array
            selectedSAIdsArray.add(selectedSAId);
        }
        //else if muliti checked
        else if(selectedSAIds != ''){
            //Add all records to array
            selectedSAIdsArray = selectedSAIds.split(',');
        }

        //If one or more SAs selected
        if(selectedSAIdsArray.size() > 0){

            //Get list of service appointments not in Dispatched or In Progress status
            //-Dispatched SAs can not be moved due to validation being performed on the Dispatch Work event
            //-In Progress SAs need to remain with current driver on duty
            saList =    [SELECT Id, SchedStartTime, Duration, SchedEndTime, ServiceTerritoryId, EarliestStartTime, DueDate 
                        FROM ServiceAppointment 
                        WHERE Id IN : selectedSAIdsArray 
                        AND Status != 'Dispatched' AND Status != 'In Progress' AND Status != 'Completed' LIMIT 100];

            //If no valid SAs to assign            
            if(saList.size() == 0){
                //Display message and close
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No Service Appointments selected for assignment. <br/> Dispatched, In Progress and Completed jobs can not be reassigned. <br/> To reassign Dispatched jobs change status to Scheduled.'));
            }
            //Some valid records selected
            else{

                //Get the Service Territory of the first record.  
                territoryId = saList[0].ServiceTerritoryId;

                //Get all active Dutys for the ST
                for(ServiceTerritoryMember objSTM : [SELECT ServiceResourceId, ServiceResource.Name 
                                                        FROM ServiceTerritoryMember 
                                                        WHERE TerritoryType = 'P' 
                                                        AND ServiceTerritoryId = :territoryId  
                                                        AND ServiceResource.ResourceType = 'C' 
                                                        AND ServiceResource.IsActive = true            
                                                        ORDER BY ServiceResource.Name ASC LIMIT 1000]){
                    srMap.put(objSTM.ServiceResourceId, objSTM.ServiceResource.Name);
                }

                //Add dutys to duty select list
                for(String srId : srMap.keySet()){
                    dutySelectList.add(new SelectOption(srId, srMap.get(srId)));
                }
            
                //Add to duty select list        
                dutyToAssignSelectList.addAll(dutySelectList);
            }
        }
    }

    //Performs the assignment
    public PageReference scheduleToDuty() {
        
        List<AssignedResource> assResList = new List<AssignedResource>(); //change name to assResListNew
        List<AssignedResource> assResListInsert = new List<AssignedResource>();
        List<AssignedResource> assResListUpdate = new List<AssignedResource>();
        List<ServiceAppointment> saListUpdate = new List<ServiceAppointment>();
        
        Map<Id,AssignedResource> saIdToAssResDutyMap = new Map<Id,AssignedResource>();
        Map<Id,AssignedResource> saIdToAssResDriverMap = new Map<Id,AssignedResource>();
        Set<Id> saIdSet = new Set<Id>();

        //Get sas in Set
        for(ServiceAppointment sa : saList){
            saIdSet.add(sa.Id);
        }

        if(selectedDutyForAssignment == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select a Duty to assign to.'));
            return null;
        }
        else{

            //Declare the SavePoint
            Savepoint sp;

                try{
                    //Set savepoint
                    sp = Database.setSavepoint();

                    //Get all assignments for valid Service Appointments
                    assResList = [SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.ResourceType FROM AssignedResource 
                                        WHERE ServiceAppointmentId IN :saIdSet];

                    //Get all Assigned Resource records for the Service Appointments
                    for(AssignedResource assRes : assResList){
                        //If a duty assignment (i.e. resource type is a Crew)
                        if(assRes.ServiceResource.ResourceType == 'C'){
                            //Add to duty assignment map
                            saIdToAssResDutyMap.put(assRes.ServiceAppointmentId, assRes);
                        }
                        else{
                            //Add to driver assignment map
                            saIdToAssResDriverMap.put(assRes.ServiceAppointmentId, assRes);
                        }
                    }

                    //Assign all Service Appointments
                    for(ServiceAppointment saRec : saList){

                        //If the Service Appointment is already assigned to a duty (i.e. function selected from scheduled SAs in the Gantt)
                        if(saIdToAssResDutyMap.containsKey(saRec.Id)){

                            //Then change the SR of the Assigned Resource record to the duty, add keep driver as is (mananged package will update driver)
                            saIdToAssResDutyMap.get(saRec.Id).ServiceResourceId = selectedDutyForAssignment; 
                            assResListUpdate.add(saIdToAssResDutyMap.get(saRec.Id));
                        }
                        //Else if the Service Appointment is already assigned to just a driver (i.e. non duty based scenario)
                        else if(saIdToAssResDriverMap.containsKey(saRec.Id)){

                            //Then change the SR of the Assigned Resource record to the duty
                            saIdToAssResDriverMap.get(saRec.Id).ServiceResourceId = selectedDutyForAssignment;
                            assResListUpdate.add(saIdToAssResDriverMap.get(saRec.Id)); 
                        }
                        //Else the Appointment is not currently assigned to a duty or a driver
                        else{
                            
                            //Set scheduled start and end based on the earliest start and duration
                            saRec.SchedStartTime = saRec.EarliestStartTime;
                            saRec.SchedEndTime = saRec.SchedStartTime.addMinutes(Integer.valueOf(saRec.Duration));
                            saListUpdate.add(saRec);

                            //Create an assignment record
                            AssignedResource assResRec = new AssignedResource();
                            assResRec.ServiceAppointmentId = saRec.Id;
                            assResRec.ServiceResourceId = selectedDutyForAssignment;
                            assResListInsert.add(assResRec);
                        }
                    }

                    //Apply changes
                    if(saListUpdate.size() > 0){
                        update saListUpdate;
                    }
                    if(assResListInsert.size() > 0){
                        insert assResListInsert;
                    }
                    if(assResListUpdate.size() > 0){
                        update assResListUpdate;
                    }
                }
                catch(Exception e){
                    
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));            
                    System.debug('Exception Occured : '+e.getMessage());
                    System.debug('Exception Occured : '+e.getStackTraceString());

                    // Rollback to save point
                    Database.rollback( sp );
                    return null;
                }

            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'The Service Appointments (' + saList.size() + ') have been assigned to the Duty!' ));
            saList.clear();
            assResList.clear();
            return null;
        }
    }
}