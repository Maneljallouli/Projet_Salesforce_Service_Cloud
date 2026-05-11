import { LightningElement, api, wire, track } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';
import addCaseComment from '@salesforce/apex/CaseCommentController.addCaseComment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    @track newComment = '';
    wiredCommentsResult;

    @wire(getCaseComments, { caseId: '$recordId' })
    wiredComments(result) {
        this.wiredCommentsResult = result;
        if (result.data) {
            // Optionnel : Formater les dates pour plus de lisibilité
            this.commentsData = result.data.map(c => ({
                ...c,
                FormattedDate: new Date(c.CreatedDate).toLocaleString()
            }));
        }
    }

    get isButtonDisabled() {
        return !this.newComment.trim();
    }

    handleInputChange(event) {
        this.newComment = event.target.value;
    }

    async handleSubmit() {
        try {
            await addCaseComment({ 
                caseId: this.recordId, 
                commentBody: this.newComment 
            });
            this.newComment = ''; // Réinitialiser le champ
            await refreshApex(this.wiredCommentsResult); // Rafraîchir la liste
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Succès',
                message: 'Commentaire ajouté !',
                variant: 'success'
            }));
        } catch (error) {
            console.error(error);
        }
    }
}