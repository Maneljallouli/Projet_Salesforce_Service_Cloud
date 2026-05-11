import { api, track } from 'lwc';
// Import obligatoire pour les messages de chat personnalisés
import BaseChatMessage from 'lightningsnapin/baseChatMessage';
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

/**
 * Pour Web (v1), il faut étendre BaseChatMessage et non LightningElement
 */
export default class AgentforceChatUI extends BaseChatMessage {
    @api userType; 
    @api messageContent; 
    @api timeStamp; 

    @track formattedTime = '';
    logoUrl = AGENTFORCE_LOGO;

    connectedCallback() {
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