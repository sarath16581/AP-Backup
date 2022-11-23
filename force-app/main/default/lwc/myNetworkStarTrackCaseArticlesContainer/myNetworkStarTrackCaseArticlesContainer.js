import {
    api,
    LightningElement
} from 'lwc';
import {
    getArticles
} from 'c/myNetworkStarTrackCaseArticlesService';


export default class MyNetworkStarTrackCaseArticlesContainer extends LightningElement {

    @api recordId; //case id
    hasPassedThroughAPNetwork = false; //flag to determine the articles passed through AP Network scans
    isLoading = false; //flag to show/hide the spinner on server call
    articleDetails; //articles related to case from apex

    connectedCallback() {
        this.isLoading = true;
        //get articles related to case
        getArticles(this.recordId)
            .then(response => {
                this.hasPassedThroughAPNetwork = response.hasPassedThroughAPNetwork;
                if (this.hasPassedThroughAPNetwork) {
                    this.articleDetails = response.articleDetails;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.error('getArticles call failed: ' + error);
            })

    }
}