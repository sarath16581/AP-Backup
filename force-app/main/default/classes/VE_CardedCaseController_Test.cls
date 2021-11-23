/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 07/11/2016
  * @description  : Test Class for VE_CardedCaseController
  */
@isTest
private with sharing class VE_CardedCaseController_Test {
    
    // Variables
    private static final String ADMIN = 'System Administrator';
    
    @testSetup
    private static void testDataSetup(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN LIMIT 1];
        User ssswAgent = TestUtility.createUser('Wayne',prof.id,null);
        Database.insert(ssswAgent);
        
        CardedCaseEventCode__c eventCode = new CardedCaseEventCode__c();
        eventCode.Name = 'DD-ER11';
        eventCode.EventType__c = 'DD-ER11';
        Database.insert(eventCode);
        
        List<Article__c> articleList = new List<Article__c>();
        Article__c articleOne = TestUtility.createArticle('12345',null,null,null,null);
        Article__c articleTwo = TestUtility.createArticle('123456',null,null,null,null);
        Article__c articleThree = TestUtility.createArticle('123457',null,null,null,null);
        
        articleList.add(articleOne);
        articleList.add(articleTwo);
        articleList.add(articleThree);
        Database.insert(articleList);
        
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                        accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        Database.insert(con);
        
        Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
        
        List<Network__c> ntwrkList = new List<Network__c>();
        
        Network__c blueNtwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                        'testBlue@test.com');
        blueNtwrk.Parent_SBU__c = Label.BLUE_POST;
        
        Network__c redNtwrk = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                        'testRed@test.com');
        redNtwrk.Parent_SBU__c = Label.RED_POST;
        
        Network__c noSBU = TestUtility.createNetwork('MELBOURNE BOURKE STREET',ntwrkRecTypeMap.get('Retail').getRecordTypeId(),
                                                        'test@test.com');
        
        ntwrkList.add(blueNtwrk);
        ntwrkList.add(redNtwrk);
        ntwrkList.add(noSBU);
        Database.insert(ntwrkList);
        
        Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ReferenceID__c = '1234567';
        csRec.ProductCategory__c = 'Domestic Letters';
        csRec.Network__c = redNtwrk.Id;
        
        Case csRecWithEvent = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRecWithEvent.ReferenceID__c = '12345';
        csRecWithEvent.ProductCategory__c = 'Domestic Parcels';
        csRecWithEvent.Network__c = blueNtwrk.Id;
        
        Case lettersWithEvent = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        lettersWithEvent.ReferenceID__c = '123456';
        lettersWithEvent.ProductCategory__c = 'Domestic Letters';
        lettersWithEvent.Network__c = noSBU.Id;
        
        List<Case> caseList = new List<Case>();
        caseList.add(csRec);
        caseList.add(csRecWithEvent);
        caseList.add(lettersWithEvent);
        Database.insert(caseList);
        
        Article__c parcelArticle = [SELECT Id FROM Article__c WHERE Name = '12345' LIMIT 1];
        Article__c letterArticle = [SELECT Id FROM Article__c WHERE Name = '123456' LIMIT 1];
        
        List<EventMessage__c> eventList = new List<EventMessage__c>();
        
        EventMessage__c parcelEventMsg = new EventMessage__c();
        parcelEventMsg.Article__c = parcelArticle.Id;
        parcelEventMsg.EventType__c = 'DD-ER11';
        parcelEventMsg.EventDescription__c = 'Attempted delivery - Customer not in attendance';
        parcelEventMsg.DeviceUser__c = 'BROWJA';
        parcelEventMsg.SenderName__c = 'Blackbay';
        parcelEventMsg.DeviceID__c = '16C0AA7D060073E65B7606490108000B';
        parcelEventMsg.UserName__c = 'BROWJA';
        
        EventMessage__c letterEventMsg = new EventMessage__c();
        letterEventMsg.Article__c = letterArticle.Id;
        letterEventMsg.EventType__c = 'DD-ER11';
        letterEventMsg.EventDescription__c = 'Attempted delivery - Customer not in attendance';
        letterEventMsg.DeviceUser__c = 'BROWJA';
        letterEventMsg.SenderName__c = 'Blackbay';
        letterEventMsg.DeviceID__c = '16C0AA7D060073E65B7606490108000B';
        letterEventMsg.UserName__c = 'BROWJA';
        
        eventList.add(parcelEventMsg);
        eventList.add(letterEventMsg);
        
        Database.insert(eventList);
    }
    
    /**
      * @description       This method tests scenario of loading carded case template
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testTemplateLoad(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: ADMIN AND LastName = 'Wayne' LIMIT 1];
        System.runAs(runningUser){
            VE_CardedCaseController cont = new VE_CardedCaseController();
            Case csRec = [SELECT Id,CaseNumber,Description,Type,ProductCategory__c,ProductSubCategory__c,EnquirySubType__c,ReferenceID__c,
                            Network__r.Parent_SBU__c FROM Case WHERE ReferenceID__c = '1234567' LIMIT 1];
            cont.cardedCase = csRec;
            System.debug('** Printing eventMessageFields just for coverage only ==>'+ cont.eventMessageFields);
            System.assert(cont.eventMessage == null);
        }
    }
    
    /**
      * @description       This method tests scenario of loading carded case template with eventMessage
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testTemplateLoadWithEventMessageParcel(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: ADMIN AND LastName = 'Wayne' LIMIT 1];
        System.runAs(runningUser){
            VE_CardedCaseController cont = new VE_CardedCaseController();
            Case csRec = [SELECT Id,CaseNumber,Description,Type,ProductCategory__c,ProductSubCategory__c,EnquirySubType__c,ReferenceID__c,
                            Network__r.Parent_SBU__c FROM Case WHERE ReferenceID__c = '12345' LIMIT 1];
            cont.cardedCase = csRec;
            System.debug('** Printing eventMessageFields just for coverage only ==>'+ cont.eventMessageFields);
            System.assert(cont.eventMessage != null);
        }
    }
    
    /**
      * @description       This method tests scenario of loading carded case template with eventMessage
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testTemplateLoadWithEventMessageLetters(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: ADMIN AND LastName = 'Wayne' LIMIT 1];
        System.runAs(runningUser){
            VE_CardedCaseController cont = new VE_CardedCaseController();
            Case csRec = [SELECT Id,CaseNumber,Description,Type,ProductCategory__c,ProductSubCategory__c,EnquirySubType__c,ReferenceID__c,
                            Network__r.Parent_SBU__c FROM Case WHERE ReferenceID__c = '123456' LIMIT 1];
            cont.cardedCase = csRec;
            System.debug('** Printing eventMessageFields just for coverage only ==>'+ cont.eventMessageFields);
            System.assert(cont.eventMessage != null);
        }
    }
}