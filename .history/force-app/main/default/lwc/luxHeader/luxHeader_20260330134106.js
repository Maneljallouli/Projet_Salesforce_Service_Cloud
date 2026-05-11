import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

// Import des champs de l'objet User
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import CITY_FIELD from '@salesforce/schema/User.City';

export default class LuxHeader extends NavigationMixin(LightningElement) {
    @track activePage = 'home';
    @track dropdownOpen = false;

    // Récupération automatique des données User sans Apex
    @wire(getRecord, { 
        recordId: USER_ID, 
        fields: [NAME_FIELD, EMAIL_FIELD, PHONE_FIELD, CITY_FIELD] 
    })
    userData;

    // Détection de la page active
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

    // Getters pour extraire les valeurs des champs User
    get userName() {
        return getFieldValue(this.userData.data, NAME_FIELD) || 'Client Luxe';
    }

    get userEmail() {
        return getFieldValue(this.userData.data, EMAIL_FIELD) || '';
    }

    get contactPhone() {
        return getFieldValue(this.userData.data, PHONE_FIELD) || 'Non renseigné';
    }

    get contactCity() {
        return getFieldValue(this.userData.data, CITY_FIELD) || 'Non renseignée';
    }

    get userInitials() {
        const name = this.userName;
        if (!name || name === 'Client Luxe') return 'MJ';
        const parts = name.split(' ');
        return parts.length >= 2 
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase() 
            : name.substring(0, 2).toUpperCase();
    }

    // Navigation et UI
    setActive(e) {
        e.preventDefault();
        const page = e.currentTarget.dataset.page;
        this.activePage = page;
        let targetApiName = page === 'home' ? 'Home' : 
                            page === 'demandes' ? 'Mes_Demandes__c' : 
                            page === 'nouvelle' ? 'Nouvelle_Demande__c' : 
                            page === 'faq' ? 'FAQ__c' : 'Produits__c';

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: targetApiName }
        });
    }

    toggleDropdown() { this.dropdownOpen = !this.dropdownOpen; }
    closeDropdown() { this.dropdownOpen = false; }
    handleLogout() { window.location.href = '/luxportail/secur/logout.jsp'; }

    // Classes CSS
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}