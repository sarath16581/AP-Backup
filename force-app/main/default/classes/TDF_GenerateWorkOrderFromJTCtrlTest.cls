/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for gen work from job template
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate call
*                               -Removed referenced to validateStartAndEndDate
*                               -Created Service Territory Member records for all Service Resources
* 2021-09-16 - keerthi akula - updated TDF_GenerateWorkOrderFromJTCtrlTest 
*                            - Added validateGenerateWOFromJTCtrlNine
*                            - Added validateGenerateWOFromJTCtrlTen
*/
@isTest
public class TDF_GenerateWorkOrderFromJTCtrlTest{

    //Test date validation on form 
    static testmethod void validateGenerateWOFromJTCtrlOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        insert objJobTemplate;

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));
        
        objController.createWorkOrders();

        objController.goBack();

        objController.startDate = null;

        objController.createWorkOrders();

        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean b;

        msgs = ApexPages.getMessages();
        b = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Please enter the dates')) b = true;
        }
        system.assert(b);        

        objController.startDate = System.today();
        objController.endDate = System.today()+61;
        objController.createWorkOrders();

        msgs = ApexPages.getMessages();
        b = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Date range should be 60 days')) b = true;
        }
        system.assert(b);                 
    }

    //Test create Prepare Vehicle job
    static testmethod void validateGenerateWOFromJTCtrlTwo(){

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Adjusted start time to back 2 days to prevent error       
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;
        
        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Prepare Vehicle');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));
        objController.startDate = System.today().addDays(1);
        objController.endDate = System.today().addDays(2);
        objController.createWorkOrders();
    }

    //Test create Prepare Trailer job
    static testmethod void validateGenerateWOFromJTCtrlThree(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Prepare Trailer');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }

    //Test create Drop Trailer job
    static testmethod void validateGenerateWOFromJTCtrlFour(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Drop Trailer');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }

    //Test create Return Vehicle job
    static testmethod void validateGenerateWOFromJTCtrlFive(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Return Vehicle');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }

    //Test create Return and Refuel Vehicle job
    static testmethod void validateGenerateWOFromJTCtrlSix(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;        

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Return & Refuel Vehicle');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }                   

    //Test create Fit For Duty job
    static testmethod void validateGenerateWOFromJTCtrlSeven(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;        

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Fit For Duty');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }

    //Test create Rest Break job
    static testmethod void validateGenerateWOFromJTCtrlEight(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        //TDF Enhance 2020-08-31: Create Service Territory Member for the Service Resource
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;        

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        //AJ 25.06.18 Changed Meal Break to Rest Break
        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Rest Break');
        insert objJobTemplate;
        
        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objController.createWorkOrders();
    }
    //17-09-2021 keerthiakul@auspost.com.au 
    //test method if the duty/job template in AEST and user in AWST
    @isTest  
    static void validateGenerateWOFromJTCtrlNine(){

        Test.startTest();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours2('Afternoon Shift', 'Australia/Sydney');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation2('Dendanong', 'Site', 'Australia/Sydney');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objServiceResourceUser = objTestDataFactory.getUser2(sysAdmin.Id, 'tdf@australiaPost.com', 'Australia/Sydney');
        insert objServiceResourceUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objServiceResourceUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;        

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate2(objRouteTemplate.Id, objSiteLocation.Id, 'Rest Break', '0030', '1200','1500');
        insert objJobTemplate;
        
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        User objAdminUser = objTestDataFactory.getUser2(sysAdmin.Id, 'tdf@australiaPost.com', 'Australia/Perth');
        insert objAdminUser;

        system.runas(objAdminUser){
            TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

            objController.createWorkOrders();
        }
        WorkOrder[] workOrderCreated =  [SELECT Id from WorkOrder]; 
        ServiceAppointment[] serviceAppointments =  [SELECT SchedStartTime from ServiceAppointment];
        Test.stopTest();
        system.assertEquals(1, serviceAppointments.size(), 'Work order is not created'); 
        system.assertEquals(1, workOrderCreated.size(), 'Service Appointment is not created');
    }  
     //17-09-2021 keerthiakul@auspost.com.au 
    //test method if the duty/job template in AWST and user in AEST 
    @isTest
     static void validateGenerateWOFromJTCtrlTen(){

        Test.startTest();
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours2('Afternoon Shift', 'Australia/Perth');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation2('Dendanong', 'Site', 'Australia/Perth');
        insert objSiteLocation;        

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objServiceResourceUser = objTestDataFactory.getUser2(sysAdmin.Id, 'tdf@australiaPost.com', 'Australia/Sydney');
        insert objServiceResourceUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objServiceResourceUser);
        insert objServiceResource;

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;        

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate2(objRouteTemplate.Id, objSiteLocation.Id, 'Rest Break', '2330', '1200', '1500');
        insert objJobTemplate;
        
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        User objAdminUser = objTestDataFactory.getUser2(sysAdmin.Id, 'tdf@australiaPost.com', 'Australia/Sydney');
        insert objAdminUser;


        system.runas(objAdminUser){
            TDF_GenerateWorkOrderFromJT_ControllerX objController = new TDF_GenerateWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

            objController.createWorkOrders();
        }
      WorkOrder[] workOrderCreated =  [SELECT Id from WorkOrder]; 
      ServiceAppointment[] serviceAppointments =  [SELECT SchedStartTime from ServiceAppointment]; 
      Test.stopTest();
      system.assertEquals(1, workOrderCreated.size(),'Work order is not created');
      system.assertEquals(1, serviceAppointments.size(),'Service Apointment is not created');
      
    }
}