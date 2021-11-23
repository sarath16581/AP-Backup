public with sharing class FieldValueDisplay {
	public FieldValueDisplay(string developerName, string label, object value){
		this.developerName = developerName;
		fieldLabel = label;
		fieldValue = value;
	}
	public string developerName{get;set;}
	public string fieldLabel{get;set;}
	public object fieldValue{get;set;}
}