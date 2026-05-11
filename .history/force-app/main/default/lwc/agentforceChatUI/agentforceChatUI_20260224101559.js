import { LightningElement, api, track } from 'lwc';
// Cette ligne importe l'image que tu as nommée "AgentforceLogo" dans les ressources statiques
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

export default class AgentforceChatUI extends LightningElement {
    @api userType; 
    @api messageContent; 
    @api timeStamp; 

    @track formattedTime = '';
    
    // On crée une variable pour utiliser le logo dans le HTML
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