import { api } from 'lwc';
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

export default class AgentforceChatUI extends LightningElement {
    @api configuration;
    @api conversationEntry;
    
    logoUrl = AGENTFORCE_LOGO;

    get sender() {
        return this.conversationEntry?.sender?.role;
    }

    get textContent() {
        try {
            const entryPayload = JSON.parse(this.conversationEntry?.entryPayload || '{}');
            return entryPayload.abstractMessage?.staticContent?.text || '';
        } catch (e) {
            return '';
        }
    }

    get generateMessageBubbleClassname() {
        if (this.isSupportedSender()) {
            return `embedded-messaging-message-content ${this.sender}`;
        }
        return 'embedded-messaging-message-content EndUser';
    }

    get isSupportedSender() {
        const validTypes = ['EndUser', 'Agent', 'Chatbot'];
        return validTypes.includes(this.sender);
    }

    get isBot() {
        return this.sender === 'Agent' || this.sender === 'Chatbot';
    }
}
