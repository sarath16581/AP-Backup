/**
 * @description ICPS Add Articles Quick Action
 * @author Harry Wang
 * @date 2022-06-06
 * @group Controller
 * @changelog
 * 2022-06-06 - Harry Wang - Created
 */
({
	/**
	 * handle quick action modal close from child component
	 */
	handleClose: function (component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},

	/**
	 * handle view refresh from child component
	 */
	handleRefresh: function (component, event, helper) {
		$A.get("e.force:refreshView").fire();
	}
})