public with sharing class TaskUtil {

	
	static List<RecordType> taskRecordTypes{
		get {
			if(taskRecordTypes == null){
				taskRecordTypes = [select id,developerName,name from RecordType where SObjectType='Task'];
			}
			return taskRecordTypes;
		}
	}
	
	public static Set<id> getRecordTypesWithDevNameContains(string devName){
		Set<id> result = new Set<id>();
		for(RecordType t: taskRecordTypes){
			if(t.DeveloperName.contains(devName)){
				result.add(t.id);
			}
		}
		return result;
	} 
}