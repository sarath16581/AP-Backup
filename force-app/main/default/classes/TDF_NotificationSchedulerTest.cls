/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for scheduled jobs based on the Notification Scheduler custom settings
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               - Deleted validateNotificationSchedulerOne - this was for Service Reports which are not used
*                               - Removed SeeAllData (to produce consistent results)
*                               - Changed API Version from 40 to 48 to support Crew Data Model
*                               - Created seperate test methods for:
*                                   - Rest Break Notification
*                                   - Refresh Territories
*                               - Created new test methods for:
*                                   - DispatchWorkScheduler
*                                   - GenerateWorkScheduler
* 2020-09-10 - Andrew Judd - Added Asserts                             
*/
//@isTest(SeeAllData = true)
@isTest
public class TDF_NotificationSchedulerTest{

    //Test method 1 - for Rest Break Scheduled job
    static testmethod void validateSchedulerOneRestBreak(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        System.runAs(objAdminUser){

            //Set up custom settings
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'RestBreakNotificationScheduler';
            objNotificationSch.FeedMessage__c = 'Rest Break Notification';
            objNotificationSch.ScheduleTime__c = 30;
            insert objNotificationSch;

            OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
            insert objOperatingHours;

            ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
            insert objServiceTerritory;

            //#Create Driver 1 - Set the FFD passed more than 5 hrs to ensure alert of driver and supervisor
            ServiceResource objServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objAdminUser);
            objServiceResource1 .Fit_For_Duty_Passed__c = System.now().addMinutes(-335);
            insert objServiceResource1;
            
            //Create STM
            insert(objTestDataFactory.getServiceTerritoryMember(objServiceResource1.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7)));

            String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

