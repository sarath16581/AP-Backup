/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 25/11/2015
  * @description  : Test Class for CaseOpportunityUtility
  *
  * 02/06/2020    : Shashwat.a.nath@accenture.com Updated the method testUpdateOpportunityDriver to assign PS with permission to bypass the classic opportunity creation restriction 
                    to the running user
  */
@isTest
private with sharing class CaseOpportunityUtility_Test {
    
    @testSetup static void testDataCreate() {
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
    }
    
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String COV_SALES_PROFILE = 'Coverage Sales';
        
    /**
      * @description       This method tests scenario of updating opportunity driver of Sales manager review case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateOpportunityDriver(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: COV_SALES_PROFILE LIMIT 1];
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        insert runningUser;
        
        // Query your permission set name from Organization to bypass the validation.
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = runningUser.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        System.runAs(runningUser){
            TestUtility.severityLevelValue();
            TestUtility.createUniqueCaseCustomSetting();
            TestUtility.createStatTrackingCustomSetting();
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.MailingStreet = 'Bourke Street';
            Database.insert(con);
            
            Opportunity opp = TestUtility.createOpportunity('Test Opp',acc.Id,'Identify',Date.Today() + 10);
            Database.insert(opp);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get(SSSWConstants.RECTYPE_CASE_SALES_MANAGER).getRecordTypeId());
            csRec.Opportunity__c = opp.Id;
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            opp = [SELECT OwnerId FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
            csRec = [SELECT Opportunity_Driver1__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(opp.OwnerId,csRec.Opportunity_Driver1__c);
        }
    }
    
    /**
      * @description       This method tests scenario of updating opportunity driver of Sales manager review case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateOPC(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            TestUtility.createUniqueCaseCustomSetting();
            TestUtility.createStatTrackingCustomSetting();
            TestUtility.createTestEntitlementProcessData();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.MailingStreet = 'Bourke Street';
            Database.insert(con);
            
            Opportunity opp = TestUtility.createOpportunity('Test Opp',acc.Id,'Identify',Date.Today() + 10);
            Database.insert(opp);
            
            Product2 prod = TestUtility.createProduct('Prod','Prod Family','Prod Class');
            Database.insert(prod);
            
            Opp_Product_Classification__c opcRec = TestUtility.createOPC(acc.Id,opp.Id,prod.Id);
            Database.insert(opcRec);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get(SSSWConstants.RECTYPE_CASE_SALES_MANAGER).getRecordTypeId());
            csRec.Originating_OPC__c = opcRec.Id;
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            opcRec = [SELECT Under_Review_by_Sales_Manager__c  FROM Opp_Product_Classification__c WHERE Id =: opcRec.Id LIMIT 1];
            System.assertEquals(true,opcRec.Under_Review_by_Sales_Manager__c );
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testUpdateOppDriverExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: COV_SALES_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseOpportunityUtility helper = new CaseOpportunityUtility();
            Test.startTest();
                helper.updateOpportunityDriver(new List<Case>{null});
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
    private static testMethod void testUpdateOPCExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: COV_SALES_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseOpportunityUtility helper = new CaseOpportunityUtility();
            Test.startTest();
                helper.updateOPCUnderReviewBySalesManagerFlag(new List<Case>{null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
}