public class UpdateCasesSubjectsDescriptionsFull {

    public static void run() {

        Map<String, Map<String, List<String>>> templates = new Map<String, Map<String, List<String>>>{
            'Demande information' => new Map<String, List<String>>{
                'Disponibilité produit' => new List<String>{
                    'Bonjour, je souhaite savoir si le sac modèle Riviera en cuir cognac est encore disponible.',
                    'Pouvez-vous confirmer la disponibilité de la veste en soie ivoire taille 38 ? Merci.',
                    'Je cherche le parfum Édition Limitée Nuit Dorée. Est-il en stock ?',
                    'Les escarpins Automne-Hiver en daim noir sont-ils disponibles en taille 40 ?',
                    'La ceinture monogramme taille 85 est-elle disponible en boutique ou en ligne ?'
                },
                'Suivi commande' => new List<String>{
                    'J\'ai passé une commande le 15 mars et n\'ai pas reçu de confirmation d\'expédition.',
                    'Commande numéro 20260289 non expédiée, pouvez-vous vérifier le statut ?',
                    'Je souhaite suivre la commande réf. ORD-445821, le suivi ne fonctionne pas.',
                    'Ma commande attend depuis 10 jours, date de livraison estimée ? Réf. 20260178.',
                    'Statut de ma commande en boutique la semaine dernière, référence BC-20260315.'
                },
                'Information sur prix / promotion' => new List<String>{
                    'Collection printemps en promotion lors des prochaines ventes privées ?',
                    'Prix montre Élégance Or Rose avec bracelet cuir ?',
                    'Offres en cours pour le programme fidélité Gold ?',
                    'Le prix affiché inclut-il la TVA pour les clients hors UE ?',
                    'Certains articles sont à prix réduit en ligne mais pas en boutique, pourquoi ?'
                },
                'Informations sur personnalisation' => new List<String>{
                    'Faire graver les initiales sur une ceinture, possible et délai ?',
                    'Options de personnalisation disponibles pour sac modèle Prestige ?',
                    'Portefeuille personnalisé avec monogramme, délais et tarifs ?',
                    'Paires de chaussures sur mesure, options et délais ?',
                    'Choisir couleur du fil de couture pour sac bespoke, possible ?'
                }
            },

            'Echange produit' => new Map<String, List<String>>{
                'Taille / ajustement' => new List<String>{
                    'Chaussures taille 39 trop petites, je souhaite taille 40.',
                    'Veste reçue M trop large, échange contre S ? Réf. ORD-20260298.',
                    'Pantalon taille 40 ne correspond pas, échange taille 38.',
                    'Ceinture taille 85 trop grande, échange contre 80.',
                    'Robe taille 36 trop ajustée, échange contre 38. Commande 10 mars.'
                },
                'Couleur / modèle' => new List<String>{
                    'Sac reçu noir au lieu de bordeaux, échange demandé.',
                    'Escarpins en daim beige reçus au lieu de taupe.',
                    'Foulard modèle "Jardin" reçu, modèle "Marine" commandé.',
                    'Bracelet version dorée reçu au lieu de argentée. Réf. ORD-20260341.',
                    'Portefeuille en cuir lisse reçu, cuir grainé commandé.'
                },
                'Produit défectueux' => new List<String>{
                    'Fermeture éclair sac reçue défectueuse, échange immédiat.',
                    'Couture écharpe en cachemire défait après premier port.',
                    'Talon chaussures décollé, échange souhaité.',
                    'Montre reçue avec verre fissuré, emballage intact.',
                    'Fermoir collier défaillant, remplacement demandé. Réf. ORD-20260402.'
                },
                'Produit non conforme à la commande' => new List<String>{
                    'Article reçu ne correspond pas à ma commande, sac Capri reçu au lieu de Riviera.',
                    'Colis contient produit d\'autre client, commande ORD-20260215.',
                    'Référence produit sur l\'étiquette incorrecte, merci de corriger.',
                    'Version femme parfum Éclat Blanc commandée, version homme reçue.',
                    'Commande de deux articles, un manquant. Réf. ORD-20260388.'
                }
            },

            'Réclamation' => new Map<String, List<String>>{
                'Produit endommagé / défectueux' => new List<String>{
                    'Sac arrivé rayé et poignée abîmée, remboursement ou remplacement demandé.',
                    'Flacon de parfum brisé, liquide sur autres articles, réclamation urgente.',
                    'Chaussures avec défauts visibles, très déçu de la qualité.',
                    'Montre avec bracelet cassé, remplacement demandé.',
                    'Pochette avec tache sur cuir, échange immédiat demandé.'
                },
                'Livraison retardée' => new List<String>{
                    'Commande ORD-20260123 retardée, aucune communication reçue.',
                    'Commande pour anniversaire arrivée avec 5 jours de retard.',
                    'Livraison express payée non respectée, remboursement souhaité.',
                    'Colis bloqué depuis 6 jours, personne ne répond aux appels.',
                    'Date de livraison pour événement non respectée, préjudice réel.'
                },
                'Erreur de facturation' => new List<String>{
                    'Facturé deux fois pour commande ORD-20260298, remboursement demandé.',
                    'Montant débité supérieur à confirmation de commande, veuillez corriger.',
                    'Code promo non appliqué sur facture, régularisation demandée.',
                    'Retour du mois dernier non crédité, réclamation.',
                    'Facture avec TVA incorrecte, client professionnel.'
                },
                'Mauvais produit livré' => new List<String>{
                    'Colis contient mauvais articles, erreur préparation.',
                    'Produit livré ne correspond ni à la référence ni à la photo.',
                    'Sac noir commandé, sac rouge reçu, deuxième erreur.',
                    'Colis contient articles d\'autre client, erreur.',
                    'Article masculin reçu alors que commande féminine.'
                }
            },

            'Retour produit' => new Map<String, List<String>>{
                'Remboursement demandé' => new List<String>{
                    'Retour robe reçue le 12 mars, remboursement complet souhaité.',
                    'Renvoi sac commandé, remboursement sur carte bancaire demandé.',
                    'Réclamation du 18 mars, remboursement non reçu, délai ?',
                    'Retour escarpins jamais portés, remboursement demandé.',
                    'Droit de rétractation exercé pour commande ORD-20260289.'
                },
                'Retour pour non-conformité' => new List<String>{
                    'Article ne correspond pas à la description, retour et remboursement demandé.',
                    'Produit livré différent des photos du site, retour demandé.',
                    'Qualité du cuir inférieure, retour et remboursement demandé.',
                    'Coloris du produit reçu différent de la fiche produit, retour demandé.',
                    'Dimensions réelles non conformes, retour demandé. Réf. ORD-20260401.'
                }
            }
        };

        List<Case> existingCases = [
            SELECT Id, Category__c, Subcategory__c, Subject, Description
            FROM Case
            WHERE Status = 'Closed'
            AND Category__c != null
            AND Subcategory__c != null
            ORDER BY CreatedDate ASC
            LIMIT 400
        ];

        List<Case> casesToUpdate = new List<Case>();
        Map<String, Integer> indexTracker = new Map<String, Integer>();

        for (Case c : existingCases) {
            String cat = c.Category__c;
            String sub = c.Subcategory__c;

            if (templates.containsKey(cat) && templates.get(cat).containsKey(sub)) {
                List<String> texts = templates.get(cat).get(sub);
                String key = cat + '|' + sub;
                Integer idx = indexTracker.containsKey(key) ? indexTracker.get(key) : 0;
                String selectedText = texts[Math.mod(idx, texts.size())];
                indexTracker.put(key, idx + 1);

                c.Subject = selectedText.length() > 60 ? selectedText.substring(0, 60).trim() + '...' : selectedText;
                c.Description = selectedText;
                casesToUpdate.add(c);
            }
        }

        Integer batchSize = 100;
        for (Integer i = 0; i < casesToUpdate.size(); i += batchSize) {
            Integer endIdx = Math.min(i + batchSize, casesToUpdate.size());
            List<Case> batch = new List<Case>();
            for (Integer j = i; j < endIdx; j++) {
                batch.add(casesToUpdate[j]);
            }
            update batch;
        }
    }
}