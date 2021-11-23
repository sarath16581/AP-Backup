/** 
* @author Andrew Judd
* @date 2020-09-01
* @domain Field Service 
* @description  Test class for the Edit Job form and controller
*
* @changelog 
* 
*/
@isTest
public class TDF_EditJobControllerTest {

    //Test edit a job with deliver Job and a preceding collect job for search result
    static testmethod void validateEditJobMethodOne(){

        List<ServiceAppointment> saList;

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        //Create Driver Service Resource
        ServiceResource objDriverServiceResource = objTestDataFactory.getServiceResource('Driver 1', objAdminUser);
        insert objDriverServiceResource;

        //Create Duty Service Resource
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource = objTestDataFactory.getDutyServiceResource('DT61',objDriverServiceResource.Id, startDateTime, endDateTime );
        insert objDutyServiceResource;

        //Create Service Territory Member record assigning duty SR to the ST
        ServiceTerritoryMember objServiceTerritoryMember = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember;

        //Create Duty Template
        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        objRouteTemplate.Duty_SR__c = objDutyServiceResource.Id; //Set the operational duty
        insert objRouteTemplate;

        //Create site location 1
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('DC Site', 'Site');
        insert objSiteLocation1;

        //Create site location 2
        Schema.Location objSiteLocation2 = new Schema.Location();
        objSiteLocation2 = objTestDataFactory.getLocation('Customer One', 'Site');
        insert objSiteLocation2;            

        //Create a collect Job Template at 1200 
        Job_Template__c objJobTemplate1 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation1.Id, 'Collection');
        insert objJobTemplate1;

