import { LightningElement, api, wire, track } from 'lwc';
import getDiscussions from '@salesforce/apex/DiscussionController.getDiscussions';
import postQuestion from '@salesforce/apex/DiscussionController.postQuestion';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomDiscussion extends LightningElement {
    @api recordId;
    @track newMessage = '';
    @track discussions;
    wiredResult;

    @wire(getDiscussions, { recordId: '$recordId' })
    wiredData(result) {
        this.wiredResult = result;
        if (result.data) {
            this.discussions = result.data;
        }
    }

    handleTextChange(event) {
        this.newMessage = event.target.value;
    }

    handlePost() {
        if (!this.newMessage || !this.newMessage.trim()) {
            this.showToast('Erreur', 'Veuillez écrire un message.', 'error');
            return;
        }

        postQuestion({ recordId: this.recordId, message: this.newMessage })
            .then(() => {
                this.showToast('Succès', 'Votre question a été publiée !', 'success');
                this.newMessage = ''; 
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Erreur', 'Impossible de publier : ' + error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}