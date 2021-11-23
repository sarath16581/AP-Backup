/**************************************************
Description: This class contains unit tests for validating PUD Create Booking via MPB Interface

History:
2019-11-11  	dheeraj.mandavilli@auspost.com.au			Created.
2020-03-18		dheeraj.mandavilli@auspost.com.au           Included ArticleCount field
2021-10-15 - Ranjeewa Silva - Added test cases for populating additional address data returned by AME.
*************************************/
@isTest
global class ResourcePudCreateBookingV1_Test {
    @testSetup
    public static void setup() {
        
        //Create Organisation
        Account acc =TestUtility.createBusinessAccount('Test Org','01290000000VkR9AAK');
        insert acc;
        acc.LEGACY_ID__c='60000000';
        update acc;
        Id accid=acc.id;
        system.debug('acc id:::'+accid);     
        
        //Create Billing Account
        Billing_Account__c testBillingAcc = TestUtility.createBillingAccount('Test Billing', accid);
        testBillingAcc.LEGACY_ID__c = '213123123';
        insert(testBillingAcc);
        
        //Create Network   
        Network__c network = TestDataProvider.createTestNetwork();    
        network.Name = 'Test Network';
        network.Org_ID__c = '445763';
        network.RecordTypeId='012900000015fu4AAA';
        Database.insert(network);           
  
    }
    
    
    public static testMethod void testBookingCreate1() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        

        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
            
        Test.startTest();
        
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"000213123123","customerId":"'+accId+'","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6","addressLine2":"436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"'+OrgId+'","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';       RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();

        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
          
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(201, response.getResponseCode());      
        
        Test.stopTest();
        
      
    }
    
    public static testMethod void testBookingCreate2() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        Test.startTest();
        
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"213123123","customerId":"'+accId+'","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6 436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"'+OrgId+'","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';       RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();
        
       
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(201, response.getResponseCode());      
        
        Test.stopTest();
            
    }
    
    public static testMethod void testBookingCreatenegativeTest1() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        Test.startTest();
        //Updated Billing account in JSON with a number that doesnt exist
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"21312312","customerId":"'+accId+'","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6 436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"'+OrgId+'","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';             RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(500, response.getResponseCode());      
        
        Test.stopTest();
    }
    
    public static testMethod void testBookingCreatenegativeTest2() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        Test.startTest();
        //Updated Billing account in JSON with a number that doesnt exist
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"213123123","customerId":"0010w000007k52iAAA","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6 436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"'+OrgId+'","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';       RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(500, response.getResponseCode());      
        
        Test.stopTest();
    }
    
    public static testMethod void testBookingCreatenegativeTest3() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        Test.startTest();
        //Updated Billing account in JSON with a number that doesnt exist
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"213123123","customerId":"'+accId+'","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6 436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"445764","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';       RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(500, response.getResponseCode());      
        
        Test.stopTest();
    }
    
    public static testMethod void testBookingCreatenegativeTest4() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        Test.startTest();
        //Updated Billing account in JSON with a number that doesnt exist
        String payload = '{"requestor":{"sourceSystem":"MPB"},"booking":{"customerNumber":"60000000","billingAccountNumber":"","customerId":"'+accId+'","locationName":"Happy Hats Kew1","dateVal":"2019-11-12","startTime":"08:00:00","endTime":"17:00:00","contactPhone":"0444444443","contactName":"Nick Jonas Sr","contactEmail":"piggy5@example.com","addressLine1":"L 6 436 ST KILDA RD","city":"Melbourne","postCode":"3004","state":"VIC","bookingComments":"Some instructions on delivery driver 4..","depot":"'+orgid+'","revenueCheck":true,"articleCount":"4","articles":[{"articleId":"99702060490201004562503","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060484701004562507","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060478701004562506","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"},{"articleId":"99702060465401004562501","length":"30","width":"22","height":"22","weight":"14","internationalOrDomestic":"DOMESTIC","destinationPostCode":"4101"}]}}';       RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        
        ResourcePudCreateBookingV1 handle = new ResourcePudCreateBookingV1();
        ResourceAPIService.IResourceResponse response = handle.post();
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse2());
        
        // 201 will be sent back because the 500 is handled in the async response
        System.assertEquals(500, response.getResponseCode());      
        
        Test.stopTest();
    }
    
    public static testMethod void testAddressValidateTest1() {
        
        Id accId;
        Account Acc=[Select Id from Account where Legacy_Id__c='60000000' LIMIT 1];
        accId=Acc.Id;
        system.debug('Account Id:::'+accId);
        
        Network__c nwk = [Select Id,Org_ID__c from Network__c where Org_ID__c='445763' LIMIT 1];
        String OrgId = nwk.Org_ID__c;
        system.debug('Network Id:::'+OrgId);
        
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
        
        Pickup_Booking_Settings__c setting1 = new Pickup_Booking_Settings__c(); 
        setting1.Job_Offset_Days__c= 6;
        insert setting1;
        
        
        //Create Test Data
        Map<String, Id> recordIdMap = new Map<String,Id>();
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        
        //Create a Booking for customer booking location
        PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
        insert booking;
        
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new PUD_MPBtoSFIntMockResponse());
        List<AMEInitialResponse.Address> addressList = ResourcePudCreateBookingV1.getDPIDFromAME('55 Collins',booking.id);
        
        
        Test.stopTest();
    }

    @IsTest
    static void testGetGeoCoordinates_NoFrontageGeoDataAvailable() {

        // =====================================
        // Data Preparation
        // =====================================

        Network__c network = [Select Id from Network__c];
        Account customer = [Select Id from Account];

        PUD_Booking_Location__c pudBookingLocation = PUDTestUtility.createBookingLocation('Customer Location', customer.Id, null);
        insert(pudBookingLocation);

        PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', pudBookingLocation.Id, customer.Id, null, network.Id, null);
        insert(booking);

        AusPostSettings__c setting = new AusPostSettings__c();
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'token';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/';
        insert setting;

        // =====================================
        // Stubbing
        // =====================================
        Test.setMock(HttpCalloutMock.class, new AMEHttpMock());

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        ResourcePudCreateBookingV1.getGeocoridinates('99999_BASIC', 'HIGH', booking.Id);
        Test.stopTest();

        PUD_Booking__c updatedBooking = [
                Select Id, Address_Verified__c, Street__c, City__c, Post_Code__c, State__c, Geo__Latitude__s, Geo__Longitude__s,
                        DPID__c, Side_Of_Street_Code__c, Frontage_Geo__Latitude__s, Frontage_Geo__Longitude__s
                From PUD_Booking__c
                WHERE Id=:booking.Id
        ];

        System.assertEquals(true, updatedBooking.Address_Verified__c, 'Expected booking to be updated as address verified');
        System.assertNotEquals(booking.Street__c, updatedBooking.Street__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.City__c, updatedBooking.City__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Post_Code__c, updatedBooking.Post_Code__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.State__c, updatedBooking.State__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Geo__Latitude__s, updatedBooking.Geo__Latitude__s, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.DPID__c, updatedBooking.DPID__c, 'Expected booking to be updated with address returned by AME');
    }

    @IsTest
    static void testGetGeoCoordinates_FrontageGeoDataAvailable() {
        // =====================================
        // Data Preparation
        // =====================================

        Network__c network = [Select Id from Network__c];
        Account customer = [Select Id from Account];

        PUD_Booking_Location__c pudBookingLocation = PUDTestUtility.createBookingLocation('Customer Location', customer.Id, null);
        insert(pudBookingLocation);

        PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', pudBookingLocation.Id, customer.Id, null, network.Id, null);
        insert(booking);

        AusPostSettings__c setting = new AusPostSettings__c();
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'token';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/';
        insert setting;

        // =====================================
        // Stubbing
        // =====================================
        Test.setMock(HttpCalloutMock.class, new AMEHttpMock());

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        ResourcePudCreateBookingV1.getGeocoridinates('99999_WITH_FRONTAGE_GEO', 'HIGH', booking.Id);
        Test.stopTest();

        PUD_Booking__c updatedBooking = [
                Select Id, Address_Verified__c, Street__c, City__c, Post_Code__c, State__c, Geo__Latitude__s, Geo__Longitude__s,
                        DPID__c, Side_Of_Street_Code__c, Frontage_Geo__Latitude__s, Frontage_Geo__Longitude__s
                From PUD_Booking__c
                WHERE Id=:booking.Id
        ];

        System.assertEquals(true, updatedBooking.Address_Verified__c, 'Expected booking to be updated as address verified');
        System.assertNotEquals(booking.Street__c, updatedBooking.Street__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.City__c, updatedBooking.City__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Post_Code__c, updatedBooking.Post_Code__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.State__c, updatedBooking.State__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Geo__Latitude__s, updatedBooking.Geo__Latitude__s, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.DPID__c, updatedBooking.DPID__c, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Frontage_Geo__Latitude__s, updatedBooking.Frontage_Geo__Latitude__s, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Frontage_Geo__Longitude__s, updatedBooking.Frontage_Geo__Longitude__s, 'Expected booking to be updated with address returned by AME');
        System.assertNotEquals(booking.Side_Of_Street_Code__c, updatedBooking.Side_Of_Street_Code__c, 'Expected booking to be updated with address returned by AME');
    }

    public class AMEHttpMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('9999_BASIC')) {
                res.setStatusCode(200);
                res.setBody('{"id":"5e35c199-2ebf-42ac-ab1b-835b54efa4c2","results":[{"id":"75d04573-a9e1-414e-ace8-9845ff8f4be8","references":[],"addresses":[{"singleLine":"500 HAY ST PERTH WA 6000","score":1,"semiStructured":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST"],"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU"},"deliveryData":{"postcodeDID":"6000","localityDID":7608,"groupDID":123842,"roundDID":602862,"sectionDID":404527,"dpid":82496590,"sectionSequence":1260,"deliveryPointSequence":1,"deliveryOfficeRoundId":15,"phantom":false,"addressType":"THOROUGHFARE","thoroughfareAddressType":"PRIMARY","secondaryCount":0,"deliveryPointCategory":"BUSINESS"},"structured":{"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU","thoroughfareName":"HAY","thoroughfareNumber1":"500","thoroughfareType":"ST","deliveryPointIdentifier":82496590,"buildingAliases":["DISTRICT COURT BUILDING","DISTRICT COURT OF WA"],"buildingName":"DISTRICT COURT OF WA"},"upu":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST","PERTH WA 6000"]},"geoDataList":[{"featureType":"CENTROID","latitude":-31.95522663,"longitude":115.86339423}],"dpid":82496590,"confidence":"HIGH"}]}]}');
                return res;
            } else if (req.getEndpoint().contains('99999_WITH_FRONTAGE_GEO')) {
                res.setStatusCode(200);
                res.setBody('{"id":"5e35c199-2ebf-42ac-ab1b-835b54efa4c2","results":[{"id":"75d04573-a9e1-414e-ace8-9845ff8f4be8","references":[],"addresses":[{"singleLine":"500 HAY ST PERTH WA 6000","score":1,"semiStructured":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST"],"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU"},"deliveryData":{"postcodeDID":"6000","localityDID":7608,"groupDID":123842,"roundDID":602862,"sectionDID":404527,"dpid":82496590,"sectionSequence":1260,"deliveryPointSequence":1,"deliveryOfficeRoundId":15,"phantom":false,"addressType":"THOROUGHFARE","thoroughfareAddressType":"PRIMARY","secondaryCount":0,"deliveryPointCategory":"BUSINESS","sideOfStreetCode":"ANY"},"structured":{"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU","thoroughfareName":"HAY","thoroughfareNumber1":"500","thoroughfareType":"ST","deliveryPointIdentifier":82496590,"buildingAliases":["DISTRICT COURT BUILDING","DISTRICT COURT OF WA"],"buildingName":"DISTRICT COURT OF WA"},"upu":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST","PERTH WA 6000"]},"geoDataList":[{"featureType":"CENTROID","latitude":-31.95522663,"longitude":115.86339423}, {"featureType":"GNAF_FRONTAGE","latitude":-30.95522663,"longitude":116.86339423}],"dpid":82496590,"confidence":"HIGH"}]}]}');
                return res;
            }

            return null;
        }
    }
}