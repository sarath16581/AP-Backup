/** 
* @author Andrew Judd
* @date 2020-09-07
* @domain Field Service 
* @description  Test class for TDF_DisplayUnresourcedDutiesAction
*
* @changelog 
* 
*/
@isTest
public class TDF_DisplayUnresourcedDutiesActionTest {

    //Test method
    static testmethod void validateDisplayUnresourcedMethodOne(){

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

        //Create Duty Service Resource 
        //Note Driver Service Resource and start and end dates are for the inital SCM required to activate the Service Crew
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, startDateTime, endDateTime);
        insert objDutyServiceResource1; 

        //Create a Service Territory Member for the Duty
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;

        TDF_DisplayUnresourcedDutiesAction tdfDURDA = new TDF_DisplayUnresourcedDutiesAction();
        
        //#Test - Call display unresourced for the duty with no driver assigned
        String resultString = tdfDURDA.action(null, objServiceTerritoryMember.Id, System.now(), null, null);        

        //Assert - Expect duty has no driver assignment message
        System.assert(resultString.contains('The following duties do not have a driver assigned'), 'The following duties do not have a driver assigned message not returned'); 

    }    

}