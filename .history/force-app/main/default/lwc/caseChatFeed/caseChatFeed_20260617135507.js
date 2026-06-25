import { LightningElement, api, wire, track } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';
import postMessage from '@salesforce/apex/CaseCommentController.postMessage';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track userInput = '';
    wiredCommentsResult;

    @wire(getCaseComments, { caseId: '$recordId' })
    wiredCallback(result) {
        this.wiredCommentsResult = result;
    }

    get commentsData() {
        if (this.wiredCommentsResult && this.wiredCommentsResult.data) {
            return this.wiredCommentsResult.data.map(comment => ({
                ...comment,
                author: comment.isClient ? comment.author : 'Support Client',
                bubbleClass: comment.isClient
                    ? 'comment-bubble client-bubble slds-m-bottom_small'
                    : 'comment-bubble support-bubble slds-m-bottom_small'
            }));
        }
        return [];
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    handleSend() {
        if (!this.userInput.trim()) {
            return;
        }
        postMessage({ caseId: this.recordId, message: this.userInput })
            .then(() => {
                this.userInput = '';
                return refreshApex(this.wiredCommentsResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}