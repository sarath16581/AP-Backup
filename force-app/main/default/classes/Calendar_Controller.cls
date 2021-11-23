/*------------------------------------------------------------
Author:        Nathan Main
Date:          14/07/2016
Company:       salesforce.com
Description:   Class used by Custom_Calendar VF page to access
               events for the current user and their direct reports.

Test Class:    Calendar_Controller_Test
History   :    18/07/16 NMAIN - Added LIMIT 20000 to Future and Past event SOQL query and removed the full select of the User object.
               22/07/16 NMAIN - If Account is not set do not attempt to add it to the calendar event
------------------------------------------------------------*/

public class Calendar_Controller {

    public String selecteduserId {set;get;}
    public map<Id, User> userMap {get;set;}


    //constructor
    public Calendar_Controller() {
        selecteduserId = null;
        userMap = getUsersForUserRole(UserInfo.getUserId());
        selecteduserId = UserInfo.getUserId();
        eventdata(selecteduserId);
    }

    @RemoteAction
    public static string eventdata(string selecteduserIdLocal){

        list<calEvent> events = new list<calEvent>();
        String dtFormat = 'EEE, d MMM yyyy HH:mm:ss';
        TimeZone tz = UserInfo.getTimeZone();
        String timez = String.valueOf(tz);
        DateTime currentDateTime = DateTime.now();

        // Future events
        for(Event evnt: [select Id, Subject, What.Name, Owner.Alias, isAllDayEvent, StartDateTime, EndDateTime, Status__c from Event where OwnerID = :selecteduserIdLocal AND StartDateTime > :currentDateTime LIMIT 20000]){
            DateTime startDT = evnt.StartDateTime;
            DateTime endDT = evnt.EndDateTime;

            calEvent myEvent;
            if (evnt.Status__c == 'Completed')
                myEvent = new calEvent(evnt.What.Name, evnt.isAllDayEvent, startDT.format(dtFormat,timez), endDT.format(dtFormat,timez), '/' + evnt.Id,  evnt.Owner.Alias, 'event-personal-completed');
            else
                myEvent = new calEvent(evnt.What.Name, evnt.isAllDayEvent, startDT.format(dtFormat,timez), endDT.format(dtFormat,timez), '/' + evnt.Id,  evnt.Owner.Alias, 'event-future');

            events.add(myEvent);
        }

        // past events
        for(Event evnt: [select Id, Subject, What.Name, Owner.Alias, isAllDayEvent, StartDateTime, EndDateTime, Status__c from Event where OwnerID = :selecteduserIdLocal AND StartDateTime < :currentDateTime AND Status__c <> 'Complete' LIMIT 20000]){
            DateTime startDT = evnt.StartDateTime;
            DateTime endDT = evnt.EndDateTime;

            calEvent myEvent;
            if (evnt.Status__c == 'Completed')
                myEvent = new calEvent(evnt.What.Name, evnt.isAllDayEvent, startDT.format(dtFormat,timez), endDT.format(dtFormat,timez), '/' + evnt.Id,  evnt.Owner.Alias, 'event-personal-completed');
            else
                myEvent = new calEvent(evnt.What.Name, evnt.isAllDayEvent, startDT.format(dtFormat,timez), endDT.format(dtFormat,timez), '/' + evnt.Id,  evnt.Owner.Alias, 'event-personal-late');

            events.add(myEvent);
        }

        string jsonEvents = JSON.serialize(events);
        jsonEvents = jsonEvents.replace('startString','start');
        jsonEvents = jsonEvents.replace('endString','end');

        return jsonEvents;

    }


   public PageReference showTeamMemberEvents()
   {
        eventdata(selecteduserId);
        return null;
   }

    public List<SelectOption> getListOfUser()
    {
        List<SelectOption> UserOptionList = new List<SelectOption>();

        UserOptionList.add(new SelectOption(UserInfo.getUserId(),'---Show My Events---'));

        for (Id id : userMap.keySet()) {
            System.debug('=== ' + userMap.get(id).Name);
            UserOptionList.add(new SelectOption(Id , userMap.get(id).Name));
        }

        return UserOptionList ;
    }

    // Return users who have the named role.
    // Must be an exact match or this will fail horribly.
    public map<Id, User> getUsersForRoleName(String name) {
        Id roleId = [SELECT Id FROM UserRole WHERE Name = :name LIMIT 1].Id;

        return getUsersForRoleId(roleId);
    }

    // Return users who have the role identified by the user ID.
    // This will fail horribly if the User ID does not exist, and
    // will not return anything if the User ID is not active or
    // is not a Standard license. It will also fail if the user
    // does not have a role defined.
    public map<Id, User> getUsersForUserRole(Id userId) {
        Id roleId = [SELECT UserRoleId FROM User WHERE Id = :userId].UserRoleId;
        return getUsersForRoleId(roleId);
    }

    // Return users who have the identified role, and all users
    // with roles subordinate to that role.
    public map<Id, User> getUsersForRoleId(Id roleId) {
        // Get roles under this role.
        set<Id> allSubRoleIds = getSubRoleIds(new set<ID>{ roleId });
        // Return a map of active standard Users with these roles.

        userMap = new map<Id, User>([SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User
        WHERE UserRoleId IN :allSubRoleIds
        AND IsActive = true
        AND UserType = 'Standard']);
        return userMap;
    }

    // Recursive method that gets all subordinate roles for a given role.
    public set<ID> getSubRoleIds(set<Id> roleIds) {
        set<Id> retVal = new set<Id>();
        // Get roles subordinate to these roles.
        for (UserRole r : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleID != null]) {
            retVal.add(r.Id);
        }
        // Recursive call. - Removed this because we only want to go one level deep.
        //if (!retVal.isEmpty())
        //    retVal.addAll(getSubRoleIds(retVal));

        return retVal;
    }

    //Class to hold calendar event data
    public class calEvent{
        public String title {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;set;}
        public String endString {get;set;}
        public String url {get;set;}
        public String className {get;set;}
        public String ownerAlias {get;set;}

        //Constructor
        public calEvent(){}

        public calEvent(String eventTitle, Boolean eventAllDay, String eventStartString, String eventEndString, String eventUrl, String eventOwnerAlias, String eventClassName)
        {
           if (eventTitle != null)
                title = eventOwnerAlias + ' ' + eventTitle;
            else
                title = eventOwnerAlias;

            allDay = eventAllDay;
            startString = eventStartString;
            endString = eventEndString;
            url = eventUrl;
            ownerAlias = eventOwnerAlias;
            className = eventClassName;
        }
    }

}