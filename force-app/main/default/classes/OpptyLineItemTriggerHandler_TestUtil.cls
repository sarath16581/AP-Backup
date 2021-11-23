/**************************************************
Type:       Test Data Factory Class - for OpportunityLineItem Object
Purpose:    Provide data factory function for Test Class for the OpportunityLineItem Object Trigger
--------------------------------------------------
August 2, 2018 - Created by daric.antoni.a.dava
**************************************************/
@IsTest
public class OpptyLineItemTriggerHandler_TestUtil {
    
    @testvisible private static User getTestUser(String profile){
        
        Profile p = [SELECT Id FROM Profile WHERE Name = :profile];
        
        User u1 = new User();
        u1.Alias = 'testname';
        u1.Email = 'test@auspost.com.au';
        u1.EmailEncodingKey = 'UTF-8'; 
        u1.FirstName = 'Holding'; 
        u1.LastName = 'User';
        u1.LanguageLocaleKey = 'en_US'; 
        u1.LocaleSidKey = 'en_US'; 
        u1.ProfileId = p.Id; 
        u1.isActive = true;
        u1.TimeZoneSidKey = 'America/Los_Angeles'; 
        u1.UserName = 'auTestX@auspost.com.au.cde';  
        
        return u1;
    }
    
    @testvisible private static Account getTestAccount(Id u1,Id recordTypeId){
        
        Account accVar = new Account();
        accVar.name = 'Test Company'; 
        accVar.recordtypeid = recordTypeId; 
        accVar.type = 'Small Business';  
        accVar.phone = '11111111';
        accVar.email__c = 'test@test.com';
        accVar.abn__c = '12345678901';
        accVar.Website = 'www.google.com';
        accVar.Organisation_Trading_Name__c = 'Trade';
        accVar.BillingCity = 'City';
        accVar.BillingCountry = 'Country';
        accVar.BillingState = 'State';
        accVar.BillingPostalCode = '3006';
        accVar.ShippingCity = 'City';
        accVar.ShippingCountry = 'Country';
        accVar.ShippingState = 'State';
        accVar.ShippingStreet = 'Street';
        accVar.ShippingPostalCode = '3006';
        accVar.OwnerId = u1;
        
        return accVar;
    }
    
    @testvisible private static Product2 getTestProduct(String name, Boolean isException){
        Product2 prodVar1 = new Product2();
        
        prodVar1.Name = name;
        prodVar1.ProductCode = 'EP 1';
        prodVar1.IsActive = TRUE;
        prodVar1.Is_Exception_Product__c = isException;
        
        return prodVar1;
    }
    
    @testvisible private static Product2 getTestProduct(String name,String prodCode, Boolean isException){
        Product2 prodVar1 = new Product2();
        
        prodVar1.Name = name;
        prodVar1.ProductCode = prodCode;
        prodVar1.IsActive = TRUE;
        prodVar1.Is_Exception_Product__c = isException;
        
        return prodVar1;
    }
    
    @testvisible private static Pricebook2 getTestPricebook(String name, Boolean isActive){ 
        Pricebook2 pbVar1 = new Pricebook2();
        pbVar1.Name = name;
        pbVar1.IsActive = isActive;
        
        return pbVar1;
    }
    
    @testvisible private static PricebookEntry getTestPricebookEntry(ID PBID, Id productId, decimal UnitPrice){
        PricebookEntry price = new PricebookEntry();
        price.Pricebook2Id = PBID;
        price.Product2Id = productId;
        price.UnitPrice = UnitPrice;
        price.IsActive = true;
        price.UseStandardPrice = false;
        
        return price;
    }
    
    @testvisible private static Opportunity getTestOpportunity(ID accId){
        Opportunity oppVar = new Opportunity();
        
        oppVar.name = 'test oppty 1'; 
        oppVar.accountid = accId; 
        oppVar.type = 'New Business';
        oppVar.amount = 20000; 
        oppVar.stagename = 'Identify'; 
        oppVar.closedate = System.today();
        oppVar.Contract_Number__c = '99999'; 
        oppVar.Contract_Start_Date__c = Date.newInstance(2012, 07 ,27);
        oppVar.Contract_End_Date__c = Date.newInstance(2012, 07 ,27);
        
        return oppVar;
    }
    
    @testvisible private static OpportunityLineItem getTestOpportunityLineItem(ID oppId, Id pbeID, Id prodID){
        OpportunityLineItem oliVar1 = new OpportunityLineItem();
        
        oliVar1.Description = 'test oli desc 1'; 
        oliVar1.OpportunityID = oppId;
        oliVar1.PricebookEntryId = pbeID;
        oliVar1.Product2Id = prodID;
        oliVar1.Quantity = 1.0;
        oliVar1.Discount = 0;
        oliVar1.UnitPrice = 1;
        oliVar1.Contract_Start_Date__c = Date.newInstance(2012, 07 ,27);
        oliVar1.Contract_End_Date__c = Date.newInstance(2013, 07 ,27); // RSolomon - Updated the end date to pass the VR's criteria where end date should be after the start date
        
        return oliVar1;
    }
}