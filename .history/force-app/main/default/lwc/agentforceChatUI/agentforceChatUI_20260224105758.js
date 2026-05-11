import { api, track } from 'lwc';
// Importation spécifique requise pour le chat Web (v1)
import BaseChatMessage from 'lightningsnapin/baseChatMessage';
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

/**
 * Composant de message personnalisé pour Agentforce.
 * @slot default
 */
export default class AgentforceChatUI extends BaseChatMessage {
    // Propriétés API obligatoires pour le moteur de chat
    @api userType; 
    @api messageContent; 
    @api timeStamp; 

    @track formattedTime = '';
    logoUrl = AGENTFORCE_LOGO;

    connectedCallback() {
        this.formatTime();
    }

    formatTime() {
        if (this.timeStamp) {
            const date = new Date(this.timeStamp);
            this.formattedTime = date.toLocaleTimeString([], { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        }
    }

    get messageText() {
        return this.messageContent || '';
    }

    get isBot() {
        return this.userType === 'Agent';
    }

    get messageClass() {
        return this.userType === 'Agent' ? 'msg-bot' : 'msg-user';
    }
}