/**
 * @author Hasantha Liyanage
 * @date 2023-07-17
 * @group Controller Extention
 * @tag apex controller
 * @tag Attachments
 * @domain ui
 * @description Handling the resend email functionality based on the custom permission set assigned to user
 * @changelog
 * 2023-07-17 - hasantha.liyanage@auspost.com.au - Created
 */
public with sharing class CompensationResendButtonExtension
{
    public Boolean compensationEmailResendDone {get; set;}
    public String compensationEmailResendResult {get; set;}
    public Boolean isAllowedToCreateCompensation {
        get {
            if(isAllowedToCreateCompensation == null) {
                return true;
            }
            return isAllowedToCreateCompensation;
        }
        private set;
    }
    public static final Boolean isCompensationUser {
        get {
            if(isCompensationUser == null) {
                isCompensationUser = FeatureManagement.checkPermission('Is_Compensation_User');
            }
            return isCompensationUser;
        }
        private set;
    }
    public static final Boolean IsCompensationSupervisor {
        get {
            if(isCompensationSupervisor == null) {
                isCompensationSupervisor = FeatureManagement.checkPermission('Is_Compensation_Supervisor');
            }
            return isCompensationSupervisor;
        }
        private set;
    }

    public CompensationResendButtonExtension(ApexPages.StandardController stdController){
        if(!isCompensationUser && !isCompensationSupervisor) {
            isAllowedToCreateCompensation = false;
        }
    }

    public void resendCompensationEmail()
    {
        String recordId = ApexPages.currentPage().getParameters().get('id');
        
        recordId = String.escapeSingleQuotes(recordId);

        try
        {
            CHAS_CompensationFormController.updateToken(recordId, true, true, true);
            this.compensationEmailResendResult = 'Compensation email has been sent';
        } catch (Exception e)
        {
            this.compensationEmailResendResult = e.getMessage();
        }

        this.compensationEmailResendDone = true;
    }
}