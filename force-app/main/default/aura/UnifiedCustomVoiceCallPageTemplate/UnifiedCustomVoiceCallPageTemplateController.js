({
    doInit: function(component, event, helper) {
        let windowUrl = window.location.href;
        if (!windowUrl.includes('flexipageEditor')) {
            component.set('v.activeSections', []); // automatically collapse the accordion if not in flexipage editor mode
        }
    }
})