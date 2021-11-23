/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Extension class for StarTrack Send Email page
Inputs:        Case - StandardController
Test Class:    StarTrackSendEmailExt_Test
History
August 26, 2015 - Patrick James Franco - Created
September 1, 2015 - Patrick James Franco - Added toAddress defaulting logic for Tactical Cases
------------------------------------------------------------*/
public with sharing class StarTrackSendEmailExt {

    public StarTrackSendEmailExt(ApexPages.StandardController SC){
        //class no longer used
        /*
        if(!Test.isRunningTest()){
            SC.addFields(new List<String>{'Recent_Caller_Email__c', 'SuppliedEmail'});
        }

        Case thisCase = (Case) SC.getRecord();
        toAddress = '';

        Id salesEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        Id tacticalId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('StarTrack Business Solutions Communications').getRecordTypeId();

        if(thisCase.RecordTypeId.equals(salesEnquiryId) && String.isNotBlank(thisCase.Recent_Caller_Email__c)){
            toAddress = thisCase.Recent_Caller_Email__c;
        }

        if(thisCase.RecordTypeId.equals(tacticalId) && String.isNotBlank(thisCase.SuppliedEmail)){
            toAddress = thisCase.SuppliedEmail;
        }*/
    }
}