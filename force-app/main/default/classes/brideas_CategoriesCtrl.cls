public with sharing class brideas_CategoriesCtrl {
    public brideas_Category__c[] records { get; private set; }
    public List<SelectOption> categoryOptions { get; private set; }
    public String rId { get; set; }
    public String formName { get; set; }
    public String formDescription { get; set; }

    public brideas_CategoriesCtrl(){
        categoryOptions = new List<SelectOption>();
        Schema.DescribeFieldResult categoriesFieldDescribe = Schema.Idea.Categories.getDescribe();
        List<Schema.PicklistEntry> picklistValues = categoriesFieldDescribe.getPicklistValues();
        List<brideas_Category__c> existedList = new List<brideas_Category__c>([SELECT Name FROM brideas_Category__c]);
        Set<String> existedNames = new Set<String>();

        for (brideas_Category__c existedItem : existedList) {
            existedNames.add(existedItem.Name);
        }

        for (Schema.PicklistEntry picklistItem : picklistValues) {
            if (!existedNames.contains(picklistItem.getValue())) {
                categoryOptions.add(new SelectOption(picklistItem.getValue(), picklistItem.getLabel()));
            }
        }

        this.loadRecords();
    }

    public PageReference edit() {
        return null;
    }

    public PageReference remove() {
        if (!Schema.sObjectType.brideas_Category__c.isDeletable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You do not have permissions'));
            return null;
        }

        try {
            brideas_Category__c categoryItem = [SELECT Id FROM brideas_Category__c WHERE Id = :rId];

            delete categoryItem;

            this.loadRecords();

        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage() + ' (recordId:' + rId + ')'));
        }

        return null;
    }

    public PageReference save() {
        brideas_Category__c categoryItem;

        try {
            categoryItem = [SELECT Description__c FROM brideas_Category__c WHERE Name = :formName LIMIT 1];

            if (Schema.sObjectType.brideas_Category__c.fields.Description__c.isUpdateable()) {
                categoryItem.Description__c = formDescription;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You do not have permissions to update categories field'));
                return null;
            }
        } catch (Exception ex) {
            if (!Schema.sObjectType.brideas_Category__c.isCreateable()
                    || !Schema.sObjectType.brideas_Category__c.fields.Name.isUpdateable()
                    || !Schema.sObjectType.brideas_Category__c.fields.Description__c.isUpdateable()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You do not have permissions to create records'));
                return null;
            }

            categoryItem = new brideas_Category__c(Name = formName, Description__c = formDescription);
        }

        upsert categoryItem;

        return ApexPages.currentPage().setRedirect(TRUE);
    }

    @AuraEnabled
    public static brideas_Category__c getCategoryItem(String categoryName){
        brideas_Category__c item;

        try {
            item = [SELECT Name, Description__c FROM brideas_Category__c WHERE Name = :categoryName LIMIT 1];
        } catch (Exception ex) {
            return null;
        }

        return item;
    }

    @AuraEnabled
    public static String getFeaturedCategory(){
        return brideas_Helper.getConfigValue('featured_category');
    }
    
    /*Below code is added on 16-08-2018 to retrieve featured category image url 
      and render the image on Ideas List page as part of Communities changes.*/
    @AuraEnabled
    public static String getFeaturedCategoryImageUrl(){
        return brideas_Helper.getConfigValue('featured_category_image_URL');
    }

    private void loadRecords(){
        if (!Schema.sObjectType.brideas_Category__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You do not have permissions'));
            return;
        }

        records = [SELECT Name, Description__c FROM brideas_Category__c ORDER BY Name ASC LIMIT 1000];
    }
}