import { LightningElement, api, wire } from 'lwc';
import getCaseComments from '@salesforce/apex/CaseCommentController.getCaseComments';

export default class CaseChatFeed extends LightningElement {
    @api recordId;

    // Utilisation directe du wire sans transformation complexe pour éviter les erreurs de lecture
    @wire(getCaseComments, { caseId: '$recordId' })
    comments; 

    get hasComments() {
        return this.comments && this.comments.data;
    }
}