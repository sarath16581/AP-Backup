/* @author Mav3rik
 * @date 2020-11-03
 * @group LPO Product Selection
 * @domain Core
 * @description LWC Component that hosts lpoSelectorList and manages input and output variables between the screen flow
 * @changelog
 * 2020-11-03 - Mav3rik - Created
 */
import { LightningElement, api } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

const PRODUCTS = {
  EPARCEL: "eParcel",
  EPARCEL_INTL: "eParcel International",
  MYPOST: "MyPost Business",
  SECUREPAY: "SecurePay",
  STARTRACK_EXPRESS: "Star Track Express",
  STARTRACK_COURIER: "Star Track Courier"
};

export default class LpoProductSelector extends LightningElement {
  _eParcel;
  _eParcelIntl;
  _myPost;
  _securePay;
  _starTrackExpress;
  _starTrackCourier;
  _datatables = [];

  // Inputs
  @api
  get eParcel() {
    return this._eParcel;
  }
  set eParcel(eParcel = []) {
    this._eParcel = eParcel;
    this.addTableItem(eParcel, PRODUCTS.EPARCEL);
  }

  @api
  get eParcelIntl() {
    return this._eParcelIntl;
  }
  set eParcelIntl(eParcelIntl = []) {
    this._eParcelIntl = eParcelIntl;
    this.addTableItem(eParcelIntl, PRODUCTS.EPARCEL_INTL);
  }

  @api
  get myPost() {
    return this._myPost;
  }
  set myPost(myPost = []) {
    this._myPost = myPost;
    this.addTableItem(myPost, PRODUCTS.MYPOST);
  }

  @api
  get securePay() {
    return this._securePay;
  }
  set securePay(securePay = []) {
    this._securePay = securePay;
    this.addTableItem(securePay, PRODUCTS.SECUREPAY);
  }

  @api
  get starTrackExpress() {
    return this._starTrackExpress;
  }
  set starTrackExpress(starTrackExpress = []) {
    this._starTrackExpress = starTrackExpress;
    this.addTableItem(starTrackExpress, PRODUCTS.STARTRACK_EXPRESS);
  }

  @api
  get starTrackCourier() {
    return this._starTrackCourier;
  }
  set starTrackCourier(starTrackCourier = []) {
    this._starTrackCourier = starTrackCourier;
    this.addTableItem(starTrackCourier, PRODUCTS.STARTRACK_COURIER);
  }

  addTableItem(data, label) {
    this._datatables.push({ data, label });
  }

  // Outputs
  @api eParcelSelected = [];
  @api eParcelIntlSelected = [];
  @api myPostSelected = [];
  @api securePaySelected = [];
  @api starTrackExpressSelected = [];
  @api starTrackCourierSelected = [];

  // helper function that dispatches an event that updates the output variable
  updateOutput(outputName, data) {
    const flowEvent = new FlowAttributeChangeEvent(outputName, data);
    this.dispatchEvent(flowEvent);
  }

  // Updates flow each time any child updates their selection
  handleRowSelection(event) {
    const detail = event.detail;
    switch (detail.tableId) {
      case PRODUCTS.EPARCEL:
        this.eParcelSelected = detail.rows;
        this.updateOutput("eParcelSelected", this.eParcelSelected);
        break;
      case PRODUCTS.EPARCEL_INTL:
        this.eParcelIntlSelected = detail.rows;
        this.updateOutput("eParcelIntlSelected", this.eParcelIntlSelected);
        break;
      case PRODUCTS.MYPOST:
        this.myPostSelected = detail.rows;
        this.updateOutput("myPostSelected", this.myPostSelected);
        break;
      case PRODUCTS.SECUREPAY:
        this.securePaySelected = detail.rows;
        this.updateOutput("securePaySelected", this.securePaySelected);
        break;
      case PRODUCTS.STARTRACK_EXPRESS:
        this.starTrackExpressSelected = detail.rows;
        this.updateOutput(
          "starTrackExpressSelected",
          this.starTrackExpressSelected
        );
        break;
      case PRODUCTS.STARTRACK_COURIER:
        this.starTrackCourierSelected = detail.rows;
        this.updateOutput(
          "starTrackCourierSelected",
          this.starTrackCourierSelected
        );
        break;
      default:
        break;
    }
  }
}