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
        if (result.error) {
            console.error('Apex Error:', result.error);
        }
    }

    // Transforme les données pour le HTML avec une sécurité de secours
    get historyData() {
        if (this.wiredResult && this.wiredResult.data) {
            return this.wiredResult.data.map(item => ({
                ...item,
                cssClass: item.isAction ? 'action-item' : 'message-item'
            }));
        }
        return [];
    }

    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    async handleSend() {
        const message = this.userInput.trim();
        if (!message) return;

        try {
            await postMessage({ caseId: this.recordId, message: message });
            this.userInput = '';
            await refreshApex(this.wiredResult);
        } catch (error) {
            console.error('Error sending message:', error);
        }
    }
}