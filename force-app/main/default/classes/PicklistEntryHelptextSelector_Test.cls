/* @author Pratyush Chalasani
 * @date 2023-06-02
 * @group Tests
 * @tag Selector
 * @tag Picklist Entry Helptext Selector
 * @domain Core
 * @description A selector for querying picklist entry helptext records
 * @changelog
 * 2023-06-02 - Pratyush Chalasani - Created
 */
@isTest
private class PicklistEntryHelptextSelector_Test {
	/*
		We can't insert custom metadata records from Apex.
		So his will dierctly query the first avaialble record, parse the object/field mapping
		and call the selectByObjectAndField function using the result.
		At the end we check that the selector returns a non-empty list.
	*/
    @isTest
	static void test_selectByObjectAndField() {
		Picklist_Entry_Helptext__mdt directlyQueried = [SELECT Object_Field_Name__c FROM Picklist_Entry_Helptext__mdt LIMIT 1];

		System.debug(directlyQueried);

		// Expecting "<objectname>.<fieldname>", so split by "." into two parts
		List<String> nameParts = directlyQueried.Object_Field_Name__c.split('\\.');

		System.debug(nameParts);

		SObjectType objectType = Schema.getGlobalDescribe().get(nameParts[0]);
		SObjectField fieldType = objectType.getDescribe().fields.getMap().get(nameParts[1]);

		Test.startTest();
		
		List<Picklist_Entry_Helptext__mdt> entries = PicklistEntryHelptextSelector.newInstance().selectByObjectAndField(objectType, fieldType);

		Test.stopTest();

		Assert.isTrue(entries.size() > 0, 'List should not be empty');
    }
}