/**
* @description       : pdf creation from Credit Assesment record's HTML content(Application_Summary_Content__c)
* @author            : avula.jansirani@auspost.com.au
* @group             : 
* @last modified on  : 05-14-2021
* @last modified by  : ankur.gandhi@auspost.com.au
* Modifications Log 
* Ver   Date         Author                               Modification
* -------------------------------------------------------------------------
* 1.0   21-04-2020  avula.jansirani@auspost.com.au   Initial Version
**/
public class BCASummaryPDF {
    
    public String displayText {get; set;}  // html content
    public String caId{get;set;}            // Credit Assesment record
    public String currentDateTime{get;set;}       // current date to display in pdf footer
    public String caRefNumber{get;set;}
    
    //-- Constructor
    public BCASummaryPDF(){
        
        //-- get Credit assesment Id from URL params
        caId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('caId'));
        System.debug('caId ---> ' + caId);
        
        //-- Query and get Html content from APT_Credit_Assessment__c
        APT_Credit_Assessment__c ca=  CreditsAssessmentSelector.newInstance(1, new Set<SObjectField> {APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.Name, APT_Credit_Assessment__c.Application_Summary_Content__c}).selectById( new Set<Id>{caId}).values()[0];
        if(ca != null){
            displayText = ca.Application_Summary_Content__c;
            caRefNumber = !String.isEmpty(ca.Name) ? ca.Name.replace('Credit Assess - ','') : '';
        }
        
        User currentUser = [Select TimeZoneSidKey from User where id =: USerInfo.getUserId()];
        currentDateTime = DateTime.now().format('dd/MM/yyyy hh:mm a', currentUser.TimeZoneSidKey) ;
    }
    
}