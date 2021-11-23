/**
* @author Andrew Judd ajudd@salesforce.com
* @date 2020-07-01
* @domain Field Service
* @description New class to replace duplicated versions of the same logic to generate work from duty templates
*               Based of code originally in TDF_GenerateWorkOrderFRomDBT_ControllerX
*               Logic has been modified to support:
*                   -connected data model (where collect and deliver task templates and Work Order Line Items are related)
*                   -resource by duty solution (Crew based)
*                   -additional controls, including Effective and Expiry date at Job Template level, Operational Duty assignment
*                   -at Duty and Job Template level, not creating task, or job, if null requested quantities specified
*               Called from Duty Template, Job Template, Create Adhoc Job, Dispatch Board, Generate Work FSL Gantt Action and Scheduled Generate Work
*
* @changelog
* 2020-07-01 - Andrew Judd  - Created
* 2021-09-10 - Keerthi Akul - Fixes for timezone issue, updated code related to TDF_WorkOrderUtility.createStartDateTime()
*                             method calls.
*/
public with sharing class TDF_GenerateWork {

    Public Map<String,List<Task_Template__c>> jobTemplateTasksCollectMap;
    Public Map<String,List<Task_Template__c>> jobTemplateTasksDeliverMap;

    //Method to create jobs
    //Job Template Id used when called from job template to create only for that one
    public String createJobs(Date startDate, Date endDate, String jobBoardTemplateId, String jobTemplateId){

        Map<String,String> workOrderMappingMap;
        Map<String,String> workOrderLIMappingMap;
        Map<String,String> serviceAppointmentMappingMap;

        //New map to create a connected WOLI for each task and duty day
        Map<String,WorkOrderLineItem> taskDutyDayWOLIMap;

        //New map to get the wo based on a job template and duty day
        Map<String,String> jtDutyDayToWOIdMap;

        List<Route_Assignment__c> jbAssignmentList;
        RecordType workOrderRecordType;
        Map<String, String> workOrderRecordTypeMap;

        List<WorkOrder> workOrderList;
        List<ServiceAppointment> serviceAppointmentList;
        List<AssignedResource> assignedResourceList;

        String serviceResourceIdString;

        workOrderMappingMap = new Map<String,String>();
        workOrderLIMappingMap = new Map<String,String>();
        workOrderRecordTypeMap = new Map<String, String>();
        workOrderList = new List<WorkOrder>();
        serviceAppointmentList = new List<ServiceAppointment>();
        assignedResourceList = new List<AssignedResource>();
        serviceAppointmentMappingMap = new Map<String,String>();
        jobTemplateTasksCollectMap = new Map<String,List<Task_Template__c>>();
        jobTemplateTasksDeliverMap = new Map<String,List<Task_Template__c>>();

        Route_Template__c objDutyTemplate = new Route_Template__c();

        taskDutyDayWOLIMap = new Map<String,WorkOrderLineItem>();
        jtDutyDayToWOIdMap = new Map<String,String>();

        //Get duty template record
        objDutyTemplate = [SELECT Id, Name, Status__c, Service_Territory__c, Default_Vehicle__c, Effective_Date__c, Expiry_Date__c, Duty_SR__c
        FROM Route_Template__c
        WHERE Id =: jobBoardTemplateId];

        //get Standard WorkOrder RecordType
        workOrderRecordType = [SELECT id, name FROM RecordType WHERE sobjectType = 'WorkOrder' AND Name = 'Standard' limit 1];
        workOrderRecordTypeMap = TDF_WorkOrderUtility.workOrderRecordTypeMap();

        //#Initial Duty Level validation
        //1. Check that no jobs have connected tasks assigned to different operational duties
        Set<String> ttWithOpDutyMisalignSet = new Set<String>();
        List<Task_Template__c> ttList = new List<Task_Template__c>();

        //If called for a full duty template create
        if(jobTemplateId != null){
            //Get list of all task templates
            ttList = [SELECT Id, Name, Collect_From_Job_Template__r.Assigned_Duty_SR_Id__c, Deliver_To_Job_Template__r.Assigned_Duty_SR_Id__c
            FROM Task_Template__c
            WHERE DTID__c = :jobBoardTemplateId];
        }

        //Loop thru list and ensure no linked task has different operational duties
        for(Task_Template__c tt : ttList){
            //if both not null
            if(tt.Collect_From_Job_Template__r.Assigned_Duty_SR_Id__c != null && tt.Deliver_To_Job_Template__r.Assigned_Duty_SR_Id__c != null){
                //if they are not the same
                if(tt.Collect_From_Job_Template__r.Assigned_Duty_SR_Id__c != tt.Deliver_To_Job_Template__r.Assigned_Duty_SR_Id__c){
                    //Then record as error
                    ttWithOpDutyMisalignSet.add(tt.Name);
                }
            }
        }
        //Clear task template list
        ttList.clear();

        //If operational duty override misalignment detected
        if(ttWithOpDutyMisalignSet.size()>0){
            return 'The following connected task templates have jobs assigned to different operational duties ' + ttWithOpDutyMisalignSet + '. Please resolve this before generating work.';
        }

        //To prepare dynamic query for Job Template and its related Task Templates
        DescribeSObjectResult describeResult = Job_Template__c.getSObjectType().getDescribe();
        DescribeSObjectResult describeTaskTempResult = Task_Template__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        List<String> taskTempFields = new List<String>(describeTaskTempResult.fields.getMap().keySet());

        String query = ' SELECT ' + String.join( fieldNames, ',' );
        query += ', Location__r.TimeZone, Location__r.Name, Location__r.Node_Type__c, Route_Template__r.VehicleType__c';
        //query += ',(SELECT '+String.join(taskTempFields,',')+' FROM Task_Templates__r)'; //Removed due to change in data model
        query += ',(SELECT '+String.join(taskTempFields,',') +' FROM Collect_Task_Templates__r)'; //*AJ Add to get new collect task templates
        query += ',(SELECT '+String.join(taskTempFields,',') +' FROM Deliver_Task_Templates__r)'; //*AJ Add to get new deliver task templates
        query += ' FROM ' + describeResult.getName();
        //If not for just a single job template
        if(jobTemplateId == null){
            //constrain by Duty Template
            query += ' WHERE Route_Template__c = \''+String.escapeSingleQuotes(jobBoardTemplateId)+'\'';
        }
        else{
            //else constrain by Job Template
            query += ' WHERE Id = \''+string.escapeSingleQuotes(jobTemplateId)+'\'';
        }

        System.debug('Query '+query);
        //Get all job templates for duty, or by jt id
        Map<Id,Job_Template__c> jobTemplateMap = new Map<Id,Job_Template__c>((List<Job_Template__c>)Database.query(query));

        //If no job templates found
        if(jobTemplateMap.size() == 0){
            //return message
            return 'No Job Template found';
        }

        //System.debug('AJJ jobTemplateMap = ' + jobTemplateMap);

        Map<String,Set<String>> jtToDaysWithQtyMap = new Map<String,Set<String>>();
        String daysString;
        Integer intDay;
        Set<String> daysStringSet;

        //Populate map of job template and its tasks for reference of WorkOrderLineItem creation
        for(Job_Template__c objJobTemplate : jobTemplateMap.values()){

            jobTemplateTasksCollectMap.put(objJobTemplate.Id,objJobTemplate.Collect_Task_Templates__r);
            jobTemplateTasksDeliverMap.put(objJobTemplate.Id,objJobTemplate.Deliver_Task_Templates__r);

            //Here create a Map of Job Templates with quantity indicator by day
            //Since we dont want to create a WO for a JT where all its tasks for the day are null
            //-do for collect tasks
            daysStringSet = new Set<String>();
            for(Task_Template__c tt : objJobTemplate.Collect_Task_Templates__r){

                if(tt.Monday__c != null)    daysStringSet.add('Mon');
                if(tt.Tuesday__c != null)   daysStringSet.add('Tue');
                if(tt.Wednesday__c != null) daysStringSet.add('Wed');
                if(tt.Thursday__c != null)  daysStringSet.add('Thu');
                if(tt.Friday__c != null)    daysStringSet.add('Fri');
                if(tt.Saturday__c != null)  daysStringSet.add('Sat');
                if(tt.Sunday__c != null)    daysStringSet.add('Sun');
            }
            //-do for deliver tasks
            for(Task_Template__c tt : objJobTemplate.Deliver_Task_Templates__r){

                if(tt.Monday__c != null)    daysStringSet.add('Mon');
                if(tt.Tuesday__c != null)   daysStringSet.add('Tue');
                if(tt.Wednesday__c != null) daysStringSet.add('Wed');
                if(tt.Thursday__c != null)  daysStringSet.add('Thu');
                if(tt.Friday__c != null)    daysStringSet.add('Fri');
                if(tt.Saturday__c != null)  daysStringSet.add('Sat');
                if(tt.Sunday__c != null)    daysStringSet.add('Sun');
            }

            //Add the daysStringSet to the map for the JT
            jtToDaysWithQtyMap.put(objJobTemplate.Id,daysStringSet);

        }

        //If Operational Duty not assigned (for new Crew based solution)
        if(objDutyTemplate.Duty_SR__c == null){
            // Query job board assignment to assign it to service resource of assigned resource (for Legacy driver assignment solution)
            jbAssignmentList = [SELECT Id,Service_Resource__c,Start_Date__c,End_Date__c FROM Route_Assignment__c WHERE Duty_Board__c =: jobBoardTemplateId];
        }

        // Populate maps for dynamic mapping from custom meta datatype
        for(Object_Mapping__mdt objWorkMapping : [SELECT id,MasterLabel,Source__c,Destination__c FROM Object_Mapping__mdt]){

            //Mapping from custom metadata type for  Job template and work order
            if(objWorkMapping.Source__c.split('\\.')[0]=='Job_Template__c' && objWorkMapping.Destination__c.split('\\.')[0]=='WorkOrder'){
                workOrderMappingMap.put(objWorkMapping.Source__c.split('\\.')[1],objWorkMapping.Destination__c.split('\\.')[1]);
            }
            //Mapping from custom metadata type for  Task template and work order line item
            if(objWorkMapping.Source__c.split('\\.')[0]=='Task_Template__c' && objWorkMapping.Destination__c.split('\\.')[0]=='WorkOrderLineItem'){
                workOrderLIMappingMap.put(objWorkMapping.Source__c.split('\\.')[1],objWorkMapping.Destination__c.split('\\.')[1]);
            }
            //Mapping from custom metadata type for  work order and Service appointment
            //WARNING - Ensure mapping of ServiceTerritory is removed as it is not required (set from parent) and causes a ROW_LOCK conflict
            if(objWorkMapping.Source__c.split('\\.')[0]=='WorkOrder' && objWorkMapping.Destination__c.split('\\.')[0]=='ServiceAppointment'){
                serviceAppointmentMappingMap.put(objWorkMapping.Source__c.split('\\.')[1],objWorkMapping.Destination__c.split('\\.')[1]);
            }
        }

        //AJ 26.06.18 Adjust start and end dates to align with Duty Template Effective and Expiry Dates
        //If Effective Date not null, then if start date is before effective date, then change it to effective date
        if(objDutyTemplate.Effective_Date__c != null){
            if(startDate < objDutyTemplate.Effective_Date__c){
                startDate = objDutyTemplate.Effective_Date__c;
            }
        }

        //If Expiry Date not null, then if end date is on or after expiry date, then change it to day before expiry date
        if(objDutyTemplate.Expiry_Date__c != null){
            if(endDate >= objDutyTemplate.Expiry_Date__c){
                endDate = objDutyTemplate.Expiry_Date__c.addDays(-1);
            }
        }

        //Calculate the days difference in Start and End date selected by User
        Integer daysDifference = startDate.daysBetween(endDate);

        Integer count = 0;

        //To create Work order from Job template for selected date range
        while(count <= daysDifference){

            //Get day of current date
            String dayOfDate = TDF_WorkOrderUtility.getDayOfDate(startDate).substring(0,3);

            //Iterate Job template for work order creation
            //xfor(Job_Template__c objJobTemplate : jobTemplateList){
            for(Job_Template__c objJobTemplate : jobTemplateMap.values()){

                //If the duty template is active for this day based on active days flags
                if(objJobTemplate.Active_Route_Days__c != null && objJobTemplate.Active_Route_Days__c.contains(dayOfDate)){

                    //^^If JT is active for this day based on effective date - if date populated ensure process date is on or after
                    if(objJobTemplate.Effective_Date__c == null || (startDate >= objJobTemplate.Effective_Date__c)){

                        //^^If JT is active for this day based on expiry date - if date populated ensure process date is before
                        if(objJobTemplate.Expiry_Date__c == null || (startDate < objJobTemplate.Expiry_Date__c)){

                            //If a collect/deliver Job Template and it does not have any tasks with Quantity on this day
                            //NOTE all other collect/deliver task types should be removed from picklist
                            if( (objJobTemplate.Activity_Type__c    == 'Collection' ||
                                    objJobTemplate.Activity_Type__c     == 'Delivery' ||
                                    objJobTemplate.Activity_Type__c     == 'Delivery & Collection') &&
                                    jtToDaysWithQtyMap.get(objJobTemplate.Id).contains(dayOfDate) == false){
                                //Then skip
                            }
                            //Else create a work order as per JT
                            else{

                                WorkOrder objWorkOrder = new WorkOrder();

                                //Map start time of Job template with current date for start date of work order
                                if(objJobTemplate.Next_Day_Job__c){
                                    if(objJobTemplate.Location__r.TimeZone != null){
                                        objWorkOrder.StartDate = TDF_WorkOrderUtility.createStartDateTime(startDate.addDays(1), objJobTemplate.Location__r.TimeZone, objJobTemplate.Start_Time__c);
                                    }else{
                                        objWorkOrder.StartDate = TDF_WorkOrderUtility.createStartDateTime(startDate.addDays(1), UserInfo.getTimeZone().getID(), objJobTemplate.Start_Time__c);
                                    }
                                    //objWorkOrder.Duty_Day__c = objWorkOrder.StartDate.date().addDays(-1);
                                }else{
                                    if(objJobTemplate.Location__r.TimeZone != null){
                                        objWorkOrder.StartDate = TDF_WorkOrderUtility.createStartDateTime(startDate, objJobTemplate.Location__r.TimeZone, objJobTemplate.Start_Time__c);
                                    }else{
                                        objWorkOrder.StartDate = TDF_WorkOrderUtility.createStartDateTime(startDate, UserInfo.getTimeZone().getID(), objJobTemplate.Start_Time__c);
                                    }
                                    //objWorkOrder.Duty_Day__c = objWorkOrder.StartDate.date();
                                }
                                // Timezone issue fix start here
                                 objWorkOrder.Duty_Day__c = startDate;
                                //Timezone issue fix end here
                                objWorkOrder.Duration = Integer.valueOf(objJobTemplate.Duration__c);
                                objWorkOrder.EndDate = objWorkOrder.StartDate.addMinutes(Integer.valueOf(objJobTemplate.Duration__c));

                                if(objDutyTemplate.Service_Territory__c != null){
                                    objWorkOrder.ServiceTerritoryId = objDutyTemplate.Service_Territory__c;
                                }

                                //Mappings of work order from workOrderMappingMap map created
                                for(String objsourceKey : workOrderMappingMap.keySet()){
                                    objWorkOrder.put(workOrderMappingMap.get(objsourceKey),objJobTemplate.get(objsourceKey));
                                }

                                objWorkOrder.Subject = objJobTemplate.Location__r.Name + ' - ' + objJobTemplate.Activity_Type__c;

                                /*Assign Work Order Record Type based on Vehicle and Activity type Begin */
                                if(objJobTemplate.Activity_Type__c != null && objJobTemplate.Activity_Type__c != ''){

                                    //AJ 25.06.18 Changed Meal Break to Rest Break
                                    if(objJobTemplate.Activity_Type__c == 'Rest Break'){
                                        objWorkOrder.IsRestBreak__c = true;
                                    }

                                    if(objJobTemplate.Route_Template__r.VehicleType__c != null){

                                        if(objJobTemplate.Activity_Type__c == 'Prepare Vehicle'){

                                            if(objJobTemplate.Route_Template__r.VehicleType__c == 'Prime Mover'){

                                                objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('PDC_PrimeMover');

                                                if(objDutyTemplate.Default_Vehicle__c != null){
                                                    objWorkOrder.Vehicle__c = objDutyTemplate.Default_Vehicle__c;
                                                }

                                            }else if(objJobTemplate.Route_Template__r.VehicleType__c == 'Rigid'){

                                                objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('PDC_Rigid');

                                                if(objDutyTemplate.Default_Vehicle__c != null){
                                                    objWorkOrder.Vehicle__c = objDutyTemplate.Default_Vehicle__c;
                                                }
                                            }
                                        }

                                    }else{

                                        if(objJobTemplate.Activity_Type__c == 'Prepare Vehicle'){

                                            objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('PDC_Rigid');

                                            if(objDutyTemplate.Default_Vehicle__c != null){
                                                objWorkOrder.Vehicle__c = objDutyTemplate.Default_Vehicle__c;
                                            }
                                        }
                                    }

                                    if(objJobTemplate.Activity_Type__c == 'Prepare Trailer'){
                                        objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('PDC_Trailer');

                                    }else if(objJobTemplate.Activity_Type__c == 'Drop Trailer'){
                                        objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('Drop_Off_Trailer');

                                    }else if(objJobTemplate.Activity_Type__c == 'Return Vehicle' || objJobTemplate.Activity_Type__c == 'Return & Refuel Vehicle'){
                                        objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('Return_Vehicle');

                                    }else if(objJobTemplate.Activity_Type__c == 'Fit For Duty'){
                                        objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('Fit_For_Duty');

                                    }else if(objJobTemplate.Activity_Type__c != 'Prepare Vehicle' && objJobTemplate.Activity_Type__c != 'Prepare Trailer' && objJobTemplate.Activity_Type__c != 'Drop Trailer' && objJobTemplate.Activity_Type__c != 'Return Vehicle' && objJobTemplate.Activity_Type__c != 'Return & Refuel Vehicle' && objJobTemplate.Activity_Type__c != 'Fit For Duty' && objJobTemplate.Activity_Type__c != 'Fit For Duty'){
                                        objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('Standard');

                                    }

                                }else{
                                    objWorkOrder.RecordTypeId = workOrderRecordTypeMap.get('Standard');
                                }
                                /*Assign Work Order Record Type based on Vehicle and Activity type End */

                                // Add into Work Order list
                                workOrderList.add(objWorkOrder);

                            }  //end else jt has task or is not collect/deliver
                        } //end jt is active based on expiry date
                    } //end jt is active based on effective date
                } //end dt active for this day
            }
            // Increment start date till end date
            startDate=startDate.addDays(1);
            count++;
        }

        System.debug('workOrderList ->'+workOrderList + ' Size ->'+workOrderList.size());
        // Insert Work Orders
        if(workOrderList.size()>0){
            insert workOrderList;
        }

        // Create Service Appointment and Work Order Line Item from Work Order
        for(WorkOrder objWO : TDF_WorkOrderUtility.getWOListWithTimeZone(workOrderList)){

            ServiceAppointment objServiceAppointment = new ServiceAppointment();
            objServiceAppointment.Duty_Board__c = jobBoardTemplateId;
            objServiceAppointment.SchedStartTime = objWO.StartDate;
            objServiceAppointment.Duration = Integer.valueOf(objWO.Duration);
            objServiceAppointment.SchedEndTime = objServiceAppointment.SchedStartTime.addMinutes(Integer.valueOf(objWO.Duration));
            objServiceAppointment.FSL__GanttLabel__c = objDutyTemplate.Name + ' - ' + objWO.Job_Template__r.Location__r.Name + ' - ' + objWO.Job_Template__r.Activity_Type__c;
            objServiceAppointment.Subject = objWO.Job_Template__r.Location__r.Name + ' - ' + objWO.Job_Template__r.Activity_Type__c;
            objServiceAppointment.Description = objWO.Job_Template__r.Description__c;
            objServiceAppointment.DurationType = 'Minutes';
            objServiceAppointment.Work_Order__c = objWO.Id;

            //Set custom work order lookup
            objServiceAppointment.Work_Order__c = objWO.Id;

            if(objWO.Job_Template__r.Earliest_Start_Time__c != null){
                if(objWO.Job_Template__r.Location__r.TimeZone != null){
                   // objServiceAppointment.EarliestStartTime = TDF_WorkOrderUtility.createStartDateTime(objWO.StartDate.date(), objWO.Job_Template__r.Location__r.TimeZone, objWO.Job_Template__r.Earliest_Start_Time__c);
                    objServiceAppointment.EarliestStartTime = TDF_WorkOrderUtility.createStartDateTime(objWO.Duty_Day__c, objWO.Job_Template__r.Location__r.TimeZone, objWO.Job_Template__r.Earliest_Start_Time__c);
                }else{
                   // objServiceAppointment.EarliestStartTime = TDF_WorkOrderUtility.createStartDateTime(objWO.StartDate.date(), UserInfo.getTimeZone().getID(), objWO.Job_Template__r.Earliest_Start_Time__c);
                   objServiceAppointment.EarliestStartTime = TDF_WorkOrderUtility.createStartDateTime(objWO.Duty_Day__c, UserInfo.getTimeZone().getID(), objWO.Job_Template__r.Earliest_Start_Time__c);
                }
            }else{
                objServiceAppointment.EarliestStartTime = objWO.StartDate;
            }

            if(objWO.Job_Template__r.Latest_Start_Time__c != null){
                if(objWO.Job_Template__r.Location__r.TimeZone != null){
                   // objServiceAppointment.DueDate = TDF_WorkOrderUtility.createStartDateTime(objWO.StartDate.date(), objWO.Job_Template__r.Location__r.TimeZone, objWO.Job_Template__r.Latest_Start_Time__c).addMinutes(Integer.valueOf(objWO.Job_Template__r.Duration__c));
                   objServiceAppointment.DueDate = TDF_WorkOrderUtility.createStartDateTime(objWO.Duty_Day__c, objWO.Job_Template__r.Location__r.TimeZone, objWO.Job_Template__r.Latest_Start_Time__c).addMinutes(Integer.valueOf(objWO.Job_Template__r.Duration__c));
                }else{
                    //objServiceAppointment.DueDate = TDF_WorkOrderUtility.createStartDateTime(objWO.StartDate.date(), UserInfo.getTimeZone().getID(), objWO.Job_Template__r.Latest_Start_Time__c).addMinutes(Integer.valueOf(objWO.Job_Template__r.Duration__c));
                    objServiceAppointment.DueDate = TDF_WorkOrderUtility.createStartDateTime(objWO.Duty_Day__c, UserInfo.getTimeZone().getID(), objWO.Job_Template__r.Latest_Start_Time__c).addMinutes(Integer.valueOf(objWO.Job_Template__r.Duration__c));
                }
            }else{
                objServiceAppointment.DueDate = objServiceAppointment.SchedEndTime;
            }

            //AJ 27.06.18 Set Rest Break colour as blue
            if(objWO.IsRestBreak__c == true){
                objServiceAppointment.FSL__GanttColor__c = '#0000FF';
            }

            //Mappings of work order from serviceAppointmentMappingMap map created
            for(String objsourceKey : serviceAppointmentMappingMap.keySet()){
                objServiceAppointment.put(serviceAppointmentMappingMap.get(objsourceKey),objWO.get(objsourceKey));
            }

            //Add into Service Appointment list
            serviceAppointmentList.add(objServiceAppointment);

            //Store map of JT Id and Duty Day to WOId - for reference in creation of WOLIs below
            jtDutyDayToWOIdMap.put(objWO.Job_Template__c + string.valueOf(objWO.Duty_Day__c), objWO.Id );

        }//End create SAs

        //Set to store processed task and day. If processed as 'Collect' for the duty day, no need to do again in the 'Deliver' loop for the duty day
        //Set<String> taskTempDayProcessed = new Set<String>();
        String taskIdDutyDay;
        Double reqQty;

        //Create Collect WOLIs
        for(WorkOrder objWO : workOrderList){

            //Get COLLECT task templates of Job template for work order line items creation
            for(Task_Template__c objTaskTemplate : getTaskTemplatesCollectForJobTemplate(objWO.Job_Template__c)){

                //^^If there is a WO created for the task's job template duty day
                if(jtDutyDayToWOIdMap.get(objTaskTemplate.Collect_From_Job_Template__c + string.valueOf(objWO.Duty_Day__c)) != null){

                    //Get day of work order start date
                    String dayofStartDate = TDF_WorkOrderUtility.getDayOfDate(Date.valueOf(objWO.Duty_Day__c)).substring(0,3);

                    //If day exists in task template then create work line item
                    if(objTaskTemplate.Active_Route_Days__c.contains(dayofStartDate)){

                        //Get requested amount of from task template depending upon the day
                        if      (dayofStartDate == 'Mon')   {reqQty = objTaskTemplate.Monday__c;}
                        else if (dayofStartDate == 'Tue')   {reqQty = objTaskTemplate.Tuesday__c;}
                        else if (dayofStartDate == 'Wed')   {reqQty = objTaskTemplate.Wednesday__c;}
                        else if (dayofStartDate == 'Thu')   {reqQty = objTaskTemplate.Thursday__c;}
                        else if (dayofStartDate == 'Fri')   {reqQty = objTaskTemplate.Friday__c;}
                        else if (dayofStartDate == 'Sat')   {reqQty = objTaskTemplate.Saturday__c;}
                        else if (dayofStartDate == 'Sun')   {reqQty = objTaskTemplate.Sunday__c;}

                        //If the task quantity is not null for this day
                        if(reqQty != null){

                            //Create key for map of WOLIs by Task Template Id and Duty Day
                            taskIdDutyDay = objTaskTemplate.Id + string.valueOf(objWO.Duty_Day__c);

                            WorkOrderLineItem objWorkOrderLI;

                            //If map contains record for this task and duty day
                            if(taskDutyDayWOLIMap.containsKey(taskIdDutyDay)){
                                //Get from the map
                                objWorkOrderLI = taskDutyDayWOLIMap.get(taskIdDutyDay);
                            }
                            else{
                                //Create a new record
                                objWorkOrderLI = new WorkOrderLineItem();
                            }

                            //Initially set the primary WO (Master Detail) as one must be set
                            objWorkOrderLI.WorkOrderId = objWO.Id;

                            //However if there is a deliver
                            if(objTaskTemplate.Deliver_To_Job_Template__c != null){
                                //And the deliver job is in the map - it might not be in the map if a connected job is generated standalone
                                if(jobTemplateMap.get(objTaskTemplate.Deliver_To_Job_Template__c) != null){
                                    //And the deliver is for a customer
                                    if(jobTemplateMap.get(objTaskTemplate.Deliver_To_Job_Template__c).Location__r.Node_Type__c == 'Customer'){
                                        //Add there is a work order for this Job Template Duty Day
                                        if(jtDutyDayToWOIdMap.get(objTaskTemplate.Deliver_To_Job_Template__c + string.valueOf(objWO.Duty_Day__c)) != null){
                                            //Then change the primary WO to this (Customer jobs are the primary home for all tasks)
                                            objWorkOrderLI.WorkOrderId = jtDutyDayToWOIdMap.get(objTaskTemplate.Deliver_To_Job_Template__c + string.valueOf(objWO.Duty_Day__c));
                                        }
                                    }
                                }
                            }

                            //Set the Collect From work order field
                            objWorkOrderLI.Collect_From_Work_Order__c = objWO.Id;

                            //Mappings of work order from workOrderLIMappingMap map created
                            for(String objsourceKey : workOrderLIMappingMap.keySet()){
                                objWorkOrderLI.put(workOrderLIMappingMap.get(objsourceKey),objTaskTemplate.get(objsourceKey));
                            }

                            //*AJ Workorder task is now redundant due to change in data model
                            //objWorkOrderLI.Task__c = 'Collect Product';

                            //Set the requested quanity
                            objWorkOrderLI.Requested_Quantity__c = reqQty;

                            // Add into Work Order Line Item list
                            //workOrderLIList.add(objWorkOrderLI);
                            // Add into Work Order Line Item to Map
                            taskDutyDayWOLIMap.put(taskIdDutyDay, objWorkOrderLI);

                        } //end if req qty not null
                    } //end if active duty day
                } //end if wo for jt day
            }
            //Get DELIVER task templates of Job template for work order line items creation
            for(Task_Template__c objTaskTemplate : getTaskTemplatesDeliverForJobTemplate(objWO.Job_Template__c)){

                //^^If there is a WO created for the task's job template duty day
                System.debug('xxx objTaskTemplate '+ objTaskTemplate.Name);
                System.debug('xxx The DT JT ' + jtDutyDayToWOIdMap.get(objTaskTemplate.Deliver_To_Job_Template__c + string.valueOf(objWO.Duty_Day__c)));
                if(jtDutyDayToWOIdMap.get(objTaskTemplate.Deliver_To_Job_Template__c + string.valueOf(objWO.Duty_Day__c)) != null){

                    //Get day of work order start date
                    String dayofStartDate = TDF_WorkOrderUtility.getDayOfDate(Date.valueOf(objWO.Duty_Day__c)).substring(0,3);

                    //If day exists in task template then create work line item
                    if(objTaskTemplate.Active_Route_Days__c.contains(dayofStartDate)){

                        //Get requested amount of from task template depending upon the day
                        if      (dayofStartDate == 'Mon')   {reqQty = objTaskTemplate.Monday__c;}
                        else if (dayofStartDate == 'Tue')   {reqQty = objTaskTemplate.Tuesday__c;}
                        else if (dayofStartDate == 'Wed')   {reqQty = objTaskTemplate.Wednesday__c;}
                        else if (dayofStartDate == 'Thu')   {reqQty = objTaskTemplate.Thursday__c;}
                        else if (dayofStartDate == 'Fri')   {reqQty = objTaskTemplate.Friday__c;}
                        else if (dayofStartDate == 'Sat')   {reqQty = objTaskTemplate.Saturday__c;}
                        else if (dayofStartDate == 'Sun')   {reqQty = objTaskTemplate.Sunday__c;}

                        //If the task quantity is not null for this day
                        if(reqQty != null){

                            //Create key for map of WOLIs by Task Template Id and Duty Day
                            taskIdDutyDay = objTaskTemplate.Id + string.valueOf(objWO.Duty_Day__c);

                            WorkOrderLineItem objWorkOrderLI;

                            //If map contains record for this task and duty day
                            if(taskDutyDayWOLIMap.containsKey(taskIdDutyDay)){
                                //Get from the map
                                objWorkOrderLI = taskDutyDayWOLIMap.get(taskIdDutyDay);
                            }
                            else{
                                //Create a new record
                                objWorkOrderLI = new WorkOrderLineItem();
                            }

                            //Initially set the primary WO (Master Detail) as this
                            objWorkOrderLI.WorkOrderId = objWO.Id;

                            //However if there is a collect is for a customer
                            if(objTaskTemplate.Collect_From_Job_Template__c != null){
                                //And the collect job is in the map - it might not be in the map if a connected job is generated standalone
                                if(jobTemplateMap.get(objTaskTemplate.Collect_From_Job_Template__c) != null){
                                    //And the collect is for a customer
                                    if(jobTemplateMap.get(objTaskTemplate.Collect_From_Job_Template__c).Location__r.Node_Type__c == 'Customer'){
                                        //Add there is a work order for this Job Template Duty Day
                                        if(jtDutyDayToWOIdMap.get(objTaskTemplate.Collect_From_Job_Template__c + string.valueOf(objWO.Duty_Day__c)) != null){
                                            //Then change the primary WO to this (Customer jobs are the primary home for all tasks)
                                            objWorkOrderLI.WorkOrderId = jtDutyDayToWOIdMap.get(objTaskTemplate.Collect_From_Job_Template__c + string.valueOf(objWO.Duty_Day__c));
                                        }
                                    }
                                }
                            }

                            //Set the Deliver To work order field.
                            objWorkOrderLI.Deliver_To_Work_Order__c = objWO.Id;

                            //Mappings of work order from workOrderLIMappingMap map created
                            for(String objsourceKey : workOrderLIMappingMap.keySet()){
                                objWorkOrderLI.put(workOrderLIMappingMap.get(objsourceKey),objTaskTemplate.get(objsourceKey));
                            }

                            //*AJ Workorder task is now redundant due to change in data model
                            //objWorkOrderLI.Task__c = 'Deliver Product';

                            //Set the requested quanity
                            objWorkOrderLI.Requested_Quantity__c = reqQty;

                            // Add into Work Order Line Item list
                            //workOrderLIList.add(objWorkOrderLI);
                            // Add into Work Order Line Item to Map
                            taskDutyDayWOLIMap.put(taskIdDutyDay, objWorkOrderLI);

                        } //end if req qty not null
                    } //end if active duty day
                } //end if a wo for jt
            }
        }

        // Insert Work Order Line Items
        if(taskDutyDayWOLIMap.size() > 0){
            //insert workOrderLIList;
            insert taskDutyDayWOLIMap.values();
        }

        // Insert Service Appointments
        if(serviceAppointmentList.size()>0){
            insert  serviceAppointmentList;
        }

        Set<String> serviceAppointmentIdSet = new Set<String>();

        for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
            serviceAppointmentIdSet.add(objServiceAppointment.Id);
        }

        serviceAppointmentList = new List<ServiceAppointment>();
        serviceAppointmentList = [SELECT Id, Work_Order__r.Job_Template__r.Assigned_Duty_SR_Id__c, Work_Order__r.Duty_Day__c
        FROM ServiceAppointment
        WHERE Id IN : serviceAppointmentIdSet];

        //Get the Duty SR assigned to the Duty Template
        //serviceResourceIdString = objDutyTemplate.Duty_SR__c;

        // Creating Assigned Resource from Service appointment
        for(ServiceAppointment objSA : serviceAppointmentList){

            //First get the operational duty assigned directly against the Duty or Job
            //-via formula field that returns either the duty assigned to the duty template or job template
            //*New approach for crew based solution and assigning to a Duty SR
            //Note that standard FSL will throw and exception if the SR assigned to the Job does not have an active primary territory
            //-accept this and have the user resolve the error when manually generating the job
            serviceResourceIdString = objSA.Work_Order__r.Job_Template__r.Assigned_Duty_SR_Id__c;

            //If an operational duty is directly assigned
            if(serviceResourceIdString != null){

                //Then use that directly assigned value

            }
            //Else use the Duty Assignment records
            //*Legacy approach when assigning to a Driver SR
            else{
                //If there are some job assigment records
                if(jbAssignmentList.size() > 0){
                    //Call function to return assignment for this duty day
                    serviceResourceIdString = TDF_WorkOrderUtility.getJobBoardAssignment(objSA.Work_Order__r.Duty_Day__c,jbAssignmentList);
                }
            }

            //If there is a resource to assign to
            if(serviceResourceIdString != null){

                //Create a resource assignment record
                AssignedResource objAssignedResource = new AssignedResource();
                objAssignedResource.ServiceAppointmentId = objSA.Id;
                objAssignedResource.ServiceResourceId = serviceResourceIdString;

                //Add to Assigned Resource list
                assignedResourceList.add(objAssignedResource);
            }
        }

        //Insert Assigned Resources
        if(assignedResourceList.size() > 0){
            insert assignedResourceList;
        }

        return 'Work Orders (' + workOrderList.size() + ') generated';

    }

    //*AJ To get Collect Task Templates for Job Template
    public List<Task_Template__c> getTaskTemplatesCollectForJobTemplate(String WOJobTemplateId){
        if(jobTemplateTasksCollectMap.containsKey(WOJobTemplateId)){
            return jobTemplateTasksCollectMap.get(WOJobTemplateId);
        }
        return null;
    }

    //*AJ To get Deliver Task Templates for Job Template
    public List<Task_Template__c> getTaskTemplatesDeliverForJobTemplate(String WOJobTemplateId){
        if(jobTemplateTasksDeliverMap.containsKey(WOJobTemplateId)){
            return jobTemplateTasksDeliverMap.get(WOJobTemplateId);
        }
        return null;
    }
}