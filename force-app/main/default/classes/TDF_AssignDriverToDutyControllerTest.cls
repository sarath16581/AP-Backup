/** 
* @author Andrew Judd
* @date 2020-09-02
* @domain Field Service 
* @description  Test class for the Assign Driver to Duty form, controller, and TDF_CreateServiceCrewMember
*
* @changelog 
* 
*/
@isTest
public class TDF_AssignDriverToDutyControllerTest {

    static testmethod void validateAssignDriverToDutyMethodOne(){

        String rrId;
        Roster__c objRoster;
        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean passBol;
        Datetime startDateTime;
        Datetime endDateTime;
        //Note we override this value below to avoid timezone risk
        String startGantt = String.valueOf(System.now().month()) + '-' + String.valueOf(System.now().day()) + '-' + String.valueOf(System.now().year());

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        //Create primary ST
        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //Create users
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf1@auspost.com');
        insert objUser1;
        User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@auspost.com');
        insert objUser2;

        //Create Driver Service Resource 1
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Driver Service Resource 2 (used to activate the Service Crew)
        ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
        insert objDriverServiceResource2;

        //Create Duty Service Resource 1. 
        //Note Driver Service Resource and start and end dates are for the inital SCM required to activate the Service Crew
        //-Use Driver 2 so checks for Driver 1 below are clear
        startDateTime = System.now().addDays(-3);
        endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource2.Id, startDateTime, endDateTime);
        insert objDutyServiceResource1;

        //Create Service Territory Member records assigning duties and drivers to the ST
        ServiceTerritoryMember objServiceTerritoryMemberDuty = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMemberDuty;
        ServiceTerritoryMember objServiceTerritoryMemberDriver = objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMemberDriver;

        //Get work order record type id
        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');

        //Create a Work Order
        WorkOrder objWorkOrder = objTestDataFactory.getWorkOrder(standardWORecordType);
        insert objWorkOrder;

        //Create a Service Appointment
        startDateTime = System.now().addMinutes(30);
        ServiceAppointment objServiceAppointment = objTestDataFactory.getServiceAppointment(objWorkOrder.Id, objServiceTerritory.Id, startDateTime, 30);
        insert objServiceAppointment;

        //Assign the Service Appointment to the Duty
        insert objTestDataFactory.getAssignedResource(objServiceAppointment.Id, objDutyServiceResource1.Id);

        //Set the SA to dispatched
        objServiceAppointment.Status = 'Dispatched';
        update objServiceAppointment;

        //Set page
        PageReference pageRef = Page.TDF_AssignDriverToDuty;
        Test.setCurrentPage(pageRef);
        TDF_AssignDriverToDutyController objController;

        //#Test 1 - selection of a driver from duty in gantt and assign
        pageRef.getParameters().put('id', objDutyServiceResource1.Id);
        pageRef.getParameters().put('stm', objServiceTerritoryMemberDuty.Id);
        pageRef.getParameters().put('start', startGantt);

        objController = new TDF_AssignDriverToDutyController();
        objController.startDate = System.today(); 
        objController.endDate = System.today();
        
        //Duty is Id, so set selected record to driver
        objController.selectedSRForAssignment = objDriverServiceResource1.Id;
        objController.assignDriver();

        //Assert - confirm assignment created for the driver
        List<ServiceCrewMember> scmTestList;
        scmTestList = [SELECT Id FROM ServiceCrewMember WHERE ServiceResourceId = :objDriverServiceResource1.Id];
        //scmTestList = [SELECT Id, ServiceResourceId FROM ServiceCrewMember];
        System.debug('scmTestList =' + scmTestList);
        System.assert(scmTestList.size() == 1, 'An SCM for the driver assign from duty was not created');

        //#Test 2 - remove assignment by assigning none
        pageRef.getParameters().put('id', objDutyServiceResource1.Id);
        pageRef.getParameters().put('stm', objServiceTerritoryMemberDuty.Id);
        pageRef.getParameters().put('start', startGantt);

        objController = new TDF_AssignDriverToDutyController();
        objController.startDate = System.today(); 
        objController.endDate = System.today();
        
        //Set selected SR as empty string (none)
        objController.selectedSRForAssignment = null;
        objController.assignDriver(); 
        
        //Assert - confirm assignment removed for the driver
        scmTestList = [SELECT Id FROM ServiceCrewMember WHERE ServiceResourceId = :objDriverServiceResource1.Id];
        System.assert(scmTestList.size() == 0, 'The driver assignment was not deleted');

        //#Test 3 - selection of a duty from driver in gantt and assign
        pageRef.getParameters().put('id', objDriverServiceResource1.Id);
        pageRef.getParameters().put('stm', objServiceTerritoryMemberDriver.Id);
        pageRef.getParameters().put('start', startGantt);

        objController = new TDF_AssignDriverToDutyController();
        objController.startDate = System.today(); 
        objController.endDate = System.today();
        
        //Driver is Id, so set selected record to duty
        objController.selectedSRForAssignment = objDutyServiceResource1.Id;
        objController.assignDriver();

        //Assert - confirm assignment created for the driver
        scmTestList = [SELECT Id FROM ServiceCrewMember WHERE ServiceResourceId = :objDriverServiceResource1.Id];
        System.assert(scmTestList.size() == 1, 'An SCM for the driver assign from driver was not created');

    }

}