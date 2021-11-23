/**
 ** Description: VOC Enquiry Calculation
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.12.2016
 ** History:--------------------------------------------
 **         JAN.12.2016 David Catindoy - Created
 **/
public class StarTrackVOCEnquiryCalculation {

    @InvocableMethod
    public static void VOCEnquiryCalculation(List<Id> caseIds){
        
        StarTrackUtil.calculateVOCEnquiry(caseIds);
        
    }
}