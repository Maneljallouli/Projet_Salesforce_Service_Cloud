import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

// Import de la méthode Apex modifiée
import getMyNotifications from '@salesforce/apex/NotificationController.getMyNotifications';

// Import des champs de l'objet User
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import CITY_FIELD from '@salesforce/schema/User.City';

export default class LuxHeader extends NavigationMixin(LightningElement) {
    @track activePage = 'home';
    @track dropdownOpen = false;
    
    // États pour les notifications
    @track notifDropdownOpen = false;
    @track hasNotifications = false; 
    @track notifications = []; 

    // Récupération dynamique via le Controller Apex
    @wire(getMyNotifications)
    wiredNotifs({ error, data }) {
        if (data) {
            this.notifications = data;
            // On affiche la boule dorée seulement s'il y a des données
            this.hasNotifications = data.length > 0;
            console.log('Notifications Luxe chargées:', data);
        } else if (error) {
            console.error('Erreur notifications Apex:', error);
            this.hasNotifications = false;
        }
    }

    @wire(getRecord, { 
        recordId: USER_ID, 
        fields: [NAME_FIELD, EMAIL_FIELD, PHONE_FIELD, CITY_FIELD] 
    })
    userData;

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const name = ref.attributes.name;
        const map = {
            'Mes_Demandes__c': 'demandes',
            'Nouvelle_Demande__c': 'nouvelle',
            'FAQ__c': 'faq',
            'Produits__c': 'produits'
        };
        this.activePage = map[name] || 'home';
    }

    // Getters pour l'affichage Profil
    get userName() { return getFieldValue(this.userData.data, NAME_FIELD) || 'Client Luxe'; }
    get userEmail() { return getFieldValue(this.userData.data, EMAIL_FIELD) || ''; }
    get contactPhone() { return getFieldValue(this.userData.data, PHONE_FIELD) || 'Non renseigné'; }
    get contactCity() { return getFieldValue(this.userData.data, CITY_FIELD) || 'Non renseignée'; }

    get userInitials() {
        const name = this.userName;
        if (!name || name === 'Client Luxe') return 'MJ';
        const parts = name.split(' ');
        return parts.length >= 2 
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase() 
            : name.substring(0, 2).toUpperCase();
    }

    // Navigation
    setActive(e) {
        e.preventDefault();
        const page = e.currentTarget.dataset.page;
        this.activePage = page;
        const targetApiName = page === 'home' ? 'Home' : 
                            page === 'demandes' ? 'Mes_Demandes__c' : 
                            page === 'nouvelle' ? 'Nouvelle_Demande__c' : 
                            page === 'faq' ? 'FAQ__c' : 'Produits__c';

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: targetApiName }
        });
    }

    // Gestion des menus déroulants
    toggleDropdown() { this.dropdownOpen = !this.dropdownOpen; }
    closeDropdown() { this.dropdownOpen = false; }

    toggleNotifDropdown() { 
        this.notifDropdownOpen = !this.notifDropdownOpen; 
        // Cache la boule de notification une fois consultée
        if(this.notifDropdownOpen) {
            this.hasNotifications = false; 
        }
    }
    closeNotifDropdown() { this.notifDropdownOpen = false; }

    handleLogout() { 
        const logoutEndpoint = '/MJSupport/secur/logout.jsp';
        const destinationUrl = 'https://olivesoft--pfe.sandbox.my.site.com/MJSupport/s/login';
        window.location.href = `${logoutEndpoint}?retUrl=${encodeURIComponent(destinationUrl)}`; 
    }

    // Classes CSS dynamiques
    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}