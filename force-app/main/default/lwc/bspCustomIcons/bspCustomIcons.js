/**
* @description Renders a custom icons and images for New BSP Lightning community usage
* @author Ankur Gandhi
* @date 2020-08-19
* @group Tracking
* @changelog
* 15/08/2023	hasantha.liyanage@auspost.com.au	added claim icon
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
	'chevron-right': '#DC1928',
	'track': '#ffffff',
	'redirect': '#ffffff',
	'register': '#ffffff',
	'missing-item': '#382F2D',
	'redeliver': '#382F2D',
	'van': '#382F2D',
	'help': '#382F2D',
	'schedule': '#382F2D',
	'round-exclaim-filled': '#EDA518',
	'round-tick': '#158744',
	'back-arrow': '#dc1928',
	'stepper-future':'#4D4E54',
	'stepper-current':'#dc1928',
	'stepper-past':'#6D6D72',
	'edit-pencil':'#31313D',
	'help-filled':'#919194',
	'support':'#31313D',
	'plus':'#31313D',
	'bin':'#31313D',
	'search':'#31313D',
	'download':'#31313D',
	'upload':'#ffffff',
	'view':'#31313D',
	'map-pin-filled':'#31313D',
	'support-filled':'#31313D',
	'round-tick-filled': '#1D964F',
	'round-cross-filled': '#D61834',
	'lock':'#4d4d54',
};

export default class BspCustomIcons extends LightningElement {

	@api icon = '';
	@api fill = 'default';
	@api size = 'medium'; // or small or large
	@api maintainHeightRatio = false;
	@api maintainWidth = false;
	@api iconclass = '';

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
	get iconIsChevronRight() {
		return this.icon === 'chevron-right';
	}
	get iconIsTrack() {
		return this.icon === 'track';
	}
	get iconIsRedirect() {
		return this.icon === 'redirect';
	}
	get iconIsRegister() {
		return this.icon === 'register';
	}
	get iconIsMissingItem() {
		return this.icon === 'missing-item';
	}
	get iconIsRedeliver() {
		return this.icon === 'redeliver';
	}
	get iconIsVan() {
		return this.icon === 'van';
	}
	get iconIsClaim() {
		return this.icon === 'claim';
	}
	get iconIsHelp() {
		return this.icon === 'help';
	}
	get iconIsSchedule() {
		return this.icon === 'schedule';
	}
	get iconIsRoundExclaim() {
		return this.icon === 'round-exclaim';
	}
	get iconIsMapPin() {
		return this.icon === 'map-pin';
	}
	get iconIsWarningAlert() {
		return this.icon === 'warning-alert';
	}
	get iconIsComplete() {
		return this.icon === 'complete';
	}
	get iconIsSTLogo() {
		return this.icon === 'st-logo';
	}
	get iconIsAPLogo() {
		return this.icon === 'ap-logo';
	}
	get iconIsRoundExclaimFilled() {
		return this.icon === 'round-exclaim-filled';
	}
	get iconIsChat() {
		return this.icon === 'chat';
	}
	get iconIsRoundTick() {
		return this.icon === 'round-tick';
	}
	get iconIsStepperFuture() {
		return this.icon === 'stepper-future';
	}
	get iconIsStepperCurrent() {
		return this.icon === 'stepper-current';
	}
	get iconIsStepperPast() {
		return this.icon === 'stepper-past';
	}
	get iconIsBackArrow() {
		return this.icon === 'back-arrow';
	}
	get iconIsEditPencil() {
		return this.icon === 'edit-pencil';
	}
	get iconIsHelpFilled() {
		return this.icon === 'help-filled';
	}
	get iconIsSupport() {
		return this.icon === 'support';
	}
	get iconIsPlus() {
		return this.icon === 'plus';
	}
	get iconIsBin() {
		return this.icon === 'bin';
	}
	get iconIsSearch() {
		return this.icon === 'search';
	}
	get iconIsDownload() {
		return this.icon === 'download';
	}
	get iconIsUpload() {
		return this.icon === 'upload';
	}
	get iconIsView() {
		return this.icon === 'view';
	}
	get iconIsMapPinFilled() {
		return this.icon === 'map-pin-filled';
	}
	get iconIsSupportFilled() {
		return this.icon === 'support-filled';
	}
	get iconIsRoundTickFilled() {
		return this.icon === 'round-tick-filled';
	}
	get iconIsRoundCrossFilled() {
		return this.icon === 'round-cross-filled';
	}
	get iconIsLock() {
		return this.icon === 'lock';
	}
	get iconIsInbox() {
		return this.icon === 'inbox';
	}
	get cssClass() {
		return this.iconclass + ' ' + this.size + ' ' + (this.maintainWidthRatio ? 'maintain-width-ratio' : (this.maintainHeightRatio ? 'maintain-height-ratio' : '' ));
	}
	get fillColour() {
		return (this.fill === 'default' && Object.keys(DEFAULT_COLOURS).includes(this.icon) ? DEFAULT_COLOURS[this.icon] : (this.fill === 'default' ? '#000000' : this.fill));
	}

}