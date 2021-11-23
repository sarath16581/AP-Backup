/**************************************************
Type:       Wrapper Class 
Purpose:    Used by CaseDetailCaseContExt controller.
            Used inorder to support re-labelling & ability to use fieldSetMember parameters on VF page  
History:
--------------------------------------------------
Dec-2013:  shruthi.kunchinadka@bluewolf.com  Created                                            
**************************************************/
public class FieldSetMemberWrapper {
    public Schema.FieldSetMember fieldSetMem {get; set;}
    public String myLabel {get; set;}
    public Boolean required {get; set;}
    public Boolean dbRequired {get; set;}
    
    public FieldSetMemberWrapper(String label, Schema.FieldSetMember mem) {
        myLabel=label;
        fieldSetMem = mem;
        required = mem.getRequired();
        dbRequired = mem.getDBRequired();
    }
}