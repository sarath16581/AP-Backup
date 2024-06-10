/**
 * @description Happy Parcel Card with a built in loader
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 * 2020-09-21 - Disha Kariya - Added a button icon
 * 2021-10-18 - Nathan Franklin - added no-flex style
 * 2024-05-17 - Seth Heang - Added a new loading attribute next to the title of the card
 */
import { LightningElement, api } from "lwc";
import HappyParcelBase from "c/happyParcelBase";

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

	get wrapperCss() {
		return 'slds-card slds-card_boundary ' + (this.variant) + (!this.loading && this.selectable ? ' selectable' + (this.selected ? ' selected' : '') : '');
	}

	get titleLoadingSpinner(){
		return this.titleLoading;
	}

	handleSelectableClick() {
		this.selected = !this.selected;

		if(this.selected) {
			this.dispatchEvent(new CustomEvent('select'));
		} else {
			this.dispatchEvent(new CustomEvent('deselect'));
		}
	}

	handleButtonClick(){
	    this.dispatchEvent(new CustomEvent('cardbuttonclick'));
	}

	get headingStyleOverride() {
		return 'padding-right: ' + this.headingRightPadding + 'px;';
	}

}