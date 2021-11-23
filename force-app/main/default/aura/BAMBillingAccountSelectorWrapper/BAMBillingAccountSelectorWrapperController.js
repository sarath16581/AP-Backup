/**
 * 2020-05-27 - Nathan Franklin - Added a wrapper to help support binding changes back to the parent account without the need to fully re-render the parent
 */
({

	onInitLoad: function(component, event, helper) {
		console.log('SELECTED: ', component.get('v.selected'));
	},

	onChangeBillingAccounts:function(component, event, helper) {
		console.log('onChangeBillingAccounts');

		const selectedBillingAccountIds = event.getParam('selected');
		component.set('v.selected', selectedBillingAccountIds);
	}

});