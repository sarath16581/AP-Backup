({
    afterRender: function (cmp, helper) {
        this.superAfterRender();
        helper.checkAllValid(cmp, false);
        //-- Added navigation here, because with doInit first below navigation cmp loaded then again current cmp is ovewriting
        if(cmp.get('v.authUserData.isUserAuthenticated')) {
            // cmp.set('v.showNav', true);
            if (!cmp.get('v.authUserData.isUserPhoneEmpty')) {
                if(cmp.get('v.wizardData.navigationSourceType') == 'nav_next'){
                    helper.gotoNextPage(cmp);
                }else if(cmp.get('v.wizardData.navigationSourceType') == 'nav_prev'){
                    helper.gotoPrevPage(cmp);
                }
            }
            
        } else {
            // cmp.set('v.showNav', false);
        }
    }
})