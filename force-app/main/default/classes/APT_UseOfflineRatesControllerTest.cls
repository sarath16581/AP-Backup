/**
 * @author Naveen Rajanna
 * @date 2021-07-07
 * @description This apex class is test class for apex class - APT_UseOfflineRatesController
 * @changelog
 * 2021-07-07 - Naveen Rajanna - Created
*/
@isTest
private class APT_UseOfflineRatesControllerTest {
    
    @testSetup static void setup() {
 		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(
            Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, 
            LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER
        );

        System.runAs(testuser) {
            //Create Organisation
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.type = 'New Customer';
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
            bundle1.Non_contracted__c = false;
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
        }
	}
    
    static testMethod void testSaveMethod() {
        User testuser = [SELECT Id FROM User WHERE UserName= :APT_Constants.EMAIL_TEST_USER];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
        Apttus_Config2__PriceList__c priceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
        Apttus_Config2__PriceListItem__c pli = [SELECT Id FROM Apttus_Config2__PriceListItem__c LIMIT 1];
        
        System.runAs(testuser) {
            Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert proposal;            
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            insert prodconfig;            
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                        1, 'Product/Service', null, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                        'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
                                                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                                                        bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
                                                        bundleLine.Apttus_Config2__NetPrice__c = 5225;
                                                        bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                                                        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine;
            
            Test.startTest();
                String configId = prodconfig.Id;
                Map<String, String> outputMap = APT_UseOfflineRatesController.save(configId, proposal);
                System.assertEquals('success', outputMap.get('result'));
            Test.stopTest();
        }
    }

    static testMethod void testSaveMethod_Failure1() {
        User testuser = [SELECT Id FROM User WHERE UserName= :APT_Constants.EMAIL_TEST_USER];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
        Apttus_Config2__PriceList__c priceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
        Apttus_Config2__PriceListItem__c pli = [SELECT Id FROM Apttus_Config2__PriceListItem__c LIMIT 1];
        
        System.runAs(testuser) {
            Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert proposal;

            Test.startTest();
                try {
                    Map<String, String> outputMap2 = APT_UseOfflineRatesController.save('InvalidConfigId', proposal);
                }
                catch(Exception ex) {}
            Test.stopTest();
        }
    }

    static testMethod void testSaveMethod_Failure2() {
        Test.startTest();
            Map<String, String> outputMap = APT_UseOfflineRatesController.save(null, null);
            System.assertEquals('error', outputMap.get('result'));
        Test.stopTest();
    }

    static testMethod void testSaveMethod_Failure3() {
        User testuser = [SELECT Id FROM User WHERE UserName= :APT_Constants.EMAIL_TEST_USER];        
        System.runAs(testuser) {
            Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
            insert proposal;
            String configId = proposal.Id;
            Test.startTest();
                try {
                    Map<String, String> outputMap = APT_UseOfflineRatesController.save(configId, proposal);
                }
                catch(Exception ex) {}
            Test.stopTest();
        }
    }
}