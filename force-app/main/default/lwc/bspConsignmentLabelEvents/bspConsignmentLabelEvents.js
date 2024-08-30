/**
 * @description LWC for displaying article event table in article's tracking Id search result for BSP Community
 * @changelog:
 * 2024-08-02 - Seth Heang - added passSafeDropDownloadState attribute pass-through
*/
import { LightningElement, api } from 'lwc';

export default class BspConsignmentLabelEvents extends LightningElement {
	@api labelEvents;
	@api selectedEventArticle;
	@api selectedConsignmentSearchType;
	@api isConsignmentAuthenticated;
	@api isConsignmentSerchIsAPType;
    

	onChangeOfSelectedEvent(event){
		const c = new CustomEvent('selectedarticlechange', {detail : event.detail});
		this.dispatchEvent(c);
    }

	@api 
	setSafeDropDownloadLoading(isLoading) {
		this.template.querySelectorAll("c-bsp-label-event-row").forEach((item) => {
			item.setSafeDropDownloadLoading(isLoading);
		});
		  
	}
}