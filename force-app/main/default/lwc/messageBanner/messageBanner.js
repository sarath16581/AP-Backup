/**
 * @description Banner messages in Help and support community
 * @author Mahesh Parvathaneni
 * @date 2022-05-17
 * @changelog
 */

import { api, LightningElement } from "lwc";

export default class MessageBanner extends LightningElement {
	@api message; //message from parent
	@api bannerType; //banner type exposed to parent
	@api imgLink; //image link exposed to parent
	@api dispatchCloseEvent = false; //dispatch close event to parent
	bannerClass = "banner-container"; // css class for banner container

	connectedCallback() {
		if (this.bannerType) {
			this.bannerClass = this.bannerClass + " " + this.bannerType;
		}
	}

	//handler for close icon
	//dispatches event to the parent if required
	handleCloseIconClick() {
		this.template
			.querySelector("div.banner-container")
			.classList.add("slds-hide");
		if (this.dispatchCloseEvent) {
			this.dispatchEvent(new CustomEvent("closebanner"));
		}
	}
}
