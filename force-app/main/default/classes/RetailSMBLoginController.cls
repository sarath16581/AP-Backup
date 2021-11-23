/*
    @Author      :  Snigdha.Sahu@auspost.com.au
    @Name        :  RetailSMBLogin
    @Date        :  06/05/2016
    @Description :  Custom Controller for Site Login
*/
global with sharing class RetailSMBLoginController {
    global String username{get;set;}
    global String password{get;set;}
    global RetailSMBLoginController () {}

    global PageReference login() {
        /*String startUrl = System.currentPageReference().getParameters().get('startURL');
        system.debug ( ' Retail SMB'  + startURL); */
        String startUrl = 'https://devsit-auspost.cs6.force.com/RetailBusinessCustomers/RetailSMB';
        return Site.login(username, password, startUrl);
        
    }
    

}