@isTest
public class TDF_DeleteWorkOrderFromJTCtrl_Test{

    static testmethod void testDeleteWorkOrderFromJTCtrl(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objLocation.Id);
        insert objJobTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String standardWORecordType = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Standard').getRecordTypeId();

        for(Integer i=0; i<10; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            objWorkOrder.Job_Template__c = objJobTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;

        PageReference pageRef = Page.TDF_DeleteWorkOrderFromJobTemplate;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objJobTemplate.Id);

        TDF_DeleteWorkOrderFromJT_ControllerX objDeleteFromJTController = new TDF_DeleteWorkOrderFromJT_ControllerX(new ApexPages.StandardController(objJobTemplate));

        objDeleteFromJTController.confirmDeletion();

        objDeleteFromJTController.startDate = System.today().addDays(-1);
        objDeleteFromJTController.endDate = System.today().addDays(1);

        objDeleteFromJTController.confirmDeletion();

        System.assertEquals(10, workOrderList.size());

        objDeleteFromJTController.deleteWorkOrders();

        workOrderList = [SELECT Id FROM WorkOrder WHERE Duty_Board__c =: objJobTemplate.Id];

        System.assertEquals(0, workOrderList.size());

        objDeleteFromJTController.cancel();       
    }
}