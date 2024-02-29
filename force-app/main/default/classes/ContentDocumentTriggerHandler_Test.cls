/***
 * @author Hasantha Liyanage
 * @date 2024-02-23
 * @domain Core
 * @description Test class for ContentDocumentTriggerHandler
 * @changelog
 ***/
@IsTest
private class ContentDocumentTriggerHandler_Test {
	@IsTest
	private static void main() {

		ContentDocumentTriggerHandler handler = new ContentDocumentTriggerHandler();
		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(ContentDocument.SObjectType, handler.getSObjectType(), 'Expected ContentDocument sobject type');

	}
}