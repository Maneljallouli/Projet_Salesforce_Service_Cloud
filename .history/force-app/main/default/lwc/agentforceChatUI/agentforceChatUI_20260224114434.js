import { LightningElement, api } from 'lwc';
import AGENTFORCE_LOGO from '@salesforce/resourceUrl/AgentforceLogo';

export default class AgentforceChatUI extends LightningElement {
    @api configuration;
    
    logoUrl = AGENTFORCE_LOGO;
}
