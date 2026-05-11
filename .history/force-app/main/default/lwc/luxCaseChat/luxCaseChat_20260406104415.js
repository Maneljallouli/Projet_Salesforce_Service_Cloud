import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import getComments  from '@salesforce/apex/ChatController.getComments';
import sendComment  from '@salesforce/apex/ChatController.sendComment';

const CHANNEL = '/event/Case_Message__e';

export default class LuxCaseChat extends LightningElement {

    @api recordId; // Doit être exactement 'recordId' pour l'injection auto

    @track messages     = [];
    @track newMessage   = '';
    @track isLoading    = true;
    @track isSending    = false;
    @track errorMessage = '';

    _wiredResult;
    _subscription = null;

    @wire(getComments, { caseId: '$recordId' })
    wiredComments(result) {
        this._wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.isLoading = false;
            this.messages  = data.map(m => ({
                ...m,
                bubbleClass : m.isOwn === 'true'
                    ? 'lux-chat-row lux-chat-row--own'
                    : 'lux-chat-row lux-chat-row--other'
            }));
            this._scrollToBottom();
        } else if (error) {
            this.isLoading    = false;
            this.errorMessage = 'Impossible de charger les messages.';
        }
    }

    get hasMessages() { return this.messages.length > 0; }

    connectedCallback() {
        this._subscribeToEvents();
        onError(err => console.error('Erreur EMP API:', err));
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, () => {});
        }
    }

    _subscribeToEvents() {
        subscribe(CHANNEL, -1, (event) => {
            if (event.data.payload.Case_Id__c === this.recordId) {
                refreshApex(this._wiredResult);
            }
        })
        .then(sub => { this._subscription = sub; })
        .catch(err => console.error('Erreur subscribe:', err));
    }

    handleInput(event) {
        this.newMessage = event.target.value;
        this.errorMessage = '';
    }

    handleKeyDown(event) {
        if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
            this.handleSend();
        }
    }

    handleSend() {
        const msg = this.newMessage.trim();

        // CORRECTION : Validation de l'ID côté client
        if (!this.recordId) {
            this.errorMessage = 'Erreur technique : ID de la requête introuvable.';
            return;
        }

        if (!msg) {
            this.errorMessage = 'Veuillez saisir un message.';
            return;
        }

        this.isSending = true;
        this.errorMessage = '';

        sendComment({ caseId: this.recordId, message: msg })
            .then(() => {
                this.newMessage = '';
                this.isSending  = false;
                return refreshApex(this._wiredResult);
            })
            .catch(err => {
                this.isSending = false;
                // CORRECTION : Extraction du message d'erreur réel
                this.errorMessage = 'Erreur : ' + (err.body ? err.body.message : err.message);
                console.error('Erreur sendComment:', err);
            });
    }

    _scrollToBottom() {
        setTimeout(() => {
            const body = this.template.querySelector('.lux-chat-body');
            if (body) body.scrollTop = body.scrollHeight;
        }, 100);
    }
}