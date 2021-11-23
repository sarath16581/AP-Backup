@isTest
private class TestNetworkUtil {

    private static RecordType licenceRecType = RecordTypes.getRecordTypeByName('Licence', 'Account');
    private static RecordType facitlityRecType = RecordTypes.getRecordTypeByName('Facility', 'Account');
    private static RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');
    private static RecordType otherRecType = RecordTypes.getRecordTypeByName('Other', 'Network__c');
    private static RecordType insuranceRT = RecordTypes.getRecordTypeByName('Insurance', 'Partner_Addendum__c');
    //Setup Method
    @testsetup
    private  static void setup(){
        // Insert Partner Info Custom Setting
        Partner_Info_Settings__c setting = new Partner_Info_Settings__c(
                Email_List_Vic__c = 'testvic@test.com',
                Email_List_NSW__c = 'testnsw@test.com',
                First_Reminder_Days__c = 63,
                Second_Reminder_Days__c = 25,
                Third_Reminder_Days__c = 7,
                Level_3_Approval_Amount__c = 10000
        );
        insert setting;

        List<ACCOUNT_LICENCE_RECORDTYPES__c> las = new List<ACCOUNT_LICENCE_RECORDTYPES__c>();
        las.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence'));
        las.add(new ACCOUNT_LICENCE_RECORDTYPES__c(Name='Licence CMA'));
        insert las;

        //Insert parent Organisation
        Account parentAccount = new Account(
                name = 'Test0',
                phone = '123',
                RecordTypeId = organizationRecType.id);
        insert parentAccount;
        //Insert nominated contact
        Contact testContact1 = new Contact(
                FirstName = 'First',
                LastName = 'Last',
                MailingCity = 'Melbourne',
                MailingState = 'VIC',
                MailingStreet = '673 bourke street',
                MailingPostalCode = '3000',
                AccountId = parentAccount.Id,
                Email = 'example@email.com');
        insert testContact1;
        //Add contact on Parent Org as Nominated Contact
        parentAccount.Nominated_Partner_Contact_Incent_User__c = testContact1.Id;
        update parentAccount;
        //Insert Parent Network
        network__c parentNetwork = new Network__c(Org_ID__c = '2345', Network_Manager__c=UserInfo.getUserId(), State__c='Vic', RecordTypeId = otherRecType.Id);
        insert parentNetwork;
        //Insert Network
        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;
        Account licenceAcc2 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                //Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Active',
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        insert licenceAcc2;
        //Create Facility based Network created above
        Account facilityAcc1 = new Account(
                name='test1',
                phone='123',
                recordtypeid=facitlityRecType.id,
                Is_a_facility__c = true,
                Network_Facility__c = network.id,
                Licence_Type__c = 'LPO',
                Subjected_To_GST__c = false,
                ParentId = licenceAcc2.Id );
        insert facilityAcc1;

        Account licenceAcc1 = new Account(
                name='test2',
                phone='124',
                recordtypeid=licenceRecType.id,
                Facility__c =facilityAcc1.id,
                Licence_Status__c= 'Draft',
                Assignment_Effective_From_Date__c = System.today(),
                ParentId = parentAccount.id );
        insert licenceAcc1;

        Partner_Addendum__c addendum1 = new Partner_Addendum__c(
                Licence__c = licenceAcc1.id,
                Status__c = 'Draft',
                Sub_Type__c = 'Ad-hoc',
                Start_Date__c = Date.today().addDays(2),
                End_Date__c = Date.today().addDays(200),
                RecordTypeId = insuranceRT.Id
        );

        insert addendum1;
    }

