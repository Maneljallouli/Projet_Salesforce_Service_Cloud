import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { CloseActionScreenEvent } from 'lightning/actions';

import sendEmailDraft from '@salesforce/apex/CaseEmailController.sendEmailDraft';
import triggerAgent from '@salesforce/apex/AgentDraftController.triggerAgent';

import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD   from '@salesforce/schema/Case.Reponse_Brouillon__c';
import STATUS_FIELD  from '@salesforce/schema/Case.Statut_du_brouillon__c';

export default class AgentDraftPanelAction extends LightningElement {
    @api recordId;
    @track draftBody = '';
    @track isEditing = false;
    wiredCaseResult;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ANALYSE_FIELD, DRAFT_FIELD, STATUS_FIELD]
    })
    wiredCase(result) {
        this.wiredCaseResult = result;
        if (result.data) {
            this.draftBody = getFieldValue(result.data, DRAFT_FIELD) || '';
            setTimeout(() => { this._refreshPreview(); }, 0);
        }
    }

    get analyse() {
        return this.wiredCaseResult?.data
            ? getFieldValue(this.wiredCaseResult.data, ANALYSE_FIELD) : '';
    }

    get isDraftReady() {
        return this.wiredCaseResult?.data
            ? getFieldValue(this.wiredCaseResult.data, STATUS_FIELD) === 'Approuvé' : false;
    }

    get hasData() {
        return !!this.draftBody;
    }

    renderedCallback() {
        if (!this.isEditing) {
            this._refreshPreview();
        }
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
            setTimeout(() => { this._refreshPreview(); }, 0);
        } else if (tab === 'regenerer') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Agent Sollicité',
                message: 'L\'Agentforce prépare une nouvelle réponse...',
                variant: 'info'
            }));
            triggerAgent({ caseId: this.recordId })
                .then(() => console.log('Agent lancé avec succès via Flow'))
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Erreur',
                        message: error.body?.message || 'Erreur lors du lancement de l\'agent',
                        variant: 'error'
                    }));
                });
        }
    }

    handleTextChange(event) {
        this.draftBody = event.target.value;
    }

    handleIgnore() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Ignoré',
            message: 'Le brouillon a été ignoré.',
            variant: 'warning'
        }));
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSend() {
        const result = await LightningConfirm.open({
            message: 'Voulez-vous vraiment envoyer cet email au client ?',
            variant: 'headerless',
            label: 'Confirmation d\'envoi',
        });

        if (result) {
            sendEmailDraft({ caseId: this.recordId, body: this.draftBody })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Email envoyé',
                        message: 'La réponse a été envoyée au client.',
                        variant: 'success'
                    }));
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Erreur',
                        message: error.body?.message || 'Une erreur est survenue lors de l\'envoi',
                        variant: 'error'
                    }));
                });
        }
    }
}