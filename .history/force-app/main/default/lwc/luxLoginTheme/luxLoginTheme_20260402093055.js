import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {
    static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* 1. FORCE LE FOND DE PAGE GLOBAL */
            body {
                background-color: #F4F1EC !important;
            }

            /* 2. LE BANDEAU NOIR */
            .lux-banner-container {
                background-color: #24170f !important;
                padding: 50px 20px !important;
                text-align: center !important;
                border-radius: 8px 8px 0 0 !important;
                display: block !important;
                width: 100% !important;
                max-width: 450px !important;
                margin: 0 auto !important;
                box-sizing: border-box !important;
            }

            .lux-text-main {
                color: #c8a75c !important;
                font-family: 'Playfair Display', serif !important;
                font-size: 28px !important;
                letter-spacing: 5px !important;
                text-transform: uppercase !important;
                display: block !important;
            }

            /* 3. LE CARREAU BLANC PRÉCIS (BACKGROUND FORMULAIRE) */
            /* On cible spécifiquement le composant interne pour qu'il ne s'étende pas à toute la page */
            .salesforceIdentityLoginForm, 
            .salesforceIdentitySelfRegisterForm,
            .cLogin {
                background-color: #ffffff !important;
                border: 1px solid #e2ddd4 !important;
                border-top: none !important;
                border-radius: 0 0 8px 8px !important;
                padding: 40px 35px !important;
                margin: 0 auto !important;
                max-width: 450px !important; /* TRÈS IMPORTANT : limite la largeur du carreau blanc */
                box-shadow: 0 15px 35px rgba(0,0,0,0.08) !important;
                box-sizing: border-box !important;
                display: block !important;
            }

            /* 4. AJUSTEMENT DES CHAMPS ET LIENS */
            .slds-input {
                background-color: #fcfaf7 !important;
                border: 1px solid #dcd1bd !important;
                height: 45px !important;
            }

            .salesforceIdentityLoginForm a, 
            .salesforceIdentitySelfRegisterForm a {
                color: #24170f !important;
                font-size: 13px !important;
                font-weight: 600 !important;
            }

            /* 5. BOUTON D'ACTION */
            .slds-button_brand {
                background-color: #c8a75c !important;
                border: none !important;
                height: 50px !important;
                width: 100% !important;
                font-weight: bold !important;
            }
        `;
        document.head.appendChild(style);
    }
}