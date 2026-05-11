import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getMyContactInfo from '@salesforce/apex/SavCaseController.getMyContactInfo';

export default class LuxHeader extends NavigationMixin(LightningElement) {

    @track activePage = 'home';
    @track dropdownOpen = false;
    @track contactInfo = {};

    // On utilise ton Apex pour avoir le lien Contact et les infos profil
    @wire(getMyContactInfo)
    wiredContact({ error, data }) {
        if (data) {
            this.contactInfo = data;
        } else if (error) {
            console.error('Erreur profil:', error);
        }
    }

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const name = ref.attributes.name;
        
        if (name === 'Mes_Demandes__c')          this.activePage = 'demandes';
        else if (name === 'Nouvelle_Demande__c') this.activePage = 'nouvelle';
        else if (name === 'FAQ__c')               this.activePage = 'faq';
        else if (name === 'Produits__c')          this.activePage = 'produits';
        else                                      this.activePage = 'home';
    }

    setActive(e) {
        e.preventDefault();
        const page = e.currentTarget.dataset.page;
        this.activePage = page;

        let targetApiName = 'Home';
        if (page === 'demandes')      targetApiName = 'Mes_Demandes__c';
        else if (page === 'nouvelle') targetApiName = 'Nouvelle_Demande__c';
        else if (page === 'faq')       targetApiName = 'FAQ__c';
        else if (page === 'produits')  targetApiName = 'Produits__c';

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: targetApiName }
        });
    }

    // Getters pour les infos utilisateur
    get userName() {
        return (this.contactInfo.firstName + ' ' + this.contactInfo.lastName) || 'Client Luxe';
    }

    get userInitials() {
        const f = this.contactInfo.firstName || 'M';
        const l = this.contactInfo.lastName || 'J';
        return (f[0] + l[0]).toUpperCase();
    }

    get userEmail() { return this.contactInfo.email || ''; }
    get contactPhone() { return this.contactInfo.phone || ''; }
    get contactCity() { return this.contactInfo.city || ''; }

    // Gestion du menu
    toggleDropdown() { this.dropdownOpen = !this.dropdownOpen; }
    closeDropdown() { this.dropdownOpen = false; }

    handleLogout() {
        // Redirection vers la page de déconnexion standard du portail
        window.location.href = '/luxportail/secur/logout.jsp';
    }

    // Getters CSS
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}