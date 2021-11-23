({
    // Your renderer method overrides go here
    afterRender: function(component, helper){
        this.superAfterRender();
        window.setTimeout(
            $A.getCallback(function() {
                analytics.component.community.pageCategory=component.get("v.pageName"); 
                analytics.component.community.pageDescription=document.title;
                _satellite.track('community-navigate');
            }), 3000
        );
    }
})