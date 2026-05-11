import { LightningElement, api, track } from 'lwc';

export default class AgentforceChatUI extends LightningElement {
    // Propriétés requises par l'interface de chat Salesforce
    @api userType; 
    @api messageContent; 
    @api timeStamp; 

    @track formattedTime = '';

    connectedCallback() {
        // Formatage de l'heure sécurisé
        if (this.timeStamp) {
            const date = new Date(this.timeStamp);
            this.formattedTime = date.toLocaleTimeString([], { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        }
    }

    // Getter pour le texte (plus propre que de passer par une variable @track supplémentaire)
    get messageText() {
        return this.messageContent || '';
    }

    // Détermine si le message vient de l'IA/Agent
    get isBot() {
        return this.userType === 'Agent';
    }

    // Retourne la classe CSS selon l'émetteur
    get messageClass() {
        return this.userType === 'Agent' ? 'msg-bot' : 'msg-user';
    }
}