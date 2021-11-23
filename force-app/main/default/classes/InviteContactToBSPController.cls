/**************************************************
Description:    Controller for the InviteContactToBSP Page
History:
--------------------------------------------------
2019-09-17  shashwat.a.nath@accenture.com  Created
**************************************************/

public with sharing class InviteContactToBSPController {

    // Constructor
    public InviteContactToBSPController(ApexPages.StandardController controller){

    }
    /**
    *  This method is Invoked from "InviteContactToBSP" page on click of "Invite Contact to BSP" Custom Button on Contact Detail Page
    *  It checks for the any existing community user for the Contact in process.
    *  Returns the userlist
    */
    @remoteaction
    public static List<User> fetchCurrentUserDetails(String recordId){
        system.debug('Contact Record Id =>' +recordId);
        List<User> userList = new List<User>();
        userList = [SELECT Id FROM User WHERE ContactId =:recordId AND UserName LIKE '%.bsp' LIMIT 1];
        return userList;
    }
}