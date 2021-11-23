/**************************************************
Type:       Handle display facility detail fieldsets 
Purpose:    return facility details for FacilityDetail.componnet          
History:
--------------------------------------------------
13th.12.2013  Jack.li@bluewolf.com  Created                                            
**************************************************/
public with sharing class FacilityDetail {

    public String Id_Name;
    public Network__c record;
    public boolean displayBusinessHours {get;set;}
    public static final string SOBJECTNAME  = 'Network__c';
    
    //to avoid too many field set describe call limit, create a staic map to keep all fields set in memeory
    static Map<String, Schema.FieldSet> facilityFieldSets {
        get{
            if(facilityFieldSets == null){
                facilityFieldSets = Schema.SObjectType.Network__c.fieldSets.getMap();
            }
            return facilityFieldSets;
        }
    }  
    
    public void setId_Name (String s) {
        Id_Name = s;
    }
    
    public String getId_Name() {
        return Id_Name;
    }

    public List<Schema.FieldSetMember> getFields() {
        List<Schema.FieldSetMember> fieldSets = new List<Schema.FieldSetMember>();
        String keyField = 'Facility_Search_'+Id_Name.split(',')[1];
        if (facilityFieldSets.containsKey(keyField)) {           
            Schema.FieldSet fs1 = facilityFieldSets.get(keyField);
            fieldSets = fs1.getFields();  
			
	        for(Schema.FieldSetMember f : fieldSets) {
	            if(f.getFieldPath()=='Display_Business_Hours__c'){
	                displayBusinessHours=true;
	            }
	        }			
        }

        return fieldSets;        
    }
        
    /* public void getRecord(){
        for(Schema.FieldSetMember f : this.getFields()) {
            if(f.getFieldPath()=='Display_Business_Hours__c'){
                displayBusinessHours=true;
            }
        }
    }*/
}