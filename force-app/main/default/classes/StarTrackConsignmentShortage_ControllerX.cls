global class StarTrackConsignmentShortage_ControllerX {
    
    public Case caseRecord;
    public Boolean buttonHit {get; set;}
    
    public StarTrackConsignmentShortage_ControllerX(){
        buttonHit = false;
    }
    
    public void setCaseRecord (Case caseRec) {
        caseRecord = [SELECT Enquiry_Type__c, Value_of_Goods__c, OwnerId, Approval_Status__c, Tier__c, Consignment_Shortage__c, Case_Age_Total_Hours__c FROM Case WHERE Id = :caseRec.Id];
    }
    
    public Case getCaseRecord() {
        return caseRecord;
    } 
    
    public void searchUpdatedCase(){
        if(caseRecord.Enquiry_Type__c == 'Shortage'){
            caseRecord = [SELECT Enquiry_Type__c, Value_of_Goods__c, OwnerId, Approval_Status__c, Tier__c, Consignment_Shortage__c, Case_Age_Total_Hours__c FROM Case WHERE Id = :caseRecord.Id];
        } else{
            buttonHit = true;
        }
    }
    
    @RemoteAction
    global static Case refreshCase(String recordId) {
        return [SELECT Enquiry_Type__c, Value_of_Goods__c, OwnerId, Approval_Status__c, Tier__c, Consignment_Shortage__c, Case_Age_Total_Hours__c FROM Case WHERE Id = :recordId];
    }
    
}