import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {
    static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* 1. BANDEAU PLUS GRAND */
            .lux-banner-container {
                background-color: #24170f !important;
                padding: 60px 20px !important; /* Augmenté de 40px à 60px */
                text-align: center !important;
                border-radius: 4px 4px 0 0 !important;
                display: block !important;
                width: 100% !important;
                box-sizing: border-box !important;
            }

            .lux-text-main {
                color: #c8a75c !important;
                font-family: 'Playfair Display', serif !important;
                font-size: 32px !important; /* Augmenté de 24px à 32px */
                font-weight: bold !important;
                letter-spacing: 6px !important;
                text-transform: uppercase !important;
                margin-bottom: 12px !important;
                display: block !important;
            }

            .lux-text-sub {
                color: #c8a75c !important;
                font-family: 'Lato', sans-serif !important;
                font-size: 14px !important; /* Augmenté de 12px à 14px */
                letter-spacing: 4px !important;
                text-transform: uppercase !important;
                display: block !important;
            }

            /* 2. LIENS SOUS LE BOUTON (Forgot password / Register) */
            /* On cible les liens à l'intérieur du formulaire Salesforce */
            .salesforceIdentityLoginForm a, 
            .salesforceIdentityLoginForm .footerAction a,
            .cLogin a {
                color: #24170f !important; /* Noir/Brun foncé au lieu du blanc */
                font-weight: bold !important;
                text-decoration: none !important;
                font-size: 13px !important;
            }

            .salesforceIdentityLoginForm a:hover {
                color: #c8a75c !important; /* Devient doré au survol */
                text-decoration: underline !important;
            }

            /* 3. AJUSTEMENT DU FORMULAIRE */
            .salesforceIdentityLoginForm, .cLogin {
                margin-top: 0 !important;
                border-top: none !important;
                border-radius: 0 0 4px 4px !important;
                padding-bottom: 30px !important;
            }
        `;
        document.head.appendChild(style);
    }
}