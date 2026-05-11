import { LightningElement, track } from 'lwc';

export default class LuxLoginPage extends LightningElement {
    @track username = '';
    @track password = '';
    @track isLoading = false;
    @track errorMsg = '';

    // Getter pour le texte du bouton (corrige le problème du ternaire)
    get loginButtonLabel() {
        return this.isLoading ? 'Connexion...' : 'Connexion';
    }

    handleUsername(event) {
        this.username = event.target.value;
    }

    handlePassword(event) {
        this.password = event.target.value;
    }

    handleLogin() {
        if (!this.username || !this.password) {
            this.errorMsg = 'Veuillez remplir tous les champs.';
            return;
        }

        this.errorMsg = '';
        this.isLoading = true;

        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/luxportail/login'; // endpoint Salesforce Identity

        const fields = {
            username: this.username,
            password: this.password,
            startURL: '/luxportail',
            _csrf: this.getCsrf()
        };

        Object.entries(fields).forEach(([key, val]) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = key;
            input.value = val || '';
            form.appendChild(input);
        });

        document.body.appendChild(form);
        form.submit();
    }

    getCsrf() {
        const meta = document.querySelector('meta[name="salesforce-community-url"]');
        return meta ? meta.getAttribute('data-csrf') || '' : '';
    }
}