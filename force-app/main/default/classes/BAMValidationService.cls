/**************************************************
Description: provides some validation helper functions for user inputs
History:
--------------------------------------------------
2019-04-11  sameed.khan@auspost.com.au  Created
**************************************************/
public with sharing class BAMValidationService {

    // TODO fix dodgy code
    public static String lastFoundCNumber = '';

    public static Boolean checkIfDuplicateContactExistsInOrg(Id orgId, String firstName, String lastName, String Email, Id ownContactId) {
        List<Contact> duplicateContacts = [
            SELECT FirstName, LastName, Email, AccountId
            FROM Contact
            WHERE AccountId = :orgId
            AND FirstName = :firstName
            AND LastName = :lastName
            AND Email = :email
            AND Id != :ownContactId
        ];
        return duplicateContacts.size() > 0;
    }

    public static Boolean checkIfDulicateCnumberExistsInOrg(String orgId, String email) {
        // LDAP check

        String cNumber; 
        if(!Test.isRunningTest()) {
            cNumber = LDAP_UserAccount_v1.queryUserAccount('', Email);
        }
       
        if (!String.isBlank(cNumber)) {
            lastFoundCNumber = cNumber;
            List<Contact> contactsInSameOrgWithSameCNumber = [SELECT Id, Name, OID_ID__c, AccountId FROM Contact WHERE OID_ID__c =: cNumber AND AccountId =: orgId];
            return contactsInSameOrgWithSameCNumber.size() > 0;
        }
        return false;
    }
}