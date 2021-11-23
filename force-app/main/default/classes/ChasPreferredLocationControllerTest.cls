/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Test class for ChasPreferredLocationController. Class is used for PO transfer request. 
--------------------------------------- History --------------------------------------------------
23.0.62020    arjun.singh@auspost.com.au    Created
 */
@isTest
private class ChasPreferredLocationControllerTest {
    /**
     * @Description Method tests the PO service request and returned po locations data.
     */
    @isTest
     static void chasPORequestServiceTest()
     {  
       createPORequestRecordInSetting();
       Decimal ltStr = -37.80778;
       Decimal lonStr = 144.96095;
       String currentlocation = '{"latitudeStr" :' +ltStr+ ',"longitudeStr" : '+lonStr+ '}' ;
       String currentlocationJson = JSON.serialize(currentlocation);
       

      Test.setMock(HttpCalloutMock.class, new ChasPreferredLocationApiMockGenerator());

      Test.StartTest();
        ChasPreferredLocationController.getNearByPostOfficeAddress('3000', currentlocation);
      Test.StopTest();  
     }
     private static void createPORequestRecordInSetting(){

      Organization org =  [SELECT IsSandbox FROM Organization LIMIT 1];
        
      AusPostSettings__c setting = new AusPostSettings__c();
      setting.Name = 'POTransferRequest';
        if(org.IsSandbox){
          setting.AppKey__c = 'BjLgWKihutuTEJCFgRz12IheyRFV1DQm';
          setting.URL__c = 'https://digitalapi-stest.npe.auspost.com.au/locations/v2/points/postcode/';
        }else{
          setting.AppKey__c = '';
          setting.URL__c = '';
        }
        insert setting;
     }
}