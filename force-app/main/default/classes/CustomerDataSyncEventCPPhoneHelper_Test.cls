/**
 * @description       : This is a test class for CustomerDataSyncEventCPPhoneHelper
 * @author            : Sreenish Krishnan
 * @domain            : Connecetd Customer
 * @last modified on  : 07-14-2022
 * @last modified by  : Sreenish Krishnan
 **/
//TODO this needs to be completed
@isTest
public with sharing class CustomerDataSyncEventCPPhoneHelper_Test {
	@isTest
    static void deserialisePayload() {
        CustomerDataSync__e event = new CustomerDataSync__e();
        List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>();
        CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper wr = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
		wr.phone = '+61452626262';
		payloadWrappers.add(wr);
        event.phones__c = JSON.serialize(payloadWrappers);
        CustomerDataSyncEventCPPhoneHelper helper = new CustomerDataSyncEventCPPhoneHelper();
        CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper actual = helper.deserialisePayload(event)[0];
        System.assertEquals(wr.phone, actual.phone);
    }
}