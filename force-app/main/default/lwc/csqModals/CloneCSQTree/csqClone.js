/**
 * @author Paul Perry
 * 
 * Custom LWC dialog that overrides the default Submit for Approval action displaying additional content.
 */
import CSQCloneDialog from './csqClone.html';

const CLONE_OPTIONS = [
	{ label: 'Clone as is (for ABN update)', value: 'full' },
	{ label: 'Reset approval statusses', value: 'reapprove' },
];

export default class CsqClone {
	constructor(thisRef) {
		this.thisRef = thisRef;
		thisRef.options = CLONE_OPTIONS;
		thisRef.cloneOptionValue = 'full';
	}

	/**
	 * Select the CSQCloneDialog template to display this dialog
	 * @returns Template
	 */
	render = () => CSQCloneDialog;

	connectedCallback() {
		if (!this.thisRef.title) {
			this.thisRef.title = 'Clone CSQ';
		}
	}

	/**
	 * Click event from parent LWC component
	 * @param event details
	 * @returns void
	 */
	handleClick(event) {
		let result;

		if (event.target.name === 'btnClone') {
			const inputElems = [
				...this.thisRef.template.querySelectorAll('[data-name="input"]')
			];
			const invalidItems = inputElems.filter(
				item => !item.reportValidity()
			);

			if (invalidItems.length) {
				// Focus the first invalid element
				if (invalidItems[0].focus) {
					invalidItems[0].focus();
				}
				
				return;
			} 

			// Provide submission details as submit button was clicked
			result = inputElems.reduce(
				(res, item) => Object.assign(
					res,
					{ [item.name] : item.value }
				), { }
			);
		}

		// Close the dialog
		this.thisRef.close(result);
	}
}