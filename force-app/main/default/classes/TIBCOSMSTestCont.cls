public class TIBCOSMSTestCont {
    public String phoneNum {get; set;}
    public String message {get; set;}
    public Boolean showResult {get; set;}
    public String result {get; set;}
    
    public TIBCOSMSTestCont()
    {
        showResult = false;
    }
    
    public PageReference send()
    {
        showResult = true;
        result = TIBCOSMSWrapper.sendSMS(phoneNum, message);        
        return null;
    }
}