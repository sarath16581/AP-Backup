/******************************************************************************************
    
    Author:         Lyndon Lavapie
    Date Created:   03/10/2016
    Description:    Handler for AgreementDocumentTriggerHandler
    
    Change Log:
    Date:          Author:                  Description:
    03/10/2016     Lyndon Lavapie			Created
    04/10/2019     disha.kariya@auspost.com.au  Added test method for new Update Method in handler
    03/06/2022     Talib Raza               REQ2801136: Test method changed to verify Assignment_Effective_To_Date__c to 4 years
    
*******************************************************************************************/
@isTest
private class AgreementDocumentTriggerHandler_Test {
    private static final Id ORGANISATION_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
    private static final Id FACILITY_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();
    private static final Id FACILITY_CMA_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility CMA').getRecordTypeId();
    private static final Id LICENCE_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Licence').getRecordTypeId();
    private static final Id LICENCE_CMA_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Licence CMA').getRecordTypeId();

    @testSetup
    private static void setup(){

        List<ACCOUNT_LICENCE_RECORDTYPES__c> las4 = new List<ACCOUNT_LICENCE_RECORDTYPES__c>();
        las4.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence'));
        las4.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence CMA', Renewable__c=true, Renew_document_type__c='CMA Agreement - Renewal'));
        insert las4;

        Network__c parentNetwork;
        List<Account> listLicences = new List<Account>();
        List<Account> listFacilities = new List<Account>();
        List<Network__c> listNetworks = new List<Network__c>();

        // Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_Vic__c = 'test@test.com',
                Email_List_NSW__c = 'test@test.com',
                First_Reminder_Days__c = 63,
                Second_Reminder_Days__c = 25,
                Third_Reminder_Days__c = 7,
                Level_3_Approval_Amount__c = 10000
        );

        insert setting;

        Account parentAccount = new Account(
                name = 'Test0',
                phone = '123',
                RecordTypeId = ORGANISATION_RECORD_TYPE
        );

        insert parentAccount;

        parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c='Vic');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        listNetworks.add(network);

        Network__c networkCMA = new Network__c(Org_ID__c = '4342', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'CMA');
        listNetworks.add(networkCMA);
        insert listNetworks;

        Account facilityAcc = new Account(
                name='test1',
                phone='123',
                recordtypeid=FACILITY_RECORD_TYPE,
                Is_a_facility__c = true,
                Network_Facility__c = network.id,
                Licence_Type__c = 'LPO',
                Subjected_To_GST__c = false   );
        listFacilities.add(facilityAcc);

        Account facilityCMA = new Account(
                name='test1',
                phone='123',
                recordtypeid=FACILITY_CMA_RECORD_TYPE,
                Is_a_facility__c = true,
                Network_Facility__c = networkCMA.id,
                Licence_Type__c = 'CMA',
                Subjected_To_GST__c = false   );
        listFacilities.add(facilityCMA);
        insert listFacilities;
        // Add a licence to this facility
        Account licenceAcc = new Account(
                name='test2',
                phone='124',
                recordtypeid=LICENCE_RECORD_TYPE,
                Facility__c =facilityAcc.id,
                Licence_Status__c= 'Draft',
                ParentId = parentAccount.id );
        listLicences.add(licenceAcc);

        Account licenceCMA = new Account(
                name='test2',
                phone='124',
                recordtypeid=LICENCE_CMA_RECORD_TYPE,
                Facility__c =facilityCMA.id,
                Licence_Status__c= 'Draft',
                Assignment_Effective_From_Date__c = System.Today().addYears(-3),
                ParentId = parentAccount.id );
        listLicences.add(licenceCMA);
        insert listLicences;
    }
  
    private static testMethod void testAgreementDocumentDelete() {
        
        Account licence = [SELECT id from Account where recordtype.Id = :LICENCE_RECORD_TYPE limit 1];
        Test.startTest();
        	Agreement_Document__c agreementDocument = new Agreement_Document__c(Licence__c=licence.Id, 
                                                                                Approval_Type__c='No', 
                                                                                Status__c='Active', 
                                                                                Agreement_Effective_From_Date__c=Date.today());
            insert agreementDocument;
            Boolean isDeleted = true;
        try{
            delete agreementDocument;
        } catch (DmlException de) {
           	isDeleted = false;
        }
        List<Agreement_Document__c> agreementDocuments = New List<Agreement_Document__c>([Select Id From Agreement_Document__c]);
        System.assertNotEquals(0, agreementDocuments.size());
        System.assertEquals(false, isDeleted);
        Test.stopTest();
    }

    private static testMethod void testAgreementDocumentUpdate() {
        //Get CMA Licence
        Account licence = [SELECT id, Assignment_Effective_To_Date__c from account where recordtype.id=:LICENCE_CMA_RECORD_TYPE limit 1];
        //Insert Conga Template for Renewal
        APXTConga4__Conga_Template__c congaTemplate = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'CMA Agreement - Renewal', Licence_Type__c='CMA');
        Insert congaTemplate;
        Test.startTest();
            Agreement_Document__c agreementDocument = new Agreement_Document__c(Licence__c=licence.Id,
                    Approval_Type__c='No',
                    Licence_Type__c = 'CMA',
                    Status__c='Draft',
                    Document_ID__c = congaTemplate.Id,
                    Agreement_Effective_From_Date__c=Date.today());
            insert agreementDocument;

            agreementDocument.Status__c = 'Active';

            Update agreementDocument;
            Account licenceUpdated = [SELECT id,Assignment_Effective_To_Date__c from account where id=:agreementDocument.Licence__c limit 1];
        //Verify if Assignment Effective From has been updated to be after 4 (Previously was 3 three) years
        System.assertEquals(System.Today().addYears(4), licenceUpdated.Assignment_Effective_To_Date__c);
        Test.stopTest();

    }
}