<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Apttus_Config2__SearchFieldUpdate</fullName>
        <description>Update the incentive search field with Incentive Number</description>
        <field>Apttus_Config2__SearchField__c</field>
        <formula>Apttus_Config2__IncentiveNumber__c</formula>
        <name>Search Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>true</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Apttus_Config2__SetIncentiveCode</fullName>
        <description>Set incentive code from the auto generated incentive number</description>
        <field>Apttus_Config2__IncentiveCode__c</field>
        <formula>Apttus_Config2__IncentiveNumberAuto__c</formula>
        <name>Set Incentive Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>true</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Apttus_Config2__SetIncentiveNumber</fullName>
        <description>Set incentive number from the auto generated incentive number</description>
        <field>Apttus_Config2__IncentiveNumberText__c</field>
        <formula>Apttus_Config2__IncentiveNumberAuto__c</formula>
        <name>Set Incentive Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>true</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Apttus_Config2__Search Field Update</fullName>
        <actions>
            <name>Apttus_Config2__SearchFieldUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Apttus_Config2__Incentive__c.Apttus_Config2__IncentiveNumber__c</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Populate an external Id search field with incentive number, so that side bar support can work with Incentive Number search</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Apttus_Config2__Set Incentive Code</fullName>
        <actions>
            <name>Apttus_Config2__SetIncentiveCode</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Apttus_Config2__Incentive__c.Apttus_Config2__IncentiveCode__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Set incentive code for new incentives. The incentive code is auto generated.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Apttus_Config2__Set Incentive Number</fullName>
        <actions>
            <name>Apttus_Config2__SetIncentiveNumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Apttus_Config2__Incentive__c.Apttus_Config2__IncentiveNumberText__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Set incentive number for new incentives. The incentive number is auto generated.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
