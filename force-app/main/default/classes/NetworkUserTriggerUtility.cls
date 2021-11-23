/**************************************************
Type:       NetworkUserTriggerUtility
Purpose:

History:
-----------------------------------------------------------------------------------------
7/03//2017  dion.gunn@auspost.com.au                Initial Implementation as part of myNetwork project.
                                                                    //Creates network users Automatically if not already present.
21/05/2107  kalpita.talwadekar@auspost.com.au       updated code comments
                                                                updated for adding user role and missing permission set for super user
15/05/2108  kalpita.talwadekar@auspost.com.au       updated code for adding new object access permission set for all users

07/06/2018  kalpita.talwadekar@auspost.com.au       updated code for coding standard follow - TDO-240
25-02-2019  swati.mogadala@auspost.com.au            added a custom setting to concatenate org info to a username when adding a new network userINC1300632
**************************************************/

public class NetworkUserTriggerUtility {
    //Timezone picklist values to timezoneSidKey values on User object.
    private static final Map<String, String> timzoneSidKeys =
            new Map<String, String>{
                    'Western Australia' => 'Australia/Perth',
                    'Northern Territory' => 'Australia/Darwin',
                    'Queensland' => 'Australia/Brisbane',
                    'South Australia' => 'Australia/Adelaide',
                    'New South Wales' => 'Australia/Sydney',
                    'Lord Howe' => 'Australia/Lord_Howe',
                    'Norfolk' => 'Pacific/Norfolk'
            };

    /**
     * @description       method to create the network users if not an existing user is SELECTed
     * @param             List<Facility_User__c> networkUsers
     * @return            Void
     * @throws            NA
     */
    public static void createNetworkUsers(List<Facility_User__c> networkUsers) {

        //Grab all the details about the available user licenses FROM  each network.
        Set<Id> networkIds = new Set<Id>();
        for (Facility_User__c networkUser : networkUsers) {
            if(networkUser.Is_MyNetwork_User__c) {  //Kalpi: Added check for mynetwork users Is_MyNetwork_User__c
                networkIds.add(networkUser.Network__c); 
                
            }
           
        }

        //query the portal license on the networks
        List<Network__c> networks = new List<Network__c> ([ SELECT Id, Portal_Licenses__c FROM Network__c WHERE Id IN :networkIds]);

        //to hold the porta license for each network above
        Map<Id, Decimal> networkIdToLicenses = new Map<Id, Decimal>();
        for (Network__c netwrk : networks) {

            //if portal license field is not blank
            if (netwrk.Portal_Licenses__c != null) {
                networkIdToLicenses.put(netwrk.Id, netwrk.Portal_Licenses__c);
            } else {
                networkIdToLicenses.put(netwrk.Id, 0);
            }
        }

        //Query the network user profile
        Profile prof = [ SELECT id FROM Profile WHERE Name = 'MyNetwork Portal' LIMIT 1];

        //query existing users under this profile
        List<User> existingUsers = [ SELECT FirstName, LastName, Email, Username FROM User WHERE ProfileId = :prof.Id];

        //check if existing user with same details as network user to be created
        checkExistingNetworkUsers(networkUsers, existingUsers);

        //Query the existing network users to subtract them FROM  the  available portal licenses.
        List<Facility_User__c> existingNetworkUsers = [ SELECT Id, Network__c FROM  Facility_User__c WHERE Network__c in:networkIds];
        
        //loop through exsiting network users to get the available portal license count for assignmet
        for (Facility_User__c networkUser : existingNetworkUsers) {
            Decimal licenses = networkIdToLicenses.get(networkUser.Network__c);
            networkIdToLicenses.put(networkUser.Network__c, licenses - 1);
        }

        //Create the new users from the network user list
        List<User> usersToInsert = new List<User>();
        for (Facility_User__c networkUser : networkUsers) {

            //vaidate the entered user details before creating new user
            if (networkUser.User__c == null && validUserDetails(networkUser)) {

                User user = new User();
                user.FirstName = networkUser.First_Name__c;
                user.LastName = networkUser.Last_Name__c;
                user.Username = findUniqueName(networkUser, existingUsers);
                user.Alias = networkUser.First_Name__c.left(1) + networkUser.Last_Name__c.left(6);
                user.ProfileId = prof.Id;
                user.Email = networkUser.Email_Address__c;
                user.EmailEncodingKey = 'ISO-8859-1';
                user.TimeZoneSidKey = timzoneSidKeys.get(networkUser.Timezone__c);
                user.LocaleSidKey = 'en_AU';
                user.LanguageLocaleKey = 'en_US';
                usersToInsert.add(user);
            } else if (networkUser.User__c == null && !validUserDetails(networkUser)) { //if not valid show message on screen

                networkUser.addError('Please ensure all fields are completed when creating a new user');
            } else if (networkUser.User__c != null && validUserDetails(networkUser)) {

                networkUser.addError('Only complete the New User fields when an existing user cannot be found.');
            }
        }

        // if users are available for insert, save them to database
        if (!usersToInsert.isEmpty()) {
            Database.DMLOptions dmlo = new Database.DMLOptions();
            dmlo.EmailHeader.triggerUserEmail = true; // we need to send the welcome email.
            List<Database.SaveResult> sr = database.insert(usersToInsert, dmlo);
        }

        Map<String,String> userRoles = new map<String,String>();
        //loop through network user list for user role mapping and deduct the license that will be left on the network
        for (Integer i = 0; i < networkUsers.size(); i++) {

            //if no existing user and valid user details entered with portal license available
            if (networkUsers[i].User__c == null && validUserDetails(networkUsers[i])
                    && networkIdToLicenses.get(networkUsers[i].Network__c) > 0) {

                // map user roles
                networkUsers[i].User__c = usersToInsert[i].Id;
                Decimal licenses = networkIdToLicenses.get(networkUsers[i].Network__c);
                userRoles.put(usersToInsert[i].Id,networkUsers[i].User_Role__c);
                networkIdToLicenses.put(networkUsers[i].Network__c, licenses - 1);
            } else if (networkUsers[i].User__c != null && networkIdToLicenses.get(networkUsers[i].Network__c) > 0) {

                //if no existing user is SELECTed and portal license available
                Decimal licenses = networkIdToLicenses.get(networkUsers[i].Network__c);
                networkIdToLicenses.put(networkUsers[i].Network__c, licenses - 1);
            } else if (networkIdToLicenses.get(networkUsers[i].Network__c) <= 0) {

                //Throw an error and rollback if the user tries to create a network user with no licenses.
                networkUsers[i].addError('This network has no available licenses. Please speak with support.');
            }
        }

        //check if the list is not empty
        if (!networkUsers.isEmpty() && !usersToInsert.isEmpty()) {
            System.enqueueJob(new createPermissionSets(networkUsers));
            insertUserRole(userRoles); //to insert user role for myNetwork user and super user
        }
    }

