global with sharing class CustomComponentFactory {
	
	
	public static Apexpages.Component newComponent(string componentName, string refId){
		system.debug('George says: Loading component ' + componentName + ' with refId ' + refId);
		if(componentName == 'MRSFiltersComponent') {
			return new Component.MRSFiltersComponent();
		}else if(componentName == 'SAPFiltersComponent'){
			return new Component.SAPFiltersComponent();
		}else if(componentName == 'TIBCODataVisualizerComponent'){
			if(refId != null && refId.trim() != '') {
				//TIBCOSearchResult_v1 searchResult = TIBCOArticleService_v1.searchArticles_v1(new string[] {refId});
				//return new Component.TIBCODataVisualizerComponent_v1(searchResult=searchResult,enableCreateCase=false);
				
				TIBCOSearchResult searchResult = TIBCOArticleService.searchArticles(new string[] {refId}, true);
				return new Component.TIBCODataVisualizerComponent(searchResult=searchResult,enableCreateCase=false);
			}
		}
		
		return null;
	}
}