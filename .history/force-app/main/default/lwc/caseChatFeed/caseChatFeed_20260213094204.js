import { LightningElement, api, wire } from 'lwc';
import getCaseHistory from '@salesforce/apex/CaseCommentController.getCaseHistory';

export default class CaseChatFeed extends LightningElement {
    @api recordId;

    @wire(getCaseHistory, { caseId: '$recordId' })
    history;

    get hasData() {
        return this.history && this.history.data && this.history.data.length > 0;
    }
}