<!--
 @description Render details about creation of case investigation records related to articles of ST cases
 @author Mahesh Parvathaneni
 @date 2022-11-18
 -->

<aura:application description="MyNetwork StarTrack App used for Lightning out for Visualforce" extends="ltng:outApp">
    <aura:dependency resource="c:myNetworkCaseArticlesContainer" />
    <aura:dependency resource="markup://force:*" type="EVENT" />
    <aura:dependency resource="markup://force:showToast" type="EVENT" />
</aura:application>