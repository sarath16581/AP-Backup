/*
    Test class for the Require Rejection Comments trigger
    
    Version history
    24/10/2018 - kalpita - updated the user role name to developer name 
*/
@isTest
public class SegmentationRequireRejectionCommentTest
{
      


 @testSetup
static void usersetup(){

    insertUser();

 }




       // For this first test, create an object for approval, then
       //simulate rejecting the approval with an added comment for explanation. 
       //The rejection should be processed normally without being interrupted.
     
    private static testmethod void testRejectionWithComment()
    {

        // Generate sample work item using utility method.
        Id testWorkItemId = generateAndSubmitObject();
        
    
        // Reject the submitted request, providing a comment.
        Approval.ProcessWorkitemRequest testRej = new Approval.ProcessWorkitemRequest();
        testRej.setComments('Rejecting request with a comment.');
        testRej.setAction  ('Reject');
        testRej.setWorkitemId(testWorkItemId);
    
        Test.startTest();        
            // Process the rejection
         Approval.ProcessResult testRejResult =  Approval.process(testRej);
        Test.stopTest();
        
        // Verify the rejection results
        System.assert(testRejResult.isSuccess(), 'Rejections that include comments should be permitted');
        System.assertEquals('Rejected', testRejResult.getInstanceStatus(), 
          'Rejections that include comments should be successful and instance status should be Rejected');
    }

   //seperate user creation due to roles
    @future
    private static void insertUser() { 

    Profile saleProf = [SELECT Id,Name FROM profile where Name = 'Coverage Sales' LIMIT 1];  

        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName='Inside_Sales_BMS_SR'];

        User testdirector = TestUtility.createUser('director',saleProf.id,null);
    
        insert(testdirector);

        User testmanager = TestUtility.createUser('tmanager',saleProf.id,null);

        testmanager.managerID = testdirector.ID;

        insert(testmanager);

        User testuserX = TestUtility.createUser('userX',saleProf.id,null);  //user role ID for Inside Sales South 1 - SR
      
        testuserX.ManagerId = testmanager.Id;
        insert(testuserx);

        User testuser = TestUtility.createUser('testuser',saleProf.id,r.ID);

        testUser.ManagerId = testmanager.Id;
        Insert(testuser); 
  
    }


      /* Utility method for creating single object, and submitting for approval.      
         The method should return the Id of the work item generated as a result of the submission.
       */
    private static Id generateAndSubmitObject()
    {
        // Create a sample object and then submit it for approval.

     
       //insertUser();
        Profile saleProf = [SELECT Id,Name FROM profile where Name = 'Coverage Sales' LIMIT 1];  
        User testuserX =[select  lastname ,ManagerId,profileid from User where lastname ='userX' limit 1 ];
        User testuser = [select  lastname ,ManagerId,profileid from User where lastname ='testuser' and profileID = :saleProf.ID limit 1 ];
        User testmanager =[select  lastname ,ManagerId,profileid from User where lastname ='tmanager' limit 1 ];
        system.debug('TestuserX is' + testuserx) ;
         system.debug('testuser is' + testuser) ;
        system.debug('testmanager is' + testmanager) ;
        Segmentation_Change_Request__c testSccr = new Segmentation_Change_Request__c();

        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account activeAcc = TestUtility.createBusinessAccount('Active Enterprises',
                                                                accRecTypeMap.get('Organisation').getRecordTypeId());
            activeAcc.LEGACY_ID__c = '12345';
            activeAcc.abn__c = '12345678901';
            activeAcc.Organisation_Trading_Name__c = 'Trade';
            activeAcc.billingstreet = 'street';
            activeAcc.billingcity = 'city';
            activeAcc.billingstate = 'state';
            activeAcc.billingpostalcode = '3000';
            activeAcc.billingcountry = 'AU';
            activeAcc.shippingstreet = 'street';
            activeAcc.shippingcity = 'city';
            activeAcc.shippingstate = 'state';
            activeAcc.shippingpostalcode = '3000';
            activeAcc.shippingcountry = 'AU';
            activeAcc.Sales_Segment__c ='Inside Sales South';
            activeAcc.Sales_Director__c =testmanager.ID;
           activeAcc.OwnerId = testuserx.Id;
          insert(activeAcc);
      
        
           system.debug('activeAcc is' + activeAcc) ;
        
          Organisation_Role__c orgRole = new Organisation_Role__c();
          orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c 
                                              WHERE Organisation__c =: activeAcc.id
                                              AND Role_Type__c='Prospect'];
                orgRole.Role_Type__c='Customer'; 
              Database.update(orgRole);
        system.debug('activeAcc is after update' + activeAcc) ;
             

        testSccr.Proposed_Account_Manager__c=testuser.id;
        testSccr.Reasonforchange__c='Anomaly Request';
        testSccr.Had_Handover_Conversation__c='yes';
        testSccr.Description__c='test';  
        testSccr.Organisation__c=activeAcc.Id;
        testSccr.Approval_Status__c = 'New';
                                                                       
        insert(testSccr);
        
        testSCCR.Hidden_Outgoing_Approver__c =testmanager.ID;
        
        update(testSCCR);

        Segmentation_Change_Request__c debugSccr = [select Hidden_Outgoing_Approver__c,Hidden_Incoming_Aprrover__c from Segmentation_Change_Request__c where id =:testSccr.ID];
         system.debug('testSccr is' + debugSccr.Hidden_Outgoing_Approver__c + ' ' + debugSccr.Hidden_Incoming_Aprrover__c);
      Approval.ProcessSubmitRequest testReq = new Approval.ProcessSubmitRequest();
           
        testReq.setObjectId(testSccr.Id);
       system.debug('testREQ is' + testREQ);
       Approval.ProcessResult reqResult  = Approval.process(testReq);
        System.assert(reqResult.isSuccess(),'Unable to submit new Sales Coverage change request record for approval');
         
        return reqResult.getNewWorkitemIds()[0];


    }

}