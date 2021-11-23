/**************************************************
Description:    Controller for ConsignmentAssignment and CaseConsignmentAssignment page

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public with sharing class ConsignmentAssignmentExt {
    private final Case casObj;
    public string caseID {get; private set;}
    public string caseNumber {get; private set;}
    public string articleTest {get; private set;}
    public String conNote {get; private set;}
    public ConsignmentAssignmentExt(ApexPages.StandardController stdController){
        this.casObj = (case)stdController.getrecord();
        if(casObj != null){
            caseID = this.casObj.id;
            caseNumber = this.casObj.caseNumber;
            articleTest = this.casObj.articletest__c;
        } else{
            caseNumber = null;
            caseID = null;
            articleTest = null;
        }
        string conNoteVal = ApexPages.currentPage().getParameters().get('connote');
        if(conNoteVal == null){
            conNote = null;
        } else {
            conNote = conNoteVal;
        }
    }
}