    static testMethod void testBankFieldUpdates() {
    	//creating custom settings
        insert new List<BankMapping__c> {
        	new BankMapping__c(Name = '1', Network_Field__c = 'ANZ__c'), 
        	new BankMapping__c(Name = '2', Network_Field__c = 'CBA__c'),
        	new BankMapping__c(Name = '5', Network_Field__c = 'RBA__c'),
        	new BankMapping__c(Name = '9', Network_Field__c = 'Westpac__c')
        };
        
        Network__c n1 = new Network__c();
        n1.Name = 'Melb CBD';
        n1.BusBankChq__c = '1, 2,3';
        n1.BusBankChqCash__c = ' 2,3,5';
        
        Network__c n2 = new Network__c();
        n2.Name = 'Syd CBD';
        n2.BusBankChq__c = '3, 6,10 ';
        n2.BusBankChqCash__c = '4,7,11';
        
        insert new List<Network__c> {n1, n2};
        
        List<Network__c> nwList = [SELECT ANZ__c, CBA__c, RBA__c, Westpac__c FROM Network__c WHERE ID IN (:n1.Id, :n2.Id) ORDER BY Name ASC];
       	
       	//Melb CBD
       	System.assertEquals(nwList[0].ANZ__c, NetworkUtil.PICKLIST_VALUE_CHECK_ONLY);
        System.assertEquals(nwList[0].CBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nwList[0].RBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nwList[0].Westpac__c, null);
        
        //Syd CBD
        System.assertEquals(nwList[1].ANZ__c, null);
        System.assertEquals(nwList[1].CBA__c, null);
        System.assertEquals(nwList[1].RBA__c, null);
        System.assertEquals(nwList[1].Westpac__c, null);
        
        //checking update
        n2.BusBankChq__c += ',1';
        n2.BusBankChqCash__c += ',1,2';
        update n2;
        
        Network__c nw = [SELECT ANZ__c, CBA__c, RBA__c, Westpac__c FROM Network__c WHERE ID = :n2.Id];
        System.assertEquals(nw.ANZ__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nw.CBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nw.RBA__c, null);
        System.assertEquals(nw.Westpac__c, null);
    }

    static testMethod void testNetworkManager() {
        //Fetch the profile.
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        //Create a user.
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com',
                Work_Center_Code__c='123456');

        insert testUser;
        Network__c facilityNetwork = [SELECT id from Network__c where Network_Manager__c!=null limit 1];
        facilityNetwork.Network_Manager__c = testUser.Id;
        facilityNetwork.State__c = 'NSW';
        update facilityNetwork;
    }
    //PUD 19/09/2019 ajudd@salesforce.com - Added to test NetworkUtil.updateBookingLocationAddress
    //Validate that when updating the dictated fields on the Network (address), these are updated on the dependent Booking Location record
	testmethod static void testNetworkAddressUpdate(){
        Map<String, Id> recordIdMap = new Map<String,Id>();
        List<Network__c> networkList = new List<Network__c>();
        List<PUD_Booking_Location__c> bookingLocationList = new List<PUD_Booking_Location__c>();
        String strNewSuburbNetwork = 'NETWORK SUBURB 88';
        String strNewSuburbBookingLocation;
        
        Test.startTest();
        
        //Create Test Data
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        
        //Create a Booking for network booking location
        PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blNetLPO'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
		insert booking;
        
        //Update the network address of one of the networks       
        networkList = [SELECT Id, ORG_UNIT_ADDR_3__c FROM Network__c WHERE Id = :recordIdMap.get('netLPO')];
        system.debug('networkList = '+ networkList);
        for (Network__c network : networkList){
            network.ORG_UNIT_ADDR_3__c = strNewSuburbNetwork;
        }
        update networkList;
        
        Test.stopTest();
        
        //Confirm that the booking Location address is now updated
        bookingLocationList = [SELECT Id, City__c FROM PUD_Booking_Location__c WHERE Id = :recordIdMap.get('blNetLPO')];
		strNewSuburbBookingLocation = bookingLocationList[0].City__c;
        
        System.assertEquals(true, (strNewSuburbBookingLocation == strNewSuburbNetwork));   
    }
}