/**
  * @author       : Talib Raza
  * @date         : 08/05/2019
  * @description  : Capture content and postage claims, displayed when Compensation option no 
--------------------------------------- History --------------------------------------------------
08.05.2019    Talib Raza      		Created
08.10.2024	  Talib Raza			   REQ3526971 - Compensation, content and postage claim changes.
**/
import { LightningElement, api, track } from 'lwc';
import LwcForm from 'c/lwcForm';

export default class ContentAndPostageClaim extends LwcForm {
	@track amountNotValid = false;
	@api contentClaimChangeHandler;
	@api postageClaimChangeHandler;

	connectedCallback() {
		this.values.contentClaim = 0;
		this.values.postageClaim = 0;
		this.fireChangeHandlerContentClaim();
		this.fireChangeHandlerPostageClaim();
	}

	handleContentClaimChange(event) {
		this.amountNotValid = false;
		this.values.contentClaim = event.target.value;
		this.fireChangeHandlerContentClaim();
	}

	handlePostageClaimChange(event) {
		this.amountNotValid = false;
		this.values.postageClaim = event.target.value;
		this.fireChangeHandlerPostageClaim();
	}

	fireChangeHandlerContentClaim() {
		if (typeof this.contentClaimChangeHandler === 'function') {
			this.contentClaimChangeHandler(this.values.contentClaim);
		}
	}

	fireChangeHandlerPostageClaim() {
		if (typeof this.postageClaimChangeHandler === 'function') {
			this.postageClaimChangeHandler(this.values.postageClaim);
		}
	}

	@api reportValidity() {
		const inputComponents = this.template.querySelectorAll(".form-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		inputsArray.forEach(inputCmp => inputCmp.reportValidity());
	}

	@api checkValidity() {
		const inputComponents = this.template.querySelectorAll(".form-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		return inputsArray.reduce((acc, inputCmp) => {
			inputCmp.reportValidity();
			return acc && inputCmp.checkValidity();
		}, true);
	}
}