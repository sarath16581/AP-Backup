/**
 * Created by nmain on 14/02/2018.
 */

@isTest
public with sharing class TDF_RefreshTerritoriesTest {

    @testSetup static void dataSetup() {

        // Set up two drivers
        // each driver has a user a service resource and the service resource has a primary territory Member with a start date < appointment dates

        if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'FollowWorkOrder';
            objNotificationSch.FeedMessage__c = 'Test';
            objNotificationSch.ScheduleTime__c = -24; //negative to prevent follow
            insert objNotificationSch;
        }

        /*if(TDF_NotificationScheduler__c.getAll().get('PlanningBoardDutyTemplateCountCheck') == null){
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'PlanningBoardDutyTemplateCountCheck';
            objNotificationSch.Service_Appointment_Query_Limit__c = 1;
            objNotificationSch.Error_Message__c = 'There are <DT> Duty Templates based on the filter criteria. Which is more than the limit of <?>. Please refine the search by specifying Date Range.';
            insert objNotificationSch;
        }*/

        // Create Custom Settings
        TDF_Settings__c custSettings = new TDF_Settings__c();
        custSettings.Assignment_End_Date_Time_Offset__c = 14;
        custSettings.Assignment_Start_Date_Time_Offset__c = 2;
        insert custSettings;

        //Create operating hours
        OperatingHours oh = new OperatingHours();
        oh.Name = 'All Hours';
        oh.TimeZone = 'Australia/Sydney';
        insert oh;

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        //Create WO1
        Id recordTypeIdWorkOrder = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Fit For Duty').getRecordTypeId();
        WorkOrder objWorkOrder1 = new WorkOrder();
        objWorkOrder1 = objTestDataFactory.getWorkOrder(recordTypeIdWorkOrder);
        insert objWorkOrder1;
        
        //Create WO2
        WorkOrder objWorkOrder2 = new WorkOrder();
        objWorkOrder2 = objTestDataFactory.getWorkOrder(recordTypeIdWorkOrder);
        insert objWorkOrder2;
        
        //Create WO3
        WorkOrder objWorkOrder3 = new WorkOrder();
        objWorkOrder3 = objTestDataFactory.getWorkOrder(recordTypeIdWorkOrder);
        insert objWorkOrder3;

        //system.debug(' TTTTTT objWorkOrder1.Id:'+objWorkOrder1.Id);

        //Set date for SA Start
        Date d = date.today();
        String todayDateStr = DateTime.newInstance(d.year(),d.month(),d.day()).format('d/MM/YYYY');
        system.debug('TTTTTTTT todayDateStr:'+todayDateStr);

        // Create Users
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf001@australiaPost.com');
        insert objAdminUser;

        User objAdminUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf002@australiaPost.com');
        insert objAdminUser2;

        Schema.Location objSiteLocation = objTestDataFactory.getLocation('Dandanong', 'Site');
        objSiteLocation.IsInventoryLocation = true;
        objSiteLocation.IsMobile = true;
        insert objSiteLocation;

        // Create ServiceResources
        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        objServiceResource.LocationId = objSiteLocation.Id;
        insert objServiceResource;

        ServiceResource objServiceResource2 = objTestDataFactory.getServiceResource('TDF Test2', objAdminUser2);
        insert objServiceResource2;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        //create Parent Territory
        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //create Sub Territories
        ServiceTerritory subTer1 = new ServiceTerritory(Name = 'Dan 2000 - 0400', IsActive = True, Territory_Hours__c = '20, 21, 22, 23, 24, 00, 01, 02, 03', ParentTerritoryId = objServiceTerritory.Id, OperatingHoursId=oh.Id);
        insert subTer1;
        ServiceTerritory subTer2 = new ServiceTerritory(Name = 'Dan 0400 - 0800', IsActive = True, Territory_Hours__c = '04, 05, 06, 07', ParentTerritoryId = objServiceTerritory.Id, OperatingHoursId=oh.Id);
        insert subTer2;
        ServiceTerritory subTer3 = new ServiceTerritory(Name = 'Dan 0800 - 1200', IsActive = True, Territory_Hours__c = '08, 09, 10, 11', ParentTerritoryId = objServiceTerritory.Id, OperatingHoursId=oh.Id);
        insert subTer3;
        ServiceTerritory subTer4 = new ServiceTerritory(Name = 'Dan 1200 - 1600', IsActive = True, Territory_Hours__c = '12, 13, 14, 15', ParentTerritoryId = objServiceTerritory.Id, OperatingHoursId=oh.Id);
        insert subTer4;
        ServiceTerritory subTer5 = new ServiceTerritory(Name = 'Dan 1600 - 2000', IsActive = True, Territory_Hours__c = '16, 17, 18, 19', ParentTerritoryId = objServiceTerritory.Id, OperatingHoursId=oh.Id);
        insert subTer5;

        //create SAs
        ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(objWorkOrder1.Id, objServiceTerritory.Id, DateTime.parse(todayDateStr +' 03:00 AM'), 1);
        insert objServiceAppointment1;
        ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(objWorkOrder2.Id, objServiceTerritory.Id, DateTime.parse(todayDateStr +' 05:30 AM'), 1);
        insert objServiceAppointment2;
        ServiceAppointment objServiceAppointment3 = objTestDataFactory.getServiceAppointment(objWorkOrder3.Id, objServiceTerritory.Id, DateTime.parse(todayDateStr +' 11:30 AM'), 1);
        insert objServiceAppointment3;
        //ServiceAppointment objServiceAppointment4 = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, DateTime.parse(todayDateStr +' 03:00 PM'), 1);
        //insert objServiceAppointment4;

        //Create STM records. Parent then Secondary
        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        //objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, DateTime.parse('01/02/2018 05:30 AM'), DateTime.parse('01/02/2018 05:30 AM'));
        objServiceTerritoryMember.TerritoryType = 'P';
        objServiceTerritoryMember.ServiceResourceId = objServiceResource.Id;
        objServiceTerritoryMember.ServiceTerritoryId = objServiceTerritory.Id;
        //objServiceTerritoryMember.EffectiveStartDate = DateTime.parse('01/02/2018 05:30 AM');
        objServiceTerritoryMember.EffectiveStartDate = DateTime.now().addDays(-30);
        objServiceTerritoryMember.EffectiveEndDate = null;
        insert objServiceTerritoryMember;

        ServiceTerritoryMember objServiceTerritorySecondarMember1 = new ServiceTerritoryMember();
        //objServiceTerritorySecondarMember1 = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, subTer1.Id, DateTime.parse('01/02/2018 05:30 AM'), DateTime.parse('01/04/2018 05:30 AM'));
        objServiceTerritorySecondarMember1 = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, subTer1.Id, DateTime.now().addDays(-30), DateTime.now().addDays(+60));
        objServiceTerritorySecondarMember1.TerritoryType = 'S';
        insert objServiceTerritorySecondarMember1;

        ServiceTerritoryMember objServiceTerritoryMember2 = new ServiceTerritoryMember();
        //objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, DateTime.parse('01/02/2018 05:30 AM'), DateTime.parse('01/02/2018 05:30 AM'));
        objServiceTerritoryMember2.TerritoryType = 'P';
        objServiceTerritoryMember2.ServiceResourceId = objServiceResource2.Id;
        objServiceTerritoryMember2.ServiceTerritoryId = objServiceTerritory.Id;
        //objServiceTerritoryMember.EffectiveStartDate = DateTime.parse('01/02/2018 05:30 AM');
        objServiceTerritoryMember2.EffectiveStartDate = DateTime.now().addDays(-30);
        objServiceTerritoryMember2.EffectiveEndDate = null;
        insert objServiceTerritoryMember2;

        ServiceTerritoryMember objServiceTerritorySecondarMember2 = new ServiceTerritoryMember();
        //objServiceTerritorySecondarMember1 = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, subTer1.Id, DateTime.parse('01/02/2018 05:30 AM'), DateTime.parse('01/04/2018 05:30 AM'));
        objServiceTerritorySecondarMember2 = objTestDataFactory.getServiceTerritoryMember(objServiceResource2.Id, subTer2.Id, DateTime.now().addDays(-30), DateTime.now().addDays(+60));
        objServiceTerritorySecondarMember2.TerritoryType = 'S';
        insert objServiceTerritorySecondarMember2;

        Test.startTest();
        // Create AssignedResource
        AssignedResource as1 = new AssignedResource(ServiceResourceId=objServiceResource.Id,ServiceAppointmentId=objServiceAppointment1.Id);
        insert as1;
        AssignedResource as2 = new AssignedResource(ServiceResourceId=objServiceResource.Id,ServiceAppointmentId=objServiceAppointment2.Id);
        insert as2;
        AssignedResource as3 = new AssignedResource(ServiceResourceId=objServiceResource2.Id,ServiceAppointmentId=objServiceAppointment3.Id);
        insert as3;
        //AssignedResource as4 = new AssignedResource(ServiceResourceId=objServiceResource.Id,ServiceAppointmentId=objServiceAppointment4.Id);
        //insert as4;
        Test.stopTest();


    }

    // Test Methods
    static testMethod void testRefreshByServiceTerritoryId() {

        Test.startTest();
        serviceTerritory stp = [SELECT Id from serviceTerritory WHERE Name = 'Dandenong'];

        TDF_RefreshTerritories.RefreshByServiceTerritoryId(stp.Id);
        Test.stopTest();

    }
}