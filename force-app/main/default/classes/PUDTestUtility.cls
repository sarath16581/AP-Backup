/*
 * Class to create test data for pickup and delivery functions
 * AJ 17 Sep 2019 - Created
 * AJ 20 Nov 2019 - Added set of Depot on create booking
 * AJ 06 Dec 2019 - Added create of Route object record 
 */ 
@isTest
public class PUDTestUtility {
    
    //public static Date DATE_TODAY = date.today();
    static Date DATE_TODAY = date.today();
    
    static String TEST_FIRSTNAME = 'Charlie';
    static String TEST_LASTNAME = 'Booker';
    static String TEST_EMAIL = 'test@test.com';
    
    static String BOOKING_CONTACT = 'Don';
    static String BOOKING_PHONE = '0444444444';
    static String BOOKING_EMAIL = 'don@test.com';

    //static String BOOKING_ROUTE = 'R1';
    static Time BOOKING_START_TIME = Time.newInstance(9, 0, 0, 0);
    static Time BOOKING_END_TIME = Time.newInstance(17, 0, 0, 0);
    static Integer BOOKING_DWELL_TIME = 10;

    //Create set of base record for PUD Testing     
    public static Map<String, Id> createPUDBasicRecords(){
        
        //Map to store object Ids to return
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        
        //Create Account
        Account acc = createTestAccount('9999');
        insert acc;
        recordIdMap.put('acc',acc.Id);
        
        //Create test SPB
        Network__c networkSPB = createNetwork ('Red Box SPB 1', 'Street_Posting_Box_6');
        insert networkSPB;
        recordIdMap.put('netSPB',networkSPB.Id);
        
        //Create test LPO
        Network__c networkLPO = createNetwork ('Kew LPO', 'Retail_2');
        insert networkLPO;
        recordIdMap.put('netLPO',networkLPO.Id);
        
        //Create test Depot
        Network__c networkDepot = createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        recordIdMap.put('netDepot',networkDepot.Id);
        
        //Create a Route
        PUD_Route__c route = createRoute ('DT61', networkDepot.Id);
        insert route;
        recordIdMap.put('route',route.Id);
        
        //Create Customer Booking location
        PUD_Booking_Location__c custBookingLocation = createBookingLocation('Godfreys Kew', acc.Id, null);
        insert custBookingLocation;
        recordIdMap.put('blCust', custBookingLocation.Id);
        
        //Create Network Booking location for LPO
        PUD_Booking_Location__c netBookingLocationLPO = createBookingLocation('Kew LPO', null, networkLPO.Id);
        insert netBookingLocationLPO;
        recordIdMap.put('blNetLPO', netBookingLocationLPO.Id);
              
        return recordIdMap;
    }
    
    
    public static Account createTestAccount(String legacyId)
    {
        // create some weirdo account to bypass the billing account trigger error
        Account legacy = new Account();
        legacy.FirstName = 'legacy';
        legacy.LastName = 'retired';
        legacy.PersonEmail = 'retired@example.com';
        legacy.LEGACY_ID__c = '60000000';
        insert legacy;

        // create an Account(Org)
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();

        Account testAccount = new Account();
        testAccount.RecordTypeId = rId;
        testAccount.Name='TestAccount';
        testAccount.LEGACY_ID__c = legacyId;
        return testAccount;
    }
    
    public static Contact createTestContact(Id accId, String oId)
    {
        Contact testContact = new Contact();
        testContact.FirstName = TEST_FIRSTNAME;
        testContact.LastName = TEST_LASTNAME;
        testContact.Email = TEST_EMAIL;
        testContact.AccountId = accId;
        testContact.OID_ID__C = oId;
        testContact.Status__c = 'Active';
        return testContact;
    }
    
    //Create test network
    public static Network__c createNetwork (String networkName, String recordTypeDevName)
    {
        Network__c network = new Network__c();
        
        //Create with RT
        Id rId = Schema.SObjectType.Network__c.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        
        network.Name = networkName;
        network.ORG_UNIT_ADDR_1__c = 'NETWORK 1 ';
        network.ORG_UNIT_ADDR_2__c = 'NETWORK STREET CORNER';
        network.ORG_UNIT_ADDR_3__c = 'NETWORK SUBURB 1';
        network.Post_Code__c = '3000';
        network.State__c = 'VIC';
        network.RecordTypeId = rId;
        return network;
    }

