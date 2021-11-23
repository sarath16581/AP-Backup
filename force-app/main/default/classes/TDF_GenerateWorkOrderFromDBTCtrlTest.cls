/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for gen work from duty template
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate call
*                               -Updated create of Job Template with Vehicle Location
*/
@isTest
public class TDF_GenerateWorkOrderFromDBTCtrlTest{

    static testmethod void validateGenerateWOFromDBTCtrlOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromDBT;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objRouteTemplate.Id);

        TDF_GenerateWorkOrderFromDBT_ControllerX objController = new TDF_GenerateWorkOrderFromDBT_ControllerX(new ApexPages.StandardController(objRouteTemplate));
        
        objController.createWOandWOLineItem();

        objController.goBack();

        //TDF Enhance 2020-08-31: Method removed
        //objController.validateStartAndEndDate();

        objController.startDate = null;

        objController.createWOandWOLineItem();

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
        objController.createWOandWOLineItem();

        msgs = ApexPages.getMessages();
        b = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Date range should be 60 days')) b = true;
        }
        system.assert(b);                 
    }

    static testmethod void validateGenerateWOFromDBTCtrlTwo(){

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = 24;
            insert objNotificationSch;
        }

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        List<Job_Template__c> jobTemplateList = new List<Job_Template__c>();
        List<Task_Template__c> taskTemplateList = new List<Task_Template__c>();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        //TDF Enhance 2020-08-31: Comment out as not required
        //Schema.Location objVehicleLocation = new Schema.Location();
        //objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        //insert objVehicleLocation;

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

        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7));
        insert objServiceTerritoryMember;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        //TDF Enhance 2020-08-31: Changed to specify a site location, not a vehicle location
        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        jobTemplateList.add(objJobTemplate);

        Job_Template__c objJobTemplate1 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Prepare Vehicle');
        jobTemplateList.add(objJobTemplate1);

        Job_Template__c objJobTemplate2 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Prepare Trailer');
        jobTemplateList.add(objJobTemplate2);

        Job_Template__c objJobTemplate3 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Drop Trailer');
        jobTemplateList.add(objJobTemplate3);

        Job_Template__c objJobTemplate4 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Return Vehicle');
        jobTemplateList.add(objJobTemplate4);

        Job_Template__c objJobTemplate5 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Return & Refuel Vehicle');
        jobTemplateList.add(objJobTemplate5);                

        Job_Template__c objJobTemplate6 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Fit For Duty');
        jobTemplateList.add(objJobTemplate6);

        //AJ 25.06.18 Changed Meal Break to Rest Break
        Job_Template__c objJobTemplate7 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id, 'Rest Break');
        jobTemplateList.add(objJobTemplate7);        
        insert jobTemplateList;

        for(Job_Template__c objJT : jobTemplateList){
            //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
            Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJT.Id, null);
            taskTemplateList.add(objTaskTemplate);
        }        
        insert taskTemplateList;        

        PageReference pageRef = Page.TDF_GenerateWorkOrderFromDBT;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objRouteTemplate.Id);

        TDF_GenerateWorkOrderFromDBT_ControllerX objController = new TDF_GenerateWorkOrderFromDBT_ControllerX(new ApexPages.StandardController(objRouteTemplate));
        objController.startDate = System.today().addDays(1);
        objController.endDate = System.today().addDays(2);
        objController.createWOandWOLineItem();

    }   
}