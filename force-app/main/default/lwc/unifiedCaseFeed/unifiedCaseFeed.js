/**
 * @description This LWC component displays case's related feed update from associated objects such as Scheduled Contact Requests, EmailMessage and Scan Event Messages
 *          The list is sorted in descending order where latest changes will be displayed at the top row, and in the leftmost of the three cards of the row.
 * @author Seth Heang
 * @changelog
 * 2024-06-23 - Seth Heang - created
 */
import { LightningElement, wire, api } from 'lwc';
import getLatestCaseFeedsResults from '@salesforce/apex/UnifiedCaseFeedController.getLatestCaseFeedsResults';
import { reduceErrors } from 'c/ldsUtils';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

const CONTACT_REQUEST_ICON = 'standard:contact_request';

export default class UnifiedCaseFeed extends NavigationMixin(LightningElement) {
	/**
	 * The record Id from Case lightning record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * Used to display an error message to the user.
	 * @type {string}
	 */
	errorMessage;

	/**
	 * Used to toggle loading spinner state while query is loading
	 * @type {boolean}
	 */
	isLoading;

	/**
	 * Used to toggle loading spinner state while query is loading
	 * @type {boolean}
	 */
	viewMore = false;

	/**
	 * Used to store feed results from wire adaptor and used for refreshApex() data refresh
	 * @type {{feedHeader: string, feedBody: string, feedDateTime: string, feedCustomIcon: string, feedRecordId: string}[]}
	 */
	wiredFeedResults= [];

	/**
	 * Used to store feed results and data manipulation (e.g. DateTime formatted and sorted) for UI display
	 * @type {{feedHeader: string, feedBody: string, feedDateTime: string, feedCustomIcon: string, feedRecordId: string}[]}
	 */
	feedResults = [];

	/**
	 * @description wire adaptor to get the latest case feed results from related objects such as SCR, Email and Scan Event.
	 * @param caseId pass to apex controller to query related feed objects
	 * @return result list of wrapper objects with generic attributes for ease of display
	 */
	@wire(getLatestCaseFeedsResults, { caseId: "$recordId" })
	wiredCaseFeeds(result) {
		try {
			this.isLoading = true;
			console.log("SETH result wired: " + JSON.stringify(result));
			// this variable "wiredFeedResults" is used for refreshApex()
			this.wiredFeedResults = result;
			if (result.error) {
				console.error(result.error);
				this.errorMessage = reduceErrors(result.error).join(",");
				this.isLoading = false;
			} else if (result.data) {
				this.feedResults = result.data;
				this.feedResults = this.feedResults.map((item) => {
					return {
						...item,
						iconClass: item.feedCustomIcon === CONTACT_REQUEST_ICON ? "scr-icon-color" : ""
					};
				});
				// Sorting the feedResults by feedDateTime in descending order
				this.feedResults = this.sortFeedDateTimeInDescendingOrder(this.feedResults);

				// Loop over the feedResults and format each feedDateTime
				this.feedResults = this.feedResults.map((item) => {
					return {
						...item,
						formattedDateTime: this.formatDateTimeWithTimeZone(item.feedDateTime, "Australia/Sydney")
					};
				});
			}
		} catch (error) {
			console.error(error);
			this.errorMessage = reduceErrors(error).join(", ");
		} finally {
			this.isLoading = false;
		}
	}

	/**
	 * @description sort date time in descending order (latest date time comes first in the list)
	 * @param feedResults
	 * @returns {{feedHeader: string, feedBody: string, feedDateTime: string, feedCustomIcon: string, feedRecordId: string}[]}
	 */
	sortFeedDateTimeInDescendingOrder(feedResults) {
		if (!feedResults && feedResults.length === 0) {
			return;
		}
		return feedResults.sort((a, b) => new Date(b.feedDateTime) - new Date(a.feedDateTime));
	}

	/**
	 * @description Format date and time string from UTC to a more readable format (e.g. 24/09/2024 10:24 pm)
	 * @param dateString
	 * @param timeZone
	 * @returns {string}
	 */
	formatDateTimeWithTimeZone(dateString, timeZone) {
		if (!dateString || !timeZone) {
			return "";
		}
		const date = new Date(dateString);

		// Format date part with time zone
		const optionsDate = { year: "numeric", month: "numeric", day: "numeric", timeZone: timeZone };
		const formattedDate = new Intl.DateTimeFormat("en-AU", optionsDate).format(date);

		// Format time part with time zone
		const optionsTime = { hour: "2-digit", minute: "2-digit", hour12: true, timeZone: timeZone };
		const formattedTime = new Intl.DateTimeFormat("en-AU", optionsTime).format(date);

		// Combine date and time
		return `${formattedDate} ${formattedTime}`;
	}

	/**
	 * @description determine if there is no feed results and used to display empty-state illustration
	 * @returns {boolean}
	 */
	get noFeedResult() {
		return this.feedResults.length === 0;
	}

	/**
	 * @description determine if there is more than 3 feed results and used to display view more button
	 * @returns {boolean}
	 */
	get hasMoreRows() {
		return this.feedResults.length > 3;
	}

	/**
	 * @description get numbers of feed results hidden behind view more button
	 * @returns {number}
	 */
	get viewMoreCount() {
		return this.feedResults.length - 3;
	}

	/**
	 * @description split the full feed results list and only get the 3 latest feed results
	 * @returns {{feedHeader: string, feedBody: string, feedDateTime: string, feedCustomIcon: string, feedRecordId: string}[]} the 3 latest feed results
	 */
	get latest3Feeds() {
		return this.feedResults.slice(0, 3);
	}

	/**
	 * @description split the full feed results list and get the remaining feed results after the 3 latest feeds
	 * @returns {{feedHeader: string, feedBody: string, feedDateTime: string, feedCustomIcon: string, feedRecordId: string}[]} remaining feed results after the 3 latest feeds
	 */
	get remainingFeeds() {
		return this.feedResults.slice(3);
	}

	/**
	 * @description refresh the feed results query from apex controller
	 * @returns {Promise<void>}
	 */
	async handleRefreshFeeds() {
		this.isLoading = true;
		await refreshApex(this.wiredFeedResults);
		this.isLoading = false;
	}

	/**
	 * @description toggle viewMore flag on/off for UI visibility
	 */
	handleViewMore() {
		this.viewMore = !this.viewMore;
	}

	/**
	 * @description open a subtab of the console case tab
	 * @param event contain recordId where the navigation redirects to the record page
	 */
	navigateToRecordViewPage(event) {
		const recordId = event.target.dataset.value;
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: recordId,
				actionName: "view"
			}
		});
	}
}
