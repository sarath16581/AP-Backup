/**
 * @author Paul Perry
 * 
 * Custom LWC dialog that overrides the default Submit for Approval action displaying additional content.
 */
import SubmitApprovalDialog from './submitApprovalDialog.html';

const CHECKBOXES = [
	'Freight profile has been captured for all StarTrack products?  (images attached)',
	'Dangerous Goods – confirmation/ approval from National Dangerous Goods Manager?',
	'Photos of Van/ truck pickup point attached?',
	'Incompatible freight – have you referenced the prohibited list?',
	'Does the freight profile exceed the tolerance levels of 10% pallet work or 5% Incompatible Items?'
];

export default class SubmitApproval {
	constructor(thisRef) {
		this.thisRef = thisRef;
		thisRef.checkboxes = CHECKBOXES.map((label, index) => ({
			id : `cb${index}`,
			label
		}));
	}

	/**
	 * Select the SubmitApprovalDialog template to display this dialog
	 * @returns Template
	 */
	render = () => SubmitApprovalDialog;

	connectedCallback() {
		if (!this.thisRef.title) {
			this.thisRef.title = 'Submit for Approval';
		}
	}

	/**
	 * Click event from parent LWC component
	 * @param event details
	 * @returns void
	 */
	handleClick(event) {
		let result;

		if (event.target.name === 'btnSubmit') {
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