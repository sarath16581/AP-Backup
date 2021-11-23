({
    // Your renderer method overrides go here
    afterRender: function(component, helper){
        this.superAfterRender();
        //var analyticsPageName = 'form:' + component.get("v.pageName");
        //analytics.component.form.name=analyticsPageName;
        var stage = analytics.component.form.stage=component.get("v.stage");
        window.setTimeout(
            $A.getCallback(function() {
                analytics.component.form.name='form:' + component.get("v.pageName");
                analytics.component.form.step=component.get("v.step");
                if (stage !== '') analytics.component.form.stage=component.get("v.stage");
                _satellite.track('helpsupport-form-navigate');
            }), 3000
        );
    }
})