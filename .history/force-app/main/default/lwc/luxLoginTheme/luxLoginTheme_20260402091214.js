// luxTheme.js
import { LightningElement } from 'lwc';

export default class LuxTheme extends LightningElement {

   static renderMode = 'light';

    connectedCallback() {
        const style = document.createElement('style');
        style.innerText = `
            /* LE BANDEAU NOIR */
            .lux-banner-container {
                background-color: #24170f !important;
                padding: 40px 20px !important;
                text-align: center !important;
                border-radius: 4px 4px 0 0 !important;
                display: block !important;
                width: 100% !important;
                box-sizing: border-box !important;
            }

            .lux-text-main {
                color: #c8a75c !important;
                font-family: 'Playfair Display', serif !important;
                font-size: 24px !important;
                font-weight: bold !important;
                letter-spacing: 5px !important;
                text-transform: uppercase !important;
                margin-bottom: 8px !important;
                display: block !important;
            }

            .lux-text-sub {
                color: #c8a75c !important;
                font-family: 'Lato', sans-serif !important;
                font-size: 12px !important;
                letter-spacing: 3px !important;
                text-transform: uppercase !important;
                display: block !important;
            }

            /* AJUSTEMENT DU FORMULAIRE POUR COLLER AU BANDEAU */
            .salesforceIdentityLoginForm, .cLogin {
                margin-top: 0 !important;
                border-top: none !important;
                border-radius: 0 0 4px 4px !important;
            }
        `;
        document.head.appendChild(style);
    }
}