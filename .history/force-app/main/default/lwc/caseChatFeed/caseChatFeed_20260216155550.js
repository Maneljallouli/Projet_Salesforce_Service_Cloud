import { LightningElement, api, wire, track } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';
import postMessage from '@salesforce/apex/CaseCommentController.postMessage'; // Import de l'action d'envoi
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track userInput = ''; // Pour stocker le texte saisi
    wiredCommentsResult;

    @wire(getCaseComments, { caseId: '$recordId' })
    wiredCallback(result) {
        this.wiredCommentsResult = result;
    }

    get commentsData() {
        if (this.wiredCommentsResult && this.wiredCommentsResult.data) {
            return this.wiredCommentsResult.data.map(comment => {
                const isTechnicalId = /^User\d+/.test(comment.author);
                return { 
                    ...comment, 
                    author: isTechnicalId ? 'Client Support' : comment.author 
                };
            });
        }
        return [];
    }

    // Gère la saisie de l'utilisateur
    handleInputChange(event) {
        this.userInput = event.target.value;
    }

    // Gère le clic sur le bouton "Send Message"
    handleSend() {
        if (!this.userInput.trim()) {
            return; // Ne rien faire si le texte est vide
        }

        postMessage({ caseId: this.recordId, message: this.userInput })
            .then(() => {
                this.userInput = ''; // Vider le champ de texte
                return refreshApex(this.wiredCommentsResult); // Rafraîchir la liste des messages
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