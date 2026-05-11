import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD from '@salesforce/schema/Case.Reponse_Brouillon__c';

export default class AgentDraftPanel extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [ANALYSE_FIELD, DRAFT_FIELD] })
    caseRecord;

    get analyse() { return getFieldValue(this.caseRecord.data, ANALYSE_FIELD); }
    get draftBody() { return getFieldValue(this.caseRecord.data, DRAFT_FIELD); }

    handleSend() {
        // Logique d'envoi simple ou via Flow
        console.log('Envoi de l\'email...');
    }
}