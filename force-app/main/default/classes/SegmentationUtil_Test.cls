/**************************************************
Type:       Test Class  
Purpose:    Test class for SegmentationUtil

History:
--------------------------------------------------
04.08.2016  eugene.jandusay@auspost.com.au        Created
14.02.2017  eric.shen@auspost.com.au      update test class to reflect SCCR new
05.03.2020  seth.heang@auspost.com.au     fixed test class failure with user role and increase code coverage
**************************************************/

@isTest
private class SegmentationUtil_Test {
    private static testMethod  void testSegmentationUtil(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name = 'System Administrator' LIMIT 1];
       // Profile customerteamp = [SELECT Id FROM Profile WHERE Name='Customer Team'];
       Profile customerteamp = [SELECT Id FROM Profile WHERE Name='Coverage Sales'];
       // Change user role from 'Inside_Sales_South_1_SR' to 'Inside_Sales_BMS_SR' as the former is no longer in the system
       UserRole ur =TestUtility.getUserRole('Inside_Sales_BMS_SR');
        User extestUser = [Select Id from User where Name = 'Test User' limit 1];
        
        List<User> usrList = new List<User>();
        
        User customerTeamUser = TestUtility.createUser('Admin',customerteamp.id,null);
        customerTeamUser.Sales_Director__c = extestUser.Id;
        
        User testmanager = TestUtility.createUser('manager',adminProf.id,null);

        User testuserX = TestUtility.createUser('userX',adminProf.id,null);
        
        usrList.add(testmanager);
        usrList.add(testuserX);
        
        Database.insert(usrList);
        
       // User testuser = TestUtility.createUser('testuser',adminProf.id,null);
         User testuser = TestUtility.createUser('testuser',customerteamp.id,ur.id);
         
        testUser.ManagerId = testmanager.Id;
        
        Database.insert(testUser);
        
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
            List<Hub_Catchment_Reference__c> hubCRList = new List<Hub_Catchment_Reference__c>();
            
            Hub_Catchment_Reference__c activehcr = new Hub_Catchment_Reference__c(Post_Code__c='2000',
                                                                                    Hub_Catchment__c='Two Thousand',
                                                                                    Active__c=True);   
            Hub_Catchment_Reference__c inactivehcr = new Hub_Catchment_Reference__c(Post_Code__c='2000',
                                                                                        Hub_Catchment__c='Two Thousand',
                                                                                        Active__c=False);   
            
            hubCRList.add(activehcr);
            hubCRList.add(inactivehcr);
            
            Database.insert(hubCRList);
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            List<Account> accList = new List<Account>();
            
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
            
            Account inactiveAcc = TestUtility.createBusinessAccount('InActive Enterprises',
                                                                accRecTypeMap.get('Organisation').getRecordTypeId());
            inactiveAcc.LEGACY_ID__c = '12345';
            inactiveAcc.abn__c = '12345678901';
            inactiveAcc.Organisation_Trading_Name__c = 'Trade';
            inactiveAcc.billingstreet = 'street';
            inactiveAcc.billingcity = 'city';
            inactiveAcc.billingstate = 'state';
            inactiveAcc.billingpostalcode = '3000';
            inactiveAcc.billingcountry = 'AU';
            inactiveAcc.shippingstreet = 'street';
            inactiveAcc.shippingcity = 'city';
            inactiveAcc.shippingstate = 'state';
            inactiveAcc.shippingpostalcode = '2906';
            inactiveAcc.shippingcountry = 'AU';
            
            Account smallBusiness = TestUtility.createBusinessAccount('Small Enterprises',
                                                                accRecTypeMap.get('Organisation').getRecordTypeId());
            smallBusiness.LEGACY_ID__c = '12345';
            smallBusiness.abn__c = '12345678901';
            smallBusiness.Organisation_Trading_Name__c = 'Trade';
            smallBusiness.billingstreet = 'street';
            smallBusiness.billingcity = 'city';
            smallBusiness.billingstate = 'state';
            smallBusiness.billingpostalcode = '3000';
            smallBusiness.billingcountry = 'AU';
            smallBusiness.shippingstreet = 'street';
            smallBusiness.shippingcity = 'city';
            smallBusiness.shippingstate = 'state';
            smallBusiness.shippingpostalcode = '2906';
            smallBusiness.shippingcountry = 'AU';
            smallBusiness.OwnerId = testuserx.Id;
            
