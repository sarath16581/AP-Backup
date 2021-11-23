/**************************************************
Type:       Utility Class for Billing Account Staging object
Purpose:    After a Billing Account is loaded into the staging object,
            check if record exists in Billing Account. If yes, obtain 
            FK value to Account, otherwise set to 'Temporary Customer'.
            Move data across from staging to Billing Account and then
            delete record in staging.
Used By:    BillingAccountStagingTrigger
History:
--------------------------------------------------
14.10.2011    Richard Enojas(Salesforce.com)    Created
**************************************************/
public class BillingAccountStagingUtil {
    public static void moveBillingAccounts(List<Id> stgBAforTransfer, List<String> BALegacyIds){
        
        //list of staging records
        List<Billing_Account_Staging__c> stgBAlist = [SELECT Id, Name, LEGACY_ID__c, Customer_Name_2__c, ABN__c, ACN__c,
                                                            Suburb__c, State__c, Country__c, Postal_Code__c, Search_Term__c,
                                                            Fax_Number__c, Phone_Number__c, Credit_Person__c, Credit_Person_Code__c 
                                                        FROM Billing_Account_Staging__c
                                                        WHERE Id in : stgBAForTransfer];
        
        //list of Billing Accounts that are existing; corresponds to an update
        List<Billing_Account__c> existingBAlist = [SELECT Id, Legacy_Id__c, Organisation__c 
                                                    FROM Billing_Account__c
                                                    WHERE Legacy_Id__c in : BALegacyIds];
        
        Account temp = [SELECT Id FROM Account WHERE Legacy_Id__c='60000000' limit 1];
        Map<String, Billing_Account__c> existingBAmap = new Map<String, Billing_Account__c>();
        
        List<Billing_Account__c> BAsToUpsert = new List<Billing_Account__c>();
        List<Billing_Account_Staging__c> stgBAsToDelete = new List<Billing_Account_Staging__c>();
        List<Id> idsToPurge = new List<Id>();
        
        //define BA map
        for (Billing_Account__c BA : existingBAlist) {
            existingBAmap.put(BA.Legacy_Id__c,BA);
        }
        
        //generate BA upsert list
        for (Billing_Account_Staging__c BAS : stgBAlist){
            system.debug(BAS.legacy_id__c);
            String UpdatedId = BAS.legacy_id__c.replaceFirst('^0+(?!$)', '');
            system.debug(UpdatedId);
         
            Billing_Account__c BA = new Billing_Account__c (name=BAS.Name, legacy_id__c=UpdatedId, customer_name_2__c=BAS.Customer_Name_2__c,
                                                                abn__c=BAS.ABN__c, acn__c=BAS.ACN__c, suburb__c=BAS.Suburb__c, state__c=BAS.State__c,
                                                                country__c=BAS.Country__c, postal_code__c=BAS.Postal_Code__c, search_term__c = BAS.Search_Term__c,
                                                                credit_person__c=BAS.credit_person__c, credit_person_code__c=BAS.credit_person_code__c,
                                                                phone_number__c=BAS.phone_number__c, fax_number__c=BAS.fax_number__c);
            if (existingBAmap.containsKey(UpdatedId))
                BA.organisation__c=existingBAmap.get(UpdatedId).Organisation__c;
            else
                BA.organisation__c=temp.Id;
            
            BAsToUpsert.add(BA);
            stgBAsToDelete.add(BAS);
            idsToPurge.add(BAS.id);
        }
        
        
        try{
            upsert BAsToUpsert Legacy_Id__c; 
        }catch (DmlException e) {
            System.debug(e.getMessage());
        }
        
        delete stgBAsToDelete;
        Database.emptyRecycleBin(idsToPurge);
    }        
    @isTest(seeAllData=true)
    private static void testBAUpsert(){
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
         
        //Account tmp = new Account(name='test account', recordtypeid=rectype.Id, phone='11111111', email__c='test@test.com', Legacy_Id__c='Temporary Customer');
        //insert tempacct;
        Account temp = [SELECT Id FROM Account WHERE Legacy_Id__c='60000000' limit 1];
        
        Account acct = new Account(
            name='temp', recordtypeid=rectype.Id, type='Small Business',  
            phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com',
            Organisation_Trading_Name__c='Trade',
            BillingCity='City',
            BillingCountry='Country',
            BillingState='State',
            BillingPostalCode='12345',
            ShippingCity='City',
            ShippingCountry='Country',
            ShippingState='State',
            ShippingStreet='Street',
            ShippingPostalCode='12345');
        insert acct;
        
        //create account
        //Account acct = new Account(name='test account', recordtypeid=rectype.Id, phone='11111111', email__c='test@test.com');
        //insert acct;
        
        //create billing account
        Billing_Account__c ba = new Billing_Account__c(name='test1', legacy_id__c='test1', 
                                                    customer_name_2__c='test acct', organisation__c=acct.id);
        insert ba;
        
        //create billing account staging
        Billing_Account_Staging__c bas1 = new Billing_Account_Staging__c(name='test2', legacy_id__c='test2', 
                                                                    customer_name_2__c='test account');
        insert bas1;
        
        Billing_Account_Staging__c bas2 = new Billing_Account_Staging__c(name='test1', legacy_id__c='test1', 
                                                                    customer_name_2__c='test account');
        insert bas2;
        
        test.startTest();
        
        //assert
        //system.assertEquals(temp.id, [select organisation__c from Billing_Account__c where legacy_id__c='test2' limit 1].organisation__c);
        system.assertEquals('test account', [select customer_name_2__c from Billing_Account__c where legacy_id__c='test1' limit 1].customer_name_2__c);
        
        test.stopTest();
    }
}