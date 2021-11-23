/**************************************************
Type:       Wrapper Class 
Purpose:    Used by CaseDetailCaseContExt controller.
            Used inorder to support sorting & ability to use fieldSet parameters on VF page  
History:
--------------------------------------------------
Dec-2013:  shruthi.kunchinadka@bluewolf.com  Created                                            
**************************************************/
public class FieldSetWrapper implements Comparable {
    
    public List<FieldSetMemberWrapper> members {get; set;}
    public String myName {get; set;}
    public String myLabel {get; set;}
    
    public FieldSetWrapper(String label, String name, List<fieldSetMemberWrapper> mem) {
        myName=name;
        myLabel=label;
        members = mem;
    }
    
    public Integer compareTo(Object compareTo) {
        fieldSetWrapper fsWrapper = (FieldSetWrapper) compareTo;
        if (myName == fsWrapper.myName) return 0;
        if (myName > fsWrapper.myName) return 1;
        return -1; 
    }
}