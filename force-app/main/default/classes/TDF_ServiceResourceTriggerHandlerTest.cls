/** 
* @author Andrew Judd
* @date 2020-09-11
* @domain Field Service 
* @description  Test class for ServiceResourceTrigger trigger, ServiceResourceTriggerHandler, and TDF_ServiceResourceTriggerHandler
*
* @changelog 
* 
*/
@isTest
public class TDF_ServiceResourceTriggerHandlerTest {

    //Test service resource trigger hander
    static testmethod void validateServiceResourceTriggerMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objUser1 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objUser1;
        User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@australiaPost.com');
        insert objUser2;           

        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        //Create Driver Service Resource 1 - to activate the crew
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Driver Service Resource 2 - to activate the crew
        ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
        insert objDriverServiceResource2;

        //Create Duty Service Resource 1
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61', objDriverServiceResource1.Id, System.now().addDays(-3), System.now().addDays(-2));
        insert objDutyServiceResource1;                    

        //##Commence tests
        //Test - Update Driver Name 
        objDriverServiceResource2.Name = 'Driver 3';
        update objDriverServiceResource2;

        //Assert that External Name has been update
        System.assert([SELECT External_Name__c FROM ServiceResource WHERE Id = :objDriverServiceResource2.Id].External_Name__c == 'Driver 3', 
                        'Driver External Name was not updated');
    }

}