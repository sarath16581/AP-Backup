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
import HAPPY_PARCEL_ASSETS from '@salesforce/resourceUrl/HappyParcelAssets';

let resourcesLoaded;

export default class HappyParcelBase extends LightningElement {

	@api animationDelay = 0;
	@api animationSpeed = 500;

	connectedCallback() {
		if(!resourcesLoaded) {
			Promise.all([
				loadStyle(this, GLOBAL_ASSETS + '/css/animatecss/3.7.2/animate.css'),
				loadStyle(this, HAPPY_PARCEL_ASSETS + '/HappyParcelAssets/css/global-overrides.css')
			]).then(() => {
				resourcesLoaded = true;
			}).catch(error => {
				console.error('Unable to load resource: '+ error.body.message);
			})
		}
	}

	get animationCss() {
		return this.getAnimationStyleCss(this.animationDelay, this.animationSpeed);
	}

	getAnimationStyleCss(delay, speed) {
		return 'animation-delay: ' + (delay ? delay : this.animationDelay) + 'ms;animation-duration: ' + (speed ? speed : this.animationSpeed) + 'ms;';
	}
}