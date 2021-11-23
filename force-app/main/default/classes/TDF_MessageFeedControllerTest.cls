/** 
* @author Andrew Judd
* @date 2020-09-07
* @domain Field Service 
* @description  Test class for the TDF_MessageFeedController class
*
* @changelog 
* 2020-09-08 - Andrew Judd  - Added insert of post and comment to cover TDF_UpdateServiceAppointmentOnMessage
*                           
*/
@IsTest()
public class TDF_MessageFeedControllerTest {

    //Test message controller
    static testmethod void validateMessageFeedMethodOne(){

        List<Apexpages.Message> msgs = new List<Apexpages.Message>();
        Boolean passBol;

        //Get a unique string for Op Hrs, ST, Duty, Driver
        //-in case class needs to run as SeeAllData to allow post of chatter message and comment
        //-although it currently appears this is required with simple insert FeedItem and FeedComment approach
        String uniqueString = String.valueOf(System.now().getTime());

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        //Create base data
        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours(uniqueString + 'OH');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory(uniqueString + 'ST', objOperatingHours.Id);
        insert objServiceTerritory;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@auspost.com');
        insert objAdminUser;

        Profile tdfDriver = [SELECT Id FROM Profile WHERE Name = 'TDF Driver'];
        User objDriverUser = objTestDataFactory.getUser(tdfDriver.Id, 'tdfdriver@auspost.com');
        insert objDriverUser;        

        //Create Driver Service Resource
        ServiceResource objDriverServiceResource1 = objTestDataFactory.getServiceResource(uniqueString + 'Driver', objDriverUser);
        insert objDriverServiceResource1;

        //Create Service Territory Member record assigning driver SR 1 to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDriverServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create Duty Service Resource
        DateTime startDateTime = System.now().addDays(-3);
        DateTime endDateTime = System.now().addDays(-2);
        ServiceResource objDutyServiceResource1 = objTestDataFactory.getDutyServiceResource(uniqueString + 'Duty',objDriverServiceResource1.Id, startDateTime, endDateTime );
        insert objDutyServiceResource1;

        //Create Service Territory Member record assigning duty SR to the ST
        insert(objTestDataFactory.getServiceTerritoryMember(objDutyServiceResource1.Id, objServiceTerritory.Id, System.now().addDays(-2), System.now().addDays(7)));

        //Create site location 
        Schema.Location objSiteLocation1 = new Schema.Location();
        objSiteLocation1 = objTestDataFactory.getLocation(uniqueString + 'Site', 'Site');
        insert objSiteLocation1;

        //Create FFD Work Order and Service Appointment in Scheduled Status
        String woRecordTypeString = objTestDataFactory.getWorkOrderRTId('Fit For Duty');
        WorkOrder objWorkOrder1 = objTestDataFactory.getWorkOrder(woRecordTypeString);
        insert objWorkOrder1;
        ServiceAppointment objServiceAppointment1 = objTestDataFactory.getServiceAppointment(objWorkOrder1.Id, objServiceTerritory.Id, System.now(), 10); 
        objServiceAppointment1.Work_Order__c = objWorkOrder1.Id;                
        insert objServiceAppointment1;

        //Create Standard Work Order and Service Appointment 
        woRecordTypeString = objTestDataFactory.getWorkOrderRTId('Standard');
        WorkOrder objWorkOrder2 = objTestDataFactory.getWorkOrder(woRecordTypeString);
        insert objWorkOrder2;
        ServiceAppointment objServiceAppointment2 = objTestDataFactory.getServiceAppointment(objWorkOrder2.Id, objServiceTerritory.Id, System.now().addHours(1), 30); 
        objServiceAppointment2.Work_Order__c = objWorkOrder2.Id;                
        insert objServiceAppointment2;        

        //Assign the service appointments to the duty and driver
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment1.Id, objDutyServiceResource1.Id));
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment1.Id, objDriverServiceResource1.Id));
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment2.Id, objDutyServiceResource1.Id));
        insert(objTestDataFactory.getAssignedResource(objServiceAppointment2.Id, objDriverServiceResource1.Id));

        //Assign page
        PageReference pageRef = Page.TDF_MessageFeed;
        Test.setCurrentPage(pageRef);
        TDF_MessageFeedController objController;

        //##Commence tests
        //#Test 1 - Load page from Duty SR where no Completed FFD exists in current window
        //Set page attributes to reflect
        pageRef.getParameters().put('id', objDutyServiceResource1.Id);
        objController = new TDF_MessageFeedController();

        //Page message should be returned - no SAs selected
        msgs = ApexPages.getMessages();
        passBol = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('No current completed Fit For Duty job could be found')) passBol = true;
        }
        //Assert
        System.assert(passBol, 'No current completed Fit For Duty job could be found - message not returned.'); 

        //#Test 2 - Load page on the non FFD Service Appointment and add post from Admin user
        //Set page attributes to reflect
        pageRef.getParameters().put('id', objServiceAppointment1.Id);
        objController = new TDF_MessageFeedController();

        //Set the Driver SR FFD (to simulate completion of FFD and allow relationship between non FFD and FFD records)
        objDriverServiceResource1.Fit_For_Duty_Work_Order__c = objWorkOrder1.Id;
        update objDriverServiceResource1;        

        //Post a message on the non FFD Work Order
        FeedItem feedElement1 = new FeedItem(body='Test Feed 1 Post', ParentId = objWorkOrder2.Id, Type='TextPost');
        insert feedElement1;     

        //Assert that FFD SA Subject contains text MESSAGE RECEIVED
        String saSubject = [SELECT Subject FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id].Subject;
        System.assert(saSubject.contains('MESSAGE RECEIVED'), 'FFD Service Appoinment subject does not contain text MESSAGE RECEIVED'); 
        
        //Assert that non FFD SA Subject contains text MESSAGE RECEIVED
        saSubject = [SELECT Subject FROM ServiceAppointment WHERE Id = :objServiceAppointment2.Id].Subject;
        System.assert(saSubject.contains('MESSAGE RECEIVED'), 'Non FFD Service Appoinment subject does not contain text MESSAGE RECEIVED');
        
        //#Test 3 - Add comment to the post on the non FFD from the Driver
        System.runAs(objDriverUser){
            FeedComment feedComment1 = new FeedComment(CommentBody='Test Feed 1 Comment', FeedItemId=feedElement1.Id, CommentType='TextComment');
            insert feedComment1;
        }

        //Assert that FFD SA Subject has had MESSAGE RECEIVED text cleared
        saSubject = [SELECT Subject FROM ServiceAppointment WHERE Id = :objServiceAppointment1.Id].Subject;
        System.assert(saSubject.containsNone('MESSAGE RECEIVED'), 'FFD Service Appoinment has not had MESSAGE RECEIVED text cleared');

        //Assert that non FFD SA Subject has had MESSAGE RECEIVED text cleared
        saSubject = [SELECT Subject FROM ServiceAppointment WHERE Id = :objServiceAppointment2.Id].Subject;
        System.assert(saSubject.containsNone('MESSAGE RECEIVED'), 'Non FFD Service Appoinment has not had MESSAGE RECEIVED text cleared'); 
        
        //Delete feed item  for coverage of other project code
        FeedComment objFeedComment = [SELECT ID FROM FeedComment LIMIT 1];
        delete objFeedComment;
        delete feedElement1;

    } 

}