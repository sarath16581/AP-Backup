/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 24/06/2015
  * @description  : Test Class for HLCUtility
  * 
  * @changelog:
  * 2021-09-06  seth.heang@auspost.com.au   Uplift SF API version to 52
  */
@isTest
public with sharing class HLCUtility_Test {
    
    // Variables
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String HLC_QUEUE = 'SSSW_High_Level_Complaints';
    
    /**
      * @description       This method tests scenario of rendering HLC section
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testHLCSectionRender(){
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
            
            Database.insert(csRec);
            Test.setCurrentPage(Page.CaseDetails);
            System.currentPageReference().getParameters().put('id',csRec.id);           
            ApexPages.standardController stdController = new ApexPages.standardController(csRec);
            
            StaticResourceCalloutMock mockCallout = new StaticResourceCalloutMock ();
            mockCallout.setStaticResource('MockLayoutResponse');
            mockCallout.setStatusCode(200);
            mockCallout.setHeader('Content-Type', 'application/json');
                    
            Test.setMock(HttpCalloutMock.class, mockCallout);
            
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
                CaseDetailsCaseContExt extn = new CaseDetailsCaseContExt(stdController);
                try{
                    extn.initializePage();
                }
            	catch(QueryException exp) { // catching soql exception as "initializePage" method is not handling exception
                    System.assertEquals('System.QueryException',exp.getTypeName());
                }
                catch(Exception exp){   // catching exception as "initializePage" method is not handling exception
                    System.assertEquals('System.NullPointerException',exp.getTypeName());   
                }
                System.assertEquals(false,extn.showOwnerPanel); 
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method tests scenario of rendering HLC section
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testHLCSectionRender_HLCAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.id);
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
            
            Database.insert(csRec);
            Test.setCurrentPage(Page.CaseDetails);
            System.currentPageReference().getParameters().put('id',csRec.id);           
            ApexPages.standardController stdController = new ApexPages.standardController(csRec);
            
            StaticResourceCalloutMock mockCallout = new StaticResourceCalloutMock ();
            mockCallout.setStaticResource('MockLayoutResponse');
            mockCallout.setStatusCode(200);
            mockCallout.setHeader('Content-Type', 'application/json');
                    
            Test.setMock(HttpCalloutMock.class, mockCallout);
            
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
                CaseDetailsCaseContExt extn = new CaseDetailsCaseContExt(stdController);
                try{
                    extn.initializePage();
                }
            	catch(QueryException exp) { // catching soql exception as "initializePage" method is not handling exception
                    System.assertEquals('System.QueryException',exp.getTypeName());
                }
                catch(Exception exp){   // catching exception as "initializePage" method is not handling exception
                    System.assertEquals('System.NullPointerException',exp.getTypeName());   
                }
                System.assertEquals(true,extn.showOwnerPanel);  
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
            Test.startTest();
                try{
                    HLCUtility.getAgentQueueType(null);
                }
                catch(Exception exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals('System.NullPointerException',exp.getTypeName());
                }
            Test.stopTest();
            
        }
    }
}