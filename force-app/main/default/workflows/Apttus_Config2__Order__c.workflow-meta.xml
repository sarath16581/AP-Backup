<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Apttus_Config2__SetOriginalOrderNumber</fullName>
        <description>Set original order number from the auto generated order number</description>
        <field>Apttus_Config2__OriginalOrderNumber__c</field>
        <formula>Name</formula>
        <name>Set Original Order Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Apttus_Config2__Set Original Order Number</fullName>
        <actions>
            <name>Apttus_Config2__SetOriginalOrderNumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Apttus_Config2__Order__c.Apttus_Config2__OriginalOrderNumber__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Set original order number for new orders. The order number is auto generated.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