            accList.add(activeAcc);
            accList.add(inactiveAcc);
            accList.add(smallBusiness);
            
            Database.insert(accList);
            
            List<Organisation_Role__c> orgRoleList = new List<Organisation_Role__c>();
            
            for(Organisation_Role__c role : [SELECT Id, Role_Type__c FROM Organisation_Role__c 
                                               WHERE Organisation__c IN: accList
                                               AND Role_Type__c='Prospect']){
                role.Role_Type__c='Customer'; 
                orgRoleList.add(role);
            }
            Database.update(orgRoleList);
            
            List<Sales_Segment_Reference__c> ssrList = new List<Sales_Segment_Reference__c>();
            
            Sales_Segment_Reference__c ssr = new Sales_Segment_Reference__c(Sales_Segment__c='Telecoms');
            Sales_Segment_Reference__c ssr2 = new Sales_Segment_Reference__c(Sales_Segment__c='Telecoms');
            ssrList.add(ssr);
            ssrList.add(ssr2);
            Database.insert(ssrList);
            
            Lead leadRec = new Lead(LastName='Lead Record',FirstName='First Name',Email='x@x.com',
                                        Street='Street',City='City',State='State',Country='Country',
                                        PostalCode='1000',Parcels_per_week__c='1-9');
            Database.insert(leadRec);
            

           //Mona Map<String,Schema.RecordTypeInfo> scrRecTypeMap = Schema.Sobjecttype.Segmentation_Change_Request__c.getRecordTypeInfosByName();
            
            List<Segmentation_Change_Request__c> scrList = new List<Segmentation_Change_Request__c>();
            
            Segmentation_Change_Request__c scrL2 = new Segmentation_Change_Request__c(Proposed_Account_Manager__c=testuser.id,
                                                                                        Effective_Date_of_Change__c= Date.today(),
                                                                                        Approval_Status__c='Approved',
                                                                                       //Mona RecordTypeId= scrRecTypeMap.get('Account Manager Change').getRecordTypeId(),
                                                                                        Organisation__c=smallBusiness.Id);
            Segmentation_Change_Request__c scr = new Segmentation_Change_Request__c(Proposed_Account_Manager__c=testuser.id,
                                                                                        Effective_Date_of_Change__c= Date.today(),
                                                                                        Approval_Status__c='New',
                                                                                        //Mona RecordTypeId= scrRecTypeMap.get('Account Manager Change').getRecordTypeId(),
                                                                                        Organisation__c=activeacc.Id);
            scrList.add(scrL2);
            scrList.add(scr);
            
            Test.startTest();
                Database.insert(scrList);
                
                List<CronTrigger> cron = new List<CronTrigger>([SELECT Id, State FROM CronTrigger WHERE CronExpression like '% spTestJob']);
                for(CronTrigger CT : cron){
                    system.abortjob(CT.Id);
                }
                
                SegmentationUtil.updateSegmentationChangeRequest(scrList);
                SegmentationUtil.updateSalesSegment(scrList);
                SegmentationChangeRequest scr4 = new SegmentationChangeRequest();
                
                String sch = '0 0 1 25 12 ? ' + Date.today().year() + ' spTestJob';
                SegmentationChangeRequest.updateSegmentation();
                Database.delete(leadRec);
                Database.undelete(leadRec);
                
            Test.stopTest();
            System.assertEquals(testuser.id, [SELECT OwnerId FROM Account WHERE Id =: smallBusiness.Id].OwnerId);
        }
    }
    
    

    
    
}