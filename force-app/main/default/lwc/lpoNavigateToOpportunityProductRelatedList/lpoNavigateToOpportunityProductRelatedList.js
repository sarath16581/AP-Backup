/* @author Mav3rik
 * @date 2020-11-03
 * @group LPO Product Selection
 * @domain Core
 * @description LWC Component for Navigating to the Related List of Opportunity Product
 * @changelog
 * 2020-11-03 - Mav3rik - Created
 */
import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class LpoNavigateToOpportunityProductRelatedList extends NavigationMixin(LightningElement) {
  _recordId;
  @api 
  get recordId() { return this._recordId };
  set recordId(recordId = '') { this._recordId = recordId };

  // Detects the screen flow change and navigate away if recordId if not null
  @api
  validate() {
    if (this._recordId != '') {
      this[NavigationMixin.Navigate]({
        type: "standard__recordRelationshipPage",
        attributes: {
          recordId: this._recordId,
          objectApiName: "Opportunity",
          relationshipApiName: "OpportunityLineItems",
          actionName: "view"
        }
      });
    }
  }
}