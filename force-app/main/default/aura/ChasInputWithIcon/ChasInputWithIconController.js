/**
 * 2023-11-20 - Nathan Franklin - add oninput for scenarios where some parent components require immeadiate feedback after the user types
 */
({
    updateValue : function(cmp, event, helper) {
        cmp.set('v.value', event.target.value);
		$A.enqueueAction(cmp.get('v.oninput'));
    },
    searchOnBlur : function(cmp, event, helper) {
        event.preventDefault();
        $A.enqueueAction(cmp.get('v.onblur'));
    }
})