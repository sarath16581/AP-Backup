/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for auto follow helper and trigger TDF_AutoFollowParentRecords
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Removed reference to commented out methods
* 2020-09-07 - Andrew Judd  - Commented out method validateAutoFollowHelperMethod
*                           - Removed SeeAllData
*                           - Note that this test class is most likely redudant as remaining class TDF_AutoFollowHelper.unfollowScheduler
*                               can be tested via TDF_UnfollowWorkOrderBatchTest
* 2020-09-07 - Andrew Judd  - TODO: Confirm if validateAssignedResourceTrigger can be commented out and this entire test be deleted
*/
@isTest
public class TDF_AutoFollowParentRecordsTest{

    //@isTest(SeeAllData=true)
    @isTest()
    static void validateAssignedResourceTrigger(){
    
        TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
        objNotificationSch.Name = 'FollowWorkOrder';
        objNotificationSch.FeedMessage__c = 'Test';
        objNotificationSch.ScheduleTime__c = 24;
        insert objNotificationSch;

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
         
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf001@australiaPost.com');
        insert objAdminUser;

        User objAdminUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf002@australiaPost.com');
        insert objAdminUser1;

        Schema.Location objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        objVehicleLocation.Registration_Number__c = 'tEsT55431';
        insert objVehicleLocation;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        ServiceTerritoryMember objServiceTerritoryMember = new ServiceTerritoryMember();
        objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-3), System.now().addDays(7));
        insert objServiceTerritoryMember;
        
        String pdcRigidWORecordType = objTestDataFactory.getWorkOrderRTId('PDC - PrimeMover');

        WorkOrder objWorkOrder = new WorkOrder();
        objWorkOrder = objTestDataFactory.getWorkOrder(pdcRigidWORecordType);
        objWorkOrder.Status = 'New';            
        insert objWorkOrder;
        
        //TDF Enhance: change scheduled start to be approx 1.5 days in the past
        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(-36), 10);                
        insert objServiceAppointment;

        AssignedResource objAssignedResource = new AssignedResource();
        objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id);
        insert objAssignedResource; 

        objServiceAppointment = [SELECT ParentRecordId, SchedStartTime, SchedEndTime, (SELECT Id, ServiceResourceId, ServiceResource.RelatedRecordId FROM ServiceResources) FROM ServiceAppointment WHERE Id = :objServiceAppointment.Id]; 

        TDF_AutoFollowHelper.unfollowScheduler(objServiceAppointment);
         
    }

    // static testmethod void validateAutoFollowHelperMethod(){

    //     TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

    //     List<WorkOrder> workOrderList = new List<WorkOrder>();
    //     List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
    //     List<ServiceTerritoryMember> serviceTerritoryMemberList = new List<ServiceTerritoryMember>();
    //     List<AssignedResource> assignedResourceList = new List<AssignedResource>();        
    //     Integer counter = 0;

    //     if(TDF_NotificationScheduler__c.getAll().get('FollowWorkOrder') == null){
    //         TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
    //         objNotificationSch.Name = 'FollowWorkOrder';
    //         objNotificationSch.FeedMessage__c = 'Test';
    //         objNotificationSch.ScheduleTime__c = 24;
    //         insert objNotificationSch;
    //     }

    //     if(TDF_NotificationScheduler__c.getAll().get('DispatchBoardSACountCheck') == null){
    //         TDF_NotificationScheduler__c objNotificationSch = new TDF_NotificationScheduler__c();
    //         objNotificationSch.Name = 'DispatchBoardSACountCheck';
    //         objNotificationSch.Service_Appointment_Query_Limit__c = 300;
    //         objNotificationSch.Error_Message__c = 'Number of Service Appointment is more than <?>. Please refine the search by specifying Date Range.';
    //         insert objNotificationSch;
    //     }

    //     String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

    //     OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
    //     insert objOperatingHours;

    //     ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
    //     insert objServiceTerritory;

    //     Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    //     User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
    //     insert objAdminUser;

    //     ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
    //     insert objServiceResource;

    //     for(Integer i=0; i<1; i++){
    //         serviceTerritoryMemberList.add(objTestDataFactory.getServiceTerritoryMember(objServiceResource.Id, objServiceTerritory.Id, System.now(), System.now().addDays(counter+7)));
    //         counter += 7;
    //     }
    //     insert serviceTerritoryMemberList;

    //     Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
    //     insert objRouteTemplate;

    //     for(Integer i=0; i<5; i++){
    //         WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
    //         objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
    //         workOrderList.add(objWorkOrder);
    //     }
    //     insert workOrderList;
        
    //     counter = 0;
    //     for(WorkOrder objWorkOrder : workOrderList){
    //         ServiceAppointment objServiceAppointment = new serviceAppointment();
    //         objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addDays(counter), counter++);                
    //         objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;
    //         serviceAppointmentList.add(objServiceAppointment);

    //         objServiceAppointment = new ServiceAppointment();
    //         objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now().addHours(25), 1);
    //         objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;            
    //         serviceAppointmentList.add(objServiceAppointment);             
    //     }
    //     insert serviceAppointmentList;

    //     Schema.Location objVehicleLocation = new Schema.Location();
    //     objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
    //     insert objVehicleLocation;

    //     for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
    //         assignedResourceList.add(objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id));            
    //     }
    //     insert assignedResourceList;  

    //     //TDF_AutoFollowHelper.followScheduler();
    // }    
}