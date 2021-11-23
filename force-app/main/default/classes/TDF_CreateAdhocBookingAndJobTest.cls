/** 
* @author Andrew Judd
* @date 2020-09-01
* @domain Field Service 
* @description  Test class for the Create Adhoc Booking and Job form and controller
*
* @changelog 
* 
*/
@isTest
public class TDF_CreateAdhocBookingAndJobTest {
    
    //Test create Adhoc Template without creating a job
    static testmethod void validateCreateAdhocBookingMethodOne(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        //Create Adhoc Duty Template
        Route_Template__c objRouteTemplateAdhoc = objTestDataFactory.getDutyTemplate('Adhoc - Dandenong', objServiceTerritory.Id);
        objRouteTemplateAdhoc.Is_Adhoc__c = true; //set as an adhoc template
        insert objRouteTemplateAdhoc;

        //Create site location
        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dandenong Depot', 'Site');
        insert objSiteLocation;

        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create ULD - Full product
        Product2 objProductULDF = objTestDataFactory.getProduct('ULD - Full');
        insert objProductULDF;

        PageReference pageRef = Page.TDF_CreateAdhocJob;
        Test.setCurrentPage(pageRef);

        TDF_CreateAdhocBookingAndJob objController = new TDF_CreateAdhocBookingAndJob();

        //Set the template as an adhoc
        objController.objJobTemplate.Route_Template__c = objRouteTemplateAdhoc.Id;
        objController.objJobTemplate.Start_Time__c = '0900';
        objController.objJobTemplate.Location__c = objSiteLocation.Id;

        //Call the add task template (this will add second template)
        objController.addTaskTemplate();

        //Set task fields for collect and deliver
        Integer countTaskTemplateInt = 0;
        for(Task_Template__c tt : objController.taskTemplateList){
            //Create first task a collect
            if(countTaskTemplateInt == 0){
                tt.Task__c = 'Collect Product';
                tt.Product__c = objProductULDF.Id;
            }
            else{
                tt.Task__c = 'Deliver Product';
                tt.Product__c = objProductULDE.Id;
            }
            countTaskTemplateInt++;
        }

        //Confirm there is two task templates
        System.assert(objController.taskTemplateList.size() == 2,'There should be two task templates');

        //Delete a task template
        objController.deleteTaskTemplate(); 
        
        //Confirm there is now only one task template
        System.assert(objController.taskTemplateList.size() == 1,'There should be only one task templates');
        
        //Call save Templates
        objController.saveTemplates();

        //Get created template
        Job_Template__c[] jobTemplateList = [SELECT Id FROM Job_Template__c WHERE Route_Template__c = :objRouteTemplateAdhoc.Id LIMIT 1];

        //Confirm it exists
        System.assert(jobTemplateList.size() == 1,'No job template created');
        
    }

    //Test create Adhoc Template and generate work
    static testmethod void validateCreateAdhocBookingMethodTwo(){
        
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        //Create Adhoc Duty Template
        Route_Template__c objRouteTemplateAdhoc = objTestDataFactory.getDutyTemplate('Adhoc - Dandenong', objServiceTerritory.Id);
        objRouteTemplateAdhoc.Is_Adhoc__c = true; //set as an adhoc template
        insert objRouteTemplateAdhoc;

        //Create site location
        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dandenong Depot', 'Site');
        insert objSiteLocation;

        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create ULD - Full product
        Product2 objProductULDF = objTestDataFactory.getProduct('ULD - Full');
        insert objProductULDF;

        PageReference pageRef = Page.TDF_CreateAdhocJob;
        Test.setCurrentPage(pageRef);

        TDF_CreateAdhocBookingAndJob objController = new TDF_CreateAdhocBookingAndJob();

        //Set the template as an adhoc
        objController.objJobTemplate.Route_Template__c = objRouteTemplateAdhoc.Id;
        objController.objJobTemplate.Start_Time__c = '0900';
        objController.objJobTemplate.Location__c = objSiteLocation.Id;

        //Call the add task template (this will add second template)
        objController.addTaskTemplate();

        //Set task fields for collect and deliver
        Integer countTaskTemplateInt = 0;
        for(Task_Template__c tt : objController.taskTemplateList){
            //Create first task a collect
            if(countTaskTemplateInt == 0){
                tt.Task__c = 'Collect Product';
                tt.Product__c = objProductULDF.Id;
            }
            else{
                tt.Task__c = 'Deliver Product';
                tt.Product__c = objProductULDE.Id;
            }
            //Set amounts for all days
            tt.Monday__c = 5;
            tt.Tuesday__c = 5;
            tt.Wednesday__c = 5;
            tt.Thursday__c = 5;
            tt.Friday__c = 5;
            tt.Saturday__c = 5;
            tt.Sunday__c = 5;
            countTaskTemplateInt++;
        }
        
        //Call generate work
        objController.saveAndGenerateWork();

        //Get created records
        WorkOrder[] workOrderList = [SELECT Id, (SELECT Id FROM WorkOrderLineItems) FROM WorkOrder WHERE Duty_Board__c = :objRouteTemplateAdhoc.Id LIMIT 1];
        //If no work order created, fail test
        if (workOrderList.size() != 1){
            System.assert(false, 'No Work Order created');
        }
        else{
            //If two WOLIs not created, fail test
            if (workOrderList[0].WorkOrderLineItems.size() != 2){
                System.assert(false, 'Two Work Order Line Items not created');
            }  
        }
    }   
    
