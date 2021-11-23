<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Apttus_Config2__SetOriginalOrderLineNumber</fullName>
        <description>Set original order line number from the auto generated order line number</description>
        <field>Apttus_Config2__OriginalLineNumber__c</field>
        <formula>Name</formula>
        <name>Set Original Order Line Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Apttus_Config2__Set Original Order Line Number</fullName>
        <actions>
            <name>Apttus_Config2__SetOriginalOrderLineNumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Apttus_Config2__OrderLineItem__c.Apttus_Config2__OriginalLineNumber__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Set original order line number for new order line items. The order line number is auto generated.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
