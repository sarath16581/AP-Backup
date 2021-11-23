({
    /* Function to set the status to closed initially */
    doInit: function (cmp, event, helper) {
        cmp.set('v.status', 'closed');
    },
    
    /* Function to open the link */
    openLink: function (cmp, event) {
        window.open(cmp.get('v.link'), '_self');
    },
    
    /* Function to toggle between opened and closed status */
	toggleExpander: function(cmp, event) {
        if(cmp.get('v.status') == 'opened'){
            cmp.set('v.status', 'closed');
        }
        else if(cmp.get('v.status') == 'closed'){
            cmp.set('v.status', 'opened');
        }    
    }        
})