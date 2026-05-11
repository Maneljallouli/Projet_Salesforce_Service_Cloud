import { LightningElement, api, wire, track } from 'lwc';
import getCaseHistory from '@salesforce/apex/CaseCommentController.getCaseHistory';
import postMessage from '@salesforce/apex/CaseCommentController.postMessage';
import { refreshApex } from '@salesforce/apex';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track userInput = '';
    wiredHistoryResult;

    @wire(getCaseHistory, { caseId: '$recordId' })
    wiredHistory(result) {
        this.wiredHistoryResult = result;
    }

    get history() {
        return this.wiredHistoryResult;
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    async handleSend() {
        if(!this.userInput.trim()) return;
        
        try {
            await postMessage({ caseId: this.recordId, message: this.userInput });
            this.userInput = ''; // Vide le champ
            await refreshApex(this.wiredHistoryResult); // Rafraîchit la liste instantanément
        } catch (error) {
            console.error('Erreur lors de l\'envoi', error);
        }
    }
}