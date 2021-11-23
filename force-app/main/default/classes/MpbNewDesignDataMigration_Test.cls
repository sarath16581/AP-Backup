/**
* @author       : disha.kariya@auspost.com.au
* @date         : 31/05/2017
* @description  : Test Class for MpbNewDesignDataMigration_Schedulable
*/
@isTest
public with sharing class MpbNewDesignDataMigration_Test {
    private static final String ADMIN_PROFILE = 'System Administrator';

    /**
    * @description       This method tests MpbNewDesignDataMigration_Schedulable
    * @param             NA     
    * @return            Void
    * @throws            NA
    */
    private static testMethod void MpbNewDesignDataMigration_Test01(){
        Profile profile = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        List<Asset>assetRecs = new List<Asset>();
        List<Account> lstAccount = new List<Account>();
        List<Product2> prodRecs = new List<Product2>();
        List<Contact> conRecs = new List<Contact>();
       
        System.runAs(TestUtility.createUser('Admin',profile.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> assetRecTypeMap = Schema.Sobjecttype.Asset.getRecordTypeInfosByName();
            
            Account acc = TestUtility.createBusinessAccount('Stark Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            lstAccount.add(acc);
            Database.insert(lstAccount);
            
            Contact con1 = TestUtility.createContact('Test1','MPBNewDesign1','test1@test.om',acc.id);
            Contact con2 = TestUtility.createContact('Test2','MPBNewDesign2','test2@test.om',acc.id);
            Contact con3 = TestUtility.createContact('Test3','MPBNewDesign2','test3@test.om',acc.id);
            conRecs.add(con1);
            conRecs.add(con2);
            conRecs.add(con3);
            Database.insert(conRecs);

            Product2 mpbiz = new Product2 (Name = 'MPBIZ', Family = 'Non Financial');
            Product2 tandc = new Product2 (Name = 'TandC', Family = 'Non Financial', isActive=True);
            prodRecs.add(tandc);
            prodRecs.add(mpbiz);
            Database.insert(prodRecs);
            
            Asset asset1 = new Asset(Name = 'MPBIZ',
                    AccountId = acc.id, 
                    contactId=con1.Id,
                    Product2Id = mpbiz.Id,
                    Status = 'Registered',
                    installDate = Date.newInstance(2016,10,20),
                    RecordTypeId = assetRecTypeMap.get('General').getRecordTypeId());
            Asset asset2 = new Asset(Name = 'MPBIZ',
                    AccountId = acc.id, 
                    contactId=con2.Id,
                    Product2Id = mpbiz.Id,
                    Status = 'Registered',
                    installDate = Date.newInstance(2016,10,24),
                    RecordTypeId = assetRecTypeMap.get('General').getRecordTypeId());
            Asset asset3 = new Asset(Name = 'MPBIZ',
                    AccountId = acc.id, 
                    contactId=con3.Id,
                    Product2Id = mpbiz.Id,
                    Status = 'Registered',
                    RecordTypeId = assetRecTypeMap.get('General').getRecordTypeId());
            Asset asset4 = new Asset(Name = 'MPBIZ',
                    AccountId = acc.id, 
                    Product2Id = mpbiz.Id,
                    Status = 'Registered',
                    RecordTypeId = assetRecTypeMap.get('General').getRecordTypeId());
            
            
            assetRecs.add(asset1);
            assetRecs.add(asset2);
            assetRecs.add(asset3);
            assetRecs.add(asset4);
            
            Database.insert(assetRecs);
            
            Test.startTest(); 

                MpbNewDesignDataCreationTandC_Batchable mpbBatch = new MpbNewDesignDataCreationTandC_Batchable();
                Database.executeBatch(mpbBatch, 200);
                
                MPBUpdateMPBIZforContactId_Batchable mpbBatch1 = new MPBUpdateMPBIZforContactId_Batchable();
                Database.executeBatch(mpbBatch1, 200);
                
            Test.stopTest(); 
        }
    }
    private static testMethod void CMDdataMigration_Test02(){
        Profile profile = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        List<Asset>assetRecs = new List<Asset>();
        List<Account> lstAccount = new List<Account>();
        List<Product2> prodRecs = new List<Product2>();
        List<Contact> conRecs = new List<Contact>();
        
        System.runAs(TestUtility.createUser('Admin',profile.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Map<String,Schema.RecordTypeInfo> assetRecTypeMap = Schema.Sobjecttype.Asset.getRecordTypeInfosByName();
            
            Account acc = TestUtility.createBusinessAccount('Stark Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            lstAccount.add(acc);
            Database.insert(lstAccount);
            
            Contact con1 = TestUtility.createContact('Test1','MPBNewDesign1','test1@test.om',acc.id);
            conRecs.add(con1);
            Database.insert(conRecs);
            
            Product2 b250 = new Product2 (Name = 'B250', Family = 'Non Financial');
            Product2 tandc = new Product2 (Name = 'TandC', Family = 'Non Financial', isActive=True);
            prodRecs.add(tandc);
            prodRecs.add(b250);
            Database.insert(prodRecs);
            
            Asset asset5 = new Asset(Name = 'B250',
                    AccountId = acc.id, 
                    Product2Id = b250.Id,
                    Status = 'Registered',
                    RecordTypeId = assetRecTypeMap.get('General').getRecordTypeId());
            assetRecs.add(asset5);
            
            Database.insert(assetRecs);
            
            Test.startTest();
                CMDdataMigration_Batchable cmdBatch = new CMDdataMigration_Batchable();
                Database.executeBatch(cmdBatch, 20);
            Test.stopTest(); 
        }
    }
    
    private static testMethod void CMDdataMigration_Test03(){
        Profile profile = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Admin',profile.id,null)){
            // Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            // Account acc = TestUtility.createBusinessAccount('Stark Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            // //lstAccount.add(acc);
            // Database.insert(acc);
            
            // Product2 b250 = new Product2 (Name = 'B250', Family = 'Non Financial');
            // Database.insert(b250);
            
            // Asset asset5 = new Asset(Name = 'B250',
                    // AccountId = acc.id, 
                    // Product2Id = b250.Id,
                    // tier_type__c = 'Assigned',
                    // Status = 'Registered');
                    
            //insert asset5;
            
            
            try{
                Account testData = new Account();
                insert(testData);           
            }
            catch(DMLException excp){        
                Test.startTest();
                
                   CMDdataMigration_Batchable cmdBatch = new CMDdataMigration_Batchable();
                   cmdBatch.handleException(excp, UserInfo.getOrganizationId());
                   
                   MPBUpdateMPBIZforContactId_Batchable mpbBatch1 = new MPBUpdateMPBIZforContactId_Batchable();
                   mpbBatch1.handleException(excp, UserInfo.getOrganizationId());
                   
                Test.stopTest();
            }
        }        
    }
}