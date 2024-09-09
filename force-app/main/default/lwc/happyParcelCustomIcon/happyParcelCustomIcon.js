/**
 * @description Renders a custom icons and images for Happy Parcel usage
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import {LightningElement, api} from 'lwc';

// list of colours to use where a colour is not specified for the icon
const DEFAULT_COLOURS = {
	'close': '#ff0000',
	'tick': '#00ff00',
	'warning': '#ef8d22',
	'sad-face': '#fccf3e',
	'happy-face': '#fccf3e',
	'wink-face': '#fccf3e',
	'neutral-face': '#fccf3e',
	'event-message': '#ffffff',
	'dash': '#00ff00'
};

export default class HappyParcelCustomIcon extends LightningElement {
	
	@api icon = '';
	@api colour = 'default';
	@api size = 'medium'; // or small or large
	@api maintainHeightRatio = false;
	@api maintainWidth = false;

	get iconIsClose() {
		return this.icon === 'close';
	}
	get iconIsTick() {
		return this.icon === 'tick';
	}
	get iconIsCamera() {
		return this.icon === 'camera';
	}
	get iconIsNotFound() {
		return this.icon === 'not-found';
	}
	get iconIsSadFace() {
		return this.icon === 'sad-face';
	}
	get iconIsHappyFace() {
		return this.icon === 'happy-face';
	}
	get iconIsWinkFace() {
		return this.icon === 'wink-face';
	}
	get iconIsWarning() {
		return this.icon === 'warning';
	}
	get iconIsNeutralFace() {
		return this.icon === 'neutral-face';
	}
	get iconIsExclamation() {
		return this.icon === 'exclamation';
	}
	get iconIsEventMessage() {
		return this.icon === 'event-message';
	}
	get cssClass() {
		return this.size + ' ' + (this.maintainWidthRatio ? 'maintain-width-ratio' : (this.maintainHeightRatio ? 'maintain-height-ratio' : '' ));
	}
	get fillColour() {
		return (this.colour === 'default' && Object.keys(DEFAULT_COLOURS).includes(this.icon) ? DEFAULT_COLOURS[this.icon] : (this.colour === 'default' ? '#000000' : this.colour));
	}
	get iconIsDash(){
		return this.icon === 'dash';
	}
}