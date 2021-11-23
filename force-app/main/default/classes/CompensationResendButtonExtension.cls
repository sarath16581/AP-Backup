public with sharing class CompensationResendButtonExtension
{
    public Boolean compensationEmailResendDone {get; set;}
    public String compensationEmailResendResult {get; set;}

    public CompensationResendButtonExtension(ApexPages.StandardController stdController){}

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