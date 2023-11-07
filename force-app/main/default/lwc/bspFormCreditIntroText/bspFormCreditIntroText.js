/**
 * 	@author Hasantha Liyanage
 * 	@date 2023-11-02
 * 	@group child component
 * 	@domain BSP
 * 	@description info text on bsp credit claim header
 * 	@changelog
 * 	2023-11-02 - Hasantha Liyanage  - Created
 */

import {api, LightningElement} from 'lwc';

export default class BspFormCreditIntroText extends LightningElement {

	@api billingAccountScope;

	get isAp() {
		if (this.billingAccountScope === 'AP') {
			return true;
		} else {
			return false;
		}
	}

	get isSt() {
		if (this.billingAccountScope === 'ST') {
			return true;
		} else {
			return false;
		}
	}

	get isAll() {
		if (this.billingAccountScope === 'ALL') {
			return true;
		} else {
			return false;
		}
	}
}