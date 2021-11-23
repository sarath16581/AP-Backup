/**
*  This test class is for SSSW_FillInbox.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 80%

* 12/11/2105 Kalpita.talwadekar@auspost.com.au
* -updated
* -cover new case management process

* 18/03/2016 - Nandan - Updated test class to fix test class failure due to case team role duplicate
* 21/03/2016 - Eric -   Updated test class to increase code coverage for HLC
* 23/10/2018 - Kalpita -Updated test class to fix prod errors for running as Active User.
                        - also fixed up follow-up errors for inserting queueObject and GroupMembers, hence moved them to setup method
*/
@isTest
private class SSSW_FillInbox_Test {
    
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String HLC_QUEUE = 'SSSW_High_Level_Complaints';
    private static final String CR_QUEUE = 'SSSW_Customer_Recovery';
    
    /** 
      * @name: setup()
      * @desciption: method to create test data available throughout the test class
      * @param: NA
      * @return: NA
      *
      */
    @testSetup static void setup() {
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent']; 
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='TestingAgnt', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.p');
        insert usr;
        
        //insert caseteamrole
        CaseTeamRole rol = new CaseTeamRole(Name='Business Inbound', AccessLevel='Edit');
        insert rol;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound' );
        insert grp1;
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        QueueSobject testQueue = new QueueSObject(QueueId = grp.Id, SobjectType = 'Case');
        insert testQueue;
        GroupMember grMem = new GroupMember(UserOrGroupId = usr.id, GroupId = grp.Id);
        insert grMem;
        
        //create a second group
        Group grp2 = new Group(Type='Queue', Name='SSSW Consumer Inbound');
        insert grp2;
        QueueSobject testQueue2 = new QueueSObject(QueueId = grp2.Id, SobjectType = 'Case');
        insert testQueue2;
        GroupMember grMem2 = new GroupMember(UserOrGroupId = usr.id, GroupId = grp2.Id);
        insert grMem2;
        
        //create a group which has case and agent isnt part of group
        Group grp3 = new Group(Type='Queue', Name='SSSW Business Back Office' );
        insert grp3;
        QueueSobject testQueue3 = new QueueSObject(QueueId = grp3.Id, SobjectType = 'Case');
        insert testQueue3;
        
    }

    /** 
      * @name: myUnitTest1()
      * @desciption: test method for testing HLC and CR case assignment
      * @param: NA
      * @return: NA
      *
      */
    static testMethod void myUnitTest1() {
        
        FillInboxSettings__c fill = TestDataProvider.createTestFillInboxSettings();
        
        Case case1 = new Case();
        //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
        
        Test.startTest();
        
        ////SSSW_FillInbox.groupIds();
        SSSW_FillInbox.wsFillInbox();
       
        
        system.assert(true);
        Test.stopTest();
    }
    
    /** 
      * @name: testCaseMgmt1()
      * @desciption: test method for testing HLC and CR case assignment
      * @param: NA
      * @return: NA
      *
      */
    static testMethod void myUnitTest2() {
        
        Case case1 = new Case();
        //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
        
        Test.startTest();
        
        ////SSSW_FillInbox.groupIds();
        SSSW_FillInbox.wsFillInbox();
       
        
        system.assert(true);
        Test.stopTest();
    }
    
