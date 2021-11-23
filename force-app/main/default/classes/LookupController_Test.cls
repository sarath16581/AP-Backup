/**
 * @author
 * @date
 * @description Test class for LookupController
 */

/**
--------------------------------------- History --------------------------------------------------
10.02.2020    alex.volkov@auspost.com.au    Added filterMap parameter
27.03.2020    alex.volkov@auspost.com.au    Added assertions
**/

@IsTest
public class LookupController_Test
{
	/**
	* Test search against Network object
	* */
	@IsTest
	public static void LookupController_getSearchResultsNetwork()
	{
		String fieldList = 'Id,Name';
		String searchTerm = 'Test';
		String objName = 'Network__c';
		String fieldsToSearch = 'Name';
		List<SObject> listOfNetworks = LookupController.getSearchResults(searchTerm, fieldList, objName, fieldsToSearch, new Map<String, String>{'Name' => 'Test'});
		/** Assert results */
		System.assertNotEquals(null, listOfNetworks);
	}

	/**
	* Test search against Contact object
	* */
	@IsTest
	public static void LookupController_getSearchResultsContact()
	{
		String fieldList = 'Id,Name';
		String searchTerm = 'Test';
		String objName = 'Contact';
		String fieldsToSearch = 'Name';
		List<SObject> Contact = LookupController.getSearchResults(searchTerm, fieldList, objName, fieldsToSearch, new Map<String, String>{'Name' => 'Test'});
		/** Assert results */
		System.assertNotEquals(null, Contact);
	}

}