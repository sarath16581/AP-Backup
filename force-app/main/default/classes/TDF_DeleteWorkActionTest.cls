/** 
* @author Andrew Judd
* @date 2020-09-07
* @domain Field Service 
* @description  Test class for the TDF_DeleteWorkAction
*
* @changelog 
* 
*/
@isTest
public class TDF_DeleteWorkActionTest {

    static testmethod void validateScheduleToDutyMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objUser1;

        //Create Driver Service Resource 
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Service Territory Member record assigning driver SR 1 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create Duty Service Resource
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61',objDriverServiceResource1.Id, startDateTime, endDateTime );
        insert objDutyServiceResource1;

        //Create Service Territory Member record assigning duty SR to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create site location 
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('Depot', 'Site');
        insert objSiteLocation1;

        String standardWORecordType = objTestDataFactory.getWorkOrderRTId('Standard');
        
        //Create Work Order and Service Appointment 
        WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(standardWORecordType);
        objWorkOrder1.Duty_Day__c = System.today();
        insert objWorkOrder1;
        ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(objWorkOrder1.Id, objServiceTerritory.Id, System.now(), 30);
        objServiceAppointment1.Work_Order__c = objWorkOrder1.Id;
        insert objServiceAppointment1;

        //Assign the service appointment to duty
        AssignedResource objAssignedResource = objTestDataFactory.getAssignedResource(objServiceAppointment1.Id, objDutyServiceResource1.Id);
        insert objAssignedResource;

        TDF_DeleteWorkAction tdfDWA = new TDF_DeleteWorkAction();
        
        //#Test - Call delete work for the selected duty
        String resultString = tdfDWA.action(objDutyServiceResource1.Id,null, System.now(), null, null);        

        //Assert - message string returned to confirm work order deleted
        System.assert(resultString.contains('Work Orders deleted'), 'Work Orders deleted message not returned');   

    }
}