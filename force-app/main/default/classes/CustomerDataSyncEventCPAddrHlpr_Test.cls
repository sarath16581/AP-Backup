/**
 * @description       : This is a test class for CustomerDataSyncEventCPAddressHelper
 * @author            : George Nguyen
 * @domain            : Connecetd Customer
 * @last modified on  : 08-12-2022
 * @last modified by  : Sreenish Krishnan
 **/
@IsTest
public with sharing class CustomerDataSyncEventCPAddrHlpr_Test {

    @IsTest
    static void deserialisePayload() {
        CustomerDataSync__e event = new CustomerDataSync__e();
        List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper>();
        CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper wr = new CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper();
		wr.type = 'Other';
		wr.street1 = 'test 1';
		wr.street2 = 'test 2';
		wr.suburb = 'test sub';
		wr.state = 'test state';
		wr.postcode = '3300';
		wr.country = 'AU';
        payloadWrappers.add(wr);
        event.addresses__c = JSON.serialize(payloadWrappers);
        CustomerDataSyncEventCPAddressHelper helper = new CustomerDataSyncEventCPAddressHelper();
        CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper actual = helper.deserialisePayload(event)[0];
        System.assertEquals(wr.type, actual.type);
        System.assertEquals(wr.street1, actual.street1);
        System.assertEquals(wr.street2, actual.street2);
        System.assertEquals(wr.suburb, actual.suburb);
        System.assertEquals(wr.state, actual.state);
        System.assertEquals(wr.postcode, actual.postcode);
        System.assertEquals(wr.country, actual.country);
    }

    @IsTest
    static void getContactPointAddress() {
        CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customerData = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
        customerData.recId = '001000000000000000';
        customerData.personContactId = '003000000000000000';
        List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper>();
        CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper wr = new CustomerDataSyncEventCPAddressHelper.AddressPayloadWrapper();
		wr.type = 'Other';
		wr.street1 = 'test 1';
		wr.street2 = 'test 2';
		wr.suburb = 'test sub';
		wr.state = 'test state';
		wr.postcode = '3300';
		wr.country = 'AU';
        
        payloadWrappers.add(wr);
        String Name = wr.street1 + ' ' + wr.street2+' '+ wr.suburb + ' ' + wr.state + ' ' + wr.postcode + ' ' + wr.country;
        CustomerDataSyncEventCPAddressHelper helper = new CustomerDataSyncEventCPAddressHelper();
        ContactPointAddress cpa = helper.getContactPointAddress(customerData, payloadWrappers)[0];

        System.assertEquals(customerData.recId, cpa.ParentId);
        System.assertEquals(customerData.personContactId, cpa.Contact__c);
        System.assertEquals(wr.type, cpa.AddressType);
        System.assertEquals(wr.street1, cpa.Street);
        System.assertEquals(wr.street2, cpa.Street2__c);
        System.assertEquals(wr.suburb, cpa.City);
        System.assertEquals(wr.state, cpa.State);
        System.assertEquals(wr.postcode, cpa.PostalCode);
        System.assertEquals(wr.country, cpa.Country);
        System.assertEquals(name, cpa.Name);
    }

}