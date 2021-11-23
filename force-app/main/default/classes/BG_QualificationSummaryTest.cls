/****************************************************************************************
Author:        Jansi
Company:        CRMIT Solutions
Description:    Test class to cover  BG_QualificationSummary functionality
History:
-----------------------------------------------------------------------------------------
06.03.2020      Jansi (CRMIT Solutions)            Test class created
30.06.2021		Seth.heang@auspost.com.au		   Fix Validation Rule Error & Increase Code Coverage
*****************************************************************************************/
@isTest
public class BG_QualificationSummaryTest {
    @testSetup
    static void setupTestData() {
        
        //-- Insert Qualification_Template_Questions__c
        Qualification_Template_Questions__c qta = new Qualification_Template_Questions__c();
        qta.Category__c='Discovery';
        qta.Datatype__c='Text Field';
        qta.Order__c = 20;
        qta.Question_Text__c='Test Question1?';
        qta.Required__c = false;
        qta.Active__c = true;
        insert qta;
        
        //-- Insert Lead
        Lead l = new Lead();
        l.FirstName ='fn';
        l.LastName = 'ln';
        l.Email = 'test@test.com';
        l.phone = '0303123456';
        //l.Status = 'In progress';
        l.Company = 'org';
        insert l;
        
        //-- Insert Qualification__c
        Qualification__c q = new Qualification__c();
        q.Lead__c =l.Id;
        q.Total_Estimate__c = 20;
        q.Primary_Product__c ='Startrack';
        insert q;
        
        //-- Insert Qualification_Category_Detail__c
        Qualification_Category_Detail__c qcd = new Qualification_Category_Detail__c();
        qcd.Qualification__c = q.id;
        qcd.Selected_Category__c ='Discovery';
        qcd.Category_Estimate__c =20;
        qcd.Notes__c ='notes';
        insert qcd;

        //-- Insert Qualification_Response_Detail__c
        Qualification_Response_Detail__c qrd = new Qualification_Response_Detail__c();
        qrd.Question__c = 'Question 1?';
        qrd.Response__c = 'Answer 1';
        qrd.Qualification_Category_Detail__c = qcd.Id;
        insert qrd;

        Qualification_Response_Detail__c qrd2 = ApplicationTestDataFactory.getQualificationResponseDetail(1, 'Question 2', qcd.Id, false)[0];
        qrd2.Response_Number__c = 500;
        insert qrd2;
        
        Qualification_Response_Detail__c qrd3 = ApplicationTestDataFactory.getQualificationResponseDetail(1, 'Question 3', qcd.Id, false)[0];
        qrd3.Response_Date__c = System.today();
        insert qrd3;
        
        Qualification_Response_Detail__c qrd4 = ApplicationTestDataFactory.getQualificationResponseDetail(1, 'Question 4', qcd.Id, false)[0];
        qrd4.Response_Percent__c = 12;
        insert qrd4;
        
        Qualification_Response_Detail__c qrd5 = ApplicationTestDataFactory.getQualificationResponseDetail(1, 'Question 4', qcd.Id, false)[0];
        qrd5.Response_Multiline__c = 'Multi Line Long Answer';
        insert qrd5;
    }
    /**
	* Test method to get summary of a Qualification 
	* */
    @isTest
    static void getQualificationSummaryDetails() {
        //Boolean isTrue = true;
        Qualification__c q = [SELECT Id,Lead__c from Qualification__c where Primary_Product__c='Startrack'];
        BG_QualificationSummary.Qualification qual = BG_QualificationSummary.getQualificationSummaryDetails(q.Id);
        System.assertEquals('Startrack', qual.primaryProduct, 'Qualification Primary Product is equal');
    }
}