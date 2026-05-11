import { LightningElement } from 'lwc';

export default class LuxGlobalStyles extends LightningElement {

    connectedCallback() {

        // ── Google Fonts ──
        if (!document.getElementById('lux-fonts')) {
            const link  = document.createElement('link');
            link.id     = 'lux-fonts';
            link.rel    = 'stylesheet';
            link.href   = 'https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Lato:wght@300;400;600;700&display=swap';
            document.head.appendChild(link);
        }

        // ── CSS Global ──
        if (!document.getElementById('lux-global-css')) {
            const style   = document.createElement('style');
            style.id      = 'lux-global-css';
            style.textContent = `

                /* 1. SUPPRESSION HEADER/FOOTER SUR LOGIN/REGISTER */
                html:has([data-fqn*="login"],
                         [data-fqn*="Register"],
                         .salesforceIdentityLoginForm,
                         .salesforceIdentitySelfRegisterForm) header,
                html:has([data-fqn*="login"],
                         [data-fqn*="Register"],
                         .salesforceIdentityLoginForm,
                         .salesforceIdentitySelfRegisterForm) [data-f6-region="header"],
                html:has([data-fqn*="login"],
                         [data-fqn*="Register"],
                         .salesforceIdentityLoginForm,
                         .salesforceIdentitySelfRegisterForm) footer,
                html:has([data-fqn*="login"],
                         [data-fqn*="Register"],
                         .salesforceIdentityLoginForm,
                         .salesforceIdentitySelfRegisterForm) [data-f6-region="footer"] {
                    display: none !important;
                }

                /* 2. FOND DE PAGE */
                body, .siteforceContentArea, .body_container {
                    background: #f4f1ec !important;
                }

                /* 3. FORMULAIRE LOGIN & REGISTER */
                [data-fqn*="loginForm"],
                [data-fqn*="selfRegister"],
                .salesforceIdentityLoginForm,
                .salesforceIdentitySelfRegisterForm,
                .cLogin, .cRegister {
                    position: relative !important;
                    max-width: 500px !important;
                    margin: 80px auto !important;
                    background: #ffffff !important;
                    box-shadow: 0 20px 50px rgba(0,0,0,0.12) !important;
                    padding-top: 130px !important;
                    border: 1px solid #e2ddd4 !important;
                    border-radius: 4px !important;
                    display: block !important;
                }

                /* 4. BANDEAU NOIR MAISON LUXE */
                [data-fqn*="loginForm"]::before,
                [data-fqn*="selfRegister"]::before,
                .salesforceIdentityLoginForm::before,
                .salesforceIdentitySelfRegisterForm::before,
                .cLogin::before, .cRegister::before {
                    content: "MAISON LUXE\\A ESPACE CLIENT PRIVÉ" !important;
                    white-space: pre !important;
                    position: absolute !important;
                    top: 0 !important;
                    left: 0 !important;
                    right: 0 !important;
                    background: #24170f !important;
                    color: #c8a75c !important;
                    text-align: center !important;
                    padding: 40px 20px !important;
                    font-family: 'Playfair Display', serif !important;
                    font-size: 20px !important;
                    line-height: 1.5 !important;
                    letter-spacing: 4px !important;
                    text-transform: uppercase !important;
                    z-index: 10 !important;
                    display: block !important;
                }

                /* 5. CHAMPS & LABELS */
                input[type="text"],
                input[type="password"],
                input[type="email"],
                .slds-input {
                    background: #fcfaf7 !important;
                    border: 1px solid #dcd1bd !important;
                    height: 50px !important;
                    font-family: 'Lato', sans-serif !important;
                    border-radius: 2px !important;
                }

                label, .slds-form-element__label {
                    color: #a88655 !important;
                    font-size: 11px !important;
                    letter-spacing: 1.5px !important;
                    text-transform: uppercase;
                }

                /* 6. BOUTONS */
                .slds-button_brand,
                .loginButton,
                .registerButton,
                button[type="submit"],
                .slds-button--brand {
                    background: #c8a75c !important;
                    height: 55px !important;
                    border-radius: 2px !important;
                    font-size: 14px !important;
                    letter-spacing: 2px !important;
                    color: white !important;
                    width: 100% !important;
                    border: none !important;
                    cursor: pointer !important;
                }

                /* 7. SUPPRESSION ÉLÉMENTS PARASITES */
                .salesforceIdentityAppLogo2,
                .comm-print-header {
                    display: none !important;
                }

                /* 8. CSS GLOBAL SITE */
                h1, h2, h3 {
                    font-family: 'Playfair Display', Georgia, serif !important;
                    font-weight: 400 !important;
                    color: #2E2416 !important;
                }
                ::-webkit-scrollbar { width: 6px; }
                ::-webkit-scrollbar-track { background: #F5F0E8; }
                ::-webkit-scrollbar-thumb {
                    background: #C4A35A;
                    border-radius: 3px;
                }
            `;
            document.head.appendChild(style);
        }
    }
}