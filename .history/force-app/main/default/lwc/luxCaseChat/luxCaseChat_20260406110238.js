import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import getComments from '@salesforce/apex/ChatController.getComments';
import sendComment from '@salesforce/apex/ChatController.sendComment';

const CHANNEL = '/event/Case_Message__e';

export default class LuxCaseChat extends LightningElement {

    // Valeur interne
    _recordId;

    // recordId injecté automatiquement par la page ou récupéré via URL
    @api
    set recordId(value) {
        this._recordId = value;
        console.log('recordId reçu via @api =', value);
    }

    get recordId() {
        return this._recordId;
    }

    @track messages = [];
    @track newMessage = '';
    @track isLoading = true;
    @track isSending = false;
    @track errorMessage = '';

    _wiredResult;
    _subscription;

    // Fallback important pour Experience Cloud LWR
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!this._recordId && pageRef) {
            const idFromState =
                pageRef?.state?.recordId ||
                pageRef?.attributes?.recordId;

            if (idFromState) {
                this._recordId = idFromState;
                console.log('recordId récupéré depuis URL =', this._recordId);
            } else {
                console.warn('Aucun recordId trouvé dans CurrentPageReference', pageRef);
            }
        }
    }

    @wire(getComments, { caseId: '$_recordId' })
    wiredComments(result) {
        this._wiredResult = result;

        // Tant que l'ID n'est pas connu, ne rien faire
        if (!this._recordId) {
            this.isLoading = false;
            this.errorMessage = 'ID de la requête introuvable.';
            return;
        }

        const { data, error } = result;

        if (data) {
            this.messages = data.map(msg => ({
                ...msg,
                bubbleClass:
                    msg.isOwn === 'true'
                        ? 'lux-chat-row lux-chat-row--own'
                        : 'lux-chat-row lux-chat-row--other'
            }));

            this.isLoading = false;
            this.errorMessage = '';

            this._scrollToBottom();
        } else if (error) {
            this.isLoading = false;
            this.errorMessage =
                error?.body?.message ||
                'Impossible de charger les messages.';

            console.error('Erreur getComments :', error);
        }
    }

    get hasMessages() {
        return this.messages.length > 0;
    }

    connectedCallback() {
        this._subscribeToEvents();

        onError(error => {
            console.error('Erreur EMP API :', error);
        });
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, response => {
                console.log('Abonnement supprimé', response);
            });
        }
    }

    _subscribeToEvents() {
        subscribe(CHANNEL, -1, event => {
            const caseId = event?.data?.payload?.Case_Id__c;

            if (caseId && caseId === this._recordId) {
                refreshApex(this._wiredResult);
            }
        })
        .then(response => {
            this._subscription = response;
            console.log('Abonné au channel', CHANNEL);
        })
        .catch(error => {
            console.error('Erreur subscribe :', error);
        });
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
        const msg = this.newMessage?.trim();

        if (!this._recordId) {
            this.errorMessage = 'Erreur technique : ID de la requête introuvable.';
            return;
        }

        if (!msg) {
            this.errorMessage = 'Veuillez saisir un message.';
            return;
        }

        this.isSending = true;
        this.errorMessage = '';

        sendComment({
            caseId: this._recordId,
            message: msg
        })
        .then(() => {
            this.newMessage = '';
            return refreshApex(this._wiredResult);
        })
        .catch(error => {
            console.error('Erreur sendComment :', error);

            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Erreur lors de l’envoi du message.';
        })
        .finally(() => {
            this.isSending = false;
        });
    }

    _scrollToBottom() {
        setTimeout(() => {
            const body = this.template.querySelector('.lux-chat-body');
            if (body) {
                body.scrollTop = body.scrollHeight;
            }
        }, 100);
    }
}