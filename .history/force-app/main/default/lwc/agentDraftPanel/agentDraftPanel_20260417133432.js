import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmailDraft from '@salesforce/apex/CaseEmailController.sendEmailDraft';

import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD   from '@salesforce/schema/Case.Reponse_Brouillon__c';
import STATUS_FIELD  from '@salesforce/schema/Case.Statut_du_brouillon__c';

export default class AgentDraftPanel extends LightningElement {
    @api recordId;
    @track draftBody = '';
    @track isEditing = false;
    wiredCaseResult; // Stocke le résultat complet pour les getters

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ANALYSE_FIELD, DRAFT_FIELD, STATUS_FIELD]
    })
    wiredCase(result) {
        this.wiredCaseResult = result;
        if (result.data) {
            this.draftBody = getFieldValue(result.data, DRAFT_FIELD) || '';
            // Utilisation d'un court délai pour laisser le temps au DOM de se mettre à jour
            setTimeout(() => { this._refreshPreview(); }, 0);
        }
    }

    get analyse() {
        return this.wiredCaseResult?.data ? getFieldValue(this.wiredCaseResult.data, ANALYSE_FIELD) : '';
    }

    get isDraftReady() {
        return this.wiredCaseResult?.data ? getFieldValue(this.wiredCaseResult.data, STATUS_FIELD) === 'Approuvé' : false;
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
        if (div) {
            div.innerHTML = this.draftBody;
        }
    }

    handleTab(event) {
        const tab = event.currentTarget.dataset.tab;
        if (tab === 'modifier') {
            this.isEditing = true;
        } else if (tab === 'apercu') {
            this.isEditing = false;
            // On laisse le cycle de rendu finir avant de rafraîchir l'innerHTML
            setTimeout(() => { this._refreshPreview(); }, 0);
        } else if (tab === 'regenerer') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Régénération',
                message: 'Le processus de régénération a été lancé.',
                variant: 'info'
            }));
            // Ici tu pourrais appeler une méthode Apex pour vider les champs et relancer l'agent
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
                    message: error.body?.message || 'Une erreur est survenue',
                    variant: 'error'
                }));
            });
    }
}