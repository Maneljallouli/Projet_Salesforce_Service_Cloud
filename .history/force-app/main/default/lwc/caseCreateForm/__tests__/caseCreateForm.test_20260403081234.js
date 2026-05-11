import { createElement } from 'lwc';
import CaseCreateForm from 'c/caseCreateForm';
import getMyProducts from '@salesforce/wire-adapter-jest';

// Mock de l'appel Apex createCase
jest.mock(
    '@salesforce/apex/SavCaseController.createCase',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-case-create-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Empêche les fuites de mocks entre les tests
        jest.clearAllMocks();
    });

    it('affiche le titre du formulaire correctement', () => {
        // Arrange
        const element = createElement('c-case-create-form', {
            is: CaseCreateForm
        });

        // Act
        document.body.appendChild(element);

        // Assert
        const title = element.shadowRoot.querySelector('.lux-title');
        expect(title.textContent).toBe('Nouvelle demande');
    });

    it('affiche les champs obligatoires par défaut', () => {
        const element = createElement('c-case-create-form', {
            is: CaseCreateForm
        });
        document.body.appendChild(element);

        // Vérifie la présence des labels obligatoires
        const labels = Array.from(element.shadowRoot.querySelectorAll('label'));
        const requiredLabels = labels.filter(label => label.textContent.includes('*'));
        
        // Sujet, Catégorie, Description
        expect(requiredLabels.length).toBe(3);
    });
});