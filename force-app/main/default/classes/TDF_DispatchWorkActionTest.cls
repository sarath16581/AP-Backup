/** 
* @author Andrew Judd
* @date 2020-09-03
* @domain Field Service 
* @description  Test class for the TDF_DispatchWorkAction and TDF_DispatchWork classes
*
* @changelog 
* 2020-09-16 - Andrew Judd - Added check for connected job between two duties
* 2021-11-06 - Alvin Zhou - To update the logic to skip validation when resource is updated.
* 
*/
@isTest
public class TDF_DispatchWorkActionTest {

    //Test dispatch work
    static testmethod void validateDispatchWorkMethodOne(){

        List<ServiceAppointment> saList;
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
        User objUser2 = objTestDataFactory.getUser(sysAdmin.Id, 'tdf2@auspost.com');
        insert objUser2;

        //Create Driver Service Resource 1
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource('Driver 1', objUser1);
        insert objDriverServiceResource1;

        //Create Driver Service Resource 2
        ServiceResource objDriverServiceResource2 = objTestDataFactory.getServiceResource('Driver 2', objUser2);
        insert objDriverServiceResource2;

        //Create Duty Service Resource 1
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource('DT61',objDriverServiceResource1.Id, startDateTime, endDateTime );
        insert objDutyServiceResource1;

        //Create Duty Service Resource 2
        ServiceResource objDutyServiceResource2 = objTestDataFactory.getDutyServiceResource('DT62',objDriverServiceResource2.Id, startDateTime, endDateTime );
        insert objDutyServiceResource2;

        //Create Service Territory Member record assigning duty SR 1 to the ST
        ServiceTerritoryMember objServiceTerritoryMember1 = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember1;

        //Create Service Territory Member record assigning duty SR 2 to the ST
        ServiceTerritoryMember objServiceTerritoryMember2 = objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource2.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7));
        insert objServiceTerritoryMember2;

        //Create Duty Template
        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('DT61', objServiceTerritory.Id);
        objRouteTemplate.Duty_SR__c = objDutyServiceResource1.Id; //Set the operational duty
        insert objRouteTemplate;

        //Create site location 1 (depot for the FFD and RV)
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation('Depot', 'Site');
        insert objSiteLocation1;        

        //Create site location 2 (DC for collect)
        Schema.Location objSiteLocation2 = new Schema.Location();
        objSiteLocation2 = objTestDataFactory.getLocation('DC Site', 'Site');
        insert objSiteLocation2;

        //Create site location 3 (Cust for delivery)
        Schema.Location objSiteLocation3 = new Schema.Location();
        objSiteLocation3 = objTestDataFactory.getLocation('Customer One', 'Site');
        insert objSiteLocation3;   

        //Create a FFD Job Template at 1000 
        Job_Template__c objJobTemplate1 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation1.Id, 'Fit For Duty');
        objJobTemplate1.Start_Time__c = '1000';
        insert objJobTemplate1;
      
        //Create a collect Job Template at 1200 
        Job_Template__c objJobTemplate2 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation2.Id, 'Collection');
        objJobTemplate2.Start_Time__c = '1200';
        insert objJobTemplate2;

        //Create a deliver Job Template at 1400
        Job_Template__c objJobTemplate3 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation3.Id, 'Delivery');
        objJobTemplate3.Start_Time__c = '1400';
        insert objJobTemplate3;

        //Create a return vehicle at 1600
        Job_Template__c objJobTemplate4 =  objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation1.Id, 'Return & Refuel Vehicle');
        objJobTemplate4.Start_Time__c = '1600';
        insert objJobTemplate4;
                             
        //Create ULD - Empty product
        Product2 objProductULDE = objTestDataFactory.getProduct('ULD - Empty');
        insert objProductULDE;

        //Create a connected collect and deliver task template for the collect and deliver jobs (connected)
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate2.Id, objJobTemplate3.Id);
        objTaskTemplate.Product__c = objProductULDE.Id;
        objTaskTemplate.Monday__c = 5;
        objTaskTemplate.Tuesday__c = 5;
        objTaskTemplate.Wednesday__c = 5;
        objTaskTemplate.Thursday__c = 5;
        objTaskTemplate.Friday__c = 5;
        objTaskTemplate.Saturday__c = 5;
        objTaskTemplate.Sunday__c = 5;
        insert objTaskTemplate;

        //Call generate work to create Service Appointment, Work Order and Work Order Line Items
        TDF_GenerateWork tdfGW = new TDF_GenerateWork();
        Date startDate = System.today(); 
        String resultString = tdfGW.createJobs(startDate, startDate, objRouteTemplate.Id, null);

        //Get the Service Appointments created and adjust times so they are all scheduled into future
        saList = [SELECT Id, SchedStartTime, SchedEndTime, Work_Order__r.RecordType.DeveloperName FROM ServiceAppointment ORDER BY SchedStartTime];

        //Adjust the start of the jobs to 1 hour from now with 2 hour spacing
        //This is to ensure that dispatch works independant of when test is run
        Integer hrsInt = 1;
        for(ServiceAppointment sa : saList){
            sa.SchedStartTime = DateTime.now().addHours(hrsInt);
            sa.SchedEndTime = DateTime.now().addHours(hrsInt + 1);
            hrsInt = hrsInt + 2;
        }
        update saList;

        //##Commence tests
        //#Test 1 - Call dispatch work without a driver assigned
        TDF_DispatchWorkAction tdfDWA = new TDF_DispatchWorkAction();
        resultString = tdfDWA.action(objDutyServiceResource1.Id, null, null, null, null);

        //Expect no driver assigned message - Assert
        passBol = false;
        if (resultString.contains('does not have a driver assigned')) passBol = true;
        //Assert
        System.debug('AJJ Dispatch Work Test 1 resultString = ' + resultString);
        System.assert(passBol, 'Driver not assigned error not returned'); 

        //Assign a driver with assignment starting after the FFD start (i.e 2 hrs from now)
        System.debug('AJJ sc id = ' +objDutyServiceResource1.ServiceCrewId);
        ServiceCrewMember objServiceCrewMember1 = objTestDataFactory.getServiceCrewMember(objDutyServiceResource1.ServiceCrewId, objDriverServiceResource1.Id, DateTime.now().addHours(2), DateTime.now().addHours(10));
        insert objServiceCrewMember1;

        //#Test 2 - Call dispatch work with a driver assigned but with assignment after ffd
        resultString = tdfDWA.action(objDutyServiceResource1.Id, null, null, null, null);

        //Get all SAs with status dispatched
        saList = [SELECT Id FROM ServiceAppointment WHERE Status = 'Dispatched'];
        //Assert 
        System.assert(saList.size() == 4, 'All Service Appointments were not dispatched'); 

        //#Test 3 - Undispatch all work
        //First allow this status transition in the managed pkg (not possible by default)
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Scheduled');
        //Call undispatch
        resultString = TDF_DispatchWork.undispatch(objDutyServiceResource1.Id);
        //Get all SAs with status dispatched
        saList = [SELECT Id FROM ServiceAppointment WHERE Status = 'Dispatched'];
        //Assert 
        System.assert(saList.size() == 0, 'All Service Appointments were not undispatched'); 

        //#Test 4 - Call dispatch work with one of the connected jobs assigned to a different duty
        //Get the two collect deliver service appointments
        ServiceAppointment objServiceAppointment1 = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Work_Order__r.Job_Template__c = :objJobTemplate2.Id];
        ServiceAppointment objServiceAppointment2 = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Work_Order__r.Job_Template__c = :objJobTemplate3.Id];

        //Assign service appointment 2 to the duty 2
        AssignedResource objAssignedResource = [SELECT Id, ServiceResourceId FROM AssignedResource 
                                                WHERE ServiceAppointmentId = :objServiceAppointment2.Id 
                                                AND ServiceResource.ResourceType = 'C' LIMIT 1];
        objAssignedResource.ServiceResourceId = objDutyServiceResource2.Id;
        update objAssignedResource;
        List<WorkOrderLineItem> items = [Select Id, Skip_Validation__c from WorkorderLineItem where Skip_Validation__c = true];
        for(WorkOrderLineItem item: items) {
            item.Skip_Validation__c = false;
        }
        update items;
        //Call dispatch work
        resultString = tdfDWA.action(objDutyServiceResource1.Id, null, null, null, null);

        //Expect validation message
        passBol = false;            
        if (resultString.contains(' delivers are related to a collect on a different duty')) passBol = true;
        //Assert
        //TODO: Check this
        // System.assert(passBol, 'Delivers related to a collect on a different duty - validation error not returned');    

    }
}