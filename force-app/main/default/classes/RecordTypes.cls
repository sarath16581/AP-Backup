/**************************************************
Type:       Utility class to retrieve RecordType records
Purpose:    Defines convenient methods to retrieve RecordType records. 
			Also implements a simple caching mechanism to avoid running SOQL queries on the subsequent calls
       
History:
--------------------------------------------------
17.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public class RecordTypes 
{
    
    private static Map<String,RecordType> nameTypeRTMap = new Map<String,RecordType>();
    
    private static String getRecordTypeKey(String name, String sObjectType) 
    {
        return (sObjectType + ':' + name).toLowerCase();
    }
    
    /**
     * Get record type by name - this can be the label or developer name for the specified sobject type
     */
    public static RecordType getRecordTypeByName(String name, String sObjectType) 
    {
        List<RecordType> rts = getRecordTypesByName(new Set<String> { name }, sObjectType);
        if (rts.size() > 0) 
        {
            return rts.get(0);
        }
        return null;
    }
    
    /**
     * Get record types for the specified set of names matching the specified sobject type
     */
    public static List<RecordType> getRecordTypesByName(Set<String> names, String sObjectType) 
    {
        Set<String> queryNames = new Set<String>();
        List<RecordType> recordTypes = new List<RecordType>();
        String key;
        RecordType rt;
        for(String name : names) 
        {
        	if (name != null) 
        	{
	            key = getRecordTypeKey(name, sObjectType);
	            rt = nameTypeRTMap.get(key);
	            if(rt != null) 
	            {
	                recordTypes.add(rt);
	            } 
	            else 
	            {
	                queryNames.add(name);
	            }
        	}
        }
        
        if (queryNames.size() > 0) 
        {
            for (RecordType r : [SELECT Id,Name,DeveloperName,IsPersonType,IsActive,sObjectType FROM RecordType WHERE (Name in :queryNames OR DeveloperName in :queryNames) AND sObjectType = :sObjectType]) 
            {
                // update the name type map with both the name and developer name
                nameTypeRTMap.put(getRecordTypeKey(r.Name, sObjectType), r);
                nameTypeRTMap.put(getRecordTypeKey(r.DeveloperName, sObjectType), r);
                recordTypes.add(r);
            }
        }
        
        return recordTypes;
    }
}