/*   
    Test class for the SegmentationAllowOneSubmittedRecord of SCCR
    
    Version history
    25/10/2018 - kalpita - updated the user role name to developer name 
*/
@isTest
public class SegmentationAllowOneSubmittedRecordTest{    
    
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static testMethod  void testSegmentationAllowOneSubmittedRecord()
    {        
        // Create a sample object    
        //Create test users, to submit an SCCR, proposed account manager sould have a manger, because the approval request goes to him   
        Profile salesProf = [SELECT Id,Name FROM profile where Name = 'Coverage Sales' LIMIT 1];   
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName='Inside_Sales_BMS_SR'];

        System.runAs (thisUser){
        User testmanager = TestUtility.createUser('manager',salesProf.id,null);       
        User testuserX = TestUtility.createUser('userX',salesProf.id,null);      
        insert(testmanager);       
        insert(testuserx);       
        User testuser = TestUtility.createUser('testuser',salesProf.id,r.ID);      
        testUser.ManagerId = testmanager.Id;       
        insert(testuser);              
        //Create an account, SCCR has Master detail relationship with Account.       
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();       
        Account activeAcc = TestUtility.createBusinessAccount('Active Enterprises',accRecTypeMap.get('Organisation').getRecordTypeId());          
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
        activeAcc.OwnerId = testuserx.Id;            
        insert(activeAcc);   

        //Set the role of the orgnanisation other than Propsect, as an SCCR can't be created on a Propsect.         
        Organisation_Role__c orgRole = new Organisation_Role__c();          
        orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c                                
                   WHERE Organisation__c =: activeAcc.id                                 
                   AND Role_Type__c='Prospect'];                
        orgRole.Role_Type__c='Customer';          
        Database.update(orgRole);     

                   
        //Create an SCCR           
        Segmentation_Change_Request__c testSccr = new Segmentation_Change_Request__c(Proposed_Account_Manager__c=testuser.id, 
                                                                                     Reasonforchange__c='Anomaly Request',  
                                                                                     Had_Handover_Conversation__c='yes',Description__c='test',  
                                                                                     Organisation__c=activeacc.Id,Approval_Status__c='Submitted');
        Segmentation_Change_Request__c testSccr2 = new Segmentation_Change_Request__c(Proposed_Account_Manager__c=testuser.id, 
                                                                                      Reasonforchange__c='Anomaly Request',  
                                                                                      Had_Handover_Conversation__c='yes',Description__c='test',  
                                                                                      Organisation__c=activeacc.Id); 
        Test.startTest();                                                                                                   
        Database.insert(testSccr);

        //insert(testSccr);
        system.debug('testSccr.Approval_Status__c --> '+testSccr.Approval_Status__c);
        System.assertEquals(STATUS_SUBMITTED,testSccr.Approval_Status__c);
        //Database.Insert(testSccr2);
        Test.stopTest();   

        }   
    }
}