/*
* @author Victor.Cheng@auspost.com.au
* @date 2021-01-11
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Reference details
* @changelog
* 2021-01-11 Victor.Cheng@auspost.com.au  Created
*
*/
import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepBusinessRefs extends bcaStepBase {

    @track _businessRefs = [];
    @api get businessRefs() {
        return this._businessRefs;
    };

    @track showEditing = false;
    @track editingRef;

    connectedCallback() {

        if(this.creditAssessment && this.creditAssessment.businessRefs){
            this._businessRefs = this.creditAssessment.businessRefs;
        }
        else{
            this._businessRefs = [];
        }
    }


    get totalRefs() {
        return this._businessRefs.length;
    }

    get anyRefs() {
        return this._businessRefs.length != 0;
    }

    get onlyOneRef()
    {
        return this._businessRefs.length == 1;
    }


    clickAdd(event) {
        this.addRef();
        this.editingRef = this._businessRefs[this._businessRefs.length-1];
        this.showEditing = true;
        this.updateNavButtons(false, false);
    }

    addRef(event) {
        this.editingRef = {
            collapsed :false
            ,index: this._businessRefs.length + 1
            ,firstName:'',middleName:'',lastName:''
            ,knownByOtherName:false, timeAtAddress:true
        };
        this._businessRefs.push(this.editingRef);
    }

    deleteRef = (event) =>{
        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id - 1;
        }
        else
        {
            index = event.target.dataset.id - 1;
        }

        this._businessRefs.splice(index, 1);

        // hack to force LWC to track the change in the array
        this._businessRefs = [...this._businessRefs];

        // rename the indices
        for(let i = 0; i < this._businessRefs.length; ++i)
        {
            let ref = this._businessRefs[i];
            ref.index = i + 1;
        }
    }

    editRef(event){
        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id - 1;
        }
        else
        {
            index = event.target.dataset.id - 1;
        }
        this.editingRef = this._businessRefs[index];
        this.showEditing = true;
        this.updateNavButtons(false, false);
    }

    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;
        switch (field) {
            default:
                this.editingRef[field] = newValue;
                break;
        }
    }

    closeEditing(event) {
        this.editingRef = null;
        this.showEditing = false;

        this.updateNavButtons(true, true);
    }

}