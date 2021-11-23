/**
  * @author        Urmi Chatterjee
  * @date          08/10/2013
  * @description   Apex Class for filtering ExceptionLog__c records based on its CreatedDate and displaying the same on VFP_ExceptionSearch page. This class also includes the logic for converting the displayed records into Defect__c records, exporting the selected records in the form of CSV and logic for pagination so that the visualforce page does not get overcrowded with the number of records displayed at a time.
  * 
  * This software and all content is the property of ACCENTURE or its licensors, 
  * and is for the internal and confidential use of employees and authorized agents 
  * of ACCENTURE solely for the benefit of ACCENTURE and its affiliates.  
  * The software and contents are protected by copyright, trade secret and patent laws, 
  * and other local and international laws and treaties.  
  * Unauthorized use may subject the user to civil and criminal penalties.  
  * The software contains confidential information of ACCENTURE and its affiliates.  
  * You may not access, use, copy, install, modify, transfer, or distribute this software 
  * (electronically or otherwise), or create any copy, adaptation, transcription, or 
  * derivative thereof, except as expressly authorized by ACCENTURE.  
  * You may not divulge, disclose or communicate to any other third party, any of the 
  * confidential information contained in the software, including the software itself.  
  * ACCENTURE maintains full and exclusive right, title and ownership interest in and 
  * to the software and all copyright, patent, trade secret, trademark and other intellectual 
  * property rights therein.
  *
  */

