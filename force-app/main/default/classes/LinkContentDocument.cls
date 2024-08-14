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
	 * @param docIds content document Id list
	 * @param entityId entity Id where the content document link will be linked
	 * @return list of save results
	 */
	public static List<Database.SaveResult> linkContentDocument(List<Id> docIds, Id entityId) {
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (Id docId: docIds) {
			ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
			contentDocumentLink.ContentDocumentId = docId;
			contentDocumentLink.LinkedEntityId = entityId;
			contentDocumentLink.ShareType = 'I';
			contentDocumentLink.Visibility = 'AllUsers';
			contentDocumentLinks.add(contentDocumentLink);
		}
		return ApplicationDatabase.getInstance().dmlInsert(contentDocumentLinks);
	}
}