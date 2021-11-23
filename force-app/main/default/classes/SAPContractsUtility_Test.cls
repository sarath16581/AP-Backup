/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 19/08/2016
  * @description  : Test Class for SAPContractsUtility
  * 
  * Shashwat.a.nath@accenture.com updated the testsyncVolumeRevenue to set the Stagename to Identify to be in Sync with Validation Rule :NewRecord_Stage_Validation
  */
@isTest
private with sharing class SAPContractsUtility_Test {
    private static final String ADMIN_PROFILE = 'System Administrator';
    
    /**
      * @description       This method tests scenario of syncing volume and revenue fields for Apttus Agreement Object from SAP Contracts Object
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testsyncVolumeRevenue(){
        Profile profile = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        List<APT_SAP_Contracts__c> sapContractList = new List<APT_SAP_Contracts__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        
        System.runAs(TestUtility.createUser('Admin',profile.id,null)){
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Stark Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);
            
            Contact con = TestUtility.createContact('Arya','Stark','arya@stark.com',acc.id);
            Database.insert(con);
            
            Opportunity opp1 = new Opportunity(Name = 'TestOpp1',StageName = 'Identify',CloseDate = date.Today().addDays(365),AccountId = acc.id);
            Opportunity opp2 = new Opportunity(Name = 'TestOpp2',StageName = 'Identify',CloseDate = date.Today().addDays(365),AccountId = acc.id);  
            oppList.add(opp1);
            oppList.add(opp2);           
            Database.insert(oppList );           
            
           
           Test.startTest(); 
            Apttus__APTS_Agreement__c  aptContractY = APT_TestUtils.createAgreement(con.Id);
            aptContractY.Name = 'TestContractY';
            aptContractY.Apttus__Primary_Contact__c=con.Id;
            aptContractY.Apttus__Agreement_Category__c='Standard';
            aptContractY.APT_Product__c= 'eParcel' ;
            aptContractY.Apttus__Related_Opportunity__c=opp1.Id;
            aptContractY.Apttus__Account__c=acc.Id;
            aptContractY.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContractY.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContractY.APT_Contract_Volume__c = 100;
            aptContractY.Apttus__Total_Contract_Value__c = 100; 
            
            Apttus__APTS_Agreement__c  aptContractN = APT_TestUtils.createAgreement(con.Id);            
            aptContractN.Name = 'TestContractN';
            aptContractN.Apttus__Primary_Contact__c=con.Id;
            aptContractN.Apttus__Agreement_Category__c='Standard';
            aptContractN.APT_Product__c= 'eParcel' ;
            aptContractN.Apttus__Related_Opportunity__c=opp2.Id;
            aptContractN.Apttus__Account__c=acc.Id;
            aptContractN.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
            aptContractN.RecordType.DeveloperName = 'SecurePay Online Payments';
            aptContractN.APT_Contract_Volume__c = 0;             
            aptContractN.Apttus__Total_Contract_Value__c = null;
            
            agreementList.add(aptContractY);
            agreementList.add(aptContractN);
            Database.insert(agreementList);
            
            
            APT_SAP_Contracts__c sapContractY = new APT_SAP_Contracts__c ( APT_Apttus_Contract__c = aptContractY.Id, APT_Contract_Volume__c = 200, APT_Contracted_Revenue__c= 400, APT_SAP_Contract_Number__c = '12345', APT_Current_Quote_Indicator__c = 'Y');
            APT_SAP_Contracts__c sapContractN = new APT_SAP_Contracts__c ( APT_Apttus_Contract__c = aptContractN.Id, APT_Contract_Volume__c = 500, APT_Contracted_Revenue__c= 600, APT_SAP_Contract_Number__c = '45678', APT_Current_Quote_Indicator__c = 'N');
            sapContractList.add(sapContractY);
            sapContractList.add(sapContractN);                                                                                      
            Database.insert(sapContractList);

    
            Test.stopTest(); 

            
            Apttus__APTS_Agreement__c ag = [SELECT APT_Contract_Volume__c, Apttus__Total_Contract_Value__c FROM Apttus__APTS_Agreement__c   Where Id =: aptContractY.Id LIMIT 1];
            //System.assertEquals(200,ag.APT_Contract_Volume__c);     
            
            
            
            
        }
     }
    
}