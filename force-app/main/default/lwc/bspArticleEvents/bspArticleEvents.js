/**
 * @description LWC for displaying article event table in article's tracking Id search result for BSP Community
 * @changelog:
 * 2024-08-02 - Seth Heang - added passSafeDropDownloadState attribute pass-through
 */
import { LightningElement, api } from 'lwc';

export default class BspArticleEvents extends LightningElement {
	@api isConsignmentAuthenticated;
	@api events;
	@api reqFrom;
	@api emScanTypes;
	@api isConsignmentSerchIsAPType;
	@api isConsignmentSerchIsSTType;
	@api passSafeDropDownloadState;
}