/**************************************************
History:
--------------------------------------------------
2017-09-17   nathan.franklin@auspost.com.au Created
**************************************************/
@isTest
public with sharing class ScriptLoaderController_Test {

	public static testMethod void testCoverage() {
		ScriptLoaderController loader = new ScriptLoaderController();
		loader.jsLibs = 'jquery,jqueryui,jquery.layout';
		loader.cssLibs = 'bootstrap,jqueryui';

		System.assertEquals(loader.jsLibrariesToLoad.size(), 3);
		System.assertEquals(loader.cssLibrariesToLoad.size(), 2);

		System.assertEquals(ScriptLoaderController.jsLibrariesLoaded.size(), 3);
		System.assertEquals(ScriptLoaderController.cssLibrariesLoaded.size(), 2);

		ScriptLoaderController reloader = new ScriptLoaderController();
		reloader.jsLibs = 'jquery,jqueryui,jquery.layout,mysamplelibrary';
		reloader.cssLibs = 'bootstrap,jqueryui,mysamplelibrary';

		System.assertEquals(reloader.jsLibrariesToLoad.size(), 1);
		System.assertEquals(reloader.cssLibrariesToLoad.size(), 1);

		System.assertEquals(ScriptLoaderController.jsLibrariesLoaded.size(), 4);
		System.assertEquals(ScriptLoaderController.cssLibrariesLoaded.size(), 3);

	}

}