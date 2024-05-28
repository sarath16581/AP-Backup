/**
 * @description Custom Datatable extends standard datatable to have control of scrolling
 * @author Harry Wang
 * @date 2024-05-17
 * @changelog
 * 2024-05-17 - Harry Wang - Created
 */
import {api} from 'lwc';
import LightningDatatable from "lightning/datatable";

export default class AbnChangeContactList extends  LightningDatatable {

	/**
	 *  Override parent's scrollToTop to have full control
	 */
	@api
	scrollToTop() {
		this.template.querySelector(".slds-scrollable_y").scrollTop = 0;
	}
}