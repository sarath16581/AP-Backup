import {LightningElement, api, track} from "lwc";
import getServiceAppointment from "@salesforce/apex/TDF_MoveCollectDeliverCtrl.getServiceAppointment";
import getRelatedAppointments from "@salesforce/apex/TDF_MoveCollectDeliverCtrl.getRelatedAppointments";
import reassignRecords from "@salesforce/apex/TDF_MoveCollectDeliverCtrl.reassignRecords";

export default class Tdf_serviceAppointments extends LightningElement {
    @api recordId;
    @api startDate;
    @api endDate;
    @track showSuccess = false;
    @track loading = false;
    @track isShowDetail = true;
    @track showButton = false;
    @track record = {
        Service_Resource__r: {},
        Primary_SR__r: {}
    };
    @track duty = {};
    @track serviceCrew = "";
    @track dutyDay = "";
    @track driver = "";
    @track otherAppointments = [];
    connectedCallback() {
        const {recordId} = this;
        getServiceAppointment({recordId}).then((res) => {
            this.record = JSON.parse(res);
            if (this.record.Duty_Board__r) {
                this.duty = this.record.Duty_Board__r;
            }
            if (this.record.Service_Resource__r) {
                this.driver = this.record.Service_Resource__r.Name;
            }
            if (this.record.Primary_SR__r) {
                this.serviceCrew = this.record.Primary_SR__r.Name;
            }
            if (this.record.Work_Order__r.Duty_Day__c) {
                this.dutyDay = this.record.Work_Order__r.Duty_Day__c;
            }
        });
        this.showOtherJobs();
    }
    reassign() {
        this.loading = true;
        let idList = [];
        if (this.template.querySelector("c-tdf_related-duties")) {
            idList = this.template.querySelector("c-tdf_related-duties").getChecked();
        }

        let updatedDateTime = this.template.querySelector("c-tdf_related-duties").getUpdatedDateTime();

        const {recordId} = this;
        const inputfields = this.template.querySelectorAll("lightning-input-field");
        const assignedResourceId = inputfields[0].value;
        idList.push(recordId);
        reassignRecords({recordId, idList, assignedResourceId, updatedDateTime}).then(() => {
            this.showOtherJobs();
            this.loading = false;
            this.showSuccess = true;
            window.parent.postMessage("closeLightbox", "*");
        }).catch(() => {
            this.loading = false;
        });
    }
    showOtherJobs() {
        const {recordId} = this;
        this.showButton = false;
        this.isShowDetail = false;
        getRelatedAppointments({recordId}).then((res) => {
            this.otherAppointments = JSON.parse(res);
            if (this.otherAppointments && this.otherAppointments.length) {
                this.isShowDetail = true;
            }
        });
    }

    convertToAdhocJob() {
        this.showButton = false;
    }
}