            //Create Rest Break Work Order and Service Appointment for driver 1
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.IsRestBreak__c = true;
            insert objWorkOrder;
            ServiceAppointment objServiceAppointment;   
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(5), 30);                 
            insert objServiceAppointment;

            //Assign driver 1
            insert (objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource1.Id));

            //#Create Driver 2 - Set the FFD passed 4 hr 40 min to ensure alert just driver
            User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@australiaPost.com');
            insert objUser2; 

            ServiceResource objServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
            objServiceResource2 .Fit_For_Duty_Passed__c = System.now().addMinutes(-280);
            insert objServiceResource2;
           
            //Create STM
            insert(objTestDataFactory.getServiceTerritoryMember(objServiceResource2.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7)));

            //Create Rest Break Work Order and Service Appointment for driver 1
            WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder2.IsRestBreak__c = true;
            insert objWorkOrder2;
            ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(objWorkOrder2.Id, objServiceTerritory.Id, System.now().addHours(5), 30);                 
            insert objServiceAppointment2;

            //Assign driver 2
            insert(objTestDataFactory.getAssignedResource(objServiceAppointment2.Id, objServiceResource2.Id));
            
            //Call class to scheduled the rest break notification scheduler
            Test.startTest();
            TDF_SchedulerUtility.scheduleJobs();
            Test.stopTest();

        }
    }
    //Test method 2 - for Refresh Territory Scheduler
    static testmethod void validateSchedulerTwoRefreshTerritories(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        System.runAs(objAdminUser){

            //Create custom settings for scheduler util
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'RefreshTerritoriesScheduler';
            objNotificationSch.ScheduleTime__c = 30;
            insert objNotificationSch;

            //Create custom settings for Refresh Territories
            TDF_Settings__c objTDFSettings = new TDF_Settings__c();
            objTDFSettings.Refresh_Territory_Expiry__c = 7;
            objTDFSettings.Assignment_End_Date_Time_Offset__c = 14.0;
            objTDFSettings.Assignment_Start_Date_Time_Offset__c = 2.0;
            objTDFSettings.Refresh_All_Territories__c = true;
            insert objTDFSettings;

            OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
            insert objOperatingHours;

            ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
            insert objServiceTerritory;
        
            //Call class to schedule the refresh territory job
            Test.startTest();
            TDF_SchedulerUtility.scheduleJobs();
            Test.stopTest();
        }
    }
    //Test method 3 - for Generate Work Scheduler
    static testmethod void validateSchedulerThreeGenerateWork(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        System.runAs(objAdminUser){

            //Set up the custom settings
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'GenerateWorkScheduler';
            objNotificationSch.ScheduleTime__c = 30;
            insert objNotificationSch;

            OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
            insert objOperatingHours;

            ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
            insert objServiceTerritory;

            //Create Driver Service Resource 1 - to activate the crew
            ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objAdminUser);
            insert objDriverServiceResource1;

            //Create Duty Service Resource 1. 
            ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, System.now().addDays(-3), System.now().addDays(-2));
            objDutyServiceResource1.Auto_Generate_Work__c = true;
            insert objDutyServiceResource1;   
            
            //Create Service Territory Member record assigning duty SR 1 to the ST
            insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

            //Create Duty Template
            Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
            objRouteTemplate.Duty_SR__c = objDutyServiceResource1.Id; //set the operational duty
            insert objRouteTemplate;

            //Create site location
            Schema.Location objSiteLocation1 = new Schema.Location();
            objSiteLocation1 = objTestDataFactory.getLocation('DC Site', 'Site');
            insert objSiteLocation1;       

            //Create an FFD Job Template
            Job_Template__c objJobTemplate1 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation1.Id, 'Fit For Duty');
            insert objJobTemplate1;            
            
            //Call class to scheduled the Generate Work Scheduler
            Test.startTest();
            TDF_SchedulerUtility.scheduleJobs();
            Test.stopTest();

            //Assert that work generated for Duty Template 1
            List<WorkOrder> woList = [SELECT Id FROM WorkOrder WHERE Duty_Board__c = :objRouteTemplate.Id];
            System.assert(woList.size()==0,'The FFD job was not created');
        }
    }
    //Test method 4 - for Dispatch Work Scheduler
    static testmethod void validateSchedulerFourDispatchWork(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;
        User objAdminUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@australiaPost.com');
        insert objAdminUser2;

        System.runAs(objAdminUser){

            //Set up the custom settings
            TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
            objNotificationSch.Name = 'DispatchWorkScheduler';
            objNotificationSch.ScheduleTime__c = 30;
            insert objNotificationSch;

            OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
            insert objOperatingHours;

            ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
            insert objServiceTerritory;

            //Create Driver Service Resource 1 - to activate the crew
            ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objAdminUser);
            insert objDriverServiceResource1;

            //Create Driver Service Resource 2 - to activate the crew
            ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objAdminUser2);
            insert objDriverServiceResource2;

            //Create Duty Service Resource 1 
            ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, System.now().addDays(-3), System.now().addDays(-2));
            insert objDutyServiceResource1;     
            
            //Create Duty Service Resource 2
            ServiceResource objDutyServiceResource2 = objTestDataFactory.getDutyServiceResource('DT62', objDriverServiceResource2.Id, System.now().addDays(-3), System.now().addDays(-2));
            insert objDutyServiceResource2;             

            //Create STMs
            insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7)));
            insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource2.Id, objServiceTerritory.Id, System.now(), System.now().addDays(7)));

            String ffdWORecordType = objTestDataFactory.getWorkOrderRTId('Fit For Duty');

            //Create FFD Work Order and Service Appointment for Duty 1
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(ffdWORecordType);
            insert objWorkOrder;
            ServiceAppointment objServiceAppointment;   
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addMinutes(10), 30); 
            objServiceAppointment.Work_Order__c = objWorkOrder.Id;         
            insert objServiceAppointment;

            //Create FFD Work Order and Service Appointment for Duty 2
            WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(ffdWORecordType);
            insert objWorkOrder2;
            ServiceAppointment objServiceAppointment2;   
            objServiceAppointment2 = objTestDataFactory.getServiceAppointment(objWorkOrder2.Id, objServiceTerritory.Id, System.now(), 25); 
            objServiceAppointment2.Work_Order__c = objWorkOrder2.Id;           
            insert objServiceAppointment2;

            //Assign SA 1 to Service Resource Duty 1
            insert (objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objDutyServiceResource1.Id));
            //insert (objTestDataFactory.getAssignedResource(objServiceAppointment2.Id, objDutyServiceResource2.Id));

            //Assign a driver with assignment starting before the FFD start (i.e 1 hrs before now)
            ServiceCrewMember objServiceCrewMember1 = objTestDataFactory.getServiceCrewMember(objDutyServiceResource1.ServiceCrewId, objDriverServiceResource1.Id, DateTime.now().addHours(-1), DateTime.now().addHours(10));
            insert objServiceCrewMember1;            

            //Call class to scheduled the Generate Work Scheduler
            Test.startTest();
            TDF_SchedulerUtility.scheduleJobs();
            Test.stopTest();

            //Assert that job 2 still scheduled
            System.assert([SELECT Status FROM ServiceAppointment WHERE Id = :objServiceAppointment2.Id].Status=='Scheduled','SA 2 is not schueduled');

        }
    }
}