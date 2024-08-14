/**
 * @author Harry Wang
 * @date 2024-08-14
 * @tag ContentDocument
 * @description Utility class to link content document
 * @changelog
 * 2024-08-14 - Harry Wang - Created
 */
public with sharing class LinkContentDocument {
	/**
	 * This method is used to generate general content document links based on document Id and entity Id
	 * Inferred permission and all users visibility will be used as defaults.
	 * @param docIds content document Id list
	 * @param entityId entity Id where the content document link will be linked
	 * @return list of save results
	 */
	public static List<Database.SaveResult> generateContentDocumentLink(List<Id> docIds, Id entityId) {
		return generateContentDocumentLink(docIds, entityId, 'I', 'AllUsers');
	}

	/**
	 * This method is used to generate general content document links based on document Id, entity Id, share type and visibility
	 * @param docIds content document Id list
	 * @param entityId entity Id where the content document link will be linked
	 * @param shareType the permission granted to the user of the shared file
	 * @param visibility Specifies whether this file is available to all users, internal users, or shared users
	 * @return list of save results
	 */
	public static List<Database.SaveResult> generateContentDocumentLink(List<Id> docIds, Id entityId, String shareType, String visibility) {
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (Id docId: docIds) {
			ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
			contentDocumentLink.ContentDocumentId = docId;
			contentDocumentLink.LinkedEntityId = entityId;
			contentDocumentLink.ShareType = shareType;
			contentDocumentLink.Visibility = visibility;
			contentDocumentLinks.add(contentDocumentLink);
		}
		return ApplicationDatabase.getInstance().dmlInsert(contentDocumentLinks);
	}
}