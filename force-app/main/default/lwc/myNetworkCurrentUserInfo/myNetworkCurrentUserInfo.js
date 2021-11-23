import { LightningElement, api, track, wire } from "lwc";
import USER_ID from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/User.FirstName";
import CUSTOM_LOGO from '@salesforce/resourceUrl/MyNetworkCustomLogo';
export default class userDetails extends LightningElement {
  @track error;
  @track name;
  @api totalOpenCases = 0;
  myNetworkCustomLogo = CUSTOM_LOGO+'/MyNetworkCustomLogo.png'
  @wire(getRecord, {
    recordId: USER_ID,
    fields: [NAME_FIELD]
  })
  wireuser({ error, data }) {
    if (error) {
      this.error = error;
    } else if (data) {
      this.name = data.fields.FirstName.value;
    }
  }
}