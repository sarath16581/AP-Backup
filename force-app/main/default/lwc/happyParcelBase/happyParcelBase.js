/**
 * @description Base component which defines a number of useful properties and animate.css
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import { LightningElement, api } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import GLOBAL_ASSETS from '@salesforce/resourceUrl/GlobalAssets';

let resourcesLoaded;

export default class HappyParcelBase extends LightningElement {

	@api animationDelay = 0;
	@api animationSpeed = 500;

	connectedCallback() {
		if(!resourcesLoaded) {
			resourcesLoaded = true;
			loadStyle(this, GLOBAL_ASSETS + '/css/animatecss/3.7.2/animate.css');
		}
	}

	get animationCss() {
		return this.getAnimationStyleCss(this.animationDelay, this.animationSpeed);
	}

	getAnimationStyleCss(delay, speed) {
		return 'animation-delay: ' + (delay ? delay : this.animationDelay) + 'ms;animation-duration: ' + (speed ? speed : this.animationSpeed) + 'ms;';
	}
}