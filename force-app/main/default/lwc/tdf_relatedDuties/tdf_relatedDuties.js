import {LightningElement, api, track} from "lwc";
export default class Tdf_relatedDuties extends LightningElement {
    @api otherAppointments;
    @api recordId;
    @track selectedItems = {};
    @track updatedItems = {};
    @track expandItems = {};
    get relatedAppointments() {
        let appointments = [];
        if (this.otherAppointments) {
            appointments = JSON.parse(JSON.stringify(this.otherAppointments));
            appointments.forEach((record) => {
                if (this.expandItems[record.record.Id]) 
                    record.isShow = true;
                
                // if(record.collectFrom && record.collectFrom.length) record.isShowButton = true;
                // if(record.deliverTo && record.deliverTo.length) record.isShowButton = true;
                if (record.record.SchedStartTime) {
                    record.record.start = new Date(record.record.SchedStartTime).getTime();
                    record.record.startTime = new Date(record.record.SchedStartTime).toLocaleTimeString();
                }
                if (record.record.SchedEndTime) {
                    record.record.end = new Date(record.record.SchedEndTime).getTime();
                    record.record.endTime = new Date(record.record.SchedEndTime).toLocaleTimeString();
                }
                if (!record.record.Primary_SR__r) {
                    record.record.Primary_SR__r = {};
                }
                if (!record.record.Service_Resource__r) {
                    record.record.Service_Resource__r = {};
                }
                if (record.record.Id === this.recordId) {
                    record.isChecked = true;
                }
            });
        }
        return appointments;
    }

    checkupdate(event) {
        let targetValue = event.target.value;
        let name = event.target.name;
        let Id = event.target.dataset.id;
        this.updatedItems[Id] = {
            Id
        };
        this.updatedItems[Id][name] = targetValue;
    }

    @api getUpdatedDateTime() {
        return JSON.stringify(this.updatedItems);
    }
    checkForItem(event) {
        let isChecked = event.target.checked;
        let name = event.target.name;
        if (name === "all") {
            this.updateChecked(isChecked);
        }
    }
    @api getChecked() {
        let inputs = this.template.querySelectorAll("lightning-input");
        let idList = [];
        inputs.forEach((item) => {
            if (item.name !== "all" && item.checked) {
                idList.push(item.name);
            }
        });
        return idList;
    }
    updateChecked(isChecked) {
        let inputs = this.template.querySelectorAll("lightning-input");
        inputs.forEach((item) => {
            if (item.name !== "all") {
                item.checked = isChecked;
            }
        });
    }
    showDependency(event) {
        const id = event.target.dataset.value;
        const label = event.target.label;
        if (label === "Hide") {
            this.expandItems[id] = false;
        } else {
            this.expandItems[id] = true;
        }
    }
    checkForAll(isChecked) {
        let inputs = this.template.querySelectorAll("lightning-input");
        let willSync = true;
        inputs.forEach((item) => {
            if (item.name !== "all" && item.checked !== isChecked) {
                willSync = false;
            }
        });
        if (willSync) {
            inputs.forEach((item) => {
                if (item.name === "all") {
                    this.checked = isChecked;
                }
            });
        }
    }
}