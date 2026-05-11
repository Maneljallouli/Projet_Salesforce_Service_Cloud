import { LightningElement, wire, track } from 'lwc';
// On importe la nouvelle méthode filtrée par utilisateur
import getMyProducts from '@salesforce/apex/ProductController.getMyProducts';
import getCollections from '@salesforce/apex/ProductController.getCollections';

export default class ProductGallery extends LightningElement {

    @track activeCollection = 'All';
    @track isLoading        = true;
    @track rawProducts      = []; // Stocke les produits reçus d'Apex
    @track rawCollections   = [];

    // Récupération des catégories (boutons de filtrage)
    @wire(getCollections)
    wiredCols({ data, error }) {
        if (data) {
            this.rawCollections = data;
        } else if (error) {
            console.error('Erreur Collections:', error);
        }
    }

    // Récupération des produits spécifiques au client connecté
    // On utilise getMyProducts pour garantir l'affichage des sacs de Walid
    @wire(getMyProducts)
    wiredProducts({ data, error }) {
        this.isLoading = true;
        if (data) {
            this.rawProducts = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Erreur Produits:', error);
        }
    }

    // Getter pour les produits affichés (avec filtre local pour la réactivité)
    get products() {
        if (this.activeCollection === 'All') {
            return this.rawProducts;
        }
        return this.rawProducts.filter(p => p.Collection__c === this.activeCollection);
    }

    // Vérifie si la liste est vide après filtrage
    get isEmpty() {
        return !this.isLoading && this.products.length === 0;
    }

    // Formate les options pour les boutons du HTML
    get collectionOptions() {
        return this.rawCollections.map(c => ({
            label   : c === 'All' ? 'Tout voir' : c,
            value   : c,
            btnClass: c === this.activeCollection ? 'filter-btn active' : 'filter-btn'
        }));
    }

    // Gestion du clic sur les filtres
    filterCollection(e) {
        this.activeCollection = e.target.dataset.col;
        // Pas besoin de mettre isLoading à true ici car le filtrage est instantané (côté client)
    }

    // Image de secours en cas d'URL cassée
    handleImgError(e) {
        e.target.src = 'https://placehold.co/400x300/1a1a1a/C8A96A?text=LUX';
    }
}