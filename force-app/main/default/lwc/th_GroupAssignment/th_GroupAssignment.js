/**
 * Created by alexvolkov on 6/2/20.
 */

import { LightningElement,track } from 'lwc';
import assignTrainingToGroups from '@salesforce/apex/TH_GroupAssignmentController.assignTrainingToGroups';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';

export default class Th_GroupAssignment extends LightningElement {

 @track badges = [];
 @track mixes = [];
 @track showAddBadge = true;
 @track showAddMix = true;
 @track showSpinner = false;

 filterMap = {Type : "Regular"};
 selectedGroupId
 @track selectedBadge;
 @track selectedMix;
 dueDate;
 minDueDate = (new Date()).getFullYear() + "-" + String((new Date()).getMonth() + 1).padStart(2, '0') + "-" + String((new Date()).getDate()).padStart(2, '0') + 'T00:00:00Z';

 updateDate(event){
        this.dueDate = event.target.value;
 }

 handleGroupSelection = (record) => {
                             if(record) this.selectedGroupId = record.Id;
                }

 handleBadgeSelection = (record) => {
                            if(record) this.selectedBadge = record;
                }

  handleMixSelection = (record) => {
                              // console.log(record);
                              if(record) this.selectedMix = record;
                              // console.log(this.selectedMix);
                  }

 handleAddBadge(){
   // console.log(this.selectedBadge);
    if (this.selectedBadge && this.selectedBadge.Id)
    {
    if (!this.badges.find(b => b.Id === this.selectedBadge.Id))
    {
    this.badges.push({type: 'icon', label: this.selectedBadge.Name, Id: this.selectedBadge.Id, iconName: 'custom:custom48'});
    this.badges = [...this.badges];
   // this.template.querySelector('[data-id="badgelookup"]').setSelectedRecord(null);
   // this.template.querySelector('[data-id="badgelookup"]').clearSearchTerm();
   // this.selectedBadge = null;
    if(this.badges.length > 4) this.showAddBadge = false;
    }
    }
    else
    {
      this.dispatchEvent(new ShowToastEvent({
                                              title: 'Error occured',
                                              message: 'Please select a badge first',
                                              variant: 'error',
                                                                               }),
                                                                           );
    }

 }

  handleAddMix(){
   //  console.log(this.selectedMix);
     if (this.selectedMix && this.selectedMix.Id)
         {
         if (!this.mixes.find(m => m.Id === this.selectedMix.Id))
         {
         this.mixes.push({type: 'icon', label: this.selectedMix.Name, Id: this.selectedMix.Id, iconName: 'custom:custom78'});
         this.mixes = [...this.mixes];
        // this.template.querySelector('[data-id="mixlookup"]').setSelectedRecord(null);
        // this.template.querySelector('[data-id="mixlookup"]').clearSearchTerm();
        // this.selectedMix = null;
        if(this.mixes.length > 4) this.showAddMix = false;
         }
         }
         else
         {
           this.dispatchEvent(new ShowToastEvent({
                                                   title: 'Error occured',
                                                   message: 'Please select a trailmix first',
                                                   variant: 'error',
                                                                                    }),
                                                                                );
         }
  }

  handleRemoveBadge(event){
      this.badges = this.badges.filter(b => !(b.Id === event.detail.item.Id));
      if(this.badges.length < 5) this.showAddBadge = true;
  }

  handleRemoveMix(event){
        this.mixes = this.mixes.filter(m => !(m.Id === event.detail.item.Id));
        if(this.mixes.length < 5) this.showAddMix = true;
    }

  handleAssign(){
     if (this.selectedGroupId && (this.badges.length > 0 || this.mixes.length > 0) && this.dueDate){
      this.showSpinner = true;
      assignTrainingToGroups({pGroupIds: [this.selectedGroupId], pBadgeIds: this.badges.map(b => b.Id), pMixIds: this.mixes.map(m => m.Id), pDueDate: this.dueDate})
      .then(result => {
          this.showSpinner = false;
          this.dispatchEvent(
                          new ShowToastEvent({
                              title: 'Success',
                              message: 'Assignments enqueued successfully and will be created shortly',
                              variant: 'success'
                          })
                      )
           eval("$A.get('e.force:refreshView').fire();");
      })
      .catch(error => {
          this.showSpinner = false;
          this.dispatchEvent(new ShowToastEvent({
                                                          title: 'Error occured',
                                                          message: reduceErrors(error).join(', '),
                                                          variant: 'error',
                                                                         }),
                                                                     );
      })
     }
     else {
         this.dispatchEvent(new ShowToastEvent({
                                                title: 'Error',
                                                message: 'Please select a group, at least one badge/trailmix and a due date',
                                                variant: 'error',
                                                               }),
                                                           );
     }
  }
}