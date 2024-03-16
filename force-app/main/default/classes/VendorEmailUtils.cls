/**
 ** Description: 
 * Apex class to retrieve the vendor email address based on the environment (Sandbox or Production).
 * This class provides an invocable method for use in flows to differentiate between vendor email addresses
 * in sandbox and production environments for ABN Change Notification flow.
 **
 * @changelog
 * 2024-03-19 - Deepak Kemidi - Created
 **/
public with sharing class VendorEmailUtils {

    private static Boolean isSandbox;

    // Returns true if running from Sandbox
    public static Boolean runningInASandbox {
        get {
            if (isSandbox == null) {
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        private set;
    }

    @InvocableMethod(label='Get Vendors Email Address')
    public static List<String> getEmailAddress() {
        List<String> emailAddresses = new List<String>();
        String customMetadataTypeName = runningInASandbox ? 'SandboxVendorEmail' : 'ProductionVendorEmail';
        List<Auspost_Vendors_Email_Address__mdt> customMetadataRecords = [SELECT Vendor_Email__c FROM Auspost_Vendors_Email_Address__mdt WHERE DeveloperName = :customMetadataTypeName LIMIT 1];
        if (!customMetadataRecords.isEmpty()) {
            Auspost_Vendors_Email_Address__mdt customMetadataRecord = customMetadataRecords[0];
            emailAddresses.add(customMetadataRecord.Vendor_Email__c);
        }
        return emailAddresses;
    }
}



