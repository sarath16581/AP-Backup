<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>grax__Notify_GRAX_Schedule_Process_Completed</fullName>
        <description>Notify GRAX Schedule Process Completed</description>
        <protected>false</protected>
        <recipients>
            <field>LastModifiedById</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>grax__GRAX_Email_Templates/grax__GRAX_Schedule_Process_Notification_VF</template>
    </alerts>
    <rules>
        <fullName>grax__GRAX Schedule Process Finished</fullName>
        <actions>
            <name>grax__Notify_GRAX_Schedule_Process_Completed</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>Send email notification when a GRAX Schedule Process has finished its execution.</description>
        <formula>false /*ISCHANGED(grax__Status__c) &amp;&amp; ISPICKVAL(grax__Status__c, &apos;Completed&apos;) &amp;&amp; grax__Send_Notifications__c*/</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
