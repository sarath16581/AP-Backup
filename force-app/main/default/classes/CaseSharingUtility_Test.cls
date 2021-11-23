/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/09/2015
  * @description  : Test Class for CaseSharingUtility
  * @changelog
  * 2021-10-15 - Nathan Franklin - Removed signature test methods
  */
@isTest
private with sharing class CaseSharingUtility_Test {
    
     // Variables
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent contacting network for a case - insert
     **********************************************************************/
    private static testMethod void testContactNoNetwork_INSERT(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = null;
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(0,mbrList.size(),
                                'As no network attached to case, no case team members ');
            
        }
        
    }
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent contacting network for a case on creation
     **********************************************************************/
    private static testMethod void testContactNetwork_INSERT(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
            
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            Database.insert(ntwrk);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = ntwrk.Id;
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(0,mbrList.size(), 
                                'As network has no facilty users attached, no case team members');
            
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent contacting network for a case on creation with network users attached
     **********************************************************************/
    private static testMethod void testContactNetworkWithMbrs_INSERT(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();

            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            Database.insert(ntwrk);
            
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            ntwrkUser.Is_MyNetwork_User__c = true;
            Database.insert(ntwrkUser);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = ntwrk.Id;
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(1,mbrList.size(), 
                                'Network user is attached to the case as case team member');
            
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent contacting network without users for a case on update
     **********************************************************************/
    private static testMethod void testContactNetworkWithOutMbrs_Update(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
           
           Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();

            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            Database.insert(ntwrk);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            
            csRec.Network__c = ntwrk.Id;
            
            Test.startTest();
                Database.update(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(0,mbrList.size(),
                                'As network has no facilty users attached, no case team members');
            
        }
    }
    
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent contacting network for a case with netwok users on update
     **********************************************************************/
    private static testMethod void testContactNetworkWithMbrs_Update(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
       
       System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
           
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();

            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            Database.insert(ntwrk);
            
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            ntwrkUser.Is_MyNetwork_User__c = true;
            Database.insert(ntwrkUser);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = null;
            Database.insert(csRec);

            Test.startTest();
                csRec.Network__c = ntwrk.Id;
                Database.update(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(1,mbrList.size(),
                                'Network user is attached to the case as case team member');
            
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *      This method tests scenario of agent removing network from a case
     **********************************************************************/
    private static testMethod void testContactRemoveNetworkWithMbrs_Update(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();

            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            Database.insert(ntwrk);
            
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            ntwrkUser.Is_MyNetwork_User__c = true;
            Database.insert(ntwrkUser);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = ntwrk.Id;
            Database.insert(csRec);

            Test.startTest();
                csRec.Network__c = null;
                Database.update(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(0,mbrList.size(),
                                'Network user is removed from case team member');
            
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *       This method tests scenario of agent changing network for a case
     **********************************************************************/
    private static testMethod void testContactChangeNetworkWithMbrs_Update(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();

            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            List<Network__c> ntwrkList = new List<Network__c>();
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            
            Network__c newNtwrk = TestUtility.createNetwork('MELBOURNE COLLINS STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
                                                            
            ntwrkList.add(ntwrk);
            ntwrkList.add(newNtwrk);
            Database.insert(ntwrkList);
            
            List<Facility_User__c> ntwrkUserList = new List<Facility_User__c>();
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            Facility_User__c diffNtwrkUser = TestUtility.createNetworkUser(newNtwrk.Id,UserInfo.getUserId());
            ntwrkUser.Is_MyNetwork_User__c = true;
            diffNtwrkUser.Is_MyNetwork_User__c = true;
            ntwrkUserList.add(ntwrkUser);
            ntwrkUserList.add(diffNtwrkUser);
            Database.insert(ntwrkUserList);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Network__c = ntwrk.Id;
            Database.insert(csRec);

            Test.startTest();
                csRec.Network__c = newNtwrk.Id;
                Database.update(csRec);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId =: csRec.Id];
            System.assertEquals(1,mbrList.size(),
                                'New network user of new network is connected to case team member');
            
        }
    }
    
    
    /**********************************************************************
     *  Scenario:
     *       This method tests scenario of assigning network for cases in bulk
     **********************************************************************/
    private static testMethod void testContactNetworkWithMbrsInsert_Bulk(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            List<Network__c> ntwrkList = new List<Network__c>();
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            
            Network__c newNtwrk = TestUtility.createNetwork('MELBOURNE COLLINS STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
                                                            
            ntwrkList.add(ntwrk);
            ntwrkList.add(newNtwrk);
            Database.insert(ntwrkList);
            
            List<Facility_User__c> ntwrkUserList = new List<Facility_User__c>();
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            Facility_User__c diffNtwrkUser = TestUtility.createNetworkUser(newNtwrk.Id,UserInfo.getUserId());
            ntwrkUser.Is_MyNetwork_User__c = true;
            diffNtwrkUser.Is_MyNetwork_User__c = true;
            ntwrkUserList.add(ntwrkUser);
            ntwrkUserList.add(diffNtwrkUser);
            Database.insert(ntwrkUserList);
            
            List<Case> caseList = new List<Case>();
            for(Integer i = 0; i < 20 ; i++){
                Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                csRec.Network__c = ntwrk.Id;
                caseList.add(csRec);
            }

            Test.startTest();
                Database.insert(caseList);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId IN: caseList];
            System.assertEquals(caseList.size(),mbrList.size(),
                                'Network users are connected as case team members');
            
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *       This method tests scenario of changing network for cases in bulk
     **********************************************************************/
    private static testMethod void testContactChangeNetworkWithMbrsUpdate_Bulk(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        User ponUser = TestUtility.createUser('Peter',prof.id,null);
        Database.insert(ponUser);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            List<Network__c> ntwrkList = new List<Network__c>();
            Network__c ntwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
            
            Network__c newNtwrk = TestUtility.createNetwork('MELBOURNE COLLINS STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                            'test@test.com');
                                                            
            ntwrkList.add(ntwrk);
            ntwrkList.add(newNtwrk);
            Database.insert(ntwrkList);
            
            List<Facility_User__c> ntwrkUserList = new List<Facility_User__c>();
            Facility_User__c ntwrkUser = TestUtility.createNetworkUser(ntwrk.Id,ponUser.Id);
            Facility_User__c diffNtwrkUser = TestUtility.createNetworkUser(newNtwrk.Id,UserInfo.getUserId());
            ntwrkUser.Is_MyNetwork_User__c = true;
            diffNtwrkUser.Is_MyNetwork_User__c = true;
            ntwrkUserList.add(ntwrkUser);
            ntwrkUserList.add(diffNtwrkUser);
            Database.insert(ntwrkUserList);
            
            List<Case> caseList = new List<Case>();
            for(Integer i = 0; i < 20 ; i++){
                Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                csRec.Network__c = ntwrk.Id;
                caseList.add(csRec);
            }
            Database.insert(caseList);

            Test.startTest();
                for(Case csRec : caseList){
                    csRec.Network__c = newNtwrk.Id;
                }
                Database.update(caseList);
            Test.stopTest();
            
            List<CaseTeamMember> mbrList = [SELECT Id,ParentId,MemberId FROM CaseTeamMember WHERE ParentId IN: caseList];
            System.assertEquals(caseList.size(),mbrList.size(),
                                'Network users are connected as case team members on all cases');
        
        }
    }
    
    /**********************************************************************
     *  Scenario:
     *        This method is for covering exception and not a valid business scenario
     **********************************************************************/
    private static testMethod void testExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            
            TestUtility.severityLevelValue();
            CaseSharingUtility helper = new CaseSharingUtility();
           
            Test.startTest();
                helper.handleCaseTeamMembers(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }

    
    /**********************************************************************
     *  Scenario:
     *       insert cases to test add case team member functionality
        when parent case exists for a case when requestor is null or not
        equal to parent case owner id
     **********************************************************************/
   
    @isTest
    static void testinsertCaseTeamMembersForChildCaseNoRequestor(){
        //Get Account Record Type
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        //Insert Account
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);
        //Insert Contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.MailingState = 'Vic';
        Database.insert(con);
        //insert parent case
        Case ParentCase = new Case();
        ParentCase.Type = 'Feedback';
        ParentCase.Subject = 'Newsdd';
        ParentCase.Status = 'Network Responded';
        ParentCase.ProductCategory__c = 'Travel & ID';
        ParentCase.EnquirySubType__c = 'Product Support';
        ParentCase.ProductSubCategory__c = 'KeyPass';
        ParentCase.EnquirySubType__c = 'Article carded - no card left';
        ParentCase.DateofIncident__c = date.today();
        ParentCase.ContactId = con.Id;
        ParentCase.AccountId = acc.Id;
        ParentCase.Network__c = null;
        //set parent case existing in metadata
        ParentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
        insert ParentCase; 

        //insert child case
        Case childCase = new Case();
        childCase.Type = 'Feedback';
        childCase.Subject = 'Newsdd';
        childCase.Status = 'Network Responded';
        childCase.ProductCategory__c = 'Travel & ID';
        childCase.EnquirySubType__c = 'Product Support';
        childCase.ProductSubCategory__c = 'KeyPass';
        childCase.EnquirySubType__c = 'Article carded - no card left';
        childCase.DateofIncident__c = date.today();
        childCase.Network__c = null;
        //set child case existing in metadata
        childCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        //set parent id
        childCase.ParentId = ParentCase.Id;
        insert childCase; 
    }

    /**********************************************************************
     *  Scenario:
     *       insert cases to test add case team member functionality
        when parent case exists for a case when requestor not null and matching
        with parent case owner
     **********************************************************************/
   
    @isTest
    static void testinsertCaseTeamMembersForChildCaseWithRequestorMatchingParentCaseOwner(){
        //Get Account Record Type
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        //Insert Account
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);
        //Insert Contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.MailingState = 'Vic';
        Database.insert(con);
        //insert parent case
        Case ParentCase = new Case();
        ParentCase.Type = 'Feedback';
        ParentCase.Subject = 'Newsdd';
        ParentCase.Status = 'Network Responded';
        ParentCase.ProductCategory__c = 'Travel & ID';
        ParentCase.EnquirySubType__c = 'Product Support';
        ParentCase.ProductSubCategory__c = 'KeyPass';
        ParentCase.EnquirySubType__c = 'Article carded - no card left';
        ParentCase.DateofIncident__c = date.today();
        ParentCase.AccountId = acc.Id;
        ParentCase.ContactId = con.Id;
        ParentCase.Network__c = null;
        //set parent case existing in metadata
        ParentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
        insert ParentCase; 

        //insert child case
        Case childCase = new Case();
        childCase.Type = 'Feedback';
        childCase.Subject = 'Newsdd';
        childCase.Status = 'Network Responded';
        childCase.ProductCategory__c = 'Travel & ID';
        childCase.EnquirySubType__c = 'Product Support';
        childCase.ProductSubCategory__c = 'KeyPass';
        childCase.EnquirySubType__c = 'Article carded - no card left';
        childCase.DateofIncident__c = date.today();
        childCase.Network__c = null;
        childCase.Requestor__c = ParentCase.OwnerId;
        //set child case existing in metadata
        childCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        //set parent id
        childCase.ParentId = ParentCase.Id;
        insert childCase; 
    }

    /**********************************************************************
     *  Scenario:
     *       insert cases to test add case team member functionality
        when parent case exists for a case when queue is owner for parent 
        case
     **********************************************************************/
   
    @isTest
    static void testinsertCaseTeamMembersForChildCaseWithRequestorQueueParentCaseOwner(){
        //insert queue
        Group g1 = new Group(Name='group name', type='Queue');
        insert g1;
        System.runAs(new User(Id=UserInfo.getUserId())){
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SObjectType = 'Case');
            insert q1;
        }
        //Get Account Record Type
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        //Insert Account
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);
        //Insert Contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.MailingState = 'Vic';
        Database.insert(con);
        //insert parent case
        Case ParentCase = new Case();
        ParentCase.Type = 'Feedback';
        ParentCase.Subject = 'Newsdd';
        ParentCase.Status = 'Network Responded';
        ParentCase.ProductCategory__c = 'Travel & ID';
        ParentCase.EnquirySubType__c = 'Product Support';
        ParentCase.ProductSubCategory__c = 'KeyPass';
        ParentCase.EnquirySubType__c = 'Article carded - no card left';
        ParentCase.DateofIncident__c = date.today();
        ParentCase.AccountId = acc.Id;
        ParentCase.ContactId = con.Id;
        ParentCase.Network__c = null;
        ParentCase.OwnerId = g1.Id;
        //set parent case existing in metadata
        ParentCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
        insert ParentCase; 

        //insert child case
        Case childCase = new Case();
        childCase.Type = 'Feedback';
        childCase.Subject = 'Newsdd';
        childCase.Status = 'Network Responded';
        childCase.ProductCategory__c = 'Travel & ID';
        childCase.EnquirySubType__c = 'Product Support';
        childCase.ProductSubCategory__c = 'KeyPass';
        childCase.EnquirySubType__c = 'Article carded - no card left';
        childCase.DateofIncident__c = date.today();
        childCase.Network__c = null;
        childCase.Requestor__c = UserInfo.getUserId();
        //set child case existing in metadata
        childCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        //set parent id
        childCase.ParentId = ParentCase.Id;
        insert childCase; 
    }
}