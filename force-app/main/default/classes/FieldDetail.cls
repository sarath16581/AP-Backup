/**************************************************
Type:       Wrapper Class 
Purpose:    Used by TestCaseDetailExt controller.
            Used inorder to support re-labelling & ability to use field parameters on VF page  
History:
--------------------------------------------------
Feb-2014:  shruthi.kunchinadka@bluewolf.com  Created                                            
2021-09-15	seth.heang@auspost.com.au	Uplift SF API version to 52
**************************************************/
public class FieldDetail {
    public String myLabel {get; set;}
    public String myName {get; set;}
    public Boolean required {get; set;}
    public Boolean dbRequired {get; set;}
    public String myType {get; set;}
    public Boolean isEditable {get; set;}
    public boolean isDynamicDisplay {get;set;}
    public string groupTag {get;set;}
    
    public FieldDetail(String label, String behavior, Schema.DescribeFieldResult f) {
        myName = f.getName();
        required = behavior == 'Required';
        system.debug('**behavior'+behavior);
        //isEditable = f.isUpdateable();
        isEditable = behavior != 'Readonly';
        myType = String.valueOf(f.getType());
        myLabel = label;
    }
    
    public FieldDetail(String label, string name, boolean required, string fieldType, boolean isEditable) {
        myName = name;
        this.required = required;
        this.isEditable = isEditable;
        myType = fieldType;
        myLabel = label;
    }
}