/***
 * @author Nasir Jawed
 * @date 2022-05-20
 * @group 
 * @description Tests the execution of the CompassWrapper 
 * @changelog
 * 
*/

@IsTest
public with sharing class CompassWrapper_Test {
    
    @IsTest
    public static void CompassWrapperData() {

        
        CompassWrapper.CompassPriceWrapper cpw= new CompassWrapper.CompassPriceWrapper();
        cpw.quoteId = 'PDA-COMPASS-0000000103';
        cpw.customerId = '4604376';
        cpw.customerType = 'SalesForce Billing Account Number';
        cpw.dsrId = '09876';
        cpw.priceStructure = 'Z006';
        cpw.customerTier = 'T05';
        cpw.ratingplanDwtconvfac = 'test';
        cpw.weightRounding = 'Y';
        cpw.cubicConvfac = 250.00;
        cpw.cubingFlag = 'Y';
        cpw.ratingModel = 'PD';
        cpw.ratingGroup = 'PARCEL';
        cpw.subsequentDiscount = '1.36';
        cpw.subsequentDiscountPriceType = 'AUD';
        cpw.ratecardDwtconvfac = 'te';
        
        
        CompassWrapper.ratecardItem rateCardAttribute = new CompassWrapper.ratecardItem();
        rateCardAttribute.lodgementZone = 'ME';
        rateCardAttribute.customerTier= 'T05';
        rateCardAttribute.customRef = '0000000103';
        rateCardAttribute.ratingcardCategory = 'SP00';
        rateCardAttribute.priceStructure = 'Z006';
        
        CompassWrapper.serviceSpeeds serviceAttribute = new CompassWrapper.serviceSpeeds();
        serviceAttribute.pricePoint = 'MESSCOM';
        serviceAttribute.priceFactor = 'KRSP00S006ME';
        serviceAttribute.weightBreak = '0.5';
        serviceAttribute.weightBreakDesc = 'Up to 500g';
        serviceAttribute.basicRate = 9.14;
        serviceAttribute.kgRate = 1.68;
        serviceAttribute.priceType= 'AUD';
        
        CompassWrapper.features featuresAttribute = new CompassWrapper.features();
        featuresAttribute.pricePoint = 'TCOVER-1';
        featuresAttribute.priceFactor = 'FE000';
        featuresAttribute.name = 'Transit Cover - Requested';
        featuresAttribute.totDeclaredCover = '0';
        featuresAttribute.price = 0.85;
        featuresAttribute.minValue = '50';
        featuresAttribute.maxValue = '5000';
        featuresAttribute.pricetype = 'ART';
        
        CompassWrapper.returns returnsAttribute = new CompassWrapper.returns();
        returnsAttribute.pricePoint = 'TCOVER-1';
        returnsAttribute.priceFactor = 'FE000';
        returnsAttribute.name = 'Returns Flat Rate-Standard';        
        returnsAttribute.price = 0.85;        
        returnsAttribute.priceType = 'ART';
        
        CompassWrapper.surcharges surchargesAttribute = new CompassWrapper.surcharges();
        surchargesAttribute.pricePoint = 'UNM';
        surchargesAttribute.priceFactor = 'SU000';
        surchargesAttribute.name = 'Unmanifested Article';        
        surchargesAttribute.price = 0.85;        
        surchargesAttribute.priceType = 'ART';
        
        
        

    }
}