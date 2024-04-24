/**
 ** Description: 
 * Apex class to retrieve the vendor email address from Auspost_Vendors_Email_Address__mdt
 * This class provides an invocable method for use in flows to fetch vendor email addresses
 * for ABN Change Notification flow.
 **
 * @changelog
 * 2024-03-19 - Deepak Kemidi - Created
 **/
public with sharing class VendorEmailUtils {

	@InvocableMethod(label='Get Vendors Email Address')
	public static List<String> getEmailAddress() {
		List<String> emailAddresses = new List<String>();
		
		//Create an instance of AuspostVendorEmailSelector
		AuspostVendorEmailSelector selector = AuspostVendorEmailSelector.newInstance();
		
		//Call selectAllRecords() method to fetch all records
		List<Auspost_Vendors_Email_Address__mdt> customMetadataRecords = selector.selectAllRecords();
		
		if (!customMetadataRecords.isEmpty()) {
			for(Auspost_Vendors_Email_Address__mdt record : customMetadataRecords) {
				if (record.Vendor_Email__c != null) {
					emailAddresses.add(record.Vendor_Email__c);
				}
			}
		}
		
		String emailAddressesString = String.join(emailAddresses, ',');
		
		List<String> result = new List<String>();
		
		if(!String.isBlank(emailAddressesString)) {
			result.add(emailAddressesString);
		}
		
		return result;
	}
}