/**
Description - This apex class is test class for apex class - APT_DeleteLegacyIntDigitalBundleCnt
Created By - Raviteja Gona
Created Date - 21 Aug, 2017
Last Modified By -
Last Modified Date - 
**/
@isTest
private class APT_DeleteLegacyIntDigitalBundleCnt_Test{
 
private static testMethod void method1(){
             
             
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER, Work_Center_Code__c = 'test');
            System.runAs(testuser) {    
             //Create Account
                 Account acc = APT_TestUtils.createOrganisation();
                 insert acc;
                 
                 //Create Opportunity
                 Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
                 insert opty;
                 
                 //Create PriceList
                 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
                 insert priceList;
                 
                 //create international product
                 Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle',
                                                                             'InternationalBundle','Parcel Services');
                 insert bundle1;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Ready For Finalization',
                 null, Datetime.now(), true);
                 insert prodconfig;
                 
                 // Create LineItem
                 Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                    1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

                    try{
ApexPages.currentPage().getParameters().put(APT_Constants.CONFIGID,null);
ApexPages.currentPage().getParameters().put(APT_Constants.BUNDLELINENO,'1');
ApexPages.currentPage().getParameters().put(APT_Constants.PROPOSALID,Proposal.Id);


                    
Test.startTest();
APT_DeleteLegacyIntDigitalBundleCnt DeleteonRenew = new APT_DeleteLegacyIntDigitalBundleCnt();
            DeleteonRenew.doRenewDelete();
 PageReference pgRef = DeleteonRenew.doRenewDelete();
            
Test.stopTest();

}catch(System.Exception ex) {

}
 
 }
} 


//Added By viraj : CAS-03902-S9G3R8
private static testMethod void method2(){
             
             
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER, Work_Center_Code__c = 'test');
            System.runAs(testuser) {    
             //Create Account
                 Account acc = APT_TestUtils.createOrganisation();
                 insert acc;
                 
                 //Create Opportunity
                 Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
                 insert opty;
                 
                 //Create PriceList
                 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
                 insert priceList;
                 
                 //create international product
                 Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle',
                                                                             'InternationalBundle','Parcel Services');
                 insert bundle1;
                 
                 //Create Price list Item
                 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
                 insert pli;
                 
                 //Create Proposal
                 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
                 insert Proposal;
                 
                 //Create Product Configuration             
                 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                 proposal.Id, 'Proposal',
                 'Ad Hoc',priceList.Id, null,
                 'Ready For Finalization',
                 null, Datetime.now(), true);
                 insert prodconfig;
                 
                 // Create LineItem
                 Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                    1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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

                    try{
ApexPages.currentPage().getParameters().put(APT_Constants.CONFIGID,prodconfig.Id);
ApexPages.currentPage().getParameters().put(APT_Constants.BUNDLELINENO,'1');
ApexPages.currentPage().getParameters().put(APT_Constants.PROPOSALID,Proposal.Id);


                    
Test.startTest();
APT_DeleteLegacyIntDigitalBundleCnt DeleteonRenew = new APT_DeleteLegacyIntDigitalBundleCnt();
DeleteonRenew.haserrorMessages = false;
            DeleteonRenew.doRenewDelete();
 PageReference pgRef = DeleteonRenew.doRenewDelete();
            
Test.stopTest();

}catch(System.Exception ex) {

}
 
 }
} 
}