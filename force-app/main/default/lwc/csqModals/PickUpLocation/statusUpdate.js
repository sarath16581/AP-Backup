/**
 * @author Paul Perry
 * 
 * Custom LWC dialog allowing the user to update status information while (lobkec) in Approval Process
 */
import Utils from '../utils/generic';
import UpdateStatusDialog from './statusUpdate.html';

const CONTENT_STATUS = {
	Pending : 'Pending Information',
	Received : 'Received Information'
};
const CONTENT_MSG = [
	'You\'re about to update the Approval Status to {0}.',
	'Please amend or add optional notes and click Save to continue'
].join('<br/>');

export default class StatusUpdate {
	constructor(thisRef) {
		this.thisRef = thisRef;
	}

	render = () => UpdateStatusDialog;

	connectedCallback() {
		this.thisRef.title = CONTENT_STATUS[this.thisRef.args.status];

		this.content = Utils.format(
			CONTENT_MSG,
			Utils.wrapHtml({ 
				innerHtml : CONTENT_STATUS[this.thisRef.args.status],
				nodeName : 'b'
			})
		);

		this.notes = this.thisRef.args.notes || '';
		this.rcbPending = true;
	}

	renderedCallback() {
		if (this.rcbPending) {			
			const elem = this.thisRef.template.querySelector('.focusDefault');
			if (elem && elem.focus) {
				delete this.rcbPending;
				// Immediate focus doesn't work as the component is still in it's rendering phase
				setTimeout(() => elem.focus(), 50);
			}
		}
	}

	handleClick(event) {
		let result;

		if (event.target.name === "btnSave") {
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

			result = inputElems.reduce(
				(res, item) => Object.assign(
					res,
					{ [item.name] : item.value }
				), { }
			);
		}

		this.thisRef.close(result);
	}
}