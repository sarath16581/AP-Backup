/* @author Mav3rik
 * @date 2020-11-03
 * @group LPO Product Selection
 * @domain Core
 * @description LWC Component for showing selected Opportunity Products in datatables
 * @changelog
 * 2020-11-03 - Mav3rik - Created
 */
import { LightningElement, api } from 'lwc';

export default class LpoSelectorList extends LightningElement {
  _data;
  _columnLabel;

  @api
  get tableData() {
    return this._data;
  }
  set tableData(tableData = []) {
    this._data = tableData;
  }
  @api
  get columnLabel() {
    return this._columnLabel;
  }
  set columnLabel(columnLabel = "") {
    this._columnLabel = columnLabel;
  }

  get _columns() {
    return [
      {
        label: `${this._columnLabel} Product`,
        fieldName: "Name",
        iconName: "standard:product",
        hideDefaultActions: true
      }
    ];
  }

  // dispatch event to update lpoProductSelector
  getSelectedRows(event) {
    this.dispatchEvent(
      new CustomEvent("childselected", {
        detail: { tableId: this._columnLabel, rows: event.detail.selectedRows }
      })
    );
  }
}