/**
* @author       : snigdha.sahu@auspost.com.au
* @date         : 24/02/2017
* @description  : Test Class for BSO_TierReconciliation_Schedulable
/*******************************  History ************************************************
*06/02/2017          snigdha.sahu@auspost.com.au   Created
*01/05/2020          disha.kariya@auspost.com.au   Modified to include new bands
*/
@isTest
public class BSO_TierReconciliation_Schedulable_Test {

    @TestSetup
    static void setup(){
        // =====================================
        // Data Preparation
        // =====================================
        AusPostSettings__c oa = new AusPostSettings__c();
        oa.Password__c = 'w@X2mb?SbMi%';
        oa.Username__c = 'sssw_sts';
        oa.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
        oa.URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
        oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
        oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
        oa.Name = 'BSO_TIBCO';
        oa.Number1__c = 2;
        oa.ApplicationName__c = 'postMobile';
        oa.AppKey__c = 'b23a6687-5d9b-456c-9532-dc406662f7b4';
        oa.ServiceName__c = 'QAC';
        oa.TokenDuration__c = '84600';
        insert oa;

        //Insert Products
        List<Product2>prodRecs = new List<Product2>();

        List<Product2> product2List = ApplicationTestDataFactory.getPSRProducts(5,false);

        Database.insert(product2List);

        //Insert accounts
        Integer accNumber = 5;
        List<Asset>assetRecs = new List<Asset>();

//        //Prepare Organisation for testing
        List<Account> lstAccount = ApplicationTestDataFactory.getAccounts(accNumber, false);
        Database.insert(lstAccount);

        //Prepare Assets for testing
        for(Integer i = 0; i < accNumber; i++){
            Asset assetTrans = ApplicationTestDataFactory.getPSRTransactionalAssets(1, lstAccount[i].Id, product2List[0].Id, false,'Inactive', false)[0];
            Asset assetAssigned = ApplicationTestDataFactory.getPSRAssignedAssets(1, lstAccount[i].Id, product2List[0].Id, true, Date.today(), Date.today().addDays(14), 'Active', false)[0];
            assetRecs.add(assetAssigned);
            assetRecs.add(assetTrans);
        }

        Database.insert(assetRecs);
    }

    /**
    * @description       This method tests BSOTierReconciliation_Schedulable
    * @param             NA     
    * @return            Void
    * @throws            NA
    */
    private static testMethod void testMethodForBatchClassIntegration(){
        List<Asset> assetRecsUpdate = [SELECT Id, Name, Status, Tier_Type__c, AccountId, Product2Id FROM Asset order by Tier_Type__c];
        List<Product2> product2List = [SELECT Id, Name FROM Product2];
        Map<String, Product2> product2Map = new Map<String, Product2>();
        Map<Id, List<Asset>> accountAssetMap = new Map<Id, List<Asset>>();
        List<Asset> assetToUpdate = new List<Asset>();
        for(Product2 prod : product2List){
            product2Map.put(prod.Name, prod);
        }
        List<Account> lstAccount = [SELECT Id, Name FROM Account ORDER BY Id];

        //Create a map of account and assets
        for(Asset asset:assetRecsUpdate){
            if(!accountAssetMap.containsKey(asset.AccountId)){
                accountAssetMap.put(asset.AccountId, new List<Asset>());
            }
            accountAssetMap.get(asset.AccountId).add(asset);
        }
        //Change the active assigned Band to higher Band
        accountAssetMap.get(lstAccount[0].Id)[0].Product2Id = product2Map.get('Band2').Id;
        assetToUpdate.add(accountAssetMap.get(lstAccount[0].Id)[0]);

        //Change the transactional Band to higher band
        accountAssetMap.get(lstAccount[1].Id)[1].Product2Id = product2Map.get('Band2').Id;
        assetToUpdate.add(accountAssetMap.get(lstAccount[1].Id)[1]);

        //Change the transactional Band to higher band
        accountAssetMap.get(lstAccount[2].Id)[1].Product2Id = product2Map.get('Band2').Id;
        assetToUpdate.add(accountAssetMap.get(lstAccount[2].Id)[1]);

        //Change Freeze Period end Date
        accountAssetMap.get(lstAccount[3].Id)[0].Freeze_Period_End_Date__c = System.today().addDays(10);
        assetToUpdate.add(accountAssetMap.get(lstAccount[3].Id)[0]);
        Profile profile = [SELECT Id,Name FROM profile where Name = 'AusPost Integration' LIMIT 1];
        System.runAs(TestUtility.createUser('Test',profile.id,null)) {
            Database.update(assetToUpdate);
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BSOtoTibcoIntegration());
        BSOTierReconciliation_Batchable bsoBatch = new BSOTierReconciliation_Batchable();
        Database.executeBatch(bsoBatch, 50);

        Test.stopTest();

        //Get updated values after batch run
        assetRecsUpdate = [SELECT Id, Name, Status, Tier_Type__c, Product2Id, AccountId, Product2.Name, To_Be_Processed__c FROM Asset ORDER BY Tier_Type__c];
        accountAssetMap = new Map<Id, List<Asset>>();
        //Create a map of account and assets
        for(Asset asset:assetRecsUpdate){
            if(!accountAssetMap.containsKey(asset.AccountId)){
                accountAssetMap.put(asset.AccountId, new List<Asset>());
            }
            accountAssetMap.get(asset.AccountId).add(asset);
        }
        Active_Band_History__c abh = [SELECT Id, Organisation__c, Freeze_End_Date__c FROM Active_Band_History__c WHERE Organisation__c =:lstAccount[3].Id ORDER BY CreatedDate LIMIT 1];

        System.assertEquals('Active', accountAssetMap.get(lstAccount[0].Id)[0].Status, 'Assigned not active');
        System.assertEquals('Active', accountAssetMap.get(lstAccount[1].Id)[1].Status, 'Transactional not active');
        System.assertEquals(System.today().addDays(10), abh.Freeze_End_Date__c, 'Active Band History not updated with new end date');
        System.assertEquals(False, accountAssetMap.get(lstAccount[0].Id)[0].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[0].Id)[1].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[1].Id)[0].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[1].Id)[1].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[2].Id)[0].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[2].Id)[1].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[3].Id)[0].To_Be_Processed__c, 'To be processed is True');
        System.assertEquals(False, accountAssetMap.get(lstAccount[3].Id)[1].To_Be_Processed__c, 'To be processed is True');
    }
    public class BSOtoTibcoIntegration implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"foo":"bar"}');
            return res;
        }
    }
    private static testMethod void testMethodForSchedulableClassIntegration(){

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new BSOtoTibcoIntegration());
            BSOTierReconciliation_Schedulable bsosc = new BSOTierReconciliation_Schedulable();
            String sch = '0 5 23 * * ?';

            //run the scheduled job
            String jobID = System.schedule('Scheduled Job', sch, bsosc);
        Test.stopTest();
        System.assertNotEquals(jobID ,null, 'Job Id is null');
//    }
    }

    private static testMethod void testMethodForExceptionIntegration(){
        try{
            Account testData = new Account();
            insert(testData);
        }catch(DMLException excp){
            Test.startTest();
            List<Asset> assetList = [SELECT Id, name FROM Asset];
            SendProductDetailstoCOM cmdBatch = new SendProductDetailstoCOM(assetList);
            cmdBatch.handleException(excp, UserInfo.getOrganizationId());
            Test.stopTest();
        }
    }
}