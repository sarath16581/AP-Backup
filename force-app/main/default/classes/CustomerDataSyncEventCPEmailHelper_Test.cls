/**
 * @description       : This is a test class for CustomerDataSyncEventCPEmailHelper
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-14-2022
 * @last modified by  : Sreenish Krishnan
 **/
//TODO this needs to be completed
@isTest
public with sharing class CustomerDataSyncEventCPEmailHelper_Test {
	@isTest
    static void deserialisePayload() {
        CustomerDataSync__e event = new CustomerDataSync__e();
        List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>();
        CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper wr = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		wr.emailAddress = 'emailone@test.com.au.dummy';
		payloadWrappers.add(wr);
        event.emails__c = JSON.serialize(payloadWrappers);
        CustomerDataSyncEventCPEmailHelper helper = new CustomerDataSyncEventCPEmailHelper();
        CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper actual = helper.deserialisePayload(event)[0];
        System.assertEquals(wr.emailAddress, actual.emailAddress);
    }
}