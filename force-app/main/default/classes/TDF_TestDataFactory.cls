/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class to create TDF test data
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate to accept Collect From and Deliver To Job Template Ids
* 2020-09-01                    -Changed API from 40 to 49 
*                               -Changed API from 40 to 49
*                               -Added getDutyServiceResource
* 2020-09-02                    -Added getRoster
* 2021-09-16  keerthi akul - Added getUser2
                           - Added getLocation2
                           - Added getOperatingHours2
                           - Added getJobTemplate2
*/
@isTest
public without sharing class TDF_TestDataFactory{
     
    //Create Product
    public Product2 getProduct(String productName){
        Product2 objProduct = new Product2();
        objProduct.Name = productName;
        return objProduct;
    }

    //Create Operating hour
    public OperatingHours getOperatingHours(String name){
        OperatingHours objOperatingHours = new OperatingHours();
        objOperatingHours.Name = name;
        objOperatingHours.TimeZone = 'Australia/Sydney'; 
        return objOperatingHours;
    }
     
    //Create Service Territory
    public ServiceTerritory getServiceTerritory(String serviceTerritoryName, String ohId){
        ServiceTerritory objServiceTerritory = new ServiceTerritory();
        objServiceTerritory.Name = serviceTerritoryName;
        objServiceTerritory.OperatingHoursId = ohId;
        objServiceTerritory.IsActive = true;
        objServiceTerritory.TerritoryDispatcher__c = 'Dendanong Dispatcher';
        return objServiceTerritory;
    }

    public ServiceTerritoryMember getServiceTerritoryMember(String serviceResourceId, String serviceTerritoryId, Datetime startDate, DateTime endDate){
        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember.ServiceResourceId = serviceResourceId;
        objServiceTerritoryMember.ServiceTerritoryId = serviceTerritoryId;        
        objServiceTerritoryMember.EffectiveStartDate = startDate;
        objServiceTerritoryMember.EffectiveEndDate = endDate.addDays(1);                
        return objServiceTerritoryMember;
    }
        
    //Create DutyTemplate Record
    public Route_Template__c  getDutyTemplate(String name, String serviceTerritoryId){
        Route_Template__c objRouteTemplate = new Route_Template__c();
        objRouteTemplate.Name = name;
        objRouteTemplate.Monday__c = true;
        objRouteTemplate.Tuesday__c = true;
        objRouteTemplate.Wednesday__c = true;
        objRouteTemplate.Thursday__c = true;
        objRouteTemplate.Friday__c = true;
        objRouteTemplate.Saturday__c = true;
        objRouteTemplate.Sunday__c = true;
        objRouteTemplate.Service_Territory__c = serviceTerritoryId;
        //AJ 02.08.18 Add set Status
        objRouteTemplate.Status__c = 'Active';
        return objRouteTemplate;
    }
    
    //Create Location Record
    public Schema.Location getLocation(String locationName, String locationType){
        Schema.Location objLocation = new Schema.Location();
        objLocation.Name = locationName;
        objLocation.LocationType = locationType;
        objLocation.TimeZone  = 'Australia/Sydney';
        //AJ 28.06.18 Set flag to align with validation rule. AJ 24.09.18 Set Type and Record Type to align with Type validation rule
        if(locationType == 'Vehicle'){
            objLocation.IsInventoryLocation = true;
            objLocation.IsMobile = true; 
            objLocation.Type__c = 'Rigid Vehicle'; 
            objLocation.RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId(); 
        }
        if(locationType == 'Site'){
            objLocation.IsInventoryLocation = true; 
        }        
        return objLocation;                
    }
    
    //Create JobTemplate Record
    public Job_Template__c getJobTemplate(String routeId, String locId){
        Job_Template__c objJobTemplate = new Job_Template__c();
        objJobTemplate.Route_Template__c = routeId;
        objJobTemplate.Location__c = locId;
        objJobTemplate.Duration__c = '200';
        objJobTemplate.Start_Time__c = '1200';
        objJobTemplate.Next_Day_Job__c = true;
        objJobTemplate.Earliest_Start_Time__c = '1500';
        objJobTemplate.Latest_Start_Time__c = '1200';        
        return objJobTemplate;
    }
    
    //Create JobTemplate Record with Activity
    public Job_Template__c getJobTemplate(String routeId, String locId, String activityType){
        Job_Template__c objJobTemplate = new Job_Template__c();
        objJobTemplate.Route_Template__c = routeId;
        objJobTemplate.Location__c = locId;
        objJobTemplate.Duration__c = '200';
        objJobTemplate.Start_Time__c = '1200';
        objJobTemplate.Activity_Type__c = activityType;
        objJobTemplate.Earliest_Start_Time__c = '1200';
        objJobTemplate.Latest_Start_Time__c = '1500';
        return objJobTemplate;
    }    

    //Create TaskTemplate Record
    //TDF Enhance 2020-08-31: Update to allow set of Collect From and Deliver To Job Template and Duty Template Id
    public Task_Template__c  getTaskTemplate(String dutyTemplateId, String jobTemplateCFId, String jobTemplateDTId){                
        Task_Template__c objTaskTemplate = new Task_Template__c();
        //objTaskTemplate.Job_Template__c = jobTemplateId;
        objTaskTemplate.Collect_From_Job_Template__c = jobTemplateCFId;
        objTaskTemplate.Deliver_To_Job_Template__c = jobTemplateDTId;
        objTaskTemplate.DTID__c = dutyTemplateId;
        return objTaskTemplate;
    }                       

    //Create Admin User
    public User getUser(Id profileId, String testemail) {
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = dateString + randomInt;
        User objUser = new User(profileId = profileId, username = uniqueName+testemail, email = uniqueName+testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', Work_Center_Code__c='1234');
        return objUser;
    }
    
    //Create Service Resource Record
    public ServiceResource getServiceResource(String serviceResourceName, User objUser){
        ServiceResource objServiceResource = new ServiceResource();
        objServiceResource.Name = serviceResourceName;
        objServiceResource.RelatedRecord = objUser;
        objServiceResource.RelatedRecordId = objUser.Id;
        objServiceResource.IsActive = true;
        return objServiceResource;
    }

    //TDF Enhance 2020-09-01: Added
    //Create Duty Service Resource Record
    public ServiceResource getDutyServiceResource(String dutyServiceResourceName, String serviceResourceId, Datetime startDate, Datetime endDate){

        //Create Service Crew with the same name
        ServiceCrew objServiceCrew = getServiceCrew(dutyServiceResourceName);
        insert objServiceCrew;

        //Create a Service Crew Member record (to allow the SR to be activated)
        ServiceCrewMember objServiceCrewMember = getServiceCrewMember(objServiceCrew.Id, serviceResourceId, startDate, endDate);
        insert objServiceCrewMember;

        //Create crew service resource
        Time startTime = Time.newInstance(9, 0, 0, 0);
        ServiceResource objDutyServiceResource = new ServiceResource();
        objDutyServiceResource.Name = dutyServiceResourceName;
        objDutyServiceResource.ResourceType = 'C';
        objDutyServiceResource.IsActive = true;
        objDutyServiceResource.ServiceCrewId = objServiceCrew.Id;
        objDutyServiceResource.DutyStartTime__c = startTime;
        return objDutyServiceResource;
    }

    //TDF Enhance 2020-09-01: Added
    //Create Service Crew Record
    public ServiceCrew getServiceCrew(String serviceCrewName){
        ServiceCrew objServiceCrew = new ServiceCrew();
        objServiceCrew.Name = serviceCrewName;
        objServiceCrew.CrewSize = 1;
        return objServiceCrew;
    }     

    //TDF Enhance 2020-09-01: Added
    //Create Service Crew Member Record
    public ServiceCrewMember getServiceCrewMember(String serviceCrewId, String serviceResourceId, Datetime startDate, DateTime endDate){
        ServiceCrewMember objServiceCrewMember = new ServiceCrewMember();
        objServiceCrewMember.ServiceResourceId = serviceResourceId;
        objServiceCrewMember.ServiceCrewId = serviceCrewId;        
        objServiceCrewMember.StartDate = startDate;
        objServiceCrewMember.EndDate = endDate;                
        return objServiceCrewMember;
    }    

    //Create Route Assignment record
    public Route_Assignment__c getRouteAssignment(String srId, String dutyTemplateId){
        Route_Assignment__c objRouteAssignment = new Route_Assignment__c();
        objRouteAssignment.Service_Resource__c = srId;
        objRouteAssignment.Start_Date__c = System.today();
        objRouteAssignment.End_Date__c = System.today().addDays(7);
        objRouteAssignment.Duty_Board__c = dutyTemplateId;      
        return objRouteAssignment;
    }

    public String getWorkOrderRTId(String rtName){
        return Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
    } 

    //Create Work Order
    public WorkOrder getWorkOrder(String woRecordTypeId){
        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder.RecordTypeId = woRecordTypeId;
        objWorkOrder.StartDate = System.now();
        objWorkOrder.EndDate = System.now().addMinutes(30);
        objWorkOrder.Duty_Day__c = objWorkOrder.StartDate.Date();
        return objWorkOrder; 
    }

    public WorkOrderLineItem getWOLI(String workOrderId, String productId, String task){
        WorkOrderLineItem objWOLI = new WorkOrderLineItem();
        objWOLI.WorkOrderId = workOrderId;
        objWOLI.Product__c = productId;
        objWOLI.Task__c = task;
        return objWOLI;
    }

    //Create Service Report
    public ServiceReport getServiceReport(String parentId){
        ServiceReport objServiceReport = new ServiceReport();
        objServiceReport.ParentId = parentId;
        return objServiceReport;        
    }

    //Create Service Appointment
    public ServiceAppointment getServiceAppointment(String parentRecord, String serviceTerritoryId, DateTime startTime, Integer duration){
        ServiceAppointment objServiceAppointment = new ServiceAppointment();
        objServiceAppointment.ParentRecordId = parentRecord;
        objServiceAppointment.EarliestStartTime = startTime;
        objServiceAppointment.DueDate = startTime.addHours(duration);
        objServiceAppointment.SchedStartTime = startTime;
        objServiceAppointment.SchedEndTime = startTime.addHours(duration);
        objServiceAppointment.ServiceTerritoryId = serviceTerritoryId;
        objServiceAppointment.Status = 'Scheduled';
        return objServiceAppointment;
    }

    //Create Assigned Resource
    public AssignedResource getAssignedResource(String saId, String srId){
        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource.ServiceAppointmentId = saId;
        objAssignedResource.ServiceResourceId = srId;
        return objAssignedResource;
    }

    //Create Product2 record
    public Product2 getProduct2(String productName){
        Product2 objProduct = new Product2();
        objProduct.Name = productName;
        return objProduct;        
    }

    //Create Product Item record
    public ProductItem getProductItem(String productId, String locationId, Integer quantity){
        ProductItem objProductItem = new ProductItem();
        objProductItem.Product2Id = productId;
        objProductItem.LocationId = locationId;
        objProductItem.QuantityOnHand = quantity;
        return objProductItem;        
    }

    //Create Roster 
    public Roster__c getRoster(String driverId, String dutyId, String stId, Date startDate, Date endDate, String rosterRef, Boolean ganttAssign){
        Roster__c objRoster = new Roster__c();
        objRoster.Driver__c = driverId;
        objRoster.Duty__c = dutyId;
        objRoster.Service_Territory__c = stId;
        objRoster.Start_Date__c = startDate;
        objRoster.End_Date__c = endDate;
        objRoster.Roster_Reference__c = rosterRef;
        objRoster.Gantt_Assignment__c = ganttAssign;
        return objRoster;
    }
    
    //get user with different timezone
    public User getUser2(Id profileId, String testemail, string timezonesidkey) {
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = dateString + randomInt;
        User objUser = new User(profileId = profileId, username = uniqueName+testemail, email = uniqueName+testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = timezonesidkey,
                           alias='cspu', lastname='lastname', Work_Center_Code__c='1234');
        return objUser;
    }

    public OperatingHours getOperatingHours2(String name, string timezone ){
        OperatingHours objOperatingHours = new OperatingHours();
        objOperatingHours.Name = name;
        objOperatingHours.TimeZone = timezone; 
        return objOperatingHours;
    }
    
    //Create JobTemplate Record with Activity
    public Job_Template__c getJobTemplate2(String routeId, String locId, String activityType, string startTime, string earlistStartTime, string latestStartTime){
        Job_Template__c objJobTemplate = new Job_Template__c();
        objJobTemplate.Route_Template__c = routeId;
        objJobTemplate.Location__c = locId;
        objJobTemplate.Duration__c = '200';
        objJobTemplate.Start_Time__c = startTime;
        objJobTemplate.Activity_Type__c = activityType;
        objJobTemplate.Earliest_Start_Time__c = earlistStartTime;
        objJobTemplate.Latest_Start_Time__c = latestStartTime;
        return objJobTemplate;
    } 

    //Create Location Record
    public Schema.Location getLocation2(String locationName, String locationType, string timezone){
        Schema.Location objLocation = new Schema.Location();
        objLocation.Name = locationName;
        objLocation.LocationType = locationType;
        objLocation.TimeZone  = timezone;
        //AJ 28.06.18 Set flag to align with validation rule. AJ 24.09.18 Set Type and Record Type to align with Type validation rule
        if(locationType == 'Vehicle'){
            objLocation.IsInventoryLocation = true;
            objLocation.IsMobile = true; 
            objLocation.Type__c = 'Rigid Vehicle'; 
            objLocation.RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Vehicle').getRecordTypeId(); 
        }
        if(locationType == 'Site'){
            objLocation.IsInventoryLocation = true; 
        }        
        return objLocation;                
    }

}