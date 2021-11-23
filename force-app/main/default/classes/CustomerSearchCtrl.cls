public with sharing class CustomerSearchCtrl {
    @AuraEnabled(cacheable=true) 
    public static Decimal getMinLOA() {
        List<LOA_Settings__c> loaSettingsList = LOA_Settings__c.getall().values();
        List<decimal> loaList = new List<decimal>();
        for(LOA_Settings__c loaSetting : loaSettingsList){
            loaList.add(loaSetting.LOA_Value__c);
        }
        if(!loaList.isEmpty()){
            loaList.sort();
            return loaList.get(0);
        }
        return null;
    }
}