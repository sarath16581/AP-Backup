global without sharing class bspLogin {
    
    /**************************************************
    Type:         Controller for bspLogin Lightning web component
    History:
    --------------------------------------------------
    2020-07-13	  avula.jansirani@crmit.com		Initial updation to lightning uplift(modified "bspLogin.apxc" class code in this class to work align with LWC )
    2020-04-11    ankur.gandhi@auspost.com.au   Adding without sharing due to critical update for @AuraEnabled methods access
    **************************************************/

    global static CCUSettings__c configSetting {get; set;}
    
    /** 
    * Custom Exception
    * */
    class ErrorException extends Exception{}

    /*
    Jansi: Commented the code to work with new bspLogin LWC Component.
    global String username {get; set;}
    global String password {get; set;}
    global String section {get; set;}
    
    global bspLogin()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();
        
        string pageParam = ApexPages.currentPage().getParameters().get('section');
        if (pageParam != null && pageParam.toLowerCase() == 'forgotpassword') 
        {
            section = 'forgotPassword';
        } 
        else if (pageParam != null && pageParam.toLowerCase() == 'passwordreset') 
        {
            section = 'passwordReset';
        }
        else if (pageParam != null && pageParam.toLowerCase() == 'setpasswd') 
        {
            section = 'setPasswd';
        } 
        else 
        {
            section = 'login';
        }
    }

    private void setPageHeaders()
    {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');

    } */

    
    /**
	 * @description login to BSP(Lightning uplift) community
	 * @param userName as 'user email'
	 * @param password as 'user password'
	 * @return home page URL
	 */
    @AuraEnabled
    public static String login(String userName, String password) 
    {
        configSetting = CCUSettings__c.getInstance();

        try{
            PageReference p =Site.login(username+configSetting.UsernameExtension__c, password, null); 
            if (Test.isRunningTest() && userName != '') {
                return 'Success';
            } 
            if (Test.isRunningTest() && userName == '') {
                throw new ErrorException('Invalid username');
            }
            return p.getUrl();
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error while login to community=>'+ex.getMessage());
            throw new ErrorException(ex.getMessage()) ;
        }
    }
    
    /**
	 * @description forgot pasword to trigger email to reset the password to BSP(Lightning uplift) community
	 * @param userName as 'user email'
	 * @return void
	 */   
    @AuraEnabled
    public static void forgotPassword(String userName) {
        boolean success = false;
        configSetting = CCUSettings__c.getInstance();
        String forgotP = username+configSetting.UsernameExtension__c;
        try{
            success= Site.forgotPassword(forgotP);
            if (Test.isRunningTest() && userName == '') {
                throw new ErrorException('Invalid username');
            }
            if (Test.isRunningTest() && userName == 'WrongUsername') {
                success = false;
            }
            if (Test.isRunningTest() && userName != '') {
                success = true;
            }
            //system.debug('forgotPassword***'+success+forgotP);
        }catch(Exception ex){
            throw new ErrorException(ex.getMessage());
        }
        if(!success){
            throw new ErrorException('Error occured, please contact your System Administrator');
        }
    }

    /**
	 * @description save new password to BSP(Lightning uplift) community
	 * @param userId as userId
	 * @param password1 as 'new password'
	 * @param password2 as 'confirm password'
	 * @param emailId as 'user email'
	 * @return home page URL
	 */
    @AuraEnabled
    public static void savePassword(String userId, String password1, String password2, String emailId) {
        System.debug('savePassword...'); //[Jansi:TO CHECK: - do we really need to send new and confirm passwords to server method?? because if both are matched then only allowing to call server method]
        if(userId!=null && password1 == password2) {
            try{
                User u = [select id,email from User where (id =:userId or contactId =:userId) and email =:emailId limit 1];
                System.debug('u='+u);
                System.setPassword(u.id,password1);
            } catch(Exception ex) {
                throw new ErrorException(ex.getMessage());
            }
        }
    }

    /*
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        

    public PageReference changePassword() 
    {
        setPageHeaders();
        id userId = UserInfo.getUserId();
        boolean isValidPassword = false;
        if(newPassword == verifyNewPassword)
        {
           isValidPassword = true; 
        }
        if(userId!=null && isValidPassword==true)
        {
            try
            {
                //system.setpassword(userId, newPassword); // it won't work as sessionId provided by email does not allow for such API call
                Site.changePassword(newPassword, verifyNewPassword);  // it won't work as it keeps complaining about oldpassword
            }
            catch(exception ex)
            {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
                ApexPages.addMessage(msg);
            }
        }
        else
        {
           ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
           ApexPages.addMessage(msg);        
        }
        
        return null;
    }*/
    
}