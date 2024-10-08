import { LightningElement, api } from 'lwc';
import DesertTemplate from './templates/Desert.html';
import FishingDealsTemplate from './templates/FishingDeals.html';
import NoAccessTemplate from './templates/NoAccess.html';
import NoAccess2Template from './templates/NoAccess2.html';
import OpenRoadTemplate from './templates/OpenRoad.html';
import ParagraphTemplate from './templates/Paragraph.html';

/**
 * The Empty State component displays an empty-state graphic along optional text.
 *
 * You can pass markup into the component to display more complex content.
 *
 * **Example:**
 *
 * `<c-empty-state illustration='desert'>Click <a href="#">here</a> for more information</c-empty-state>`
 *
 * For more information on empty states and illustrations, refer to the Lightning Design System docs:
 *
 * - https://www.lightningdesignsystem.com/guidelines/empty-state/
 * - https://www.lightningdesignsystem.com/components/illustration
 *
 * @alias EmptyState
 * @hideconstructor
 */
export default class EmptyState extends LightningElement {
	/**
	 * The empty state image to display.
	 * @type {'desert'|'fishingDeals'|'noAccess'|'noAccess2'|'openRoad'|'paragraph'}
	 */
	@api illustration;

	/**
	 * Size of the image to display. Default: 'large'
	 *
	 * Sets the class `slds-illustration_small` or `slds-illustration_large`
	 * @type {'small'|'large'}
	 */
	@api size = 'large';

	/**
	 * The title text to display. (Optional)
	 *
	 * _Note: This will be ignored if markup is passed into the component._
	 * @type {string}
	 */
	@api titleText;

	/**
	 * The body text to display. (Optional)
	 *
	 * _Note: This will be ignored if markup is passed into the component._
	 * @type {string}
	 */
	@api bodyText;

	/**
	 * Position the text above or below the image. Default: 'below'
	 * @type {'above'|'below'}
	 */
	@api textPosition = 'below';

	/**
	 * Renders the empty state template based on the illustration property.
	 * 
	 * See Salesforce docs for reference: https://developer.salesforce.com/docs/platform/lwc/guide/create-render.html
	 */
	render() {
		if (this.illustration === 'desert') {
			return DesertTemplate;
		}

		if (this.illustration === 'fishingDeals') {
			return FishingDealsTemplate;
		}

		if (this.illustration === 'noAccess') {
			return NoAccessTemplate;
		}
		
		if (this.illustration === 'noAccess2') {
			return NoAccess2Template;
		}

		if (this.illustration === 'openRoad') {
			return OpenRoadTemplate;
		}

		if (this.illustration === 'paragraph') {
			return ParagraphTemplate;
		}

		throw new Error(`EmptyState: Invalid illustration '${this.illustration}'`);
	}

	get illustrationClass() {
		if (this.size === 'small') {
			return 'slds-illustration slds-illustration_small';
		}

		return 'slds-illustration slds-illustration_large';
	}

	get gridClass() {
		if (this.textPosition === 'above') {
			return 'slds-grid slds-grid_vertical-reverse';
		}

		return 'slds-grid slds-grid_vertical';
	}

	get textPositionAbove() {
		return this.textPosition === 'above';
	}

	get textPositionBelow() {
		return !this.textPositionAbove;
	}
}