/*------------------------------------------------------------  
Author:        Matt Yogaratnam
Company:       Salesforce.com
Description:   Wrapper class of exception objects that can be used to log exception messages in bulk for trigger scenarios
Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
24/03/2014    Matt Yogaratnam    Initial Release
------------------------------------------------------------*/

public class ApplicationLogWrapper {

    public string source {get;set;}
    public string sourceFunction {get;set;}
    public string referenceId {get;set;}
    public string referenceInfo{get;set;}
    public string logMessage {get;set;}
    public string payload {get;set;}
    public Exception ex {get;set;}
    public string debugLevel {get;set;}
    public string logCode {get;set;}
    public long timer {get;set;}
    

}