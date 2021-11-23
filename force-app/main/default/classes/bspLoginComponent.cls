global class bspLoginComponent {
    
    global String username {get; set;}
    global String password {get; set;}
    global String section {get; set;}
    global CCUSettings__c configSetting {get; set;}
    
    global bspLoginComponent()
    {
        //Set header for page rendering and security for IE8
        setPageHeaders();
        system.debug('testingController**');
        configSetting = CCUSettings__c.getInstance();
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

    }

    
    public pageReference login() 
    {
        ApexPages.getMessages().clear();
         setPageHeaders();
         system.debug('testingl**');
        // Once log in is successful, navigate to VF page bspEnquiry
        PageReference p = Site.login(username+configSetting.UsernameExtension__c, password, '/bspEnquiry');
        system.debug(p);
        return p;
    }
    
   public PageReference forgotPassword() {
        setPageHeaders();
        system.debug('forgotPassword***'+username+configSetting.UsernameExtension__c);
        String forgotP = username+configSetting.UsernameExtension__c;
        boolean success = Site.forgotPassword(forgotP);
        system.debug('forgotPassword***'+success+forgotP);
        PageReference pr = new PageReference('/bspLogin?section=PasswordReset');
        pr.setRedirect(true);
        
        if (success) {              
            return pr;
        }
        return null;
    }

    public PageReference securePage()
    {
        // this function redirects to https protocol
        string sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        integer firstSemiColonPos = sfdcBaseURL.indexOf(':');
        string protocolString = sfdcBaseURL.substring(0,firstSemiColonPos);
        string sitePathPrefix = Site.getPathPrefix();

        if(protocolString!='https')
        {       
            string secureURL = 'https' + sfdcBaseURL.substring(firstSemiColonPos) + sitePathPrefix;
            PageReference securePage = new PageReference(secureURL);
            securePage.setRedirect(true);
            return securePage;  
        }
        else
        {   
            return null;
        }          
    }    
}