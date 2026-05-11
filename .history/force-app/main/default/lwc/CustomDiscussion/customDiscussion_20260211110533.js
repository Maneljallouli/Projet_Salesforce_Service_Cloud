import { LightningElement, api, wire, track } from 'lwc';
import getDiscussions from '@salesforce/label/c.DiscussionController.getDiscussions';
import postQuestion from '@salesforce/label/c.DiscussionController.postQuestion';
import { refreshApex } from '@salesforce/apex';

export default class CustomDiscussion extends LightningElement {
    @api recordId;
    @track newMessage = '';
    wiredDiscussionResult;
    discussions;

    // Récupération dynamique des messages
    @wire(getDiscussions, { recordId: '$recordId' })
    wiredDiscussions(result) {
        this.wiredDiscussionResult = result;
        if (result.data) {
            this.discussions = result.data;
        }
    }

    handleTextChange(event) {
        this.newMessage = event.target.value;
    }

    // Envoi dynamique vers Salesforce
    handlePost() {
        if (this.newMessage) {
            postQuestion({ recordId: this.recordId, message: this.newMessage })
                .then(() => {
                    this.newMessage = '';
                    return refreshApex(this.wiredDiscussionResult); // Rafraîchit la liste
                })
                .catch(error => {
                    console.error('Erreur:', error);
                });
        }
    }
}