/**
 * @author Paul Perry
 * 
 * Consolidated LWC Quick Actions for CSQ related Modal dialogs
 * 
 * usage:

	import myModal from 'c/csqModals';
 
		myModal.open({
			modal: <Name as per ModalConfig>',
			size: <'small' || 'medium' || 'large'>,
			title: <title>,
			description: <description>, 	// required by LWC Modal
			label: <label>, 				// required by LWC Modal
			args: { status : this.status }	// optional additional arguments required by sub template
		});
 */

import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import PickUpLocationStatusUpdateJs from './PickUpLocation/statusUpdate';
import CustomerScopingQuestionnaireSubmitApprovalJs from './CustomerScopingQuestionnaire/submitApprovalDialog';

const ModalConfig = {
	'PickUpLocation_StatusUpdate' : PickUpLocationStatusUpdateJs,
	'CustomerScopingQuestionnaire_SubmitApprovalDialog' : CustomerScopingQuestionnaireSubmitApprovalJs
};

const ERR_INDALID_MODAL_PROVIDED = 'Invalid parameter provided for modal';

export default class CsqModals extends LightningModal {
	@api modal;
	@api title;
	@api args;

	get instance() {
		if (!this._instance) {
			if (!ModalConfig[this.modal]) {
				const msg = `${ERR_INDALID_MODAL_PROVIDED}: "${this.modal}". Available modals: ${Object.keys(ModalConfig).join(', ')}`;
				throw new Error(msg);
			}

			this._instance = new (ModalConfig[this.modal])(this);
		}

		return this._instance;
	}

	// Paul: Make sure to provide your template within your subclass render method
	render() { return this.handlerProxy('render'); }
	// Paul: Add proxy connection to each event handler in subclass
	connectedCallback() { return this.handlerProxy('connectedCallback'); }
	renderedCallback() { return this.handlerProxy('renderedCallback'); }
	handleClick(event) { return this.handlerProxy('handleClick', event); }
	//handleKeyDown(event) { return this.handlerProxy('handleKeyDown', event); }

	handlerProxy(method, ...args) {
		// execute if implemented in sub template
		if (this.instance[method]) {
			return this.instance[method](...args);
		}
	}
}