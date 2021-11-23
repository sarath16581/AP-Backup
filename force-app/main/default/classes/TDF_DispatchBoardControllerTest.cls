/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for dispatch board
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate call
*/
@isTest
public class TDF_DispatchBoardControllerTest{

    static testmethod void validateDispatchBoardControllerMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'DispatchBoardSACountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 300;
            objNotificationSch.Error_Message__c = 'Number of Service Appointment is more than <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

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

        for(Integer i=0; i<1; i++){
            serviceTerritoryMemberList.add(objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(counter+7)));
            counter += 7;
        }
        insert serviceTerritoryMemberList;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        objRouteTemplate.Default_Vehicle__c = objVehicleLocation.Id;
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
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

        for(Integer i=0; i<5; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;
        
        counter = 0;
        for(WorkOrder objWorkOrder : workOrderList){
            ServiceAppointment objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
            objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
            serviceAppointmentList.add(objServiceAppointment);

            objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(1), 1);            
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
            assignedResourceList.add(objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id));            
        }
        insert assignedResourceList;

        PageReference pageRef = Page.TDF_DispatchBoard;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('lksrch', 'Truck 001');
        pageRef.getParameters().put('serviceTerritory', objServiceTerritory.Id);
        pageRef.getParameters().put('serviceRes', objServiceResource.Id);
        pageRef.getParameters().put('vehicleL', objVehicleLocation.Id);

        TDF_DispatchBoardController objController = new TDF_DispatchBoardController();

        objController.startDateTime = System.now();
        objController.endDateTime = System.now().addMonths(1);
        objController.objServiceAppointment = serviceAppointmentList[0];

        List<String> strList = new List<String>();
        strList.add(standardWORecordType);

        objController.selectedWorkOrderRecordTypesList = strList;

        strList = new List<String>();
        strList.add(objServiceResource.Id);
        objController.selectedServiceResourceList = strList;

        objController.selectedDriverForAssignment = objServiceResource.Id;

        objController.searchServiceResource();
        objController.addTaskTemplate();
        objController.deleteTaskTemplate();        
        objController.objJobTemplate = objJobTemplate;
        objController.taskTemplateList = taskTemplateList;
        objController.saveTemplates();
        objController.saveAndGenerateWork();

        objController.fetchDutyTemplates();

        objController.searchServiceAppointments();

        for(TDF_DispatchBoardController.serviceAppointmentWrapper objserviceAppointmentWrapper : objController.ServiceAppointmentWrapperList){
            objserviceAppointmentWrapper.isSelected = true;
        }

        objController.ServiceAppointmentWrapperList.add(new TDF_DispatchBoardController.serviceAppointmentWrapper(serviceAppointmentList[0], assignedResourceList[0], objServiceResource));
        objController.ServiceAppointmentWrapperList.add(new TDF_DispatchBoardController.serviceAppointmentWrapper(serviceAppointmentList[0], workOrderList[0]));
        objController.ServiceAppointmentWrapperList.add(new TDF_DispatchBoardController.serviceAppointmentWrapper(serviceAppointmentList[0]));

        objController.driverGroupServiceWrapperList.add(new TDF_DispatchBoardController.GroupServiceAppointmentWrapper('Test Driver', objController.ServiceAppointmentWrapperList));

        objController.saveSearchResult();

        objController.assignvehicle();        

        objController.search();

        objController.getFormTag();

        objController.getTextBox();

        objController.saveSearchResult();

        objController.resetPage();

        objController.resetTemplates();

        TDF_DispatchBoardController objController1 = new TDF_DispatchBoardController();  
        objController1.performServiceResourceSearch('');        
    }

    static testmethod void validateDispatchBoardControllerMethodTwo(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'DispatchBoardSACountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 300;
            objNotificationSch.Error_Message__c = 'Number of Service Appointment is more than <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

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

        for(Integer i=0; i<1; i++){
            serviceTerritoryMemberList.add(objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(counter+7)));
            counter += 7;
        }
        insert serviceTerritoryMemberList;

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

        for(Integer i=0; i<5; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;
        
        counter = 0;
        for(WorkOrder objWorkOrder : workOrderList){
            ServiceAppointment objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
            objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
            serviceAppointmentList.add(objServiceAppointment);

            objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(1), 1);            
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
            assignedResourceList.add(objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id));            
        }
        insert assignedResourceList;

        PageReference pageRef = Page.TDF_DispatchBoard;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('lksrch', 'Truck 001');
        pageRef.getParameters().put('serviceTerritory', objServiceTerritory.Id);
        pageRef.getParameters().put('serviceRes', objServiceResource.Id);
        pageRef.getParameters().put('vehicleL', objVehicleLocation.Id);

        TDF_DispatchBoardController objController = new TDF_DispatchBoardController();

        objController.startDateTime = System.now();
        objController.endDateTime = System.now().addMonths(1);
        objController.objServiceAppointment = serviceAppointmentList[0];

        List<String> strList = new List<String>();
        strList.add(standardWORecordType);

        objController.selectedWorkOrderRecordTypesList = strList;

        strList = new List<String>();
        strList.add(objServiceResource.Id);
        objController.selectedServiceResourceList = strList;

        objController.selectedDriverForAssignment = objServiceResource.Id;

        objController.searchServiceResource();
        objController.addTaskTemplate();
        objController.deleteTaskTemplate();        
        objController.objJobTemplate = objJobTemplate;
        objController.taskTemplateList = taskTemplateList;
        objController.saveTemplates();
        objController.saveAndGenerateWork();      
    }

    static testmethod void validateDispatchBoardControllerMethodThree(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
        Integer counter = 0;

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'DispatchBoardSACountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 300;
            objNotificationSch.Error_Message__c = 'Number of Service Appointment is more than <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

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

        for(Integer i=0; i<1; i++){
            serviceTerritoryMemberList.add(objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(counter+7)));
            counter += 7;
        }
        insert serviceTerritoryMemberList;

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

        for(Integer i=0; i<5; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;
        
        counter = 0;
        for(WorkOrder objWorkOrder : workOrderList){
            ServiceAppointment objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
            objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
            serviceAppointmentList.add(objServiceAppointment);

            objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(1), 1);            
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
            assignedResourceList.add(objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id));            
        }
        insert assignedResourceList;

        PageReference pageRef = Page.TDF_DispatchBoard;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('lksrch', 'Truck 001');
        pageRef.getParameters().put('serviceTerritory', objServiceTerritory.Id);
        pageRef.getParameters().put('serviceRes', objServiceResource.Id);
        pageRef.getParameters().put('vehicleL', objVehicleLocation.Id);

        TDF_DispatchBoardController objController = new TDF_DispatchBoardController();

        objController.startDateTime = System.now();
        objController.endDateTime = System.now().addMonths(1);
        objController.objServiceAppointment = serviceAppointmentList[0];

        List<String> strList = new List<String>();
        strList.add(standardWORecordType);

        objController.selectedWorkOrderRecordTypesList = strList;

        strList = new List<String>();
        strList.add(objServiceResource.Id);
        objController.selectedServiceResourceList = strList;

        objController.selectedDriverForAssignment = objServiceResource.Id;

        objController.searchServiceResource();
        objController.addTaskTemplate();
        objController.deleteTaskTemplate();        
        objController.objJobTemplate = objJobTemplate;
        objController.taskTemplateList = taskTemplateList;
        objController.saveTemplates();
        objController.saveAndGenerateWork();      
    } 

    static testmethod void validateDispatchBoardControllerMethodFour(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();        
        Integer counter = 0;

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'DispatchBoardSACountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 300;
            objNotificationSch.Error_Message__c = 'Number of Service Appointment is more than <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }

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

        for(Integer i=0; i<1; i++){
            serviceTerritoryMemberList.add(objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(counter+7)));
            counter += 7;
        }
        insert serviceTerritoryMemberList;

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

        for(Integer i=0; i<5; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;
        
        counter = 0;
        for(WorkOrder objWorkOrder : workOrderList){
            ServiceAppointment objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
            objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
            serviceAppointmentList.add(objServiceAppointment);

            objServiceAppointment = new serviceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(1), 1);            
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        PageReference pageRef = Page.TDF_DispatchBoard;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('lksrch', 'Truck 001');
        pageRef.getParameters().put('serviceTerritory', objServiceTerritory.Id);
        pageRef.getParameters().put('serviceRes', objServiceResource.Id);
        pageRef.getParameters().put('vehicleL', objVehicleLocation.Id);

        TDF_DispatchBoardController objController = new TDF_DispatchBoardController();

        objController.startDateTime = System.now();
        objController.endDateTime = System.now().addMonths(1);
        objController.objServiceAppointment = serviceAppointmentList[0];

        List<String> strList = new List<String>();
        strList.add(standardWORecordType);

        objController.selectedWorkOrderRecordTypesList = strList;

        strList = new List<String>();
        strList.add(objServiceResource.Id);
        objController.selectedServiceResourceList = strList;

        objController.selectedDriverForAssignment = objServiceResource.Id;

        objController.searchServiceResource();
        objController.addTaskTemplate();
        objController.deleteTaskTemplate();        
        objController.objJobTemplate = objJobTemplate;
        objController.taskTemplateList = taskTemplateList;
        objController.saveTemplates();
        objController.saveAndGenerateWork(); 

        objController.fetchDutyTemplates();

        objController.searchServiceAppointments();

        for(TDF_DispatchBoardController.serviceAppointmentWrapper objserviceAppointmentWrapper : objController.ServiceAppointmentWrapperList){
            objserviceAppointmentWrapper.isSelected = true;
        }

        objController.ServiceAppointmentWrapperList.add(new TDF_DispatchBoardController.serviceAppointmentWrapper(serviceAppointmentList[0], workOrderList[0]));
        objController.ServiceAppointmentWrapperList.add(new TDF_DispatchBoardController.serviceAppointmentWrapper(serviceAppointmentList[0]));

        objController.driverGroupServiceWrapperList.add(new TDF_DispatchBoardController.GroupServiceAppointmentWrapper('Test Driver', objController.ServiceAppointmentWrapperList));

        objController.saveSearchResult();

        objController.assignvehicle();        

        objController.search();

        objController.getFormTag();

        objController.getTextBox();

        objController.saveSearchResult();

        objController.resetPage();

        objController.resetTemplates();             
    }            
}