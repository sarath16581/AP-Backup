/**
 * @description Paginator component with functionality to navigate across the pages, 
 *              accepts the current page and total pages
 * @author Mahesh Parvathaneni
 * @date 2022-11-28
 */
import {
    api,
    LightningElement
} from 'lwc';

export default class PaginatorLwc extends LightningElement {
    @api currentPage; //current page passed from parent
    @api totalPages; //total pages passed from parent
    pageList = []; //page list to display

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    get previousChevronClass() {
        return this.isPreviousDisabled ? "chevron-left-inactive slds-var-p-right_x-small" : "chevron-left slds-var-p-right_x-small";
    }

    get nextChevronClass() {
        return this.isNextDisabled ? "chevron-right-inactive" : "chevron-right";
    }

    //load component
    connectedCallback() {
        this.pageList = this.generatePageRange(this.currentPage, this.totalPages);
    }

    handlePreviousClick() {
        if (!this.isPreviousDisabled) {
            this.currentPage -= 1;
            this.setPageList();
        }
    }

    handleNextClick() {
        if (!this.isNextDisabled) {
            this.currentPage += 1;
            this.setPageList();
        }
    }

    handlePageClick(event) {
        this.currentPage = parseInt(event.target.dataset.page);
        this.setPageList();
    }

    setPageList() {
        //set pagelist and fire event to set current page in parent
        this.pageList = this.generatePageRange(this.currentPage, this.totalPages);
        this.dispatchEvent(new CustomEvent('pageclick', {
            detail: {
                "pageNumber": this.currentPage
            }
        }));
    }

    /**
     * generate page array with ellipsis
     * https://gist.github.com/kottenator/9d936eb3e4e3c3e02598
     * @param {Number} currentPage 
     * @param {Number} totalPages 
     * @returns Array
     */
    generatePageRange(currentPage, totalPages) {
        const delta = 3; //no of pages on both sides for an active page
        const range = [];
        for (let i = Math.max(2, (currentPage - delta)); i <= Math.min((totalPages - 1), (+currentPage + +delta)); i += 1) {
            range.push(i);
        }

        if ((currentPage - delta) > 2) {
            range.unshift('...');
        }
        if ((+currentPage + +delta) < (totalPages - 1)) {
            range.push('...');
        }

        range.unshift(1);
        if (totalPages !== 1) range.push(totalPages);

        return range.map((i, index) => {
            return {
                key: index,
                pageNumber: i,
                className: this.currentPage === i ? "active-page" : "inactive-page",
                isEllipsis: isNaN(i)
            };
        })
    }
}