    //Create Route
    public static PUD_Route__c createRoute (String routeName, Id depotId)
    {
        PUD_Route__c route = new PUD_Route__c();
        route.Name = routeName;
        route.Depot__c = depotId;
        return route;
    }
    
    //Create Booking Location
    public static PUD_Booking_Location__c createBookingLocation (String bookingLocationName, Id customerId, Id networkId)
    {
        PUD_Booking_Location__c bookingLocation = new PUD_Booking_Location__c();
        bookingLocation.Name = bookingLocationName;
        if(customerId != null){
            bookingLocation.Customer__c = customerId;
            bookingLocation.RecordTypeId = Schema.SObjectType.PUD_Booking_Location__c.getRecordTypeInfosByDeveloperName().get('AP_Customer').getRecordTypeId();
        }
        if(networkId != null){
            bookingLocation.Network__c = networkId;
            bookingLocation.RecordTypeId = Schema.SObjectType.PUD_Booking_Location__c.getRecordTypeInfosByDeveloperName().get('AP_Network').getRecordTypeId();
        }
        bookingLocation.Customer__c = customerId;
        bookingLocation.Street__c = '1 Main St';
        bookingLocation.City__c = 'Melbourne';
        bookingLocation.State__c = 'VIC';
        bookingLocation.Post_Code__c = '3121';
        return bookingLocation;
    }
    
    //Create Booking
    //customerId here is for bookings without a booking location (i.e. MPB)
    public static PUD_Booking__c createBooking (String recordTypeDevName, Id bookingLocationId, Id customerId, Id parentBooking, Id depotId, Id routeId)
    {
        PUD_Booking__c booking = new PUD_Booking__c();
        booking.RecordTypeId = Schema.SObjectType.PUD_Booking__c.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        booking.Depot__c = depotId;
        booking.Contact_Name__c = BOOKING_CONTACT;
        booking.Contact_Phone_Number__c = BOOKING_PHONE;
        booking.Contact_Email__c = BOOKING_EMAIL;
        //booking.Route__c = BOOKING_ROUTE;
        booking.Route_Lookup__c = routeId;
        booking.Earliest_Start_Time__c = BOOKING_START_TIME;
        booking.Latest_End_Time__c = BOOKING_END_TIME;
        booking.Dwell_Time_Planned__c = BOOKING_DWELL_TIME;
        booking.Effective_Date__c = DATE_TODAY;
        booking.Parent_Booking__c = parentBooking;
        booking.Monday__c = true;
        booking.Tuesday__c = true;
        booking.Wednesday__c = true;
        booking.Thursday__c = true;
        booking.Friday__c = true;
        booking.Saturday__c = true;
        booking.Sunday__c = true;
        //if contracted customer/network booking (i.e. with booking location)
        if(bookingLocationId != null){
            booking.Booking_Location__c = bookingLocationId;
        }
        //If customer (my post business) booking
        if(customerId != null){
            booking.Customer__c = customerId;
            booking.Street__c = '1 Main St';
            booking.City__c = 'Melbourne';
            booking.State__c = 'VIC';
            booking.Post_Code__c = '3121';
        }
        return booking;
    }
    
       //Create Booking
    public static PUD_Booking_Exception__c createBookingException (Id bookingId, Date exceptionStartDate, Date exceptionEndDate)
    {
        PUD_Booking_Exception__c bookingEx = new PUD_Booking_Exception__c();
        bookingEx.Booking__c = bookingId;
        bookingEx.Start_Date__c = exceptionStartDate;
        bookingEx.End_Date__c = exceptionEndDate;
        return bookingEx;
    }
    
    //Create test user (to run as - e.g. depot supervisor)
    public static User createUser(String profileName){
        Profile profileMap = [
                SELECT Id, Name
                FROM Profile
                WHERE Name = :profileName
                LIMIT 1
        ];
        
        String uniqueUserName = 'pudtestuser' + DateTime.now().getTime() + '@testorg.com';
        
        User testUser = new User();
        testUser.Alias = 'standt';
        testUser.ProfileId = profileMap.Id;
        testUser.FirstName = 'Tim';
        testUser.LastName = 'Test';
        testUser.Username = uniqueUserName;
        testUser.Email = 'standarduser@testorg.com';
        testUser.TimeZoneSidKey = 'Australia/Sydney'; 
        testUser.LocaleSidKey = 'en_AU'; 
        testUser.EmailEncodingKey = 'ISO-8859-1'; 
        testUser.LanguageLocaleKey = 'en_US'; 
        testUser.IsActive = true;
        System.debug(testUser);
        return  testUser;
    }
    
}