    /**
      * @description       method to insert the user roles based on type of user created
      * @param             Map<String,String> userRoles
      * @return            Void
      * @throws            NA
      */
    @future
    public static void insertUserRole(Map<String,String> userRoles) {
        Map<String, String> userRoleMapping =
                new Map<String, String>{
                        'MyNetwork Super User' => 'SSSW MyNetwork Manager',
                        'MyNetwork User' => 'SSSW MyNetwork User'
                };

        Map<String,ID> userRoleMap = new Map<String, Id>();

        //query through user role for myNetwork to map the values with name
        for( UserRole ur: [ SELECT Name, Id FROM UserRole WHERE Name Like '%MyNetwork%' LIMIT 2]) {
            userRoleMap.put(ur.Name, ur.Id);
        }

        List<User> usersToUpdate = new List<User>();

        //based on above mapping, set the user role for new users
        for(String s: userRoles.keySet()) {
            usersToUpdate.add(new user(Id=s, userroleId=userRoleMap.get(userRoleMapping.get(userRoles.get(s)))));
        }

        //update user record
        if(!usersToUpdate.isempty()) {
            database.update(usersToUpdate);
        }

    }

    /**
      * @description       method to validate the network user created to see if al mandate and sufficient information available to create user in the system.
      * @param             Facility_User__c networkUser
      * @return            Void
      * @throws            NA
      */
    public static Boolean validUserDetails(Facility_User__c networkUser) {
        //validate the user details are entered correctly on the form
        if (networkUser.First_Name__c != null && networkUser.Last_Name__c != null &&
                networkUser.Email_Address__c != null && networkUser.Network__c != null
                && networkUser.Timezone__c != null && networkUser.User_Role__c != null) {
            return true;
        } else {
            return false;
        }
    }

    /**
      * @description       method to validate the network user duplicacy based on FirstName+LastName+Email
      * @param             List<Facility_User__c> networkUsers, List<User> existingUsers
      * @return            Void
      * @throws            NA
      */
    public static void checkExistingNetworkUsers(List<Facility_User__c> networkUsers, List<User> existingUsers) {
        //for every new network user check if an existing network user is present with same details
        for (Facility_User__c networkUser : networkUsers) {

            for (User usr : existingUsers) {

                if(!String.isBlank(networkUser.First_Name__c) &&  !String.isBlank(networkUser.Last_Name__c)
                        &&  networkUser.First_Name__c.equalsIgnoreCase(usr.Firstname) && networkUser.Last_Name__c.equalsIgnoreCase(usr.LastName)
                        && networkUser.Email_Address__c.equalsIgnoreCase(usr.Email)) {

                    // if yes show error on form
                    networkUser.addError('A user account matching the First Name, Last Name and Email Address was already found for ' +
                            networkUser.First_Name__c + ' ' + networkUser.Last_Name__c);
                    break;
                }
            }
        }
    }

