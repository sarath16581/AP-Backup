/**
 * Created by hasan on 11/10/2023.
 */

import {LightningElement, api} from 'lwc';
import {NavigationMixin} from "lightning/navigation";

export default class BspModalBasic extends NavigationMixin(LightningElement) {

	closeModal() {
		this.dispatchEvent(new CustomEvent('closemodal'));
	}
}