@isTest
public class TDF_DeleteWorkOrderFromDBTCtrl_Test{

    static testmethod void testDeleteWorkOrderFromDBTCtrl(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        for(Integer i=0; i<10; i++){
            WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
            objWorkOrder.Duty_Board__c = objRouteTemplate.Id;
            workOrderList.add(objWorkOrder);
        }
        insert workOrderList;

        PageReference pageRef = Page.TDF_DeleteWorkOrderFromDBT;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objRouteTemplate.Id);

        TDF_DeleteWorkOrderFromDBT_ControllerX objDeleteFromDBTController = new TDF_DeleteWorkOrderFromDBT_ControllerX(new ApexPages.StandardController(objRouteTemplate));

        objDeleteFromDBTController.confirmDeletion();

        objDeleteFromDBTController.startDate = System.today();
        objDeleteFromDBTController.endDate = System.today().addDays(1);

        objDeleteFromDBTController.confirmDeletion();

        System.assertEquals(10, workOrderList.size());

        objDeleteFromDBTController.deleteWorkOrders();

        workOrderList = [SELECT Id FROM WorkOrder WHERE Duty_Board__c =: objRouteTemplate.Id];

        System.assertEquals(0, workOrderList.size());

        objDeleteFromDBTController.cancel();        
    }
}