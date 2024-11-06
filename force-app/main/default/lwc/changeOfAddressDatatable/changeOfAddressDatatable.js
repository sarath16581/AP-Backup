/**
 * @description Custom Datatable extends standard datatable to have control of scrolling
 * @author Harry Wang
 * @date 2024-10-16
 * @changelog
 * 2024-10-16 - Harry Wang - Created
 */
import {api} from 'lwc';
import LightningDatatable from "lightning/datatable";

export default class ChangeOfAddressDatatable extends  LightningDatatable {

	/**
	 *  Override parent's scrollToTop to have full control
	 */
	@api
	scrollToTop() {
		this.template.querySelector(".slds-scrollable_y").scrollTop = 0;
	}
}