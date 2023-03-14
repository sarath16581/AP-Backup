/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 21/06/2015
  * @description  : Test Class for CaseCommonTrigger
  */
@isTest
private with sharing class CaseCommonTrigger_Test {
    
     // Variables
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String BACK_OFC_QUEUE = 'SSSW_BOH_Group_2';
    private static final String HLC_QUEUE = 'SSSW_High_Level_Complaints';
    private static final String CR_QUEUE = 'SSSW_Customer_Recovery';
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase(){
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

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id];
            System.assertEquals(false,caseRec.IsHLC__c);
            System.assertEquals(false,caseRec.IsCR__c);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case assigning it to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase_HLCAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        Database.insert(runningUser);
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        System.runAs(runningUser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id];
            System.assertEquals(true,caseRec.IsHLC__c);
            System.assertEquals(false,caseRec.IsCR__c);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case assigning it to CR agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase_CRAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        Database.insert(runningUser);
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: CR_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        System.runAs(runningUser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id];
            System.assertEquals(false,caseRec.IsHLC__c);
            System.assertEquals(true,caseRec.IsCR__c);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case assigning it to HLC Queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase_HLCQueue(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Case csRec = null;
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = hlcQueue.id;

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
        }
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(true,caseRec.IsHLC__c);
        System.assertEquals(false,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of creating new case assigning it to CR Queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase_CRQueue(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Case csRec = null;
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: CR_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = hlcQueue.id;

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
    
        }
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(false,caseRec.IsHLC__c);
        System.assertEquals(true,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of assigning existing case to HLC Agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateCase_HLCAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User hlcAgent = TestUtility.createUser('hlc',prof.id,role.id);
        Database.insert(hlcAgent);
        
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = hlcAgent.id);
        Database.insert(grpMember);
        
        Case csRec = null;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Group bkOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: BACK_OFC_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = bkOfcQueue.id;
            Database.insert(csRec);
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
        
            // Share record created manually as criteria based sharing rules cannot be tested
            CaseShare shareRec = TestUtility.createCaseShare(csRec.id,'Edit',hlcAgent.id);
            Database.insert(shareRec);
        }

        System.runAs(hlcAgent){
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
            Test.startTest();
                csRec.OwnerId = hlcAgent.id;
                Database.update(csRec);
            Test.stopTest();
        }
        System.debug('** Log ==>'+[SELECT Name,ExceptionDescription__c,ClassName__c,ExceptionType__c FROM ExceptionLog__c]);
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(true,caseRec.IsHLC__c);
        System.assertEquals(false,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of assigning existing case to CR Agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateCase_CRAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User hlcAgent = TestUtility.createUser('hlc',prof.id,role.id);
        Database.insert(hlcAgent);
        
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: CR_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = hlcAgent.id);
        Database.insert(grpMember);
        
        Case csRec = null;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Group bkOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: BACK_OFC_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = bkOfcQueue.id;
            Database.insert(csRec);
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
        
            // Share record created manually as criteria based sharing rules cannot be tested
            CaseShare shareRec = TestUtility.createCaseShare(csRec.id,'Edit',hlcAgent.id);
            Database.insert(shareRec);
        }

        System.runAs(hlcAgent){
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
            Test.startTest();
                csRec.OwnerId = hlcAgent.id;
                Database.update(csRec);
            Test.stopTest();
        }
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(false,caseRec.IsHLC__c);
        System.assertEquals(true,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of assigning existing case to HLC Queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateCase_HLCQueue(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Case csRec = null;
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User hlcAgent = TestUtility.createUser('hlc',prof.id,role.id);
        Database.insert(hlcAgent);
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Group bkOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: BACK_OFC_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = bkOfcQueue.id;
            Database.insert(csRec);
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
        
            // Share record created manually as criteria based sharing rules cannot be tested
            CaseShare shareRec = TestUtility.createCaseShare(csRec.id,'Edit',hlcAgent.id);
            Database.insert(shareRec);
        }
        
        System.runAs(hlcAgent){
            Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
            Test.startTest();
                csRec.OwnerId = hlcQueue.id;
                Database.update(csRec);
            Test.stopTest();
        }
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(true,caseRec.IsHLC__c);
        System.assertEquals(false,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of assigning existing case to CR Queue
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateCase_CRQueue(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Case csRec = null;
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User hlcAgent = TestUtility.createUser('hlc',prof.id,role.id);
        Database.insert(hlcAgent);
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Group bkOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: BACK_OFC_QUEUE LIMIT 1];
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                            caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = bkOfcQueue.id;
            Database.insert(csRec);
            CaseTriggerHelper.isUpdateHLCRecursive  = false; // resetting Recursive flag to invoke update triggers
        
            // Share record created manually as criteria based sharing rules cannot be tested
            CaseShare shareRec = TestUtility.createCaseShare(csRec.id,'Edit',hlcAgent.id);
            Database.insert(shareRec);
        }
        
        System.runAs(hlcAgent){
            Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: CR_QUEUE LIMIT 1];
            Test.startTest();
                csRec.OwnerId = hlcQueue.id;
                Database.update(csRec);
            Test.stopTest();
        }
        Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(false,caseRec.IsHLC__c);
        System.assertEquals(true,caseRec.IsCR__c);
    }
    
    /**
      * @description       This method tests scenario of milestone completion on status change
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseMilestoneCompletion_Customer(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            
            csRec.Status = 'Awaiting Customer Response';
            csRec.Customer_Milestones_Violated__c = 1;
    
            Test.startTest();
                Database.update(csRec);
            Test.stopTest();
//            CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
//                                        WHERE CaseId =: csRec.Id AND MilestoneType.Name != 'Charter' AND MilestoneType.Name != 'First Customer Response'
//                                        ORDER BY CreatedDate ASC LIMIT 1];
             CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
                                        WHERE CaseId =: csRec.Id AND MilestoneType.Name = 'Charter' ORDER BY CreatedDate ASC LIMIT 1];
            System.assertEquals(false,milestone.IsCompleted);
            System.assertEquals(milestone.CompletionDate,null);
        }
    }
    
    /**
      * @description       This method tests scenario of milestone completion on status change
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseMilestoneCompletion_CustomerMultiple(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.OwnerId = UserInfo.getUserId();
            Database.insert(csRec);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            csRec.Status = 'Awaiting Customer Response';
            csRec.Customer_Milestones_Violated__c = 2;
            csRec.Internal_Milestones_Violated__c = 1;
            Test.startTest();
                Database.update(csRec);
            Test.stopTest();
            CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
                                        WHERE CaseId =: csRec.Id AND MilestoneType.Name != 'Charter' AND MilestoneType.Name != 'First Customer Response'
                                        ORDER BY CreatedDate ASC LIMIT 1];
            System.assertEquals(true,milestone.IsCompleted);
            System.assert(milestone.CompletionDate != null);
        }
    }
    
    /**
      * @description       This method tests scenario of milestone completion on status change
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseMilestoneCompletion_Network(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            
            csRec.Status = 'Awaiting Network Response';
            csRec.Facility_Milestones_Violated__c = 1;
    
            Test.startTest();
                Database.update(csRec);
            Test.stopTest();
            //CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
            //                            WHERE CaseId =: csRec.Id AND MilestoneType.Name != 'Charter' AND MilestoneType.Name != 'First Customer Response'
            //                            ORDER BY CreatedDate ASC LIMIT 1];
            CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
                                        WHERE CaseId =: csRec.Id AND MilestoneType.Name = 'Charter' ORDER BY CreatedDate ASC LIMIT 1];
            System.assertEquals(false,milestone.IsCompleted);
            System.assertEquals(null,milestone.CompletionDate); 
        }
    }
    
    /**
      * @description       This method tests scenario of milestone completion on status change
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseMilestoneCompletion_Internal(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','On Hold','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            
            csRec.Internal_Milestones_Violated__c = 1;
            Database.insert(csRec);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            
            Test.startTest();
                csRec.Status = 'In Progress';
                Database.update(csRec);
            Test.stopTest();
            //CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
            //                            WHERE CaseId =: csRec.Id AND MilestoneType.Name != 'Charter' AND MilestoneType.Name != 'First Customer Response' 
            //                            ORDER BY CreatedDate ASC LIMIT 1];
                                        
            CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
                                        WHERE CaseId =: csRec.Id AND MilestoneType.Name = 'Charter' ORDER BY CreatedDate ASC LIMIT 1];                            
            System.assertEquals(false,milestone.IsCompleted);
            System.assertEquals(null,milestone.CompletionDate);
        }
    }
    
    /**
      * @description       This method tests scenario of bulk case load to HLC Agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testMilestoneCompletion_Bulk(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.id)){
            TestUtility.createTestEntitlementProcessData();
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            List<Case> caseList = new List<Case>();
            for(Integer i=0; i < 20 ; i++){
                Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                caseList.add(csRec);
            }
            Database.insert(caseList);
            CaseTriggerHelper.isCompleteMilestonRecursive  = false; // resetting Recursive flag to invoke update triggers
            Test.startTest();
                for(Case csRec : caseList){
                    csRec.Status = 'Awaiting Customer Response';
                    csRec.Customer_Milestones_Violated__c = 1;
                }
                Database.update(caseList);
            Test.stopTest();
            CaseMilestone milestone = [SELECT Id,MilestoneType.Name,IsCompleted,CompletionDate,CaseId FROM CaseMilestone 
                                        WHERE CaseId IN: caseList AND MilestoneType.Name != 'Charter' 
                                        ORDER BY CreatedDate ASC LIMIT 1];
            System.assertEquals(true,milestone.IsCompleted);
            System.assert(milestone.CompletionDate != null); 
        }
    }
    
    /**
      * @description       This method tests scenario of bulk case load to HLC Agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testNewHLCCase_HLCAgent_Bulk(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        Database.insert(runningUser);
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        System.runAs(runningUser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            List<Case> caseList = new List<Case>();
            for(Integer i=0; i < 50 ; i++){
                Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                caseList.add(csRec);
            }

            Test.startTest();
                Database.insert(caseList);
            Test.stopTest();
            Case caseRec = [SELECT Id,IsHLC__c,IsCR__c FROM Case WHERE Id IN: caseList LIMIT 1];
            System.assertEquals(true,caseRec.IsHLC__c);
            System.assertEquals(false,caseRec.IsCR__c);
        }
    }
    
    /**
      * @description       This method tests scenario of creating authorized contacts
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCopyAuthContacts(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];        
        System.runAs(TestUtility.createUser('Wayne',adminProf.id,null)){
            TestUtility.createTestEntitlementProcessData();
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> authConrecTypeMap = Schema.Sobjecttype.AuthorisedContacts__c.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            List<Contact> contList = new List<Contact>();
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Contact authorizedcon = TestUtility.createContact('Peter','Wayne','peter@wayne.com',acc.id);
            contList.add(con);
            contList.add(authorizedcon);
            Database.insert(contList);
            
            AuthorisedContacts__c authCon = TestUtility.createAuthorizedContact(con.Id,authorizedcon.Id,
                                                                                authConrecTypeMap.get('Authorised Contact - All Cases').getRecordTypeId());
            Database.insert(authCon);
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Integer count = [SELECT Count() FROM AuthorisedContacts__c WHERE Case__c =: csRec.Id AND AuthorisingContact__c =: con.Id];
            System.assertEquals(1,count);
        }
    }
    
    /**
      * @description       This method tests scenario of parent case queue allocation on child case allocation
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateParentCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
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
            Database.insert(csRec);
            
            Test.startTest();
                
                Case childCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                childCase.ParentId = csRec.Id;
                Database.insert(childCase);
                
                childCase.AllocateToQueue__c = true;
                Database.update(childCase);
            Test.stopTest();
            Case caseRec = [SELECT Id,SystemUpdate__c FROM Case WHERE Id =: csRec.Id];
            System.assertEquals(SSSWConstants.STAT_CHILD_CASE_UPDATE,caseRec.SystemUpdate__c);
        }
    }
    
    /**
      * @description       This method tests scenario of parent case queue allocation on child case allocation
                            with parent part of the trigger context
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateParentCase_TriggerContextParent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
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
            Database.insert(csRec);

            Test.startTest();
                
                Case childCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
                childCase.ParentId = csRec.Id;
                Database.insert(childCase);
                List<Case> updateCaseList = new List<Case>();
                updateCaseList.add(csRec);
                
                childCase.AllocateToQueue__c = true;
                updateCaseList.add(childCase);
                Database.update(updateCaseList);
            Test.stopTest();
            Case caseRec = [SELECT Id,SystemUpdate__c FROM Case WHERE Id =: csRec.Id];
            System.assertEquals(SSSWConstants.STAT_CHILD_CASE_UPDATE,caseRec.SystemUpdate__c);
        }
    }
    
    /**
      * @description       Test method to validate deletion and undelete of Case
                           Scenario is not part of requirement, created for code coverage purpose only
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseDeleteUndelete(){
        Profile prof = [SELECT Id FROM Profile WHERE Name =: ADMIN_PROFILE LIMIT 1];
        User adminUser = TestUtility.createUser('Admin',prof.id,null);
        System.runAs(adminUser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            Database.delete(csRec);
            Test.startTest();
                Database.undelete(csRec);
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseTriggerHelper helper = new CaseTriggerHelper();
            Test.startTest();
                helper.updateHLC(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testDMLExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        Database.insert(runningUser);
        Group hlcQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName =: HLC_QUEUE LIMIT 1];
        GroupMember grpMember = new GroupMember(GroupId = hlcQueue.id,UserOrGroupId = runningUser.id);
        Database.insert(grpMember);
        System.runAs(runningUser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);

            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());

            csRec.Status = 'Closed';
            Test.startTest();
                try{
                    Database.insert(csRec);
                }
                catch(Exception exp){
                    System.assertEquals('System.DmlException',exp.getTypeName());
                }
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testMilestoneExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseTriggerHelper helper = new CaseTriggerHelper();
            Test.startTest();
                helper.completeMilestone(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCopyAuthContactsExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseTriggerHelper helper = new CaseTriggerHelper();
            Test.startTest();
                helper.copyAuthorisedContacts(new List<Case>{null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateParentCaseExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseTriggerHelper helper = new CaseTriggerHelper();
            Test.startTest();
                helper.updateParentCase(new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
}