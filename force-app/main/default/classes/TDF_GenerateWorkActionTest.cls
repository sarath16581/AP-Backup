/** 
* @author Andrew Judd
* @date 2020-09-05
* @domain Field Service 
* @description  Test class for the TDF_GenerateWorkAction
*
* @changelog 
* 
*/
@isTest
public class TDF_GenerateWorkActionTest {

    //Test method to call 
    static testmethod void validateGenerateWorkAction(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //Create Driver Service Resource - to activate the crew
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objAdminUser);
        insert objDriverServiceResource1;

        //Create Duty Service Resource
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, System.now().addDays(-3), System.now().addDays(-2));
        insert objDutyServiceResource1;            

        //Create Duty Template
        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        objRouteTemplate.Duty_SR__c = objDutyServiceResource1.Id; //set the operational duty
        insert objRouteTemplate;
        
        //Call class
        Test.startTest();
        TDF_GenerateWorkAction tdfGWA = new TDF_GenerateWorkAction();
        String resultString = tdfGWA.action(objDutyServiceResource1.Id, null, System.now(), System.now(), null);
        Test.stopTest();

        //Assert
        System.assert(resultString.contains(' for duty DT61'),'Generate work not successfully called');
        
    }    

}