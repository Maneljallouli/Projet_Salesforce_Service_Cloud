import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {
    static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* 1. POSITIONNEMENT DU BANDEAU NOIR */
            .lux-banner-container {
                background-color: #24170f !important;
                padding: 60px 20px !important;
                text-align: center !important;
                border-radius: 8px 8px 0 0 !important;
                display: block !important;
                width: 100% !important;
                max-width: 450px !important;
                margin: 0 auto !important;
                box-sizing: border-box !important;
                position: relative !important;
                z-index: 2 !important;
            }

            /* 2. LE CARREAU BLANC (BACKGROUND DU FORMULAIRE) */
            /* On cible le formulaire et ses conteneurs immédiats */
            .salesforceIdentityLoginForm, 
            .salesforceIdentitySelfRegisterForm,
            .cLogin,
            .comm-layout-column .ui-widget {
                background-color: #ffffff !important; /* Force le fond blanc */
                border: 1px solid #e2ddd4 !important;
                border-top: none !important; /* Pour qu'il se colle au bandeau */
                border-radius: 0 0 8px 8px !important;
                padding: 40px 30px !important; /* Espace interne pour les champs */
                margin: 0 auto !important;
                max-width: 450px !important;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1) !important;
                display: block !important;
                position: relative !important;
                z-index: 1 !important;
            }

            /* 3. STYLISATION DES INPUTS DANS LE CARREAU BLANC */
            .slds-input {
                background-color: #fcfaf7 !important;
                border: 1px solid #dcd1bd !important;
                color: #24170f !important;
            }

            /* 4. LIENS (MOT DE PASSE OUBLIÉ, ETC) */
            .salesforceIdentityLoginForm a, 
            .salesforceIdentitySelfRegisterForm a {
                color: #24170f !important;
                font-weight: bold !important;
                display: inline-block !important;
                margin-top: 10px !important;
            }

            /* 5. BOUTON SE CONNECTER */
            .slds-button_brand {
                background-color: #c8a75c !important;
                border: none !important;
                width: 100% !important;
                height: 50px !important;
                margin-top: 20px !important;
            }
        `;
        document.head.appendChild(style);
    }
}