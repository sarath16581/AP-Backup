/*
@Description 		: Utility wrapper class to hold the schema info returned by calling pagelayout API
@Author				: Ramtej Juloori
@Created			: 22/06/2018

================================ Modification Log =============================== 
Developer Name                      Date            Comments
hasantha.liyanage@auspost.com.au    15/05/2019      File upload capability added

*/ 
public with sharing class LayoutAPIRoot {
	@AuraEnabled public List<DetailLayoutSection> detailLayoutSections {get;set;}
    @AuraEnabled public List<DetailLayoutSection> editLayoutSections {get;set;}
    @AuraEnabled public List<layouts> layouts {get;set;}
    public class layouts{
        @AuraEnabled public List<DetailLayoutSection> editLayoutSections {get;set;}
        @AuraEnabled public List<DetailLayoutSection> detailLayoutSections {get;set;}
    }

    public class DetailLayoutSection {
        @AuraEnabled public string heading { get; set; }
        @AuraEnabled public List<LayoutRow> layoutRows { get; set; }
        @AuraEnabled public boolean useHeading {get;set;}
        @AuraEnabled public boolean useCollapsibleSection {get;set;}
    }

    public class Details {
        @AuraEnabled public string label { get; set; }
        @AuraEnabled public string name { get; set; }
        @AuraEnabled public string type { get; set; }
        @AuraEnabled public boolean updateable {get;set;}
        @AuraEnabled public string value { get; set; }
        @AuraEnabled public DateTime dateTimevalue { get; set; }
        @AuraEnabled public Date dateValue { get; set; }
        @AuraEnabled public boolean booleanValue { get; set; }
        @AuraEnabled public decimal decimalValue { get; set; }
        @AuraEnabled public string renderAs {get; set;}
        @AuraEnabled public boolean required {get; set;}
        @AuraEnabled public boolean isEditable {get; set;}
        @AuraEnabled public boolean isCreatable {get; set;}
        @AuraEnabled public List<pickListValue> pickListValues {get; set;}
        @AuraEnabled public string helpText {get; set;}
        @AuraEnabled public boolean useHeading {get;set;}
    }

    public class LayoutComponent {
        @AuraEnabled public Details details { get; set; }
        @AuraEnabled public integer displayLines { get; set; }
        @AuraEnabled public integer tabOrder { get; set; }
        @AuraEnabled public string type { get; set; }
        @AuraEnabled public string suggestedHeight { get; set; }
        @AuraEnabled public string suggestedWidth { get; set; }
        @AuraEnabled public string showScrollbars { get; set; }
        @AuraEnabled public string showLabel { get; set; }
        @AuraEnabled public string url { get; set; }
        @AuraEnabled public string value { get; set; }
        @AuraEnabled public boolean required { get; set; }
    }
    
    public class LayoutRow {
        @AuraEnabled public List<LayoutItem> layoutItems { get; set; }
    }

    public class LayoutItem {
        @AuraEnabled public boolean editable { get; set; }
        @AuraEnabled public string label { get; set; }
        @AuraEnabled public List<LayoutComponent> layoutComponents { get; set; }
        @AuraEnabled public boolean required { get; set; }
    }

    public class pickListValue{
        @AuraEnabled public string label {get; set;}
        @AuraEnabled public string value {get; set;}
        
        public picklistValue(string label, string value){
            this.label = label;
            this.value = value;
        }
    }
}