@isTest
private class APT_ManageSAPContractController_Test{
    
    public static testMethod void testingData(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        insert aptContract;
        APT_SAP_Contracts__c sapContract= new APT_SAP_Contracts__c(APT_Apttus_Contract__c=aptContract.Id,APT_SAP_Contract_Number__c='1234567');
        Test.startTest();
        insert sapContract;
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptContract.Id);
        APT_ManageSAPContractController SAPcontracts = new APT_ManageSAPContractController();
        SAPcontracts.textAreaUserInput = '1234567\n1234568\n1234569\n';
        //Test.startTest();
        SAPcontracts.saveSAPContracts();
        TEst.stopTest();
    }
    public static testMethod void testingData1(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        insert aptContract;
        APT_SAP_Contracts__c sapContract= new APT_SAP_Contracts__c(APT_Apttus_Contract__c=aptContract.Id,APT_SAP_Contract_Number__c='12345167');
        Test.startTest();
        insert sapContract;
        update sapContract;
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptContract.Id);
        APT_ManageSAPContractController SAPcontracts = new APT_ManageSAPContractController();
        SAPcontracts.textAreaUserInput = '12345678\n12345688\n12345698\n';
        //Test.startTest();
        SAPcontracts.saveSAPContracts();
        TEst.stopTest();
    }
     public static testMethod void testingData2(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        insert aptContract;
        APT_SAP_Contracts__c sapContract= new APT_SAP_Contracts__c(APT_Apttus_Contract__c=aptContract.Id,APT_SAP_Contract_Number__c='1234567');
        Test.startTest();
        insert sapContract;
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptContract.Id);
        APT_ManageSAPContractController SAPcontracts = new APT_ManageSAPContractController();
        SAPcontracts.textAreaUserInput = '';
        //Test.startTest();
        SAPcontracts.saveSAPContracts();
        TEst.stopTest();
    }
    public static testMethod void testingData3(){
        APT_ManageSAPContractController SAPcontracts = new APT_ManageSAPContractController();
        SAPcontracts.textAreaUserInput = '';
        SAPcontracts.title='test';
        SAPcontracts.processingText = 'In Progress';
        SAPcontracts.saveText='Saved';
        SAPcontracts.pageCancel='Cancelled';
        Test.startTest();
        SAPcontracts.saveSAPContracts();
        SAPcontracts.backToContract();
        TEst.stopTest();
    }
    public static testMethod void testingData4(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        insert aptContract;
        APT_SAP_Contracts__c sapContract= new APT_SAP_Contracts__c(APT_Apttus_Contract__c=aptContract.Id,APT_SAP_Contract_Number__c='1234567');
        Test.startTest();
        insert sapContract;
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptContract.Id);
        APT_ManageSAPContractController SAPcontracts = new APT_ManageSAPContractController();
        SAPcontracts.textAreaUserInput = '123456A\n1234568\n1234569\n';
        //Test.startTest();
        SAPcontracts.saveSAPContracts();
        delete sapContract;
        TEst.stopTest();
    }
}