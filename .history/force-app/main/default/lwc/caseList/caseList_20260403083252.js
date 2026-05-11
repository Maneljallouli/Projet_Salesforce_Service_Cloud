import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import getMyCases from '@salesforce/apex/CaseController.getMyCases';
import getMyCasesCount from '@salesforce/apex/CaseController.getMyCasesCount';

export default class CaseList extends NavigationMixin(LightningElement) {

    cases = [];
    totalCount = 0;
    error;

    wiredCasesResult;
    wiredCountResult;
    focusHandler;

    @wire(getMyCases)
    wiredCases(result) {
        this.wiredCasesResult = result;
        if (result.data) {
            this.cases = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.cases = [];
        }
    }

    @wire(getMyCasesCount)
    wiredCount(result) {
        this.wiredCountResult = result;
        if (result.data !== undefined) {
            this.totalCount = result.data;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    connectedCallback() {
        this.focusHandler = async () => {
            if (this.wiredCasesResult) await refreshApex(this.wiredCasesResult);
            if (this.wiredCountResult) await refreshApex(this.wiredCountResult);
        };
        window.addEventListener('focus', this.focusHandler);
    }

    disconnectedCallback() {
        if (this.focusHandler) {
            window.removeEventListener('focus', this.focusHandler);
        }
    }

    // --- LOGIQUE DE VISIBILITÉ CORRIGÉE ---
    get isLoading() {
        return !this.cases.length && this.totalCount === 0 && !this.error;
    }

    get hasError() {
        return !!this.error;
    }

    get isEmpty() {
        // Uniquement vide si les deux sources confirment l'absence de données
        return this.cases.length === 0 && this.totalCount === 0;
    }

    get hasCases() {
        // Priorité à la liste réelle reçue
        return this.cases.length > 0 || this.totalCount > 0;
    }

    get caseCount() {
        return this.totalCount || this.cases.length;
    }

    get enrichedCases() {
        return this.cases.map(c => ({
            ...c,
            statusClass: this.getStatusClass(c.Status),
            formattedDate: new Date(c.CreatedDate).toLocaleDateString('fr-FR', {
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            })
        }));
    }

    getStatusClass(status) {
        if (!status) return 'status-badge';
        const s = status.toLowerCase();
        if (s === 'new' || s === 'nouveau') return 'status-badge status-new';
        if (s === 'in progress' || s === 'en cours') return 'status-badge status-progress';
        return 'status-badge status-closed';
    }

    async refreshCases() {
        if (this.wiredCasesResult) await refreshApex(this.wiredCasesResult);
        if (this.wiredCountResult) await refreshApex(this.wiredCountResult);
    }

    openDetail(event) {
        const caseId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'DetailsDemande__c'
            },
            state: {
                recordId: caseId
            }
        });
    }
}