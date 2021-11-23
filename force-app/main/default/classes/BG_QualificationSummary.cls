/****************************************************************************************
Author:        Jansi
Company:        CRMIT Solutions
Description:   The qualification readonly summary class
History:
-----------------------------------------------------------------------------------------
20.02.2020      Jansi (CRMIT Solutions)            	Test class created
20.05.2021      Seth.heang@auspost.com.au           STP-5556 Add a query to retrieve the opportunity stage from qualification if it's been closed and passed back to Aura component
09.06.2021      Dheeraj.mandavilli@auspost.com.au   STP-4030 Added Opportunity.Was_Created_From_Lead__c field in the qualification query.
*****************************************************************************************/
public class BG_QualificationSummary {

    @AuraEnabled
    public static Qualification getQualificationSummaryDetails(String qualId){
        Qualification q = new QualificationWrapper(qualId).qual;
        return new QualificationWrapper(qualId).qual;
    }
    
    public class QualificationWrapper{
        @AuraEnabled public String qualId {get; set;} 
        @AuraEnabled public Qualification qual {get; set;} 
        QualificationWrapper(String qualId){
            this.qualId = qualId;
            Qualification__c qualObj = new BG_QualificationSummary().getQualification(qualId);
            if(qualObj != null){
                this.qual = new Qualification(qualObj);
            }
        }
    }
    
    public class Qualification{
        
        @AuraEnabled public String leadId {get; set;}
        @AuraEnabled public String oppId {get; set;}
        @AuraEnabled public Decimal totalEsimate {get; set;}
        @AuraEnabled public String notes {get; set;}
        @AuraEnabled public String primaryProduct {get; set;}
        @AuraEnabled public List<QualificationCategory> qualifCatList {get; set;}
        @AuraEnabled public DateTime createdDate {get; set;}
        @AuraEnabled public boolean oppIsClosed {get; set;}
        @AuraEnabled public boolean oppfromLead {get; set;}
        
        Qualification(Qualification__c qualObj){
            this.notes = qualObj.Notes__c;
            this.totalEsimate = qualObj.Total_Estimate__c;
            this.primaryProduct = qualObj.Primary_Product__c;
            this.createdDate = qualObj.createdDate;
            this.oppfromLead = qualObj.Opportunity__r.Was_Created_From_Lead__c;
            
            this.qualifCatList = new List<QualificationCategory> ();
            
            List<Qualification_Category_Detail__c> qcdList= new BG_QualificationSummary().getQCDList(qualObj.Id);
            
            for(Qualification_Category_Detail__c qcd :qcdList){
                this.qualifCatList.add(new QualificationCategory(qcd));
            }
            this.oppIsClosed = new BG_QualificationSummary().isOpportunityClosed(qualObj.Id);
        }
    }
    
    public class QualificationCategory{
        
        @AuraEnabled public String category{get; set;}
        @AuraEnabled public String categoryName{get; set;}
        @AuraEnabled public Decimal estimate {get; set;}
        @AuraEnabled public String notes {get; set;}
        @AuraEnabled public List<CategoryResponseDetails> catResList {get; set;}
        
        QualificationCategory(Qualification_Category_Detail__c qcd){
            this.category = qcd.Selected_Category__c;
            this.categoryName= qcd.Selected_Category__c;
            this.notes = qcd.Notes__c;
            this.estimate = qcd.Category_Estimate__c;
            this.catResList = new List<CategoryResponseDetails>();
            
            List<Qualification_Response_Detail__c> qrdList = new BG_QualificationSummary().getQRDList(qcd.Id);
            
            for(Qualification_Response_Detail__c QRCObj:qrdList)
                catResList.add(new CategoryResponseDetails(QRCObj) );
        }
    }
    
    
    
    public class CategoryResponseDetails{
        
        @AuraEnabled public String question {get; set;}
        @AuraEnabled public String response {get; set;}
        @AuraEnabled public String uniqueKey {get; set;}
        
        CategoryResponseDetails(Qualification_Response_Detail__c QRCObj){
            this.question = QRCObj.Question__c;
            if(QRCObj.Response__c != null){
                this.response = QRCObj.Response__c;
            }else if(QRCObj.Response_Number__c != null){
                this.response = String.valueOf(QRCObj.Response_Number__c);
            }else if(QRCObj.Response_Date__c != null){
                this.response = String.valueOf(QRCObj.Response_Date__c);
            }else if(QRCObj.Response_Multiline__c != null){
                this.response = String.valueOf(QRCObj.Response_Multiline__c);
            }else if(QRCObj.Response_Percent__c != null){
                this.response = String.valueOf(QRCObj.Response_Percent__c);
            }else if(QRCObj.Postcode_Mapping__c != null){
                this.response = String.valueOf(QRCObj.Postcode_Mapping__r.Name);
            }
            
        }
    }
    
    @AuraEnabled
    public static Qualification getQualificationDetails(String qualId) {
        return new QualificationWrapper(qualId).qual;
    }
    private Qualification__c getQualification(String qualId){
        return [SELECT Id,  Primary_Product__c, Notes__c, Total_Estimate__c, createdDate,Opportunity__r.Was_Created_From_Lead__c FROM Qualification__c WHERE Id=:qualId LIMIT 1];
    }
    private List<Qualification_Category_Detail__c> getQCDList(String qualId){
        return [SELECT Id,  Notes__c, Selected_Category__c,Category_Estimate__c FROM Qualification_Category_Detail__c WHERE Qualification__c=:qualId ];
        
    }
    private List<Qualification_Response_Detail__c> getQRDList(String qcdId){
        return [SELECT Id,  Question__c, Response__c, Response_Number__c,Response_Date__c,Response_Percent__c,Response_Multiline__c,Postcode_Mapping__c,Postcode_Mapping__r.Name FROM Qualification_Response_Detail__c WHERE Qualification_Category_Detail__c=:qcdId ];
        
    }

    /**
     * @description     Check the opportunity record associated to the Qualification record if the opportunity stage is already Closed
     * @param           String ID of Qualification__c
     * @return          Boolean TRUE or FALSE
     *
     */
    private Boolean isOpportunityClosed(String qualId){
        List<Qualification__c> qualWithClosedOpp = [SELECT Id, Opportunity__r.StageName FROM Qualification__c WHERE Id=:qualId AND Opportunity__r.StageName LIKE '%Close%' LIMIT 1];
        // Associated Opportunity is already closed
        if(!qualWithClosedOpp.isEmpty()){
            return true;
        }else{
            // Associated Opportunity is still pending work OR there is NO Associated Opportunity
            return false;
        }
    }
    
    
}