/**
 * @description       : This method maps the deserialises the payload from the field addressess__c in the Platform Event and then maps it to ContactPointAddress records 
 * @author            : George Nguyen
 * @domain            : Connected Customer
 * @last modified on  : 07-20-2022
 * @Test CustomerDataSyncEventCPAddrHlpr_Test
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class CustomerDataSyncEventCPAddressHelper {

	public List<AddressPayloadWrapper> deserialisePayload(CustomerDataSync__e event) {
		List<AddressPayloadWrapper> result = new List<AddressPayloadWrapper>();
		if(String.isBlank(event.addresses__c) == false) {
			result = (List<AddressPayloadWrapper>) System.JSON.deserialize(event.addresses__c,List<AddressPayloadWrapper>.class);
		}
		return result;
	}

	public List<ContactPointAddress> getContactPointAddress(CustomerDataSyncEventCustomerHelper.CustomerUpsertResult customerData, List<AddressPayloadWrapper> payloadWrappers) {
		List<ContactPointAddress>  result = new List<ContactPointAddress>();
		for(AddressPayloadWrapper wr: payloadWrappers) {
			result.add(new ContactPointAddress(
				ParentId = customerData.recId,
				Contact__c = customerData.personContactId,
				AddressType = wr.type,
				Street = wr.street,
				Street2__c = wr.street2,
				City = wr.suburb,
				State = wr.state,
				PostalCode = wr.postcode,
				Country = wr.country,
				Name = wr.street + ' ' + (String.isBlank(wr.street2) ? wr.street2 + ' ': '') + wr.suburb + ' ' + wr.state + ' ' + wr.postcode + ' ' + wr.country
			));
		}
		return result;
	}
	
	public class AddressPayloadWrapper {
		public String type { get; set; }
		public String street { get; set; }
		public String street2 { get; set; }
		public String suburb { get; set; }
		public String state { get; set; }
		public String postcode { get; set; }
		public String country { get; set; }
	}
}