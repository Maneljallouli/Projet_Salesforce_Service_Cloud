import { LightningElement, api, wire, track } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';
import postMessage from '@salesforce/apex/CaseCommentController.postMessage';
import { refreshApex } from '@salesforce/apex';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track userInput = '';
    wiredComments;

    // On utilise la nouvelle méthode ici
    @wire(getCaseComments, { caseId: '$recordId' })
    wiredCallback(result) {
        this.wiredComments = result;
    }

    get commentsData() {
        return this.wiredComments && this.wiredComments.data ? this.wiredComments.data : [];
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    async handleSend() {
        if (!this.userInput.trim()) return;
        try {
            await postMessage({ caseId: this.recordId, message: this.userInput });
            this.userInput = '';
            return refreshApex(this.wiredComments);
        } catch (error) {
            console.error('Erreur d\'envoi:', error);
        }
    }
}