import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {
    static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* CONTENEUR GLOBAL DU LWC */
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

            /* FORCE LE CARREAU BLANC (ZONE ROUGE) */
            .salesforceIdentityLoginForm, 
            .cLogin, 
            .community-identity-form,
            .siteforceServiceBody .cLogin {
                background-color: #ffffff !important;
                border: 1px solid #e2ddd4 !important;
                border-top: none !important;
                border-radius: 0 0 8px 8px !important;
                padding: 40px 30px !important;
                margin: 0 auto !important;
                max-width: 450px !important;
                box-shadow: 0 15px 35px rgba(0,0,0,0.1) !important;
                display: block !important;
            }

            /* STYLISATION DES LIENS */
            .salesforceIdentityLoginForm a, .cLogin a {
                color: #24170f !important;
                font-weight: bold !important;
                text-decoration: none !important;
                font-size: 13px !important;
                margin-top: 15px !important;
                display: inline-block !important;
            }

            /* BOUTON SE CONNECTER */
            .slds-button_brand {
                background-color: #c8a75c !important;
                border: none !important;
                height: 50px !important;
                width: 100% !important;
                color: white !important;
                text-transform: uppercase !important;
                font-weight: bold !important;
            }
        `;
        document.head.appendChild(style);
    }
}