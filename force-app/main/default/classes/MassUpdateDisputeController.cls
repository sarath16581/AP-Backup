/**
 * Date            Version          Owner               Desription
 * 20-Mar-17        1.0             Adrian R            Initial Version - MassUpdateDisputeController Class
 */
public with sharing class MassUpdateDisputeController {

   private final ApexPages.StandardSetController cntr;
   private final PageReference fromPage;
   private final List<SObject> objs;
   private Map<String, Schema.SObjectField> fieldMap;
   private transient ApexPages.Message currentMsg;
   private final String newLine ='<br></br>';
   private Schema.SObjectField field;
   private String sType;
   private Object convertedFieldData;
   private List<SelectOption> picklistValues;
   private String currentStep;
	
   /* Constructor */
   public MassUpdateDisputeController(ApexPages.StandardSetController controller) {
       
       try{
           currentStep = '1';
           controller.setPageSize(1000);
           cntr = (ApexPages.StandardSetController)controller;
           fromPage = cntr.cancel();
           System.debug('Parameters: ' + ApexPages.CurrentPage().getParameters());
           Id  recordId = (Id)ApexPages.CurrentPage().getParameters().get('id'); 
           System.debug('recordId: ' + recordId);
           System.debug('getSelected: ' + cntr.getSelected().size());
           if (recordId!=null && cntr.getSelected().size()==0) {
               
             //  System.debug('parent type: ' + recordId.getSobjectType());
               
               DescribeSObjectResult result = discoverSObjectType(controller.getRecord());
               System.debug('type: ' + result.getSobjectType());
               
               Map<String, Schema.SObjectField> checkfieldMap = result.fields.getMap();
                
               List<String> keys = sortByFieldLabel(checkfieldMap);
               
               
               for(String key:keys) {
                  Schema.DescribeFieldResult d = checkfieldMap.get(key).getDescribe();
                   
                   if (Schema.DisplayType.REFERENCE == d.getType()) {
                       System.debug('Field type: ' + d.getType());
                       if (d.getReferenceTo().get(0) ==  recordId.getSobjectType()){
                         //  System.debug('Reference object type: ' + d.getReferenceTo());
                         //  System.debug('Reference Field Name: ' + d.getName());
                          // String query = 'SELECT Name,Account.Name,CloseDate, Amount, Owner.Name FROM Opportunity where ' +d.getName()+'=\''+Id.valueOf(recordId)+'\'';
                           String query = generateQuery(result.getSobjectType(), d.getName(), recordId);
                           System.debug('ID: ' + query);
                           List<sObject> sobjList = Database.query(query);
          
                           cntr.setSelected(sobjList);
                       }
                   }
               }
    
           }    
               
           
           
           if (this.objs == null) {
      
               if (cntr.getSelected().size()==0 && recordId==null) {     
                  cntr.setSelected(cntr.getRecords());
                  System.debug('getSelected: ' + cntr.getSelected().size());
               }
    
               this.objs = (List<SObject>)cntr.getSelected();   
           }
           if (getRecordSize()<1) {
                String msg = 'No record was selected on the list view.  Please click Previous button and select records for mass update.'; 
                currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, msg);
           } else {
                sType= discoverSObjectType(objs.get(0)).getName(); 
                String msg = 'Number of records selected for update: ' + getRecordSize(); 
                currentMsg = new ApexPages.Message(ApexPages.severity.INFO, msg);
           }
           ApexPages.addMessage(currentMsg);
       }catch(Exception e){
           currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a record.');
           ApexPages.addMessage(currentMsg);
       }   
   }
    
    /* Method to generate Query based on Object */
    public String generateQuery(Schema.SObjectType objType, String parentReference, String parentId){
        
        String query = '';
        if (objType == Case.getSObjectType()){            
            query = 'SELECT Subject,CaseNumber,Account.Name, Status, Owner.Name FROM Case ';
        }
        /*if (objType == Opportunity.getSObjectType()){
            
            query = 'SELECT Name,Account.Name,CloseDate, Amount, Owner.Name FROM Opportunity ';
        }
        else if (objType == Contact.getSObjectType()){
            
            query = 'SELECT Name,Email,Account.Name, Title, Owner.Name FROM Contact ';
        }
        else if (objType == Asset.getSObjectType()) {
            
            query = 'SELECT Name,Product2.Name,InstallDate, Status, Quantity FROM Asset ';
        }
        else if (objType == Case.getSObjectType()){
            
            query = 'SELECT Subject,CaseNumber,Account.Name, Status, Owner.Name FROM Case ';
        }
        else if (objType == Campaign.getSObjectType()) {
            
            query = 'SELECT Name,StartDate,Type, Status, Owner.Name FROM Campaign ';
        }
        else if (objType == Lead.getSObjectType()) {
            
            query = 'SELECT Name,Email,Company, LeadSource FROM Lead ';
        }
        else if (objType == Product2.getSObjectType()) {
            
            query = 'SELECT Name,IsActive,Family, ProductCode FROM Product2 ';
        }*/
        
        query = query + 'where '+ parentReference+'=\''+Id.valueOf(parentId)+'\'';
        return query;
    }
	
    /* Getter Method */
	public String getStep() {
		return currentStep;
	}
	
    /* Getter Method */
	public String getsType() {
		return sType;
	}	   
    
    /* Getter Method */
   	public integer getRecordSize() {
     if (objs!=null) {
        return objs.size();
     } else {
        return 0;
     }
    }
    
    /* Getter and Setter Methods */
    public String filterId {
        get;
        set;    
    }
    
    /* Getter Method */
    public String getNow(Boolean bShowTime) {
        DateTime now = DateTime.now();
        if (bShowTime)
            return  now.year() + '-' + now.month()+ '-' + now.day()+' '+now.hour()+ ':' +now.minute() + ':' + now.second();
        else
            return  now.year() + '-' + now.month()+ '-' + now.day();
    }
    
    /* Getter and Setter methods to get a list of all SObjects to update */
    public List<SObject> objsToUpdate {
        get {
            return (List<SObject>) cntr.getSelected();
        }
        set;
    }
    
    /* Getter and Setter Methods */
    public String valueToUpdate {
        get;
        set;    
    }
    
    /* Getter and Setter Methods */
    public String fieldName {
        get;
        set {
            fieldName=value;
            field = fieldMap.get(value);
            if (field!=null){   
                Schema.DescribeFieldResult d = field.getDescribe();
                fieldType = d.getType().name();
                
                if (d.getType()==DisplayType.Picklist){    
                    picklistValues = new List<SelectOption>();      
                    if (d.isNillable()) {
                        picklistValues.add(new SelectOption('Please Select', '--None--'));
                    }
                    for (Schema.PicklistEntry p : d.getPickListValues()) {
                        picklistValues.add(new SelectOption(p.getValue(), p.getLabel()));
                    }
                }                   
            }
            
        }
    }
    
    /* Getter and Setter Methods */
    public String fieldType{
        get;
        set;    
    }
    
    /* Getter and Setter Methods */
    public String displayTexField{
        get{

            if (fieldType=='CURRENCY'|| fieldType=='DATE' || fieldType=='DATETIME'
                 ||fieldType=='TEXT' ||fieldType=='NUMBER'||fieldType=='COMBOBOX'
                   ||fieldType=='DOUBLE'||fieldType=='EMAIL'||fieldType=='ID'
                    ||fieldType=='ID'||fieldType=='INTEGER'||fieldType=='PERCENT'||fieldType=='MULTIPICKLIST'
                ||fieldType=='PHONE'||fieldType=='STRING'||fieldType=='REFERENCE'||fieldType=='BASE64') {
                    return 'true';
                }
            return 'false';  
        }
        set;
    }
    
    /* Getter and Setter Methods */
    public String displayTextArea{
        get{
            if (fieldType=='TEXTAREA'){
                return 'true';
            }
            return 'false';
        }
        set;
    }
    
    /* Getter and Setter Methods */
    public String displayCheckBox{
        get{
            if (fieldType=='BOOLEAN'){
                return 'true';
            }
            return 'false';
        }
        set;
    }
    
    /* Getter and Setter Methods */
    public String displayPicklist{
        get{
            if (fieldType=='PICKLIST'){
                return 'true';
            }
            return 'false';
        }
        set;
        
    }
    
    /* Getter and Setter Methods */
    public List<String> confirmationMessage{
        
        get;
        set;
    }
    
    /* Getter and Setter Methods */
    public String resultMessage{
        get;
        set;
        
    }
	
	/* Method for coverting the input to the field data type */    
    private Object convertUserInputToFieldData(){
        if (field==null) return null;
        DisplayType t = field.getDescribe().getType();
        Object s = null;
        
        try {       
                if (t==DisplayType.Double||t==DisplayType.Currency || t==DisplayType.Integer || t==DisplayType.Percent){
                    s = decimal.valueOf((String)valueToupdate);         
                } else if (t==DisplayType.Boolean){                 
                    if (valueToUpdate=='true'){
                        s = true;               
                    } else if (valueToUpdate=='false'){
                        s = false;              
                    } else {
                        s = Boolean.valueOf(valueToUpdate);
                    }
                } else if (t==DisplayType.Date) {
                    s = Date.valueOf(valueToUpdate);
                } else if (t==DisplayType.DateTime) {
                    s = DateTime.valueOf(valueToUpdate);
                } else if ((t==DisplayType.PickList || t==DisplayType.PickList) && valueToUpdate==null) {
                    s = '';
                }else {
                    s = valueToupdate;
                }
        } catch (System.TypeException e){
            System.debug('Type exception: ' + e.getMessage());
            currentMsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage());
            return null;
        }  
        
        return s;
    }
    
    /* Display the Field Info */
    public String getFieldInfoToDisplay() {
        if (field==null) 
            field = fieldMap.get('Name');
            //return '';
       // String msg = 'Field type of selected field: ' + fieldType + newline;
        String msg = 'Field type of selected field: ' + fieldType + ' ';
        Schema.DescribeFieldResult d = field.getDescribe();
        
        if (d.getType()==DisplayType.TextArea || d.getType()==(DisplayType.String)||d.getType()==(DisplayType.URL)) {
            msg += 'Max lengh: ' + d.getLength();
            valueToUpdate='';
        } else if (d.getType()==DisplayType.DateTime ){
            msg += 'Format: yyyy-MM-dd HH:mm:ss';
            valueToUpdate=getNow(true);
        } else if (d.getType()==DisplayType.Date){
            msg += 'Format: yyyy-MM-dd';
            valueToUpdate=getNow(false);
        } else if (d.getType()==DisplayType.Picklist){
            
            picklistValues = new List<SelectOption>();      
            if (d.isNillable()) {
                picklistValues.add(new SelectOption('Please Select', '--None--'));
            }
            for (Schema.PicklistEntry p : d.getPickListValues()) {
                picklistValues.add(new SelectOption(p.getValue(), p.getLabel()));
            }
          //  msg += newline + 'Please select a picklist value';
        } else if (d.getType()==DisplayType.MultiPicklist){
            
            msg += 'Valid Picklist Values: ';
            String combined ='';
            
            for (Schema.PicklistEntry p : d.getPickListValues()) {
                msg += newLine + '&nbsp;&nbsp;&nbsp;&nbsp;<b>' +p.getValue()+'</b>';
                combined += p.getValue()+';';
            }
            msg += newline + 'Use ; to seperate each picklist value you want to select';
            msg += newline + 'For example, to select all the picklist values, enter <b>' + combined + '</b> in the textbox below to select all picklist values';
        } else if (d.getType()==DisplayType.Integer){
            msg += 'Max digits: ' + d.getDigits();
        } else if (d.getType()==DisplayType.String){
            msg += 'Max length: ' + d.getLength();
        } else if (d.getType()==DisplayType.Double || d.getType()==DisplayType.Currency || d.getType()==DisplayType.Percent){
            msg += 'Format: (' + (d.getPrecision()-d.getScale()) + ','+d.getScale() +')';
        } else if (d.getType()==DisplayType.Reference){
            msg += 'Use this to change selected records to reference a different record, or even dereference records if the filed is left blank. ';
            msg += 'Please enter ' + d.getName() + ' that the selected records should reference to';
        }
        
        return msg;
    }
    
    /* Method to return to the Source Page */   
    public PageReference cancel() {
        return fromPage;
    }
	
    /* Method to return Current Page */
    public PageReference step1() { 
    	currentStep='1';   	     
        return ApexPages.currentPage();
    }
    
    /* Method to assign the Step */
    public void lexstep1() { 
    	currentStep='1';   	     
      //  return ApexPages.currentPage();
    }
    
    /* Method to assign the Step */
    public PageReference step2() {
        if(getRecordSize()<1) return fromPage;      
    	currentStep='2';   	     
        system.debug('currentStep: ' + currentStep);
        return ApexPages.currentPage();
    }
     
    /* Method to assign the Step */
     public void lexstep2() {
       // if(getRecordSize()<1) return fromPage;      
    	currentStep='2';   	     
        system.debug('currentStep: ' + currentStep);
       // return ApexPages.currentPage();
    }
    
    /* Method to assign the Step */
    public PageReference step3() {
        currentMsg = new ApexPages.Message(ApexPages.severity.INFO, getFieldInfoToDisplay());
        ApexPages.addMessage(currentMsg);
        currentStep='3';   	     
        return ApexPages.currentPage();
    }
    
    /* Method to assign the Step */
    public void lexstep3() {
        if (fieldName!='Please Select') {
            
           currentStep='3';   
        } 
    } 
    
    /* Method to assign the Step */
    public PageReference step4() {
        convertedFieldData = convertUserInputToFieldData();
        
        // data type validation
        if (currentMsg!=null) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.INFO, getFieldInfoToDisplay());
            ApexPages.addMessage(msg);
            ApexPages.addMessage(currentMsg);
            return ApexPages.currentPage();
        }
        
        String msg = 'Please review your selections before confirm: /n'; 
        msg = msg + '<br><b>Records Selected:</b>    ' + getRecordSize() +'/n';
        msg = msg + '<br><b>Field To Be Updated:</b> ' + fieldName + '</br>';
        msg = msg + '<br><b>New Value:</b>           ' + convertedFieldData + '</br>';
        currentMsg = new ApexPages.Message(ApexPages.severity.INFO, msg);
        ApexPages.addMessage(currentMsg);
        currentStep='4';   	     
        return ApexPages.currentPage();
    } 
    
    /* Method to assign the Step */
    public void lexstep4() {
        convertedFieldData = convertUserInputToFieldData();

        List<String> msgs = new List<String>();
        msgs.add('Records Selected: ' + getRecordSize());
        msgs.add('Field To Be Updated: ' + fieldName);
        msgs.add('New Value: ' + convertedFieldData);
        confirmationMessage = msgs;
        currentStep='4';
    } 
    
    /* Method to assign the Step */
    public PageReference step5() {
        currentMsg = (new MassUpdater(objs, field, convertedFieldData)).massUpdate();
        ApexPages.addMessage(currentMsg);
        currentStep='5';   	     
        return ApexPages.currentPage();
    }
    
    /* Method to assign the Step */
    public void lexstep5() {
        currentMsg = (new MassUpdater(objs, field, convertedFieldData)).massUpdate();
       // ApexPages.addMessage(currentMsg);
        resultMessage = currentMsg.getSummary();
        currentStep='5';   	     
    }
    
    /* Method to get the type of SObject */
    public DescribeSObjectResult discoverSObjectType(SObject s) {
        Map<String, Schema.SObjectType> des = Schema.getGlobalDescribe();
        
        for(Schema.SObjectType o:des.values()) {
            if( s.getSObjectType()==o) {
                return o.getDescribe();
            }     
        }
        return null;
    }
    
    /* Method to get list of field types */
    public List<SelectOption> getFieldTypeOptions() {
        // prevent url hacking
        if (objs.size()<1) return null;
        
        List<SelectOption> options = new List<SelectOption>();      
        options.add(new SelectOption('Please Select','--None--'));
                
        Schema.DescribeSObjectResult sObj = discoverSObjectType(objs.get(0));
        
        fieldMap = sObj.fields.getMap();
        
        List<String> keys = sortByFieldLabel(fieldMap);
        
        for(String key:keys) {
            Schema.DescribeFieldResult d = fieldMap.get(key).getDescribe();

            if(d.isAccessible() && d.isUpdateable()) {
                if (isSupportedFieldType(d)) {
                    String label = d.getLabel();
                    if(d.isCustom()) label += ' (' + key +  ')';
                    options.add(new SelectOption(key, label));
                }
            }
        }
        return options;
    }
    
    /* Method to get list sorted according to the field labels */
    private List<String> sortByFieldLabel(Map<String, Schema.SObjectField> gd) {
        List<String> keys = new List<String>();
        
        Map<String, List<String>> labelMap = new Map<String, List<String>>();
        
        for(Schema.SObjectField s:gd.values()) {
            String label = s.getDescribe().getLabel();
            if(labelMap.get(label) == null) {
                labelMap.put(label, new List<String>());
            }
            
            labelMap.get(label).add(s.getDescribe().getName());        
        }
        
        List<String> labels = new List<String>(labelMap.keySet());
        labels.sort();
        
        for(String label:labels){
            keys.addAll(labelMap.get(label));
        }
        
        return keys;
    }
    
    /* Method to get the relevant picklist options */
    public List<SelectOption> getPicklistValues() {
        return picklistValues;
    }
    
    /* Method to check if the field type is supported or not */
    private boolean isSupportedFieldType(DescribeFieldResult d) {
        // always return true for now, but in future some fields might not be supported
        return true;
    }
}