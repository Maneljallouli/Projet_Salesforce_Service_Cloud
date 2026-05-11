import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import sendEmailDraft from '@salesforce/apex/CaseEmailController.sendEmailDraft';
import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD   from '@salesforce/schema/Case.Reponse_Brouillon__c';
import STATUS_FIELD  from '@salesforce/schema/Case.Statut_Brouillon__c';

export default class AgentDraftPanel extends LightningElement {
    @api recordId;
    @track draftBody = '';
    @track isEditing = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ANALYSE_FIELD, DRAFT_FIELD, STATUS_FIELD]
    })
    wiredCase({ data, error }) {
        if (data) {
            this.draftBody = getFieldValue(data, DRAFT_FIELD) || '';
            // Inject HTML dans le div preview après rendu
            this._refreshPreview();
        }
    }

    get analyse() {
        return getFieldValue(this.wiredCase.data, ANALYSE_FIELD) || '';
    }

    get isDraftReady() {
        return getFieldValue(this.wiredCase.data, STATUS_FIELD) === 'Ready';
    }

    get hasData() {
        return !!this.draftBody;
    }

    renderedCallback() {
        this._refreshPreview();
    }

    _refreshPreview() {
        const div = this.template.querySelector('[data-id="preview"]');
        if (div) div.innerHTML = this.draftBody;
    }

    handleTab(event) {
        const tab = event.currentTarget.dataset.tab;
        if (tab === 'modifier') {
            this.isEditing = true;
        } else if (tab === 'apercu') {
            this.isEditing = false;
        } else if (tab === 'regenerer') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Régénération',
                message: 'Déclenche ton Flow de régénération ici.',
                variant: 'info'
            }));
        }
    }

    handleTextChange(event) {
        this.draftBody = event.detail.value;
    }

    handleIgnore() {
        // Optionnel : vider le brouillon ou juste fermer
        this.dispatchEvent(new ShowToastEvent({
            title: 'Ignoré',
            message: 'Le brouillon a été ignoré.',
            variant: 'warning'
        }));
    }

    handleSend() {
        sendEmailDraft({ caseId: this.recordId, body: this.draftBody })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Email envoyé',
                    message: 'La réponse a été envoyée au client.',
                    variant: 'success'
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Erreur',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}