    //Test validation logic
    static testmethod void validateCreateAdhocBookingMethodThree(){
        
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Dandenong');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dandenong', objOperatingHours.Id);
        insert objServiceTerritory;

        //Create Adhoc Duty Template
        Route_Template__c objRouteTemplateAdhoc = objTestDataFactory.getDutyTemplate('Adhoc - Dandenong', objServiceTerritory.Id);
        objRouteTemplateAdhoc.Is_Adhoc__c = true; //set as an adhoc template
        insert objRouteTemplateAdhoc;

        //Create Non Adhoc Duty Template
        Route_Template__c objRouteTemplateNonAdhoc = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        objRouteTemplateNonAdhoc.Is_Adhoc__c = false; //set as an non adhoc template
        insert objRouteTemplateNonAdhoc;

        //Create site location
        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dandenong Depot', 'Site');
        insert objSiteLocation;

        PageReference pageRef = Page.TDF_CreateAdhocJob;
        Test.setCurrentPage(pageRef);

        TDF_CreateAdhocBookingAndJob objController = new TDF_CreateAdhocBookingAndJob();

        //Set the template as an adhoc
        objController.objJobTemplate.Route_Template__c = objRouteTemplateAdhoc.Id;
        objController.objJobTemplate.Start_Time__c = '0900';
        objController.objJobTemplate.Earliest_Start_Time__c = '1000';
        objController.objJobTemplate.Location__c = objSiteLocation.Id;
        
        //Call function to trigger validation
        objController.saveTemplates();
        
        //Check messages returned
        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean passBol;
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Start Time must be greater or equal to Earliest Start Time')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'Start Time must be greater or equal to Earliest Start Time');

        //#Adjust the start time to beyond 2400
        objController.objJobTemplate.Start_Time__c = '3000';
        objController.saveTemplates();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Start Time must be between 0000 and 2400')) passBol = true;
        }  
        //Assert
        System.assert(passBol, 'Start Time must be between 0000 and 2400');

        //#Adjust the latest start time to beyond 2400
        objController.objJobTemplate.Start_Time__c = '1000';
        objController.objJobTemplate.Latest_Start_Time__c = '3000';
        objController.saveTemplates();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Latest Start Time must be between 0000 and 2400')) passBol = true;
        }  
        //Assert
        System.assert(passBol, 'Latest Start Time must be between 0000 and 2400');
        
        //#Adjust Effective and Exipry dates to be the same
        objController.objJobTemplate.Earliest_Start_Time__c = null;
        objController.objJobTemplate.Latest_Start_Time__c = null;
        objController.effectiveDate = System.today();
        objController.expiryDate = objController.effectiveDate;
        objController.saveTemplates();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('The expiry date must be at least 1 day after the effective date')) passBol = true;
        }  
        //Assert
        System.assert(passBol, 'The expiry date must be at least 1 day after the effective date'); 

        //Set the template as a non adhoc
        objController.objJobTemplate.Route_Template__c = objRouteTemplateNonAdhoc.Id;
        objController.effectiveDate = System.today();
        objController.expiryDate = objController.effectiveDate.addDays(1);
        objController.saveTemplates();

        //Check messages returned
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('The selected Duty Template is not Adhoc')) passBol = true;
        }  
        //Assert
        System.assert(passBol, 'The selected Duty Template is not Adhoc'); 
        
    }  
}