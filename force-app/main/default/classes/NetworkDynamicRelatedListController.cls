public with sharing class NetworkDynamicRelatedListController {
	public string relatedFieldNamesSingular {get;set;}
	
	public NetworkDynamicRelatedListController(ApexPages.StandardController stdController) {
		relatedFieldNamesSingular = ApexPages.currentPage().getParameters().get('relatedListFieldNames');
		if(!String.isBlank(relatedFieldNamesSingular)) {
			relatedFieldNamesSingular = relatedFieldNamesSingular.replaceAll('[^a-zA-Z0-9_]', '');
		}
	}
	
	public Component.Apex.OutputPanel getRelatedListComponentValue() {
		Component.Apex.OutputPanel result = new Component.Apex.OutputPanel();
		if(!String.isBlank(relatedFieldNamesSingular)) {
			List<String> fieldNames = ApexPages.currentPage().getParameters().get('relatedListFieldNames').split(',');
			for(String f: fieldNames){
				if(!String.isBlank(f)){
					Component.Apex.RelatedList r = new Component.Apex.RelatedList();
					r.list = f;	
					result.childComponents.add(r);
				}			
			}
		}
		return result;
	}
}