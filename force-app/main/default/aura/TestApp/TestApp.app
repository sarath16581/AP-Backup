<aura:application extends="force:slds" access="Global">
    <c:chasMissingItemAddressLookup
        onshowError="{!c.handleVoid}"
        onaddressTyped="{!c.handleVoid}"
        onaddressOverride="{!c.handleVoid}"
        onsearchtermchange="{!c.handleVoid}"
        onvaluechange="{!c.handleVoid}"
        onstreetchange="{!c.handleVoid}"
        searchAddressTerm="16 Tudor Street SURRY"       
    ></c:chasMissingItemAddressLookup>
    <div style="margin-top: 25px;">
        <p>Some caption here</p>
    </div>
    <div style="margin-top: 25px;">
        <lightning:input label="Another input field" name="test" type="text" value="Hi"></lightning:input>
    </div>
    <div style="margin-top: 25px;">
        <lightning:input label="Another input field" name="test" type="text" value="Hi"></lightning:input>
    </div>
    <div style="margin-top: 25px;">
        <lightning:input label="Another input field" name="test" type="text" value="Hi"></lightning:input>
    </div>
    <div style="margin-top: 25px;">
        <lightning:input label="Another input field" name="test" type="text" value="Hi"></lightning:input>
    </div>
</aura:application>