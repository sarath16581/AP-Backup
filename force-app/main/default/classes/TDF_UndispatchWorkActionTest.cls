/** 
* @author Andrew Judd
* @date 2020-09-04
* @domain Field Service 
* @description  Test class for the TDF_UndispatchWorkAction. 
*                   Note that the called method TDF_DispatchWork.undispatch is tested in TDF_DispatchWorkActionTest
*
* @changelog 
* 
*/
@isTest
public class TDF_UndispatchWorkActionTest {

    //Test undispatch work
    static testmethod void validateDispatchWorkMethodOne(){

        Boolean passBol;

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

        //#Test - Call undispatch work against a driver service resource. 
        //Note that full test of undispatch work is performed in TDF_DispatchWorkActionTest where all data is set up.
        TDF_UndispatchWorkAction tdfUDWA = new TDF_UndispatchWorkAction();
        String resultString = tdfUDWA.action(objDriverServiceResource1.Id, null, null, null, null);        

        //Expect no duty service resource message - Assert
        passBol = false;
        if (resultString.contains('No Duty Service resource')) passBol = true;
        //Assert
        System.assert(passBol, 'No Duty Service resource found message not returned'); 

    }
}