  /** 
    * @name: testCaseMgmt1()
    * @desciption: test method for testing the new case management when user is in eligible queue
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void testCaseMgmt1() {
        //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound' );
        insert grp1;
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        //query user
        User usr = [Select Id, Name from User where isActive=true limit 1];
        
        //click fill in box
        system.runAs(usr) {
            
            Test.startTest();
            //create case with owner as queue
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'New';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.ownerId = grp.Id;
            insert case1;
            
            
            //query role
            CAseTeamRole rol = [SELECT Name, Id FROM CaseTeamRole where Name = 'Business Inbound' limit 1];

            SSSW_FillInbox.wsFillInbox();
           
            system.assert(true);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: testCaseMgmt2()
    * @desciption: test method for testing the new case management when user is not in eligible queue
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void testCaseMgmt2() {
        //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound');
        insert grp1;
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        //do not add group member to queue
        
        //query user
        User usr = [Select Id, Name from User where isActive=true limit 1];
        
        system.runAs(usr) {
        //click fill in box
            Test.startTest();
                        
                //create case with owner as queue
                Case case1 = new Case();
                //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
                case1.Type = 'Feedback';
                case1.Subject = 'Newsdd';
                case1.Status = 'New';
                case1.ProductCategory__c = 'Travel & ID';
                case1.EnquirySubType__c = 'Product Support';
                case1.ProductSubCategory__c = 'KeyPass';
                case1.ownerId = grp.Id;
                insert case1;
                
                //add user to caseTeam
                //query role
                CAseTeamRole rol = [SELECT Name, Id FROM CaseTeamRole where Name = 'Business Inbound' limit 1];
                
                SSSW_FillInbox.wsFillInbox();
                
                system.assert(true);
                
            Test.stopTest();
        }
    }
    
    /** 
    * @name: testCaseMgmt3()
    * @desciption: test method for testing the new case management when user is in non-eligible queue 
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void testCaseMgmt3() {
        //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound');
        insert grp1;
        //create eligible queue
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        
        Group grp2 = [Select Id, Name from Group where Name='SSSW Consumer Inbound' limit 1];
        //do not add group member to queue
        
        //query user
        User usr = [Select Id, Name from User  where isActive=true limit 1];
        
        //do not add user to caseTeam
        
        //click fill in box
        system.runAs(usr) {
            
            Test.startTest();
                //create case with owner as queue
                Case case1 = new Case();
                //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
                case1.Type = 'Feedback';
                case1.Subject = 'Newsdd';
                case1.Status = 'New';
                case1.ProductCategory__c = 'Travel & ID';
                case1.EnquirySubType__c = 'Product Support';
                case1.ProductSubCategory__c = 'KeyPass';
                case1.ownerId = grp2.Id;
                insert case1;
                
                //SSSW_FillInbox.groupIds();
                SSSW_FillInbox.wsFillInbox();
               
                system.assert(true);
            Test.stopTest();
        }
    }
    
  /** 
    * @name: testCaseMgmt4()
    * @desciption: test method for testing the new case management 
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void testCaseMgmt4() {
        //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound');
        insert grp1;

        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        
        Group grp2 = [Select Id, Name from Group where Name='SSSW Consumer Inbound' limit 1];
        //do not add group member to queue
        
        //query user
        User usr = [Select Id, Name from User  where isActive=true limit 1];
        
        
        //do not add user to caseTeam
        
        //click fill in box
        system.runAs(usr) {
            
            //create case without owner as queue
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.Status = 'New';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.ownerId = grp2.Id;
            insert case1;
        
            Test.startTest();
            
            //SSSW_FillInbox.groupIds();
            SSSW_FillInbox.wsFillInbox();
           
            
            system.assert(true);
            Test.stopTest();
        }
    }
    
    /** 
    * @name: myUnitTest_schedule()
    * @desciption: test method for testing batch class to get the cases whihc are open for more than 3 hours 
    * @param: NA
    * @return: NA
    *
    */
    static testMethod void myUnitTest_schedule() {
       //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound' );
        insert grp1;
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        //query user
        User usr = [Select Id, Name from User where isActive = true limit 1];
        
        //click fill in box
        system.runAs(usr) {
            TimeZone tz = UserInfo.getTimeZone();
            Datetime startDate = system.now().addSeconds(tz.getOffset(system.now())/1000);
            Datetime endDate =  startDate.addhours(-4);
        
        
            //create case with owner as queue
            Case case1 = new Case();
            //case1.RecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
            case1.Status = 'New';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.createdDate = system.now().addHours(-5);
            case1.ownerId = grp.Id;
            insert case1;
            
            
            //query role
            CaseTeamRole rol = [SELECT Name, Id FROM CaseTeamRole where Name = 'Business Inbound' limit 1];
   
        }
        CaseManagement_Schedulable msc = new CaseManagement_Schedulable();
        String sch = '20 30 8 10 2 ?'; // base this on mode or whatever your params are
        
        Test.startTest();
            
            String jobID = system.schedule('Scheduled Job', sch, msc);
            system.assert(true); 
             
        Test.stopTest(); 
    }
    
    /** 
      * @name: myUnitTest_schedule()
      * @desciption: test method for testing batch class to get the cases whihc are open for more than 3 hours 
      * @param: NA
      * @return: NA
      *
      */
    static testMethod void myUnitTest_schedule2() {
       //create custom setting
        //add one value (queue name to it)
        EligibleQueue_FillInBox__c fbox = new EligibleQueue_FillInBox__c(Name='Business Inbound');
        insert fbox;
        
        //create eligible queue
        Group grp1 = new Group(Type='Queue', Name='Business Inbound' );
        insert grp1;
        
        //query the queue
        Group grp = [Select Id, Name from Group where Name='Business Inbound' limit 1];
        //query user
        User usr = [Select Id, Name from User  where isActive=true limit 1];
        
        //click fill in box
        system.runAs(usr) {
            TimeZone tz = UserInfo.getTimeZone();
            Datetime startDate = system.now().addSeconds(tz.getOffset(system.now())/1000);
            Datetime endDate =  startDate.addhours(-4);
            
            //create case with owner as queue
            Case case2 = new Case();
            case2.Type = 'Feedback';
            case2.Subject = 'Newsdd';
            case2.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
            case2.Status = 'In Progess';
            case2.ProductCategory__c = 'Travel & ID';
            case2.EnquirySubType__c = 'Product Support';
            case2.ProductSubCategory__c = 'KeyPass';
            case2.createdDate = system.now().addHours(-5);
            insert case2;
        
            //create case with owner as queue
            Case case1 = new Case();
            case1.Type = 'Feedback';
            case1.Subject = 'Newsdd';
            case1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
            case1.Status = 'New';
            case1.ProductCategory__c = 'Travel & ID';
            case1.EnquirySubType__c = 'Product Support';
            case1.ProductSubCategory__c = 'KeyPass';
            case1.createdDate = system.now().addHours(-5);
            case1.ownerId = grp.Id;
            insert case1;
            
            
            //query role
            CaseTeamRole rol = [SELECT Name, Id FROM CaseTeamRole where Name = 'Business Inbound' limit 1];
   
        }
        CaseManagement_Schedulable msc = new CaseManagement_Schedulable();
        String sch = '20 30 8 10 2 ?'; // base this on mode or whatever your params are
        
        Test.startTest();
            
            String jobID = system.schedule('Scheduled Job', sch, msc);
            system.assert(true); 
             
        Test.stopTest(); 
    }
    
