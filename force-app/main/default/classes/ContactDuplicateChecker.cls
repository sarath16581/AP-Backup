/**
 * @author Harry Wang
 * @date 2024-05-17
 * @tag CSP
 * @description Contact duplicate check class to find duplicated contacts and return unique contacts as a list
 * @changelog
 * 2024-05-17 - Harry Wang - Created
 */
public class ContactDuplicateChecker {

	// Method to generate a unique identifier for a contact
	public static String generateContactIdentifier(Contact con) {
		String firstName = con.FirstName != null ? con.FirstName.trim() : '';
		String lastName = con.LastName != null ? con.LastName.trim() : '';
		String phone = con.Phone != null ? con.Phone.trim() : '';
		String email = con.Email != null ? con.Email.trim() : '';
		String contactInfo = (firstName + '♥' + lastName + '♥' + phone + '♥' + email).toLowerCase();
		Blob contactBlob = Blob.valueOf(contactInfo);
		String sha256Code = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', contactBlob));
		return sha256Code;
	}

	// Method to find unique contacts in Account1 that are not found in Account2
	public static List<Contact> findUniqueContacts(List<Contact> contactsAccount1, List<Contact> contactsAccount2) {
		Set<String> contactsAccount2Identifiers = new Set<String>();
		Map<String, List<Contact>> hashedContactsMap = new Map<String, List<Contact>>();
		// Add identifiers of contacts from account2 to the set
		for (Contact con : contactsAccount2) {
			String contactIdentifier = generateContactIdentifier(con);
			contactsAccount2Identifiers.add(contactIdentifier);
			if (!hashedContactsMap.containsKey(contactIdentifier)) {
				hashedContactsMap.put(contactIdentifier, new List<Contact>());
			}
			hashedContactsMap.get(contactIdentifier).add(con);
		}
		List<Contact> uniqueContactsList = new List<Contact>();
		// Add contacts from account1 to the list if not found in account2 or if there's no collision
		for (Contact con : contactsAccount1) {
			String contactIdentifier = generateContactIdentifier(con);
			if (!contactsAccount2Identifiers.contains(contactIdentifier)) {
				uniqueContactsList.add(con);
			} else if (!checkFieldsForTrueDuplicates(con, hashedContactsMap.get(contactIdentifier))) {
				uniqueContactsList.add(con);
			}
		}
		return uniqueContactsList;
	}

	// Method to check individual fields for collision
	private static Boolean checkFieldsForTrueDuplicates(Contact con1, List<Contact> contacts) {
		for (Contact con2 : contacts) {
			if (con1.FirstName == con2.FirstName && con1.LastName == con2.LastName && con1.Phone == con2.Phone && con1.Email == con2.Email) {
				//True Duplicates detected i.e. No Collision
				return true;
			}
		}
		// No True Duplicates detected i.e. Collision
		return false;
	}
}