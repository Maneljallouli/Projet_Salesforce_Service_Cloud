import { LightningElement, api, wire, track } from 'lwc';
import getDiscussions from '@salesforce/apex/DiscussionController.getDiscussions';
import postQuestion from '@salesforce/apex/DiscussionController.postQuestion';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomDiscussion extends LightningElement {
    @api recordId; // Cet ID doit être rempli automatiquement par Salesforce
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
        // --- CORRECTION : Vérification de l'ID ---
        if (!this.recordId) {
            this.showToast('Erreur de configuration', 'L\'ID de la page est introuvable. Vérifiez que le composant est sur une page de détail.', 'error');
            return;
        }

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
                // Affiche l'erreur exacte venant de Salesforce
                this.showToast('Erreur', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}