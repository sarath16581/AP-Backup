<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>revcult__Append_Text</fullName>
        <field>revcult__Errors__c</field>
        <formula>PRIORVALUE(revcult__Errors__c) + BR() + BR() + revcult__Errors__c</formula>
        <name>Append Text</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>revcult__Append Error Info</fullName>
        <actions>
            <name>revcult__Append_Text</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(revcult__Errors__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
