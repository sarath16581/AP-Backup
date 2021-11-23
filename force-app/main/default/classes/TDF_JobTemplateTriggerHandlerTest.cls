/** 
* @author Andrew Judd
* @date 2020-09-01
* @domain Field Service 
* @description  Test class for Job_Template_Trigger, JobTemplateTriggerHandler, and TDF_JobTemplateTriggerHandler
*
* @changelog 
* 
*/
@isTest
public class TDF_JobTemplateTriggerHandlerTest {

    //Test job template trigger
    static testmethod void validateJobTemplateTriggerMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //Create Duty Template 1
        Route_Template__c objRouteTemplate1 = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        insert objRouteTemplate1;

        //Create Duty Template 2
        Route_Template__c objRouteTemplate2 = objTestDataFactory.getDutyTemplate('DT62', objServiceTerritory.Id);
        insert objRouteTemplate2;

        //Create site location 1
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('DC Site', 'Site');
        insert objSiteLocation1;

        //Create site location 2
        Schema.Location objSiteLocation2 = new Schema.Location();
        objSiteLocation2 = objTestDataFactory.getLocation('Customer One', 'Site');
        insert objSiteLocation2;            

        //Create a collect Job Template at 0900
        Job_Template__c objJobTemplate1 =  objTestDataFactory.getJobTemplate(objRouteTemplate1.Id, objSiteLocation1.Id, 'Collection');
        insert objJobTemplate1;

        //Create a deliver Job Template at 1000
        Job_Template__c objJobTemplate2 =  objTestDataFactory.getJobTemplate(objRouteTemplate1.Id, objSiteLocation2.Id, 'Delivery');
        objJobTemplate2.Start_Time__c = '1000';
        insert objJobTemplate2;
                             
        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create a connected collect and deliver task template for Job 1 and Job 1 (connected)
        Task_Template__c objTaskTemplate1 = objTestDataFactory.getTaskTemplate(objRouteTemplate1.Id, objJobTemplate1.Id, objJobTemplate2.Id);
        objTaskTemplate1.Product__c = objProductULDE.Id;
        objTaskTemplate1.Monday__c = 5;
        objTaskTemplate1.Tuesday__c = 5;
        objTaskTemplate1.Wednesday__c = 5;
        objTaskTemplate1.Thursday__c = 5;
        objTaskTemplate1.Friday__c = 5;
        objTaskTemplate1.Saturday__c = 5;
        objTaskTemplate1.Sunday__c = 5;
        insert objTaskTemplate1;

        //Create a collect task template for Job 2 (not connected)
        Task_Template__c objTaskTemplate2 = objTestDataFactory.getTaskTemplate(objRouteTemplate1.Id, objJobTemplate2.Id, null);
        objTaskTemplate2.Product__c = objProductULDE.Id;
        objTaskTemplate2.Monday__c = 10;
        objTaskTemplate2.Tuesday__c = 10;
        objTaskTemplate2.Wednesday__c = 10;
        objTaskTemplate2.Thursday__c = 10;
        objTaskTemplate2.Friday__c = 10;
        objTaskTemplate2.Saturday__c = 10;
        objTaskTemplate2.Sunday__c = 10;
        insert objTaskTemplate2;

        //Create a deliver task template for Job 2 (not connected)
        Task_Template__c objTaskTemplate3 = objTestDataFactory.getTaskTemplate(objRouteTemplate1.Id, null, objJobTemplate2.Id);
        objTaskTemplate3.Product__c = objProductULDE.Id;
        objTaskTemplate3.Monday__c = 12;
        objTaskTemplate3.Tuesday__c = 12;
        objTaskTemplate3.Wednesday__c = 12;
        objTaskTemplate3.Thursday__c = 12;
        objTaskTemplate3.Friday__c = 12;
        objTaskTemplate3.Saturday__c = 12;
        objTaskTemplate3.Sunday__c = 12;
        insert objTaskTemplate3;        

        //##Commence tests
        List<Task_Template__c> taskTempList;
        //#Test 1 - Reassign Job Template 1 to Duty Template 2 - confirm all its tasks are then associated to Duty Template 2
        system.runAs(new User(Id=UserInfo.getUserId())){
            objJobTemplate1.Route_Template__c = objRouteTemplate2.Id;
            update objJobTemplate1;
        }

        //Assert task template 1 now associated to Duty Template 2
        taskTempList = [SELECT Id FROM Task_Template__c WHERE DTID__c = :objRouteTemplate2.Id AND Id = :objTaskTemplate1.Id];
        System.assert(taskTempList.size()==1, 'Task Template 1 was not reassigned to Duty Template 2');

        //#Test 2 - Reassign Job Template 2 to Duty Template 2 - confirm all its tasks are then associated to Duty Template 2
        system.runAs(new User(Id=UserInfo.getUserId())){
            objJobTemplate2.Route_Template__c = objRouteTemplate2.Id;
            update objJobTemplate2;
        }

        //Assert task templates 2 and 3 now associated to Duty Template 2
        taskTempList = [SELECT Id FROM Task_Template__c 
                        WHERE DTID__c = :objRouteTemplate2.Id 
                        AND (Id = :objTaskTemplate2.Id OR Id = :objTaskTemplate3.Id)];
        System.assert(taskTempList.size()==2, 'Task Templates 2 and 3 were not reassigned to Duty Template 2');        

        //#Test 3 - Delete Job Template 1 - confirm all its tasks are deleted
        delete objJobTemplate1;

        //Assert task template 1 also deleted
        taskTempList = [SELECT Id FROM Task_Template__c 
                        WHERE Id = :objTaskTemplate1.Id];
        System.assert(taskTempList.size()==0, 'Task Template 1 was not deleted');  

        //#Test 4 - Delete Job Template 2 - confirm all its tasks are deleted
        delete objJobTemplate2;

        //Assert task templates 2 and 3 also deleted
        taskTempList = [SELECT Id FROM Task_Template__c 
                        WHERE Id = :objTaskTemplate2.Id OR Id = :objTaskTemplate3.Id];
        System.assert(taskTempList.size()==0, 'Task Templates 2 and 3 were not deleted');          

    }

}