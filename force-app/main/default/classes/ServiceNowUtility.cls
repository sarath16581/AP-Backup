/*@File Name		: ServiceNowUtility
@Description 		: This class contains all the utility methods used by Service now integration project 
@Author			: Ramtej Juloori
@Created			: 08/10/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/
public with sharing class ServiceNowUtility {

   
    /*******************************************************************************************************
     * @method name		: findObjectNameFromRecordIdPrefix
     * @description 		: method to return the object name when an Id is passed using the object prefix
     * @parameters		: String
     * @returns 			: String
     */
    public static String findObjectNameFromRecordIdPrefix(String recordId) {

        System.Debug('findObjectNameFromRecordIdPrefix: ' + recordId);

        String objectName = '';
        try {
            objectName = ((Id) recordId).getSObjectType().getDescribe().getName();
        } catch (Exception e) {
            System.debug('message ' + e.getMessage() + ' at line ' + e.getStackTraceString());
        }
        return objectName;
    }

    /*******************************************************************************************************
     * @method name      : getNameByIdUtility
     * @description      : Method to get the sobject from the record Id passed
     * @returns          : Sobject
     * @parametes        : string
     */
    public static sobject getNameByIdUtility(string recId) {
        try {
            if (recId != null) {
                string objectName = ServiceNowUtility.findObjectNameFromRecordIdPrefix(recId);
                if (objectName != '') {
                    return Database.query('SELECT Id, Name FROM ' + objectName + ' WHERE Id = \'' + recId + '\' LIMIT 1');
                } else {
                    return null;
                }

            } else {
                return null;
            }
        } catch (exception ex) {
            system.debug('ex message ' + ex.getMessage() + ' at line ' + ex.getStackTraceString());
            return null;
        }
    }
    
    public static Map < string, operatorCompare > getOperatorMap(){
        Map < string, operatorCompare > operatorMap = new Map < string, operatorCompare >();
        operatorMap.put('AND_',new operatorCompare('AND_','^',true));
        operatorMap.put('CONTAINS',new operatorCompare('CONTAINS','LIKE',false));
        operatorMap.put('ENDS_WITH',new operatorCompare('ENDS_WITH','ENDSWITH',false));
        operatorMap.put('EQUALS',new operatorCompare('EQUALS','=',false));
        operatorMap.put('GREATER_THAN',new operatorCompare('GREATER_THAN','GT_FIELD',false));
        operatorMap.put('GREATER_THAN_OR_EQUAL_TO',new operatorCompare('GREATER_THAN_OR_EQUAL_TO','GT_OR_EQUALS_FIELD',false));
        operatorMap.put('LESS_THAN',new operatorCompare('LESS_THAN','LT_FIELD',false));
        operatorMap.put('LESS_THAN_OR_EQUAL_TO',new operatorCompare('LESS_THAN_OR_EQUAL_TO','LT_OR_EQUALS_FIELD',false));
        operatorMap.put('LIKE_',new operatorCompare('LIKE_','LIKE',false));
        operatorMap.put('NOT_',new operatorCompare('NOT_','!=',false));
        operatorMap.put('NOT_EQUALS',new operatorCompare('NOT_EQUALS','!=',false));
        operatorMap.put('OR_',new operatorCompare('OR_','^OR',true));
        operatorMap.put('OR_Filter',new operatorCompare('OR_Filter','^NQ',true));
        operatorMap.put('STARTS_WITH',new operatorCompare('STARTS_WITH','STARTSWITH',false));
        return operatorMap;
    }
    
    /*******************************************************************************************************
     * @method name		: operaorCompare
     * @description 		: class to hold operator symbol mapping from salesforce to service now
     * @parameters		: NA
     * @returns 			: NA
     */
    
    public class operatorCompare{
        public string SFType {get; set;}
        public string SNType {get; set;}
        public boolean FilterType {get; set;}
        public operatorCompare(string SFType, string SNType, boolean FilterType){
            this.SFType = SFType;
            this.SNType = SNType;
            this.FilterType = FilterType;
        }
    }
}