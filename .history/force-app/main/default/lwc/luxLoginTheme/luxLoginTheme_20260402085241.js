// luxLoginTheme.js
import { LightningElement } from 'lwc';

export default class LuxLoginTheme extends LightningElement {

    connectedCallback() {
        // Vérifie que le style n'est pas déjà injecté
        if (document.getElementById('lux-login-theme')) return;

        const style = document.createElement('style');
        style.id = 'lux-login-theme';
        style.innerHTML = `

            /* ── FOND PAGE ── */
            body {
                background-color: #f5f2eb !important;
                font-family: Georgia, serif !important;
            }

            /* ── CACHER LE HEADER ── */
            c-lux-header,
            header.lux-nav,
            .lux-nav {
                display: none !important;
            }

            /* ── CONTENEUR LOGIN ── */
            .siteLoginPage {
                max-width: 520px !important;
                margin: 60px auto !important;
                background: #ffffff !important;
                padding: 40px !important;
                border-top: 6px solid #2c1a0e !important;
                box-shadow: 0 4px 32px rgba(0,0,0,0.12) !important;
                box-sizing: border-box !important;
            }

            /* ── LABELS ── */
            .slds-form-element__label {
                font-size: 10px !important;
                font-weight: 700 !important;
                letter-spacing: 0.14em !important;
                text-transform: uppercase !important;
                color: #5c4a2a !important;
                font-family: Arial, sans-serif !important;
            }

            /* ── INPUTS ── */
            .slds-input,
            input[type="text"],
            input[type="email"],
            input[type="password"] {
                border: 1px solid #c9b99a !important;
                border-radius: 0 !important;
                padding: 14px 16px !important;
                font-size: 15px !important;
                background: #ffffff !important;
                color: #1a1008 !important;
                font-family: Arial, sans-serif !important;
                height: auto !important;
                transition: border-color 0.2s ease !important;
            }

            input[type="text"]:focus,
            input[type="email"]:focus,
            input[type="password"]:focus {
                border-color: #8a6a30 !important;
                outline: none !important;
                box-shadow: none !important;
            }

            /* ── BOUTON LOG IN ── */
            .slds-button_brand,
            button[type="submit"] {
                background: #a07840 !important;
                border: none !important;
                border-radius: 0 !important;
                color: #ffffff !important;
                font-size: 11px !important;
                font-weight: 700 !important;
                letter-spacing: 0.18em !important;
                text-transform: uppercase !important;
                width: 100% !important;
                padding: 18px !important;
                font-family: Arial, sans-serif !important;
                cursor: pointer !important;
            }

            .slds-button_brand:hover,
            button[type="submit"]:hover {
                background: #8a6530 !important;
            }

            /* ── LIENS ── */
            .forgotPasswordLink,
            a[href*="ForgotPassword"] {
                color: #a07840 !important;
                font-size: 12px !important;
                text-decoration: none !important;
            }

            /* ── CACHER "Not a member?" ── */
            .selfRegLink {
                display: none !important;
            }

            /* ── ERREURS ── */
            .slds-form-element__help {
                color: #8b3a3a !important;
                font-size: 12px !important;
            }
        `;

        // Injection dans le <head> du document — échappe au Shadow DOM
        document.head.appendChild(style);
    }

    disconnectedCallback() {
        // Nettoyage quand le composant est retiré
        const style = document.getElementById('lux-login-theme');
        if (style) style.remove();
    }
}