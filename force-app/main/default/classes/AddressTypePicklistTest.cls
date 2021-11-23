/**
 * @author alexvolkov
 * @date 5/2/20
 * @description Test class for AddressTypePicklist
 */

/**
--------------------------------------- History --------------------------------------------------
05.02.2020    alex.volkov@auspost.com.au    Initial creation
**/

@IsTest
private with sharing class AddressTypePicklistTest
{
	/**
	* @description Test for getDefaultValue and getValues methods
	*/
	@IsTest
	static void testGetValues()
	{
		/** Instantiate AddressTypePicklist */
		AddressTypePicklist vPicklist = new AddressTypePicklist();
		Test.startTest();
		/** Assert the default value */
		System.assertEquals(null, vPicklist.getDefaultValue(), 'Default value is not null');
		/** Assert picklist values list */
		System.assertNotEquals(null, vPicklist.getValues(), 'Picklist is null');
		Test.stopTest();
	}
}