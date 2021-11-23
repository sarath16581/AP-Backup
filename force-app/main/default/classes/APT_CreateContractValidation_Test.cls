/* Created by: Adrian Recio
 * Description: Test class for APT_CreateContractValidationController class
 * Date: 17/08/2017
 */
@IsTest
public class APT_CreateContractValidation_Test {
    public static testMethod void Test_APT_CreateContractValidation(){
        // Create test contact
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        // Create test account
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        // Create test opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        oppList.add(opp);
        Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
        oppList.add(opp2);
        insert oppList;
        
        // Create test agreement
        List<Apttus__APTS_Agreement__c> agList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.APT_Contract_Type__c='DoV Contract';
        agList.add(aptContract);
            
        Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
        aptContract2.APT_Product__c= 'eParcel' ;
        aptContract2.Apttus__Related_Opportunity__c=opp2.Id;
        aptContract2.Apttus__Account__c=tempacct.Id;
        aptContract2.APT_Contract_Type__c='Open Ended'; // Updated to satisfy new validation in DoV Language, Adrian Recio, 2/8/2018
        agList.add(aptContract2);
        insert agList;
        
        // Create DOV Language
        APT_DoV_Language__c dovLVar = new APT_DoV_Language__c();
        dovLVar.APT_Contract__c = aptContract2.Id;
        dovLVar.APT_DoV_Action__c = 'Add';
        dovLVar.APT_DoV_Details__c = 'as detailed below';
        dovLVar.APT_DoV_Item__c = 'Pricing Schedule';
        dovLVar.APT_DoV_Product__c = 'eParcel';
        dovLVar.APT_DoV_Type__c = 'Open Ended'; // Updated to satisfy new validation in DoV Language, Adrian Recio, 2/8/2018
        insert dovLVar;
        
        ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
        
        test.startTest();
        	APT_CreateContractValidationController acValCon = new APT_CreateContractValidationController();
        	system.assertEquals(acValCon.IsError,true);
        	
        	ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
        	acValCon = new APT_CreateContractValidationController();
        	system.assertEquals(acValCon.IsError,false);
        test.stopTest();
    }
}