    /**
      * @description       method Checks to see if an EXISTING user has the same username.
      * @param             List<Facility_User__c> networkUsers, List<User> existingUsers
      * @return            Void
      * @throws            NA
      */
    public static String findUniqueName(Facility_User__c networkUser, List<User> users) {
        //create username for the new user to be inserted using the first and last name
        String username = networkUser.First_Name__c.deleteWhitespace() + '.' + networkUser.Last_Name__c.deleteWhitespace();
        Set<String> existingMatches = new Set<String>();

        for (User u : users) {

            if (u.Username.toLowerCase().contains(username.toLowerCase())) {

                existingMatches.add(u.Username);
            }
        }
        String newUsername = '';

        //if existing matches are found on the usernames 
        //Added customer setting to add sandbox name to the username along with @mynetwork INC1300632
        string orgName=User__c.getInstance().Org__c;
        if (!existingMatches.isEmpty()) {

            newUsername = networkUser.First_Name__c.deleteWhitespace() + '.' + networkUser.Last_Name__c.deleteWhitespace() + existingMatches.size() + orgName;
            return newUsername;
        } else {

            newUsername = username + orgName;
            return newUsername;
        }
    }

    /**
      * @description       class to assign permission sets asynchronously to avoid mixed DML exceptions.
      * @return            Void
      * @throws            NA
      */
    public class createPermissionSets implements System.Queueable {
        private List<Facility_User__c> networkUserList;

        public NetworkUserTriggerUtility.createPermissionSets(List<Facility_User__c> netwrkUsers) {
            this.networkUserList = netwrkUsers;
        }

        //execute method to run the code for permission set assignmet to users
        public void execute(QueueableContext qc) {
        try{ // Added exception to track any error
            //Create Permission Set Assignments for custom community permission set
            List<PermissionSet> psList = [SELECT Id, Name FROM PermissionSet WHERE 
                                          Name = 'MyNetwork_Employee_Apps' OR 
                                          Name = 'MyNetwork_Employee_Apps_Super_User' OR 
                                          Name = 'Other_Objects_Access_MyNetwork'];
                                            
            Map<String, PermissionSet> nameToPermSet = new Map<String, PermissionSet>();

            //loop through the permission set list queried above for mapping
            for (PermissionSet ps : psList) {

                    //based on user role, assign the correct permission set
                    if ('MyNetwork_Employee_Apps_Super_User'.equalsIgnoreCase(ps.Name)) { 
                        nameToPermSet.put('MyNetwork Super User', ps);
                    } else if ('MyNetwork_Employee_Apps'.equalsIgnoreCase(ps.Name)) { 
                        nameToPermSet.put('MyNetwork User', ps);
                    } else if ('Other_Objects_Access_MyNetwork'.equalsIgnoreCase(ps.Name)) { //for added new permissions on objects 
                        nameToPermSet.put('MyNetwork - Other Access', ps);
                    }
             }

            //loop through the network users to assign permission sets
            List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
            for (Facility_User__c networkUser : networkUserList) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.PermissionSetId = nameToPermSet.get(networkUser.User_Role__c).Id;
                psa.AssigneeId = networkUser.User__c;
                psaList.add(psa);

                if ('MyNetwork Super User'.equalsIgnoreCase(networkUser.User_Role__c)) {
                    psa = new PermissionSetAssignment ();
                    psa.PermissionSetId = nameToPermSet.get('MyNetwork User').Id;
                    psa.AssigneeId = networkUser.User__c;
                    psaList.add(psa);
                }

                    //for added new permissions on objects for all users
                    psa = new PermissionSetAssignment ();
                    psa.PermissionSetId = nameToPermSet.get('MyNetwork - Other Access').Id;
                    psa.AssigneeId = networkUser.User__c;
                    psaList.add(psa);
             }
                //insert permission sets for users
                if (!psaList.isEmpty()) {
                    insert psaList;
                }
           }
            catch(Exception exp){
            // Added exception to track any error
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, 
                                                    UserInfo.getOrganizationId(), 
                                                    'SSSW','NetworkUserTriggerUtility', 
                                                    'createPermissionSets', 
                                                    null, 
                                                    LoggingLevel.ERROR);
            } 
        }      
    }
}