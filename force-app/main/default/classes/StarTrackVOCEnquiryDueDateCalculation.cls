/**
 ** Description: VOC Enquiry Due Date Calculation
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.13.2016
 ** History:--------------------------------------------
 **         JAN.12.2016 David Catindoy - Created
 **/
public class StarTrackVOCEnquiryDueDateCalculation {

    @InvocableMethod
    public static void VOCEnquiryDueDateCalculation(List<Id> caseIds){
        
        StarTrackUtil.calculateVOCEnquiryDueDate(caseIds);
        
    }
}