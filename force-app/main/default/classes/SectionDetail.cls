/**************************************************
Type:       Wrapper Class 
Purpose:    Used by CaseDetailsCaseContExt controller.
            Used inorder to still support the original ordering of layoutSections  
History:
--------------------------------------------------
Mar-2014:  shruthi.kunchinadka@bluewolf.com  Created
2021-09-15	seth.heang@auspost.com.au	Uplift SF API version to 52
**************************************************/
public class SectionDetail {
	public String myLabel {get; set;}
	public List<FieldDetail> fieldDetails {get; set;}
	public boolean isDynamicDisplay {get;set;}
	public string groupTag {get;set;}
	public string groupName {get;set;}
	public integer index {get;set;}
	public string indexAsString {get{return string.valueOf(index);}}
	
	private SectionDetail(){
		
	}
	
	public SectionDetail(String sectionLabel, List<FieldDetail> fieldList) {
		index = 0;
		fieldDetails = fieldList;
		system.debug('@@ section label = ' + sectionLabel);
		List<string> parts = sectionLabel.split(':', 0);
        isDynamicDisplay = parts.size() > 1;
        if(isDynamicDisplay){
       		myLabel = parts[1];
       		groupName = parts[0];
       		groupTag = groupName.replaceAll('[^a-zA-Z0-9]', '');
        } else {
         	myLabel = parts[0];
        }
	}
	
	public SectionDetail close(){
		SectionDetail result = new SectionDetail();
		result.myLabel = this.myLabel;
		result.fieldDetails = this.fieldDetails;
		result.isDynamicDisplay = this.isDynamicDisplay;
		result.groupName = this.groupName;
		result.groupTag = this.groupTag;
		result.index = this.index;
		return result;
	}
}