public with sharing class VFC_ExceptionSearch{    
     
    // Start of Class Variables
    
    public String header {get;set;}
    public boolean checked {get;set;}
    public boolean display {get;set;} 
    public String errorMsg {get;set;}
    public Integer maxRecs {get;set;}
    private Integer startRecIndex;
    private Integer endRecIndex;
    private Datetime sDate;
    private Datetime eDate;    
    private PageReference pgRef;
    
    public ExceptionDisplayWrapper wrapVar {get; set;}
    public List<ExceptionLog__c> exportExceptions {get; set;}
    public List<ExceptionLog__c> selectedExceptions {get;set;}
    public List<ExceptionLog__c> showExceptionList {get;set;}
    
    // End of Class Variables
    
    
    /**
      * @description       Constructor to initialize some of the Class variables.  
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public VFC_ExceptionSearch(){
        selectedExceptions = new List<ExceptionLog__c>() ;
        wrapVar = new ExceptionDisplayWrapper();
        exportExceptions = new List<ExceptionLog__c>();
        showExceptionList = new List<ExceptionLog__c>();
                
        errorMsg = UTIL_ErrorConstants.BLANK_SPACE;
        display = false;     
        checked = false;
           
        // Value of maxRecs variable depends on the requirement of the User 
        maxRecs = Integer.valueOf(PaginationRecords__c.getInstance(UTIL_ErrorConstants.PAGINATION_CUSTOM_SETTING_RECORD).NumberofRecords__c);
        startRecIndex = 0;
        endRecIndex = maxRecs - 1;
        header = UTIL_ErrorConstants.HEADER;        
    }
    
    /**
      * @description       This method queries ExceptionLog__c records based on its CreatedDate being between the Start Date and End Date values obtained from the visualforce page and displays the list on the page.
                           Error message is displayed if:
                           1. Start Date or End Date fields are left empty.
                           2. Start Date is after End Date.
                           3. Start Date is after today.
      * @param             NA
      * @return            void
      * @throws            Exception
      */
    public void search(){          
        errorMsg = UTIL_ErrorConstants.BLANK_SPACE;
        display = false; 
        checked = false;
        try{
            showExceptionList.clear();
            wrapVar.exceptionList.clear();
            wrapVar.exceptionMap.clear();
            wrapVar.selected.clear();
            if((wrapVar.startDate!=null && wrapVar.endDate!=null) && (wrapVar.startDate <= wrapVar.endDate) && (wrapVar.startDate <= Date.Today())){
                sDate = datetime.newInstance(wrapVar.startDate.year(), wrapVar.startDate.month(), wrapVar.startDate.day(),0,0,0);
                eDate = datetime.newInstance(wrapVar.endDate.year(), wrapVar.endDate.month(), wrapVar.endDate.day(),23,59,99);            
                wrapVar.startDate = date.parse(sDate.format(UTIL_ErrorConstants.DATE_FORMAT));
                wrapVar.endDate = date.parse(eDate.format(UTIL_ErrorConstants.DATE_FORMAT));
            
                wrapVar.exceptionList=[Select Id, Name, ClassName__c, MethodName__c, ApexTrigger__c, NumberOfTimesOccured__c, 
                                       ConvertedToDefect__c, Severity__c, ContextUser__c, ExceptionDetails__c, ExceptionType__c, 
                                       ExceptionCode__c, IsHandled__c, Application__c From ExceptionLog__c 
                                       Where CreatedDate>=:sDate AND CreatedDate<=:eDate AND convertedToDefect__c=false LIMIT 50000]; 
                displayResult();                
            }
            else{
                errorMessage();
            }                                             
        }
        catch(Exception excp){
            // Optional Code
            UTIL_LoggingService.logHandledException(excp, UserInfo.getOrganizationId(), UTIL_ErrorConstants.ERROR_APPLICATION, UTIL_ErrorConstants.EXCEPTION_SEARCH_CLASS, 
                                                    UTIL_ErrorConstants.EXCEPTION_SEARCH_METHOD, null, LoggingLevel.ERROR);
            // End of Optional Code
            
            errorMsg = UTIL_ErrorConstants.GENERIC_ERROR_MESSAGE;
        }  
        if(String.isNotBlank(errorMsg)){ 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMsg));      
        } 
    }
    
    
    /**
      * @description       This method is called by the search method to set the ExceptionLog__c records to be displayed on the VFP_ExceptionSearch visualforce page.  
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private void displayResult(){
        if(wrapVar.exceptionList.size()>0){
            for(ExceptionLog__c exc: wrapVar.exceptionList){
                wrapVar.selected.put(exc.Id,false);
                wrapVar.exceptionMap.put(exc.Id,exc); 
            }
            showExceptionList = subsetList(wrapVar.exceptionList, startRecIndex, maxRecs);
            display = true;                    
        } 
    }
    
    
    /**
      * @description       This method is called by the search method to set error message value when search criteria is not met.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private void errorMessage(){
        if(wrapVar.startDate==null || wrapVar.endDate==null){
            errorMsg = UTIL_ErrorConstants.DATE_NULL_ERROR_MESSAGE;             
        }
        else if(wrapVar.startDate > wrapVar.endDate){
            errorMsg = UTIL_ErrorConstants.START_DATE_GREATER_MESSAGE;
        } 
        else if(wrapVar.startDate > Date.Today()){
            errorMsg = UTIL_ErrorConstants.START_DATE_AFTER_TODAY_MESSAGE;
        }  
    }
    
    
    /**
      * @description       This method calls the visualforce page VFP_ExportToCSV to export the Selected Exceptions from the page into a CSV file.  
      * @param             NA
      * @return            pageReference
      * @throws            NA
      */
    public pageReference convertToCSV(){                       
        List<ExceptionLog__c> excpTempList = new List<ExceptionLog__c>();
        exportExceptions = new List<ExceptionLog__c>();
        for(ExceptionLog__c excpVar: wrapVar.exceptionList){
            if(wrapVar.selected.get(excpVar.Id)) {
                exportExceptions.add(excpVar);
                excpTempList.add(excpVar);                
            }
        }
        if(excpTempList.size()==0){
            for(ExceptionLog__c excpVar: wrapVar.exceptionList){
                exportExceptions.add(excpVar);
                excpTempList.add(excpVar);
            }  
        }
        if(exportExceptions.size()>1000){
            for(Integer i=0;i<1000;i++){
                exportExceptions.add(excpTempList.get(i));
            }
        }
        pgRef = new PageReference(UTIL_ErrorConstants.CONVERT_TO_CSV_LINK);
        return pgRef;
    }
    
    
    /**
      * @description       This method is called by deleteException method when 'Convert to Defect' button is clicked on from VFP_ExceptionSearch page. This method maps the ExceptionLog__c fields with the Defect__c fields and inserts Defect__c records.  
      * @param             NA
      * @return            List<ExceptionLog__c>
      * @throws            NA
      */
    /*
    private List<ExceptionLog__c> defectConversion(){
        List<Defect__c> defectList= new List<Defect__c>();
        Defect__c defectInst = new Defect__c ();

        for(ExceptionLog__c excpVar: wrapVar.exceptionList){
            if(wrapVar.selected.get(excpVar.Id)) {
                selectedExceptions.add(excpVar);                
            }
        }
        for(ExceptionLog__c con: selectedExceptions) {
            defectInst = new Defect__c ();
            defectInst.Detailed_Description__c = con.ExceptionDetails__c;
            defectInst.Subject__c = con.Name;
            defectInst.Defect_Type__c = UTIL_ErrorConstants.DEFECT;
            defectInst.Developer_Assigned__c = con.ContextUser__c;
            defectInst.Reported_By__c = UserInfo.getUserId();
            defectInst.Severity__c = UTIL_ErrorConstants.SEVERITY_LEVEL_FOR_DEFECT;
            defectList.add(defectInst);
        }
        Database.insert(defectList, false);
        return selectedExceptions;
    }
    */
    
    /**
      * @description       This method calls defectConversion method to convert selected ExceptionLog__c records into Defect__c records based on the value of delException variable, it is determined whether the converted EXceptionLog__c record is to be deleted or ConvertedToDefect__c field value for that record is to be set as true.  
      * @param             NA
      * @return            void
      * @throws            Exception
      */
    /*
    public void deleteException(){
       try{
           selectedExceptions = defectConversion();
           if(wrapVar.delException.equalsIgnoreCase(UTIL_ErrorConstants.DELETE_EXCEPTION)){
                //Delete the exception
                Database.DeleteResult[] delExcp = Database.delete(selectedExceptions, false);            
           }
           else if(wrapVar.delException.equalsIgnoreCase(UTIL_ErrorConstants.CONVERT_EXCEPTION)){
                //mark convertedToDefect as true
                for(ExceptionLog__c selExcp: selectedExceptions){
                    selExcp.ConvertedToDefect__c = true;
                }
                Database.SaveResult[] updtList = Database.update(selectedExceptions, false);           
           }
           search();
       }
       catch(Exception excp){
           // Optional Code
           UTIL_LoggingService.logHandledException(excp, UserInfo.getOrganizationId(), UTIL_ErrorConstants.ERROR_APPLICATION, UTIL_ErrorConstants.EXCEPTION_SEARCH_CLASS, 
                                                   UTIL_ErrorConstants.DELETE_EXCEPTION, null, LoggingLevel.ERROR);
           // End of Optional Code
           
           errorMsg = UTIL_ErrorConstants.GENERIC_ERROR_MESSAGE;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMsg));
       }
    }
    */
    
    /**
      * @description       This method restricts the size of the ExceptionLog__c list to the value of the 'count' variable passed to it.  
      * @param             excpList the List of ExceptionLog__c records from search() method
      * @param             startIndex the Integer containing starting position for the list of records to be displayed
      * @param             maxCount the Integer containing the number of records to be displayed
      * @return            List<ExceptionLog__c>
      * @throws            NA
      */
    private List<ExceptionLog__c> subsetList(List<ExceptionLog__c> excpList, Integer startIndex, Integer maxCount){
        List<ExceptionLog__c> returnList = new List<ExceptionLog__c>();
        if(excpList!= null && excpList.size() > 0 && startIndex >= 0 && startIndex <= excpList.size()-1 && maxCount > 0){
            for(Integer i = startIndex; i < excpList.size() && i - startIndex < maxCount; i++){
                returnList.add(excpList.get(i));
            }
        }
        return returnList;
    }
    
    /**
      * @description       This method is called when the commandlink Next is clicked on VFP_ExceptionSearch for the purpose of pagination. It displays the next maxRecs number of ExceptionLog__c records.  
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public void next(){
        if(wrapVar.exceptionList.size()>maxRecs && (((wrapVar.exceptionList.size()-1) - endRecIndex) >0)){
            showExceptionList.clear();
            
            startRecIndex = endRecIndex +1;
            endRecIndex = endRecIndex + maxRecs;            
            
            if (endRecIndex > wrapVar.exceptionList.size()){
                endRecIndex = wrapVar.exceptionList.size() - 1 ;
            }
            showExceptionList = subsetList(wrapVar.exceptionList, startRecIndex,  maxRecs);
        }
        selectAll();       
    }
    
    /**
      * @description       This method is called when the commandlink Previous is clicked on VFP_ExceptionSearch for the purpose of pagination. It displays the previous maxRecs number of ExceptionLog__c records.  
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public void previous(){
        if( startRecIndex > 0){
            showExceptionList.clear();
            endRecIndex = startRecIndex - 1;
            startRecIndex = startRecIndex - maxRecs;
            showExceptionList = subsetList(wrapVar.exceptionList, startRecIndex, maxRecs);
        }
        selectAll();
    }

    
    /**
      * @description       This method is called when the commandlink Previous or Next is clicked on VFP_ExceptionSearch for the purpose of pagination. It determines whether the table header checkbox is to be selected or not.  
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public void selectAll(){
        checked = true;
        for(ExceptionLog__c excpRec: showExceptionList){
            if(!wrapVar.selected.get(excpRec.Id)){
                checked = false;
                break;
            }           
        }
    }
    
    /**
      * @author        Urmi Chatterjee
      * @date          08/10/2013
      * @description   This is a wrapper class to store the search result values of ExceptionLog__c records and other values corresponding to them.
      */
    public class ExceptionDisplayWrapper{
        public List<ExceptionLog__c> exceptionList {get; set;}
        public Map<Id, ExceptionLog__c> exceptionMap {get;set;}
        public Map<Id, Boolean> selected {get; set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public string delException {get;set;}
        
        
        /**
          * @description       Constructor to initialize some of the Wrapper Class variables.  
          * @param             NA
          * @return            void
          * @throws            NA
          */
        public ExceptionDisplayWrapper(){
            delException = UTIL_ErrorConstants.BLANK_SPACE;
            exceptionList = new List<ExceptionLog__c>();
            exceptionMap = new Map<Id, ExceptionLog__c>();
            selected = new Map<Id, Boolean>();
        }        
    }
}