/**
 * @description Happy Parcel Looping and Missorts Assessment
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import { LightningElement, api } from "lwc";
import { get, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

const TYPE_MISSORT = 'missort';
const TYPE_LOOPING = 'looping';

export default class HappyParcelLoopingMissortsAssessment extends HappyParcelBase {

	@api loading = false;
	@api analyticsApiResult;

	loopingHelpText = CONSTANTS.LABEL_HAPPYPARCELLOOPINGHELPTEXT;
	missortsHelpText = CONSTANTS.LABEL_HAPPYPARCELMISSORTHELPTEXT;

	get hasLooping() {
		const issues = get(this.analyticsApiResult, 'issues', []);
		for(let i=0;i<issues.length;i++) {
			if(issues[i].type === TYPE_LOOPING) {
				return true;
			}
		}
		return false;
	}

	get hasMissorts() {
		const issues = get(this.analyticsApiResult, 'issues', []);
		for(let i=0;i<issues.length;i++) {
			if(issues[i].type === TYPE_MISSORT) {
				return true;
			}
		}
		return false;
	}

	get looping() {
		let i = 0;
		return get(this.analyticsApiResult, 'issues', []).filter(item => {
			return (item.type === TYPE_LOOPING);
		}).map(item => {
			i++;
			const type = (item.type ? item.type.toLowerCase() : '');
			return {
				...item,
				id: i,
				badgeCss: 'slds-badge slds-text-body_small ' + type,
				hasLoopingTime: (item.looping_time && item.looping_time_unit)
			};
		});
	}
	get missorts() {
		let i = 0;
		return get(this.analyticsApiResult, 'issues', []).filter(item => {
			return (item.type === TYPE_MISSORT);
		}).map(item => {
			i++;
			const type = (item.type ? item.type.toLowerCase() : '');
			return {...item, id: i, badgeCss: 'slds-badge slds-text-body_small ' + type };
		});
	}


}