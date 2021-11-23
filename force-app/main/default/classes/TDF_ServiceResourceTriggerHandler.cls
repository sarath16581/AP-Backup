/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-09-11
* @domain Field Service  
* @description Handler to process changes to Service Resource detected in ServiceResourceTrigger
*
* @changelog 
* 2020-09-11 - Andrew Judd - Added setExternalName to enforce uniqueness of the Name field, and provide 
*                               and External Id for data import wizard when loading Roster records
*
*/
public class TDF_ServiceResourceTriggerHandler {

    //Set External Name field to enforce uniqueness of Service Resource name
    public void setExternalName(List<ServiceResource> srList, Map<Id,ServiceResource> oldMap){
        
        //For each record inserted
        for(ServiceResource srRec : srList){ 

            //If old map is null (insert)
            if(oldMap == null){
                //Set the unique name field to the same value.  This will throw an error if not unique on the insert
                srRec.External_Name__c = srRec.Name;
            }
            //Else update
            else{
                //If the name is changed
                if(srRec.Name != oldMap.get(srRec.Id).Name){
                    //Update the unique name field to the same value. This will throw an error if not unique on the update
                    srRec.External_Name__c = srRec.Name;
                }       
            }
        }
    }
}