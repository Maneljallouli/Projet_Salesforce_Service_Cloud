import { createElement } from 'lwc';
import AgentforceChatUI from 'c/agentforceChatUI';

// Mock du module BaseChatMessage pour éviter l'erreur LWC1702
jest.mock(
    'lightningsnapin/baseChatMessage',
    () => {
        return {
            default: class extends HTMLElement {}
        };
    },
    { virtual: true }
);

describe('c-agentforce-chat-ui', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should render the component', () => {
        const element = createElement('c-agentforce-chat-ui', {
            is: AgentforceChatUI
        });
        document.body.appendChild(element);
        expect(element).not.toBeNull();
    });
});