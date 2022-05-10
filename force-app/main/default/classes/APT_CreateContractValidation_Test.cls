/* Created by: Adrian Recio
 * Description: Test class for APT_CreateContractValidationController class
 * Date: 17/08/2017
 */
@IsTest
public class APT_CreateContractValidation_Test {

    @TestSetup
    static void makeData(){

        Apttus__ComplySystemProperties__c complySystemProperties = new Apttus__ComplySystemProperties__c(Name = 'System Properties', Apttus__InstanceUrl__c = String.valueOf(System.URL.getSalesforceBaseURL()));
        insert complySystemProperties;

        // Create test contact
        Contact con= APT_TestUtils.createContact();
        con.email = 'abc@test.com';
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

    }
    public static testMethod void Test_APT_CreateContractValidation(){

        List<Apttus__APTS_Agreement__c> listAgreement = [Select Id from Apttus__APTS_Agreement__c order by APT_Contract_Type__c asc];
        Apttus__APTS_Agreement__c aptContract = listAgreement[0];
        Apttus__APTS_Agreement__c aptContract2 = listAgreement[1];

        Pagereference pageRef = Page.APT_CreateContractValidation;

        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
        ApexPages.currentPage().getParameters().put('count','1');
        
        test.startTest();
        	APT_CreateContractValidationController acValCon = new APT_CreateContractValidationController();
        	ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
            ApexPages.currentPage().getParameters().put('count','1');
        	acValCon = new APT_CreateContractValidationController();
        test.stopTest();
        system.assertEquals(acValCon.IsError,false);
    }
    
    public static testMethod void Test_APT_CreateContractValidation_DocumentGeneration(){
        
        List<Apttus__APTS_Agreement__c> listAgreement = [Select Id from Apttus__APTS_Agreement__c order by APT_Contract_Type__c asc];
        Apttus__APTS_Agreement__c aptContract = listAgreement[0];
        Apttus__APTS_Agreement__c aptContract2 = listAgreement[1];

        ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
        ApexPages.currentPage().getParameters().put('count','1');
        
        Apttus__APTS_Template__c templateObj = new Apttus__APTS_Template__c();
        templateObj.Name = 'Parcel Contract';
        templateObj.Apttus__Type__c = APT_Constants.TYPE_AGR;
        templateObj.Apttus__Agreement_Types__c = APT_Constants.AGR_TYPE_MSA_SERVICE;
        templateObj.Apttus__Category__c = APT_Constants.CATG_SUBMIT;
        templateObj.Apttus__Subcategory__c = APT_Constants.SUBCATG_DEFAULT;
        templateObj.Apttus__Language__c = APT_Constants.LANG_ENG;
        templateObj.Apttus__Locale__c = APT_Constants.LOCALE_ENG;
        templateObj.Apttus__IsActive__c = true;
        insert templateObj;
        
        test.startTest();
        	APT_CreateContractValidationController acValCon = new APT_CreateContractValidationController();
        	ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
            ApexPages.currentPage().getParameters().put('count','1');
        	acValCon = new APT_CreateContractValidationController();
        	system.assertEquals(acValCon.IsError,false);
        acValCon.generateAPPCContractDocument();
        test.stopTest();

        List<AsyncApexJob> a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob];
        system.assert(a != null);

    }
}