/**************************************************
Type:       Frontend script manager for use within Visualforce
Description:    Can be included in any Visualforce component or page and is used to manage which frontend scripts should be loaded / rendered
History:
--------------------------------------------------
2017-09-17   nathan.franklin@auspost.com.au Created
**************************************************/
public without sharing class ScriptLoaderController {

	// list of libraries to be loaded with this instance of the ScriptLoader component
	// once a library has been loaded it won't get loaded again in the current scope of the page.
	public List<String> jsLibrariesToLoad { get; set; }
	public List<String> cssLibrariesToLoad { get; set; }

	// this stores all libraries currently loaded
	@TestVisible
	private static Set<String> jsLibrariesLoaded = new Set<String>();

	// this stores all libraries currently loaded
	@TestVisible
	private static Set<String> cssLibrariesLoaded = new Set<String>();

	public String jsLibs {
		get;
		set {
			if(!String.isEmpty(value) && jsLibs != value) {
				jsLibs = value;
				setupJsLibraries();
			}
		}
	}

	public String cssLibs {
		get;
		set {
			if(!String.isEmpty(value) && cssLibs != value) {
				cssLibs = value;
				setupCssLibraries();
			}
		}
	}

	public ScriptLoaderController() {
		jsLibrariesToLoad = new List<String>();
		cssLibrariesToLoad = new List<String>();
	}

	private void setupJsLibraries() {
		List<String> libs = jsLibs.split(',');
		System.Debug('> requesting js libs <' + libs);
		for(String lib : libs) {
			lib = lib.trim().toLowerCase();
			// this is to ensure libraries are enqueued more than once
			if(!jsLibrariesLoaded.contains(lib)) {
				jsLibrariesToLoad.add(lib);
				jsLibrariesLoaded.add(lib);
			}
		}

		System.Debug('> loading js libs <' + jsLibrariesToLoad);
	}

	private void setupCssLibraries() {
		List<String> libs = cssLibs.split(',');
		System.Debug('> requesting css libs <' + libs);
		for(String lib : libs) {
			lib = lib.trim().toLowerCase();
			// this is to ensure libraries are enqueued more than once
			if(!cssLibrariesLoaded.contains(lib)) {
				cssLibrariesToLoad.add(lib);
				cssLibrariesLoaded.add(lib);
			}
		}
		System.Debug('> loading css libs <' + cssLibrariesToLoad);
	}

}