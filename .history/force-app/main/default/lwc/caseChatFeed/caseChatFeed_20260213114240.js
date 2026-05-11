import { LightningElement, api, wire, track } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';
import { refreshApex } from '@salesforce/apex';

export default class CaseChatFeed extends LightningElement {
    @api recordId;
    wiredCommentsResult;

    @wire(getCaseComments, { caseId: '$recordId' })
    wiredCallback(result) {
        this.wiredCommentsResult = result;
    }

    // Cette fonction transforme les données pour l'affichage
    get commentsData() {
        if (this.wiredCommentsResult && this.wiredCommentsResult.data) {
            return this.wiredCommentsResult.data.map(comment => {
                // Si le nom commence par 'User' + chiffres, on remplace par 'Client'
                const isTechnicalId = /^User\d+/.test(comment.author);
                return { 
                    ...comment, 
                    author: isTechnicalId ? 'Client Support' : comment.author 
                };
            });
        }
        return [];
    }
}