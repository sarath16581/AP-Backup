/*
 * @changelog
 * 2021-08-15 - Seth Heang - Decommision usage of 'al' managed package from SOQL query
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
public with sharing class FieldValueImageController {
	public ID innerRecordID {get;set;}
	
	Map<string, string> innerListOfImageUrls;
	public Map<string, string> listOfImageUrls {
		get { 
			if(innerListOfImageUrls == null && innerRecordID != null) {
				system.debug('george says: innerRecordID=' + innerRecordID);
				string objectName = innerRecordID.getSObjectType().getDescribe().getName();
				system.debug('george says: objectName=' + objectName);
				Map<String, Schema.SObjectField> fieldNames = innerRecordID.getSObjectType().getDescribe().fields.getMap();
				innerListOfImageUrls = new Map<string, string>();
				FieldValueImageSettings__c settings = FieldValueImageSettings__c.getValues(objectName);
				if(settings != null){
					string[] fieldNamesFromSettings = settings.CommaSeparatedFieldNames__c.split(',');
			        Set<Object> fieldsToRetrieve = new Set<Object>();
			        string finalfield = '';
			        for(string key: fieldNamesFromSettings){
			        	if(key.trim() != '' && fieldNames.containsKey(key)){
			        		fieldsToRetrieve.add(key.trim());
                            finalfield = finalfield + key.trim() + ',';
			        	}
			        }
                    finalfield = finalfield.removeEnd(',');
                    String soql = 'SELECT ' + finalfield + ' FROM ' + objectName+ ' WHERE id =: innerRecordId';
                    List<sObject> cs = Database.query(soql);
			        if(cs.size() > 0){
			        	for(object key: fieldsToRetrieve){
			        		object imageName = cs[0].get((string)key);
			        		if(imageName instanceOf string){
			        			try {
				        			string imagePath = '/resource/' + objectName + 'Icons/' + (string)key + '/' + ((string)imageName).replaceAll('[^a-zA-Z0-9]', '') + '.png';
				        			system.debug('George says: Url = ' + imagePath);
				        			PageReference ref = new PageReference(imagePath);
				        			if(ref.getContent().size() > 0){			        				
				        				innerListOfImageUrls.put(fieldNames.get((string)key).getDescribe().getLabel() + ':', imagePath);
				        			}
			        			}catch(Exception ex){
			        				system.debug('George says: ' + ex.getMessage());
			        			}
			        		}
			        	}
			        }
				}
			}
			return innerListOfImageUrls;
		}
	}
}