@isTest
public class TDF_UnfollowWorkOrderBatchTest{
    
    static testmethod void unfollowWorkOrderBatchTestMethod(){

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

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

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

            objServiceAppointment = new ServiceAppointment();
            objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, System.now(), 1);
            objServiceAppointment.Duty_Board__c = objRouteTemplate.Id;                
            serviceAppointmentList.add(objServiceAppointment);
        }
        insert serviceAppointmentList;

        Schema.Location objVehicleLocation = new Schema.Location();
        objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        insert objVehicleLocation;

        for(ServiceAppointment objServiceAppointment : serviceAppointmentList){
            assignedResourceList.add(objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objServiceResource.Id));            
        }
        insert assignedResourceList;

        Test.startTest();
        TDF_UnfollowWorkOrderBatch objBatch = new TDF_UnfollowWorkOrderBatch();
        Database.executeBatch(objBatch);
        Test.stopTest();
    }    
}