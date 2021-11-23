/*
    Version history
    24/10/2018 - kalpita - updated the code to have test data creation and actual test run in seperate scopes to avoid governor limits 
    
*/

@isTest
private with sharing class APT_ImportControllerTest {

    public static testmethod void testAPT_ImportController(){
        Test.startTest();
        
        Account acc = new Account();
        acc.NAME = 'test acc';
        insert acc;
        
        Id rtID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt = new Apttus__APTS_Agreement__c();
        agmt.Name = 'Apttus Test';
        agmt.Apttus__Status_Category__c = 'In Signatures';
        agmt.Apttus__Status__c = 'Other Party Signatures';
        agmt.Apttus__Account__c = acc.ID;
        if(rtID != null)
        agmt.RecordTypeId = rtID;
        insert agmt;
        
        ApexPages.StandardController stdImp = new ApexPages.StandardController(agmt);
        APT_ImportController objAPTSImportCtrl = new APT_ImportController(stdImp);
        
        system.assertEquals(objAPTSImportCtrl.agreementId==agmt.Id,true);
        
        PageReference pageRef =  objAPTSImportCtrl.doThirdParty();
        system.assertEquals(pageRef!=null,true);
        
        pageRef =  objAPTSImportCtrl.doPartiallySigned();
        //system.assertEquals(pageRef!=null,true);
        
        pageRef =  objAPTSImportCtrl.doFullySigned();
        //system.assertEquals(pageRef!=null,true);
        
        objAPTSImportCtrl.doCancel();
        PageReference pagRf = new PageReference('/'+objAPTSImportCtrl.agreementId);
        //system.assertEquals(pageRef.getUrl()==pagRf.getURl(),true);
         
        Test.stopTest();
         
    }
    public static testmethod void testAPT_ImportController1(){
        
        
        Account acc1 = new Account();
        acc1.NAME = 'test acc';
        insert acc1;
        
        Id rtID1 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt1 = new Apttus__APTS_Agreement__c();
        agmt1.Name = 'Apttus Test1';
        agmt1.Apttus__Status_Category__c = 'Request';
        agmt1.Apttus__Status__c = 'Signature Declined';
        //agmt1.APT_Submit_to_Contract_Consulting_Team__c = false;
        agmt1.Apttus__Account__c = acc1.ID;
        agmt1.Apttus__Contract_End_Date__c = System.Today() + 100;
        if(rtID1 != null)
        agmt1.RecordTypeId = rtID1;
        insert agmt1;
        
        ApexPages.StandardController stdImp1 = new ApexPages.StandardController(agmt1);
        APT_ImportController objAPTSImportCtrl1 = new APT_ImportController(stdImp1);
        Test.startTest();
        objAPTSImportCtrl1.doFullySigned();
        PageReference pageRef =  objAPTSImportCtrl1.doThirdParty();
        agmt1.Apttus__Status_Category__c = 'Request';
        update agmt1;
        pageRef =  objAPTSImportCtrl1.doLegacy();
        
        ID agreeId = objAPTSImportCtrl1.agreementId;
        Apttus__APTS_Agreement__c agreement = [Select Apttus__Status_Category__c, Apttus__Status__c From Apttus__APTS_Agreement__c Where Id = :agreeId];
        system.assertEquals(agreement.Apttus__Status__c ,'Author Contract');
        
        Test.stopTest();
    }
    public static testmethod void testAPT_ImportController2(){
        Account acc = new Account();
        acc.NAME = 'test acc';
        insert acc;
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        insert opp;
        
        Contact con = APT_TestUtils.createContact();
        insert con;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal1= APT_TestUtils.getQuoteProposal(acc.id,opp.id,'Proposal','Quote', priceList.id);
        Proposal1.Apttus_Proposal__Approval_Stage__c='Accepted';
        //Proposal1.APT_Method_of_Payment__c = 'None';
        insert Proposal1;
        
        Id rtID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt = new Apttus__APTS_Agreement__c();
        agmt.Name = 'Apttus Test';
        agmt.ownerid = userinfo.getUserid();
        agmt.Apttus__Primary_Contact__c = con.id;
        agmt.Apttus__Agreement_Category__c = 'Standard';
        agmt.Apttus__Status_Category__c = 'In Signatures';
        agmt.Apttus__Status__c = 'Other Party Signatures';
        agmt.Apttus__Other_Party_Signed_By__c = con.id;
        agmt.Termination_Notice_Period__c = '30';
        agmt.Included_Product_Lines__c = 'eParcels Domestic';
        agmt.APT_Pricing_Category__c = 'Standard';
        agmt.Apttus__Subtype__c = 'Short Form';
        agmt.Term__c = 'Fixed Term';
        agmt.APT_Contract_Type__c = 'New Contract';
        agmt.Apttus__Contract_Start_Date__c = date.Today();
        agmt.APT_Contracting_Entity1__c = 'Australian Postal Corporation';
        agmt.Apttus__Related_Opportunity__c = opp.id;
        agmt.Apttus_QPComply__RelatedProposalId__c = Proposal1.Id;
        agmt.APT_Trading_As__c = 'None';
        agmt.Apttus__Account__c = acc.ID;
        if(rtID != null)
        agmt.RecordTypeId = rtID;
        insert agmt;
        
        Test.startTest();
        
            ApexPages.StandardController stdImp = new ApexPages.StandardController(agmt);
            APT_ImportController objAPTSImportCtrl = new APT_ImportController(stdImp);
            
            objAPTSImportCtrl.apiSessionId = '';
            objAPTSImportCtrl.apiServerURL  = '';
            objAPTSImportCtrl.output_text_Value = '';
            
            PageReference pageRef =  objAPTSImportCtrl.doThirdParty();
            pageRef =  objAPTSImportCtrl.doFullySigned();
            pageRef =  objAPTSImportCtrl.doPartiallySigned();
            // Commented out by Adrian Recio, temporary fix to avoid the soql 101 limit
            //pageRef =  objAPTSImportCtrl.doLegacy();
            system.assertEquals(pageRef!=null,true);
            
        test.stopTest();
    }
}