/**
 * @author Hasantha Liyanage
 * @date 2023-10-11
 * @group lwc
 * @domain BSP
 * @description headless modal for bsp confirmation messages
 * @changelog
 * 2023-10-11 - Hasantha Liyanage - Created
 */

import {LightningElement} from 'lwc';
import {NavigationMixin} from "lightning/navigation";

export default class BspModalBasic extends NavigationMixin(LightningElement) {

	closeModal() {
		this.dispatchEvent(new CustomEvent('closemodal'));
	}
}