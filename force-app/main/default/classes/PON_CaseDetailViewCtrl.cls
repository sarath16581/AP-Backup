/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 23/02/2018
  * @description  : Controller Class for Case Print Page
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
    
*******************************  History ************************************************/ 
public class PON_CaseDetailViewCtrl {

    private Id cseId;
    
    /**
      * @description       constructor for the class to setup values
      * @param             ApexPages.StandardController
      * @return            Void
      * @throws            NA
      */  
    public PON_CaseDetailViewCtrl(ApexPages.StandardController controller) {
        cseId = apexpages.currentpage().getparameters().get('ID');
    }

    /**
      * @description       action method for updated the case flag to capture case print
      * @param             NA
      * @return            Void
      * @throws            NA
      */  
    public void updatePrintFlag() {
        if(!String.isBlank(cseId)) {
            database.update(new Case(Id=cseId, Checkbox__c = true));
        }
    }


}