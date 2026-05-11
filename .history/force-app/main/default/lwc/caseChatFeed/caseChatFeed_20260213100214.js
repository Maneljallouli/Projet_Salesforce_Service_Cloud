import { LightningElement, api, wire, track } from 'lwc';
import getCaseHistory from '@salesforce/apex/CaseCommentController.getCaseHistory';
import postMessage from '@salesforce/apex/CaseCommentController.postMessage';
import { refreshApex } from '@salesforce/apex';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track userInput = '';
    wiredResult;

    @wire(getCaseHistory, { caseId: '$recordId' })
    wiredHistory(result) {
        this.wiredResult = result;
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    async handleSend() {
        if(!this.userInput.trim()) return;
        try {
            await postMessage({ caseId: this.recordId, message: this.userInput });
            this.userInput = '';
            await refreshApex(this.wiredResult);
        } catch (error) {
            console.error('Erreur:', error);
        }
    }
}