/** 
* @author Andrew Judd
* @date 2020-09-08
* @domain Field Service 
* @description  Test class for the TDF_MessageCloseAction class
*
* @changelog 
*                           
*/
@IsTest()
public class TDF_MessageCloseActionTest {

    //Test message close
    static testmethod void validateMessageCloseMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        //Create a Work Order and Service Appointment with Message Active as true
        String woRecordTypeString = objTestDataFactory.getWorkOrderRTId('Standard');
        WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(woRecordTypeString);
        insert objWorkOrder1;
        ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(objWorkOrder1.Id, objServiceTerritory.Id, System.now(), 10);               
        objServiceAppointment1.Message_Active__c = true;
        insert objServiceAppointment1;

        List<Id> saIdList = new List<Id>();
        saIdList.add(objServiceAppointment1.Id);

        //#Test 1 - Call action from controller
        Test.startTest();
        TDF_MessageCloseAction tdfMCA = new TDF_MessageCloseAction();
        String resultString = tdfMCA.action(saIdList, null, null, null);
        Test.stopTest();

        //Assert that message active flag is now false
        Boolean msgActiveFlag = [SELECT Message_Active__c FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id].Message_Active__c;
        System.assert(msgActiveFlag == false, 'The message active flag on the Service Appointment was not set to false');

    } 
}