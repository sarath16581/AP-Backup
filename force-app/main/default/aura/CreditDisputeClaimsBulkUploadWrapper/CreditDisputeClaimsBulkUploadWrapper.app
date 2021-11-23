<!--
 @description Aura application wrapping "Bulk Upload" LWC application allowing it to be exposed in Visualforce via
              Lightning Out.
 @author Ranjeewa Silva
 @date 2021-01-22
 -->
<aura:application description="Credit Dispute Claims Bulk Upload wrapper app used for Lightning out for Visualforce" extends="ltng:outApp">
    <aura:dependency resource="c:bulkUpload"/>
    <aura:dependency resource="c:caseSupportingDocuments"/>
</aura:application>