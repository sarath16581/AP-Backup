public with sharing class RelatedListLazyLoadController {
	
	public RelatedListLazyLoadController(){
	}
	
	public string relatedFieldNamesSingular {get {return relatedFieldNamesSingular; } set {relatedFieldNamesSingular = value.replaceAll('[^a-zA-Z0-9_]', '');}}
}