    /**
      * @description       This method tests scenario of fill inbox for HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFillInbox_HLCAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.id);
        Database.insert(runningUser);
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        
        System.runAs(runningUser){
            // Create fill inbox custom setting
            FillInboxSettings__c fillSetting = new FillInboxSettings__c();
            fillSetting.CommaSeparatedStatus__c = 'On Hold';
            fillSetting.Name = '00B30000008IdcD';
            fillSetting.MaxNumberOfCasesToAssign__c = 1;
            Database.insert(fillSetting);
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = hlcQueue.Id;
            Database.insert(csRec);
            
            Test.startTest();
                SSSW_FillInbox.wsFillInbox();
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method tests scenario of fill inbox for CR agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFillInbox_CRAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.id);
        Database.insert(runningUser);
        Group crQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: CR_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = crQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        
        System.runAs(runningUser){
            // Create fill inbox custom setting
            FillInboxSettings__c fillSetting = new FillInboxSettings__c();
            fillSetting.CommaSeparatedStatus__c = 'On Hold';
            fillSetting.Name = '00B30000008IdcD';
            fillSetting.MaxNumberOfCasesToAssign__c = 1;
            Database.insert(fillSetting);
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = crQueue.Id;
            Database.insert(csRec);
            
            Test.startTest();
            SSSW_FillInbox.wsFillInbox();
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method tests scenario of fill inbox for users in eligible queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFillInbox_EligibleQueueCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        //test data setup
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.id);
        Database.insert(runningUser);
        Group crQueue = [SELECT Id,DeveloperName FROM Group WHERE Name ='SSSW Business Back Office' LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = crQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        
        System.runAs(runningUser){
            // Create fill inbox custom setting
            FillInboxSettings__c fillSetting = new FillInboxSettings__c();
            fillSetting.CommaSeparatedStatus__c = 'On Hold';
            fillSetting.Name = '00B30000008IdcD';
            fillSetting.MaxNumberOfCasesToAssign__c = 1;
            Database.insert(fillSetting);
            //create eligible queue custom setting record
            Database.insert( new EligibleQueue_FillInBox__c(Name = 'SSSW Business Back Office') );
            
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            //account creation for case
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            //contact creation for case
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            //case record created for agent pull
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = crQueue.Id;
            Database.insert(csRec);
            
            //initialize fill inbox code
            Test.startTest();
                SSSW_FillInbox fBox = new SSSW_FillInbox();
                Boolean check = SSSW_FillInbox.fillInboxClicked;
                SSSW_FillInbox.wsFillInbox();
            Test.stopTest();
        }
    }
    
    
    /**
      * @description       This method tests scenario of fill inbox for users in eligible queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFillInbox_NotinEligibleQueueCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        //test data setup
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.id);
        Database.insert(runningUser);
        Group crQueue = [SELECT Id,DeveloperName FROM Group WHERE Name ='SSSW Business Back Office' LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = crQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        
        System.runAs(runningUser){
            // Create fill inbox custom setting
            FillInboxSettings__c fillSetting = new FillInboxSettings__c();
            fillSetting.CommaSeparatedStatus__c = 'On Hold';
            fillSetting.Name = '00B30000008IdcD';
            fillSetting.MaxNumberOfCasesToAssign__c = 1;
            Database.insert(fillSetting);
            
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            //account creation for case
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            //contact creation for case
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            //case record created for agent pull
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = crQueue.Id;
            Database.insert(csRec);
            
            //initialize fill inbox code
            Test.startTest();
                SSSW_FillInbox fBox = new SSSW_FillInbox();
                Boolean check = SSSW_FillInbox.fillInboxClicked;
                SSSW_FillInbox.wsFillInbox();
            Test.stopTest();
        }
    }
}