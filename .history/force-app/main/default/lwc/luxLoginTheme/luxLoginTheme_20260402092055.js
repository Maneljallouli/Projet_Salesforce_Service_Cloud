import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {
    static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* 1. LE BANDEAU NOIR */
            .lux-banner-container {
                background-color: #24170f !important;
                padding: 60px 20px !important;
                text-align: center !important;
                border-radius: 8px 8px 0 0 !important; /* Arrondi en haut */
                display: block !important;
                width: 100% !important;
                max-width: 450px !important; /* Largeur fixe pour aligner avec le bas */
                margin: 0 auto !important;
                box-sizing: border-box !important;
            }

            .lux-text-main {
                color: #c8a75c !important;
                font-family: 'Playfair Display', serif !important;
                font-size: 32px !important;
                font-weight: bold !important;
                letter-spacing: 6px !important;
                text-transform: uppercase !important;
                margin-bottom: 12px !important;
                display: block !important;
            }

            .lux-text-sub {
                color: #c8a75c !important;
                font-size: 14px !important;
                letter-spacing: 4px !important;
                text-transform: uppercase !important;
                display: block !important;
            }

            /* 2. LE CARREAU BLANC (La zone rouge sur ton dessin) */
            .salesforceIdentityLoginForm, .cLogin {
                background-color: #ffffff !important; /* Fond blanc */
                border: 1px solid #e2ddd4 !important; /* Bordure fine beige */
                border-top: none !important; /* Fusion avec le bandeau noir */
                border-radius: 0 0 8px 8px !important; /* Arrondi en bas */
                padding: 40px 30px !important; /* Marge interne pour que les inputs respirent */
                margin: 0 auto !important;
                max-width: 450px !important;
                box-shadow: 0 15px 35px rgba(0,0,0,0.1) !important; /* Ombre portée */
            }

            /* 3. STYLISATION DES LIENS EN BAS */
            .salesforceIdentityLoginForm a, .cLogin a {
                color: #24170f !important;
                font-weight: bold !important;
                text-decoration: none !important;
                font-size: 13px !important;
                margin-top: 15px !important;
                display: inline-block !important;
            }

            /* 4. LE BOUTON D'ACTION */
            .slds-button_brand {
                background-color: #c8a75c !important;
                border-color: #c8a75c !important;
                height: 50px !important;
                margin-top: 20px !important;
            }
        `;
        document.head.appendChild(style);
    }
}