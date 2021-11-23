/**************************************************
Type:       Component Controller 
Purpose:    Common Auto Complete text field 
History:
--------------------------------------------------
Aug-2015:  Fahad.Akhtar@cloudsherpas.com  Created
May-2018: Hasantha.Liyanage@auspost.com.au updated class to global access, where we had to make getData remote method  accessible from lightning component(cpVisualforceWrapper)
**************************************************/
global class StarTrack_AutoComplete_Controller {
    
    //lable field for Auto complete drop down
    public String labelFieldVar{ get; set; }
    
    //Value field for Auto complete
    public String valueFieldVar{ get; set; }
    
    //Object name for search    
    public String sObjVal{get;set;}
    
    //Random JS id value
    public Integer randomJsIden{get;set;}
    
    //Cache currently selected value
    public Object cacheField{get;private set;} 
    
    //custom dropdown value field.
    private Object targetFieldVar;

	public StarTrack_AutoComplete_Controller() {
		randomJsIden = getRandomNumber(1000000);
        sObjVal='Account';
        labelFieldVar='Name';
        valueFieldVar='Id';
	}

    /*Dummy setter Method*/
    public void setCacheField(Object cacheField){}
    
    public void setTargetFieldVar(Object targetFieldVar){
        
        if(targetFieldVar != this.targetFieldVar){
            cacheField = getCacheFieldValue(targetFieldVar);
            this.targetFieldVar = targetFieldVar;
        }
    }
    
    public Object getTargetFieldVar(){
        return targetFieldVar;
    }
    
    private Object getCacheFieldValue(Object targetFieldVar){
        Object retVal = targetFieldVar;
        if(targetFieldVar!=null){
            for(sObject sObj : Database.query('SELECT '+valueFieldVar+','+labelFieldVar+' FROM '+sObjVal+' WHERE '+valueFieldVar+' =:targetFieldVar')){
                retVal = sObj.get(valueFieldVar) + ' (' + sObj.get(labelFieldVar) + ')';
                break;
            }
        }
        
        return retVal;
    }

    
    /*
    *Random number generator to change the js function name if multiple components us
    ***/
    private Integer getRandomNumber(Integer size){
        Double d = Math.random() * size;
        return d.intValue();
    }
    
    /*
    *This method queries data according to the passed parameters
    ***/
    @RemoteAction
    global static String getData(String sObjVal,String labelFieldVar,String valueFieldVar,String param){
       
        List<object> AutoCompleteDatas = new List<object>();
        param = String.escapeSingleQuotes(param);
        for( Sobject sObj : Database.query('SELECT ' + valueFieldVar + ',' + labelFieldVar + ' FROM ' + sObjVal + ' WHERE ' + valueFieldVar + ' LIKE \'%'+param+'%\'')){
            AutoCompleteDatas.add(new AutoCompleteData(sObj.get(valueFieldVar), sObj.get(valueFieldVar) + ' (' + sObj.get(labelFieldVar) + ')'));
        }
        return JSON.serialize(AutoCompleteDatas);
    }


    global class AutoCompleteData{
        public String id;
        public String text;
        
        public AutoCompleteData(Object id, Object text){
            this.id = String.valueOf(id);
            this.text = String.valueOf(text);
        }
    }	
}