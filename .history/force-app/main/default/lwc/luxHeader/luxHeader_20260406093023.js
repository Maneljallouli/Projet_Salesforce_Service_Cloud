import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';

import getMyNotifications from '@salesforce/apex/NotificationController.getMyNotifications';
import markAllAsRead      from '@salesforce/apex/NotificationController.markAllAsRead';

import NAME_FIELD       from '@salesforce/schema/User.Name';
import EMAIL_FIELD      from '@salesforce/schema/User.Email';
import PHONE_FIELD      from '@salesforce/schema/User.Phone';
import CITY_FIELD       from '@salesforce/schema/User.City';
import CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';

const CHANNEL = '/event/Case_Status_Change__e';

export default class LuxHeader extends NavigationMixin(LightningElement) {

    @track activePage        = 'home';
    @track dropdownOpen      = false;
    @track notifDropdownOpen = false;
    @track hasUnread         = false;
    @track notifications     = [];

    _wiredNotifResult;
    _subscription = null;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD, PHONE_FIELD, CITY_FIELD, CONTACT_ID_FIELD]
    })
    userData;

    @wire(getMyNotifications)
    wiredNotifs(result) {
        this._wiredNotifResult = result;
        const { data, error } = result;
        if (data) {
            this.notifications = data;
            // Badge actif seulement s'il y a des non-lues en base
            this.hasUnread = data.length > 0;
        } else if (error) {
            console.error('Erreur notifications:', error);
            this.notifications = [];
            this.hasUnread     = false;
        }
    }

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const map = {
            'Mes_Demandes__c'    : 'demandes',
            'Nouvelle_Demande__c': 'nouvelle',
            'FAQ__c'             : 'faq',
            'Produits__c'        : 'produits'
        };
        this.activePage = map[ref.attributes.name] || 'home';
    }

    connectedCallback() {
        this._subscribeToEvents();
        onError(error => console.error('Erreur EMP API:', error));
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, () => {});
        }
    }

    _subscribeToEvents() {
        const messageCallback = (event) => {
            const currentContactId = getFieldValue(this.userData.data, CONTACT_ID_FIELD);
            const eventContactId   = event.data.payload.Contact_Id__c;
            if (currentContactId && currentContactId === eventContactId) {
                refreshApex(this._wiredNotifResult);
            }
        };

        subscribe(CHANNEL, -1, messageCallback)
            .then(sub => { this._subscription = sub; })
            .catch(err => console.error('Erreur subscribe:', err));
    }

    get notifCount()       { return this.notifications.length; }
    get hasNotifications() { return this.notifications.length > 0; }

    get userName()     { return getFieldValue(this.userData.data, NAME_FIELD)  || 'Client Luxe'; }
    get userEmail()    { return getFieldValue(this.userData.data, EMAIL_FIELD) || ''; }
    get contactPhone() { return getFieldValue(this.userData.data, PHONE_FIELD) || 'Non renseigné'; }
    get contactCity()  { return getFieldValue(this.userData.data, CITY_FIELD)  || 'Non renseignée'; }

    get userInitials() {
        const name = this.userName;
        if (!name || name === 'Client Luxe') return 'ML';
        const parts = name.trim().split(' ');
        return parts.length >= 2
            ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
            : name.substring(0, 2).toUpperCase();
    }

    setActive(e) {
        e.preventDefault();
        const page = e.currentTarget.dataset.page;
        this.activePage = page;
        const map = {
            'home'     : 'Home',
            'demandes' : 'Mes_Demandes__c',
            'nouvelle' : 'Nouvelle_Demande__c',
            'faq'      : 'FAQ__c',
            'produits' : 'Produits__c'
        };
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: map[page] || 'Home' }
        });
    }

    toggleDropdown()  { this.dropdownOpen = !this.dropdownOpen; }
    closeDropdown()   { this.dropdownOpen = false; }

    toggleNotifDropdown() {
        this.notifDropdownOpen = !this.notifDropdownOpen;

        // À l'ouverture : masquer le badge ET marquer comme lues en base
        if (this.notifDropdownOpen && this.hasUnread) {
            this.hasUnread = false;
            markAllAsRead()
                .then(() => refreshApex(this._wiredNotifResult))
                .catch(err => console.error('Erreur markAllAsRead:', err));
        }
    }

    closeNotifDropdown() { this.notifDropdownOpen = false; }

    handleLogout() {
        const logoutEndpoint = '/MJSupport/secur/logout.jsp';
        const destinationUrl = 'https://olivesoft--pfe.sandbox.my.site.com/MJSupport/s/login';
        window.location.href = `${logoutEndpoint}?retUrl=${encodeURIComponent(destinationUrl)}`;
    }

    get linkHome()     { return this.activePage === 'home'     ? 'lux-link active' : 'lux-link'; }
    get linkDemandes() { return this.activePage === 'demandes' ? 'lux-link active' : 'lux-link'; }
    get linkNouvelle() { return this.activePage === 'nouvelle' ? 'lux-link active' : 'lux-link'; }
    get linkFaq()      { return this.activePage === 'faq'      ? 'lux-link active' : 'lux-link'; }
    get linkProduits() { return this.activePage === 'produits' ? 'lux-link active' : 'lux-link'; }
}