import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

// Imports des méthodes Apex
import sendEmailDraft from '@salesforce/apex/CaseEmailController.sendEmailDraft';
import triggerAgent from '@salesforce/apex/AgentDraftController.triggerAgent';

// Imports des champs
import ANALYSE_FIELD from '@salesforce/schema/Case.Analyse_IA__c';
import DRAFT_FIELD   from '@salesforce/schema/Case.Reponse_Brouillon__c';
import STATUS_FIELD  from '@salesforce/schema/Case.Statut_du_brouillon__c';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CONTACT_EMAIL from '@salesforce/schema/Case.ContactEmail';

export default class AgentDraftPanel extends LightningElement {
    @api recordId;
    @track draftBody = '';
    @track isEditing = false;
    
    // Nouveaux états pour l'envoi
    @track toAddress = '';
    @track ccAddress = '';
    @track subject = '';

    wiredCaseResult;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ANALYSE_FIELD, DRAFT_FIELD, STATUS_FIELD, SUBJECT_FIELD, CONTACT_EMAIL]
    })
    wiredCase(result) {
        this.wiredCaseResult = result;
        if (result.data) {
            this.draftBody = getFieldValue(result.data, DRAFT_FIELD) || '';
            // Initialisation des champs d'en-tête
            if (!this.toAddress) this.toAddress = getFieldValue(result.data, CONTACT_EMAIL) || '';
            if (!this.subject) this.subject = 'Re: ' + (getFieldValue(result.data, SUBJECT_FIELD) || '');
            
            setTimeout(() => { this._refreshPreview(); }, 0);
        }
    }

    // Gestionnaires pour les nouveaux champs
    handleToChange(event) { this.toAddress = event.target.value; }
    handleCcChange(event) { this.ccAddress = event.target.value; }
    handleSubjectChange(event) { this.subject = event.target.value; }

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
            this.dispatchEvent(new ShowToastEvent({
                title: 'Agent Sollicité',
                message: 'L\'Agentforce prépare une nouvelle réponse...',
                variant: 'info'
            }));

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

    async handleSend() {
        const result = await LightningConfirm.open({
            message: 'Voulez-vous vraiment envoyer cet email au client ?',
            variant: 'headerless',
            label: 'Confirmation d\'envoi',
        });

        if (result) {
            // Mise à jour de l'appel Apex avec les nouveaux paramètres
            sendEmailDraft({ 
                caseId: this.recordId, 
                body: this.draftBody,
                toAddress: this.toAddress,
                ccAddress: this.ccAddress,
                subject: this.subject
            })
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
}