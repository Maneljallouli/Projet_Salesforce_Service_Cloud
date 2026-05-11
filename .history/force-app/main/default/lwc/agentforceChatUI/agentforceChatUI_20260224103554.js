import { LightningElement, api, track } from 'lwc';
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

/**
 * Composant personnalisé pour les bulles de chat Agentforce.
 * @slot default 
 */
export default class AgentforceChatUI extends LightningElement {
    // Propriétés obligatoires pour le target lightningSnapin__ChatMessage
    @api userType; 
    @api messageContent; 
    @api timeStamp; 

    // Variables internes pour le rendu
    @track formattedTime = '';
    logoUrl = AGENTFORCE_LOGO;

    /**
     * Exécuté lors de l'insertion du composant dans le DOM
     */
    connectedCallback() {
        this.formatTimestamp();
    }

    /**
     * Transforme le timestamp ISO en format lisible (ex: 14:30)
     */
    formatTimestamp() {
        if (this.timeStamp) {
            try {
                const date = new Date(this.timeStamp);
                this.formattedTime = date.toLocaleTimeString([], { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                });
            } catch (error) {
                console.error('Erreur de formatage de date:', error);
                this.formattedTime = '';
            }
        }
    }

    /**
     * Getter pour sécuriser l'affichage du texte
     */
    get messageText() {
        return this.messageContent || '';
    }

    /**
     * Vérifie si l'émetteur est l'Agent (IA)
     */
    get isBot() {
        return this.userType === 'Agent';
    }

    /**
     * Définit la classe CSS dynamiquement
     */
    get messageClass() {
        return this.userType === 'Agent' ? 'msg-bot' : 'msg-user';
    }
}