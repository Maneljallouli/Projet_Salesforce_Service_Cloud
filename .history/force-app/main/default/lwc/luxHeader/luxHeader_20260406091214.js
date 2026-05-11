import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';

import getMyNotifications from '@salesforce/apex/NotificationController.getMyNotifications';

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
    @track hasNotifications  = false;
    @track notifications     = [];
    @track notifCount        = 0;

    _wiredNotifResult;
    _subscription = null;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD, PHONE_FIELD, CITY_FIELD, CONTACT_ID_FIELD]
    })
    userData;

    // ── CORRECTION : cacheable=true exigé par @wire ──
    @wire(getMyNotifications)
    wiredNotifs(result) {
        this._wiredNotifResult = result;
        const { data, error } = result;
        if (data) {
            this.notifications    = data;
            this.notifCount       = data.length;
            this.hasNotifications = data.length > 0;
        } else if (error) {
            console.error('Erreur notifications:', error);
            this.hasNotifications = false;
            this.notifications    = [];
            this.notifCount       = 0;
        }
    }

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (!ref || !ref.attributes) return;
        const name = ref.attributes.name;
        const map = {
            'Mes_Demandes__c'    : 'demandes',
            'Nouvelle_Demande__c': 'nouvelle',
            'FAQ__c'             : 'faq',
            'Produits__c'        : 'produits'
        };
        this.activePage = map[name] || 'home';
    }

    connectedCallback() {
        this._subscribeToEvents();
        onError(error => {
            console.error('Erreur EMP API:', error);
        });
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, response => {
                console.log('Désinscription Platform Event:', response);
            });
        }
    }

    // ── CORRECTION : refreshApex + badge incrémental ──
    _subscribeToEvents() {
        const messageCallback = (event) => {
            console.log('Platform Event reçu:', event);

            const currentContactId = getFieldValue(this.userData.data, CONTACT_ID_FIELD);
            const eventContactId   = event.data.payload.Contact_Id__c;

            if (currentContactId && currentContactId === eventContactId) {
                console.log('Match ContactId — rafraîchissement...');
                refreshApex(this._wiredNotifResult).then(() => {
                    this.hasNotifications = true;
                });
            }
        };

        subscribe(CHANNEL, -1, messageCallback)
            .then(subscription => {
                this._subscription = subscription;
                console.log('Abonnement réussi au canal:', CHANNEL);
            })
            .catch(error => {
                console.error('Erreur subscribe:', error);
            });
    }

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

    toggleDropdown()      { this.dropdownOpen = !this.dropdownOpen; }
    closeDropdown()       { this.dropdownOpen = false; }

    toggleNotifDropdown() {
        this.notifDropdownOpen = !this.notifDropdownOpen;
        if (this.notifDropdownOpen) {
            this.hasNotifications = false;
            this.notifCount       = 0;
        }
    }
    closeNotifDropdown()  { this.notifDropdownOpen = false; }

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