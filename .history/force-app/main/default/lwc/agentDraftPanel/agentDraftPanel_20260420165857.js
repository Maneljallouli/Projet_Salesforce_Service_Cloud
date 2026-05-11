import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Imports des méthodes Apex
import sendEmailDraft from '@salesforce/apex/CaseEmailController.sendEmailDraft';
import triggerAgent from '@salesforce/apex/AgentDraftController.triggerAgent';

// Imports des champs
import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD   from '@salesforce/schema/Case.Reponse_Brouillon__c';
import STATUS_FIELD  from '@salesforce/schema/Case.Statut_du_brouillon__c';

export default class AgentDraftPanel extends LightningElement {
    @api recordId;
    @track draftBody = '';
    @track isEditing = false;
    wiredCaseResult;

    // Récupération automatique des données du Case
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
            setTimeout(() => { this._refreshPreview(); }, 0);
        } else if (tab === 'regenerer') {
            // Affichage d'un message d'attente
            this.dispatchEvent(new ShowToastEvent({
                title: 'Agent Sollicité',
                message: 'L\'Agentforce prépare une nouvelle réponse...',
                variant: 'info'
            }));

            // Appel de la méthode Apex pour déclencher l'Agent via le Flow
            triggerAgent({ caseId: this.recordId })
                .then(() => {
                    console.log('Agent lancé avec succès via Flow');
                })
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
                    message: error.body?.message || 'Une erreur est survenue lors de l\'envoi',
                    variant: 'error'
                }));
            });
    }
}