import { LightningElement, wire, track } from 'lwc';
import getProducts    from '@salesforce/apex/ProductController.getProducts';
import getCollections from '@salesforce/apex/ProductController.getCollections';

export default class ProductGallery extends LightningElement {

    @track activeCollection = 'All';
    @track isLoading        = true;
    @track rawProducts      = [];
    @track rawCollections   = [];

    @wire(getCollections)
    wiredCols({ data }) {
        if (data) this.rawCollections = data;
    }

    @wire(getProducts, { collection: '$activeCollection' })
    wiredProducts({ data, error }) {
        if (data)  { this.rawProducts = data;  this.isLoading = false; }
        if (error) { this.isLoading = false; console.error(error); }
    }

    get products() { return this.rawProducts; }

    get isEmpty() { return this.rawProducts.length === 0; }

    get collectionOptions() {
        return this.rawCollections.map(c => ({
            label   : c === 'All' ? 'Tout voir' : c,
            value   : c,
            btnClass: c === this.activeCollection ? 'filter-btn active' : 'filter-btn'
        }));
    }

    filterCollection(e) {
        this.activeCollection = e.target.dataset.col;
        this.isLoading = true;
    }

    handleImgError(e) {
        e.target.src = 'https://placehold.co/400x300/1a1a1a/C8A96A?text=LUX';
    }
}