import { LightningElement, wire, track } from 'lwc';
import getFAQs          from '@salesforce/apex/FAQController.getFAQs';
import getFAQCategories from '@salesforce/apex/FAQController.getFAQCategories';

export default class FaqList extends LightningElement {

    @track lang    = 'fr';
    @track openIds = new Set();
    @track rawFaqs = [];
    @track cats    = [];

    @wire(getFAQCategories, { lang: '$lang' })
    wiredCats({ data }) {
        if (data) this.cats = data;
    }

    @wire(getFAQs, { lang: '$lang' })
    wiredFaqs({ data }) {
        if (data) { this.rawFaqs = data; this.openIds = new Set(); }
    }

    get groupedFaqs() {
        return this.cats.map(cat => ({
            name: cat,
            faqs: this.rawFaqs
                .filter(f => f.Category__c === cat)
                .map(f => ({
                    ...f,
                    isOpen: this.openIds.has(f.Id),
                    icon  : this.openIds.has(f.Id) ? '−' : '+'
                }))
        })).filter(g => g.faqs.length > 0);
    }

    get isEmpty() {
        return this.rawFaqs.length === 0;
    }

    toggle(e) {
        const id  = e.currentTarget.dataset.id;
        const set = new Set(this.openIds);
        set.has(id) ? set.delete(id) : set.add(id);
        this.openIds = set;
    }

    setLang(e) { this.lang = e.target.dataset.lang; }

    get btnFr() { return this.lang === 'fr' ? 'lang-btn active' : 'lang-btn'; }
    get btnEn() { return this.lang === 'en' ? 'lang-btn active' : 'lang-btn'; }
}