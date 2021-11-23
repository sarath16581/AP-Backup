/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for planning board
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate call
*/
@isTest
public class TDF_PlanningBoardControllerTest{

    static testmethod void validatePlanningBoardControllerMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 1;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        insert objJobTemplate;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;  
        
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();
        for(Integer i=0; i<5; i++){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            taskTemplateList.add(objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null));
        }
        insert taskTemplateList;
        
        TDF_PlanningBoardController objController = new TDF_PlanningBoardController();
        objController.fetchDutyTemplates();
        Date todaysDate = System.today();

        objController.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }

        objController.generateWorkStartDate = todaysDate;        
        objController.generateWorkEndDate = todaysDate.addDays(7);
        objController.generateWork();
        objController.resetPage();

        TDF_PlanningBoardController objController1 = new TDF_PlanningBoardController();
        objController1.generateWork(); 

        objController1.generateWorkStartDate = todaysDate.addDays(7);
        objController1.generateWorkEndDate = todaysDate;
        objController1.generateWork();

        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;
        objController1.confirmDeleteWork();              

        objController1.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController1.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;        
        objController1.confirmDeleteWork();        
    } 

    static testmethod void validatePlanningBoardControllerMethodTwo(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 1;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 300;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }       

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        objRouteTemplate.VehicleType__c = 'Prime Mover';
        objRouteTemplate.Default_Vehicle__c = objVehicleLocation.Id;
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        objJobTemplate.Earliest_Start_Time__c = '1100';
        objJobTemplate.Latest_Start_Time__c = '1200';
        objJobTemplate.Next_Day_Job__c = false;
        objJobTemplate.Activity_Type__c = 'Prepare Vehicle';
        insert objJobTemplate;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;  
        
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();
        for(Integer i=0; i<5; i++){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            taskTemplateList.add(objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null));
        }
        insert taskTemplateList;
        
        TDF_PlanningBoardController objController = new TDF_PlanningBoardController();
        objController.fetchDutyTemplates();
        Date todaysDate = System.today();

        objController.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }

        objController.generateWorkStartDate = todaysDate;
        objController.generateWorkEndDate = todaysDate.addDays(7);
        objController.generateWork();
        objController.resetPage();

        TDF_PlanningBoardController objController1 = new TDF_PlanningBoardController();
        objController1.generateWork(); 

        objController1.generateWorkStartDate = todaysDate.addDays(7);
        objController1.generateWorkEndDate = todaysDate;
        objController1.generateWork();

        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;
        objController1.confirmDeleteWork();              

        objController1.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController1.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;        
        objController1.confirmDeleteWork();        
    }

    static testmethod void validatePlanningBoardControllerMethodThree(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 1;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 10;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        objRouteTemplate.VehicleType__c = 'Prime Mover';
        objRouteTemplate.Default_Vehicle__c = objVehicleLocation.Id;
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        objJobTemplate.Earliest_Start_Time__c = '1100';
        objJobTemplate.Latest_Start_Time__c = '1200';
        objJobTemplate.Next_Day_Job__c = false;
        objJobTemplate.Activity_Type__c = 'Prepare Vehicle';
        insert objJobTemplate;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;  
        
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();
        for(Integer i=0; i<5; i++){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            taskTemplateList.add(objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null));
        }
        insert taskTemplateList;
        
        TDF_PlanningBoardController objController = new TDF_PlanningBoardController();
        objController.fetchDutyTemplates();
        Date todaysDate = System.today();

        objController.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }

        objController.generateWorkStartDate = todaysDate;
        objController.generateWorkEndDate = todaysDate.addDays(7);
        objController.generateWork();
        objController.resetPage();

        TDF_PlanningBoardController objController1 = new TDF_PlanningBoardController();
        objController1.generateWork(); 

        objController1.generateWorkStartDate = todaysDate.addDays(7);
        objController1.generateWorkEndDate = todaysDate;
        objController1.generateWork();

        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;
        objController1.confirmDeleteWork();              

        objController1.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController1.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;        
        objController1.confirmDeleteWork();        
    } 

    static testmethod void validatePlanningBoardControllerMethodFour(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 1;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 0;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        objRouteTemplate.VehicleType__c = 'Rigid';
        objRouteTemplate.Default_Vehicle__c = objVehicleLocation.Id;
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;


        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        objJobTemplate.Earliest_Start_Time__c = '1100';
        objJobTemplate.Latest_Start_Time__c = '1200';
        objJobTemplate.Next_Day_Job__c = false;
        objJobTemplate.Activity_Type__c = 'Prepare Vehicle';
        insert objJobTemplate;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;  
        
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();
        for(Integer i=0; i<5; i++){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            taskTemplateList.add(objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null));
        }
        insert taskTemplateList;
        
        TDF_PlanningBoardController objController = new TDF_PlanningBoardController();
        objController.fetchDutyTemplates();
        Date todaysDate = System.today();

        objController.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }

        objController.generateWorkStartDate = todaysDate;
        objController.generateWorkEndDate = todaysDate.addDays(7);
        objController.generateWork();
        objController.resetPage();

        TDF_PlanningBoardController objController1 = new TDF_PlanningBoardController();
        objController1.generateWork(); 

        objController1.generateWorkStartDate = todaysDate.addDays(7);
        objController1.generateWorkEndDate = todaysDate;
        objController1.generateWork();

        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;
        objController1.confirmDeleteWork();              

        objController1.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController1.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;        
        objController1.confirmDeleteWork();        
    }

    static testmethod void validatePlanningBoardControllerMethodFive(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 1;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();        
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        insert objJobTemplate;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;  
        
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();
        for(Integer i=0; i<5; i++){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            taskTemplateList.add(objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null));
        }
        insert taskTemplateList;
        
        TDF_PlanningBoardController objController = new TDF_PlanningBoardController();
        
        //AJ Added set of dates
        objController.startDate = System.today();
        objController.endDate = System.today(); 
        
        objController.fetchDutyTemplates();
        Date todaysDate = System.today();

        objController.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
 
        objController.generateWorkStartDate = todaysDate;        
        objController.generateWorkEndDate = todaysDate.addDays(7);
        objController.generateWork();
        objController.resetPage();

        TDF_PlanningBoardController objController1 = new TDF_PlanningBoardController();
        objController1.generateWork(); 

        objController1.generateWorkStartDate = todaysDate.addDays(7);
        objController1.generateWorkEndDate = todaysDate;
        objController1.generateWork();

        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;
        objController1.confirmDeleteWork();              

        objController1.dutyTemplateWrapperList.add(new TDF_PlanningBoardController.DutyTemplateWrapper(objRouteTemplate));
        for(TDF_PlanningBoardController.DutyTemplateWrapper objWrap : objController1.dutyTemplateWrapperList){
            objWrap.isSelected = true;
        }
        objController1.deleteWorkStartDate = todaysDate.addDays(2);
        objController1.deleteWorkEndDate = todaysDate;        
        objController1.confirmDeleteWork(); 
        
        //AJ Call refresh
        objController1.refreshTerritories();
               
    } 
    
                
}