import { LightningElement, api, track } from 'lwc';

export default class AgentforceChatUI extends LightningElement {
    // Ces propriétés sont automatiquement remplies par Salesforce
    @api userType; // 'Agent' ou 'Customer'
    @api messageContent; // Le texte du message
    @api timeStamp; // L'heure du message

    @track messageText = '';
    @track formattedTime = '';

    connectedCallback() {
        // On récupère le contenu du message envoyé par Salesforce
        this.messageText = this.messageContent;
        
        // Formatage de l'heure pour coller à ton design (ex: 3:38 PM)
        const date = new Date(this.timeStamp);
        this.formattedTime = date.toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
        });
    }

    // Détermine si le message vient du bot pour afficher l'avatar
    get isBot() {
        return this.userType === 'Agent';
    }

    // Applique la classe CSS correspondante
    get messageClass() {
        return this.userType === 'Agent' ? 'msg-bot' : 'msg-user';
    }
}