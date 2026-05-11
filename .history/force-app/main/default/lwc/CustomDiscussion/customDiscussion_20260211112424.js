import { LightningElement, api, wire, track } from 'lwc';
import getDiscussions from '@salesforce/apex/DiscussionController.getDiscussions';
import postQuestion from '@salesforce/apex/DiscussionController.postQuestion';
import { refreshApex } from '@salesforce/apex';

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
        } else if (result.error) {
            console.error('Erreur de chargement:', result.error);
        }
    }

    handleTextChange(event) {
        this.newMessage = event.target.value;
    }

    handlePost() {
        if (!this.newMessage.trim()) {
            return;
        }

        postQuestion({ recordId: this.recordId, message: this.newMessage })
            .then(() => {
                this.newMessage = '';
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                console.error('Erreur lors de la publication:', error);
            });
    }
}