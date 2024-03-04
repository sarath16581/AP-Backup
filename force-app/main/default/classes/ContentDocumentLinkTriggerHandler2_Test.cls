/***
 * @author Hasantha Liyanage
 * @date 2024-02-23
 * @domain Core
 * @description Test class for ContentDocumentLinkTriggerHandler2
 * @changelog
 ***/

@IsTest
private class ContentDocumentLinkTriggerHandler2_Test {
	@IsTest
	private static void main() {

		ContentDocumentLinkTriggerHandler2 handler = new ContentDocumentLinkTriggerHandler2();
		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(ContentDocumentLink.SObjectType, handler.getSObjectType(), 'Expected ContentDocumentLink sobject type');
		System.assert(ContentDocumentLinkTriggerHandler2.getUnitOfWorkSObjectTypes().contains(Account.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(ContentDocumentLinkTriggerHandler2.getUnitOfWorkSObjectTypes().contains(ContentDocument.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(ContentDocumentLinkTriggerHandler2.getUnitOfWorkSObjectTypes().contains(ContentDocumentLink.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(ContentDocumentLinkTriggerHandler2.getUnitOfWorkSObjectTypes().contains(ContentVersion.SObjectType), 'Expected valid list of sobject types to be returned');

	}
}