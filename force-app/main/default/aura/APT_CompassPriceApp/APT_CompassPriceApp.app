<!--
 @description:	This Lightning App is used for linking PSR functionality. It extends the Lightning-out framework and use aura:dependency to call the LWC component. 
 @author Seth Heang
 @date 2022-04-01
 @changelog: 
 2022-04-01 - Seth Heang - Created
-->
<aura:application  extends="ltng:outApp" access="Global">
	<aura:dependency resource="c:apt_CompassPriceLWC"/>
</aura:application>