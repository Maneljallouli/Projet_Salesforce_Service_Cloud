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

    // --- NOUVELLE PARTIE : recherche + filtres ---
    searchTerm = '';
    selectedFilter = 'all';

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

    // --- NOUVELLE PARTIE : liste affichée avec recherche + filtres ---
    get displayedCases() {
        const rows = this.enrichedCases || [];
        const term = (this.searchTerm || '').toLowerCase().trim();

        return rows.filter(c => {
            const statusOk = this.matchesFilter(c.Status);

            const searchableText = [
                c.CaseNumber,
                c.Subject,
                c.Category__c,
                c.Status,
                c.Priority
            ]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();

            const searchOk = !term || searchableText.includes(term);

            return statusOk && searchOk;
        });
    }

    get hasDisplayedCases() {
        return !this.isLoading && !this.hasError && this.displayedCases.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.hasError && this.displayedCases.length === 0;
    }

    // --- NOUVELLE PARTIE : classes des filtres ---
    get filterAllClass() {
        return this.selectedFilter === 'all' ? 'lux-filter-btn active' : 'lux-filter-btn';
    }

    get filterOpenClass() {
        return this.selectedFilter === 'open' ? 'lux-filter-btn active' : 'lux-filter-btn';
    }

    get filterProgressClass() {
        return this.selectedFilter === 'progress' ? 'lux-filter-btn active' : 'lux-filter-btn';
    }

    get filterResolvedClass() {
        return this.selectedFilter === 'resolved' ? 'lux-filter-btn active' : 'lux-filter-btn';
    }

    get filterClosedClass() {
        return this.selectedFilter === 'closed' ? 'lux-filter-btn active' : 'lux-filter-btn';
    }

    // --- NOUVELLE PARTIE : actions recherche + filtres ---
    handleSearch(event) {
        this.searchTerm = event.target.value || '';
    }

    setFilter(event) {
        this.selectedFilter = event.currentTarget.dataset.filter;
    }

    matchesFilter(statusValue) {
        if (this.selectedFilter === 'all') {
            return true;
        }

        const status = this.normalizeStatus(statusValue);

        if (this.selectedFilter === 'open') {
            return (
                status.includes('new') ||
                status.includes('nouveau') ||
                status.includes('ouvert') ||
                status.includes('open')
            );
        }

        if (this.selectedFilter === 'progress') {
            return (
                status.includes('progress') ||
                status.includes('cours') ||
                status.includes('working') ||
                status.includes('traitement')
            );
        }

        if (this.selectedFilter === 'resolved') {
            return (
                status.includes('resolved') ||
                status.includes('resolu') ||
                status.includes('solution')
            );
        }

        if (this.selectedFilter === 'closed') {
            return (
                status.includes('closed') ||
                status.includes('cloture') ||
                status.includes('ferme')
            );
        }

        return true;
    }

    normalizeStatus(value) {
        return (value || '')
            .toString()
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '');
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

    // --- NOUVELLE PARTIE : bouton Nouvelle demande ---
    handleCreateRequest() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'NouvelleDemande__c'
            }
        });
    }
}