        //Create a deliver Job Template at 1300
        Job_Template__c objJobTemplate2 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation2.Id, 'Delivery');
        objJobTemplate2.Start_Time__c = '1300';
        insert objJobTemplate2;
                             
        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create a collect task template for Job 1 (not connected)
        Task_Template__c objTaskTemplateC = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate1.Id, null);
        objTaskTemplateC.Product__c = objProductULDE.Id;
        objTaskTemplateC.Monday__c = 5;
        objTaskTemplateC.Tuesday__c = 5;
        objTaskTemplateC.Wednesday__c = 5;
        objTaskTemplateC.Thursday__c = 5;
        objTaskTemplateC.Friday__c = 5;
        objTaskTemplateC.Saturday__c = 5;
        objTaskTemplateC.Sunday__c = 5;
        insert objTaskTemplateC;

        //Create a deliver task template for Job 2 (not connected)
        Task_Template__c objTaskTemplateD = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, null, objJobTemplate2.Id);
        objTaskTemplateD.Product__c = objProductULDE.Id;
        objTaskTemplateD.Monday__c = 5;
        objTaskTemplateD.Tuesday__c = 5;
        objTaskTemplateD.Wednesday__c = 5;
        objTaskTemplateD.Thursday__c = 5;
        objTaskTemplateD.Friday__c = 5;
        objTaskTemplateD.Saturday__c = 5;
        objTaskTemplateD.Sunday__c = 5;
        insert objTaskTemplateD;

        //Call generate work to create a Service Appointment, Work Order and Work Order Line Items
        TDF_GenerateWork tdfGW = new TDF_GenerateWork();
        Date startDate = System.today(); 
        String resultString = tdfGW.createJobs(startDate, startDate, objRouteTemplate.Id, null);

        //Get the Service Appointment for the deliver job
        saList = [SELECT Id, Work_Order__c FROM ServiceAppointment WHERE Work_Order__r.LocationId = :objSiteLocation2.Id LIMIT 1];
        
        //Confirm deliver sa created
        System.assert(saList.size() == 1, 'No deliver Service Appointment created');

        String saId = saList[0].Id;

        PageReference pageRef = Page.TDF_EditJob;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', saId);

        TDF_EditJobController objController = new TDF_EditJobController();

        //Do the search on this deliver job in its deliver woli
        //This will detect the prior collect job for display in the custom lookup
        pageRef.getParameters().put('said', saId);
        pageRef.getParameters().put('task', 'DT');
        objController.search();

        //Get the Service Appointment for the collect job
        saList = [SELECT Id, Work_Order__c FROM ServiceAppointment WHERE Work_Order__r.LocationId = :objSiteLocation1.Id LIMIT 1];
        
        //Confirm collect sa created
        System.assert(saList.size() == 1, 'No collect Service Appointment created');

        //Add wolis to form and remove
        objController.addWOLIDT();
        objController.addWOLICF();
        objController.deleteDTWOLI();
        objController.deleteCFWOLI();
        objController.getFormTag();
        objController.getTextBox();

        //Save
        objController.saveTemplates();

    }

    //Test edit a job with a collect WOLI - delete the WOLI and create a new one
    static testmethod void validateEditJobMethodTwo(){

        List<WorkOrderLineItem> woliTestList;
        
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();
        
        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        //Create Duty Template
        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        insert objRouteTemplate;

        //Create site location 1
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('DC Site', 'Site');
        insert objSiteLocation1;

        //Create site location 2
        Schema.Location objSiteLocation2 = new Schema.Location();
        objSiteLocation2 = objTestDataFactory.getLocation('Customer One', 'Site');
        insert objSiteLocation2;            

        //Create a collect Job Template
        Job_Template__c objJobTemplate1 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation1.Id, 'Delivery & Collection');
        insert objJobTemplate1;
                           
        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create a collect task template for Job 1 (not connected)
        Task_Template__c objTaskTemplateC = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate1.Id, null);
        objTaskTemplateC.Product__c = objProductULDE.Id;
        objTaskTemplateC.Monday__c = 5;
        objTaskTemplateC.Tuesday__c = 5;
        objTaskTemplateC.Wednesday__c = 5;
        objTaskTemplateC.Thursday__c = 5;
        objTaskTemplateC.Friday__c = 5;
        objTaskTemplateC.Saturday__c = 5;
        objTaskTemplateC.Sunday__c = 5;
        insert objTaskTemplateC;

        //Call generate work to create a Service Appointment, Work Order, and Collect WOLI
        TDF_GenerateWork tdfGW = new TDF_GenerateWork();
        Date startDate = System.today(); 
        String resultString = tdfGW.createJobs(startDate, startDate, objRouteTemplate.Id, null);

        //Get the Service Appointment record created
        ServiceAppointment[] saList = [SELECT Id, Work_Order__c FROM ServiceAppointment WHERE Duty_Board__c = :objRouteTemplate.Id LIMIT 1];
        //If no work order created, fail test
        if (saList.size() != 1){
            System.assert(false, 'No Service Appointment created');
        }

        String saId = saList[0].Id;

        PageReference pageRef = Page.TDF_EditJob;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', saId);
        System.debug('saId = ' + saId);

        TDF_EditJobController objController = new TDF_EditJobController();

        //#Delete the existing collect WOLI
        objController.deleteCFWOLI();

        //Save to commit the delete
        objController.saveTemplates();

        //Get any WOLIs
        woliTestList = [SELECT Id FROM WorkOrderLineItem WHERE Collect_From_Work_Order__r.Duty_Board__c = :objRouteTemplate.Id];
        System.Assert(woliTestList.size() == 0, 'There should be no collect from work order line item');

        //#Create a a new collect WOLI
        objController.addWOLICF();

        //Set woli values
        for(WorkOrderLineItem woli : objController.woliCFList){
            woli.Product__c = objProductULDE.Id;
            woli.Requested_Quantity__c = 4;
        }

        //Save to commit
        objController.saveTemplates();

        //Get the collect WOLI record created and assert
        woliTestList = [SELECT Id FROM WorkOrderLineItem WHERE Collect_From_Work_Order__r.Duty_Board__c = :objRouteTemplate.Id];
        System.Assert(woliTestList.size() == 1, 'There should be one collect from work order line item');

        //#Create a a new deliver WOLI
        objController.addWOLIDT();

        //Set woli values
        for(WorkOrderLineItem woli : objController.woliDTList){
            woli.Product__c = objProductULDE.Id;
            woli.Requested_Quantity__c = 6;
        }

        //Save to commit
        objController.saveTemplates(); 
        
        //Get the WOLI record created and assert
        woliTestList = [SELECT Id FROM WorkOrderLineItem WHERE Deliver_To_Work_Order__r.Duty_Board__c = :objRouteTemplate.Id];
        System.Assert(woliTestList.size() == 1, 'There should be one deliver to work order line item');

    }

}