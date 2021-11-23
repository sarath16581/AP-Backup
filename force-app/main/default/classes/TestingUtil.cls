/**************************************************
Type:       Utility Class for Testing
Purpose:    Provide methods that create test data.

Used By:    
History:
--------------------------------------------------
22-Sep-2009  Annie Sampson (Salesforce.com)     Migrated into Production
21-Feb-2013  Manu Erwin (Salesforce.com)        Phase 3 ECLM - added methods to construct and return (insert handled by calling test method due to governor limits)
                                                Accounts, Opportunities, and OpportunityLineItems
09-July-2015 Nandan N                            updated stage value to Identify at line 33
**************************************************/
public with sharing class TestingUtil {
  public String opId;
  public String scsId;
  public String scsecId;
  public String scsecItemId;
  public String actId;

  public TestingUtil(){
    opId = makeTestableOp();
    scsId = makeSalesCoachStage();
    scsecId = makeSalesCoachSections();
    scsecItemId = makeSecItem();
    actId = makeActivities();
    ApexPages.currentPage().getParameters().put('id', this.opId);
  }

  private String makeTestableOp(){
    Opportunity op = new Opportunity();
    op.Name='testOpName';
    op.CloseDate = Date.today();
    op.StageName='Identify';    // 09/07 - Added for test class failure
    insert op;
    return op.Id;
  }
  
  private String makeSalesCoachStage(){
    Sales_Coach_Stage__c scs = new Sales_Coach_Stage__c();
    scs.Name='testStage';
    scs.Buyer_Stage__c='testBuyStage';
    scs.Active__c=true;
    insert scs;
    return scs.Id;
  }
  
  private String makeSalesCoachSections(){
    Sales_Coach_Section__c scsec =  new Sales_Coach_Section__c();
    scsec.Section_Ordering__c =1.0;
    scsec.Section_Name__c='testSection';
    scsec.Sales_Coach_Stage__c=scsId;
    scsec.Section_Width__c=33.0;
    insert scsec;
    return scsec.Id;
  }
  
 private String makeSecItem(){
    Sales_Coach_Section_Item__c secItem = new Sales_Coach_Section_Item__c();
    secItem.Section_Ordering__c=1.0;
    secItem.Sales_Coach_Section__c=scsecId;
    secItem.Link_to_Content__c='http://www.google.com';
    secItem.Item_Name__c='testItem';
    secItem.Display__c=true;
    secItem.Products__c='';
    insert secItem;
    return secItem.Id;
 }
 
 private String makeActivities(){
  Sales_Coach_Activity__c sca = new Sales_Coach_Activity__c();
  sca.Sales_Coach_Stage__c=scsId;
  sca.Ordering_Number__c=1.0;
  sca.Activity_Details__c='testActivity';
  insert sca;
  return sca.Id;
 }

    /* PUBLIC DATA CONSTRUCTIONS */
    public static RecordType orgRecType = [SELECT Id FROM RecordType 
                                        WHERE IsActive = true
                                        AND SobjectType = 'Account'
                                        AND Name = 'Organisation' limit 1];

    public static Account accountOrg(String accName) {
        Account accOrg = new Account (
            Name = accName,
            RecordTypeId = orgRecType.Id,
            Phone = '11111111',
            Email__c = 'test@test.com',
            ABN__c = '12345678901',
            Website = 'www.google.com',
            Organisation_Trading_Name__c = 'Trade',
            BillingCity = 'City',
            BillingCountry = 'Country',
            BillingState = 'State',
            BillingPostalCode = '12345',
            ShippingCity = 'City',
            ShippingCountry = 'Country',
            ShippingState = 'State',
            ShippingStreet = 'Street',
            ShippingPostalCode = '12345'          
        );
        return accOrg;
    }
    public static Opportunity opportunity(Id accId, String opptyName) {
        Opportunity oppty = new Opportunity(
            Name = opptyName, 
            StageName  =  'Identify',
            Contract_Number__c = 'CN12345', 
            CloseDate  =  date.today(),
            Closed_Reason__c = 'Reason',
            Probability = 3,
            ECLM_RenewalCreated__c = false,
            ECLM_Contract_Status__c = 'Published',
            Contract_Start_Date__c = date.today() - 100,
            Contract_End_Date__c = date.today() + 100,
            Type = 'New Customer',
            AccountId = accId
        );
        return oppty;
    }
    public static Product2 product(String productName, String productCode) {
        Product2 prod = new Product2(
            Name = productName,
            IsActive = true,
            ProductCode = productCode
        );
        return prod;
    }
    public static PricebookEntry priceBookEntry(Id priceBookId, Id productId) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = priceBookId,
            Product2Id = productId, 
            IsActive = true,
            UnitPrice = 1000,
            UseStandardPrice = false
        );
        return pbe;
    }
    public static OpportunityLineItem opptyLine(Id opptyId, Id priceBookEntryId) {
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opptyId,
            PriceBookEntryId = priceBookEntryId,
            Quantity = 100,
            TotalPrice = 1000,
            Classification__c = 'New Business',
            Contract_Start_Date__c = date.today() - 100,
            Contract_End_Date__c = date.today() + 100,
            Contract_Number__c = '99999'
        );
        return oli;
    }
}