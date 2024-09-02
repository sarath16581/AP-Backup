/**
 * @description Happy Parcel Card with a built in loader
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-21 - Disha Kariya - Added a button icon
 * 2021-10-18 - Nathan Franklin - added no-flex style
 * 2024-05-17 - Seth Heang - Added a new loading attribute next to the title of the card
 * 2024-06-14 - Seth Heang - add displayPodDownloadButton flag and send an event to generate and download Proof Of Delivery PDF
 */
import { LightningElement, api } from "lwc";
import HappyParcelBase from "c/happyParcelBase";
import { publish } from 'c/happyParcelService'


export default class HappyParcelCard extends HappyParcelBase {

	@api loading = false;
	@api titleLoading = false;
	@api title;
	@api iconName = 'standard:account';
	@api variant = 'normal'; // or vanilla or vanilla-stretch or stretch or no-flex
	@api helpText;
	@api selectable;
	@api selected;
	@api buttonIcon;
	@api buttonVariant;
	@api headingRightPadding = 0;
	@api displayPodDownloadButton = false;

	get wrapperCss() {
		return 'slds-card slds-card_boundary ' + (this.variant) + (!this.loading && this.selectable ? ' selectable' + (this.selected ? ' selected' : '') : '');
	}

	get titleLoadingSpinner() {
		return this.titleLoading;
	}

	get showPodDownloadButton() {
		return this.displayPodDownloadButton;
	}

	handleSelectableClick() {
		this.selected = !this.selected;

		if (this.selected) {
			this.dispatchEvent(new CustomEvent('select'));
		} else {
			this.dispatchEvent(new CustomEvent('deselect'));
		}
	}

	handleButtonClick() {
		this.dispatchEvent(new CustomEvent('cardbuttonclick'));
	}

	/**
	 * @description	Publish an event to the parent HappyParcel Component listener which then execute the download POD PDF action
	 */
	handlePODButtonClick() {
		publish('generatePodPDF', {});
	}

	get headingStyleOverride() {
		return 'padding-right: ' + this.headingRightPadding + 'px;';
	}

}