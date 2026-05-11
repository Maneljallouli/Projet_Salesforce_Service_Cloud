({
    doInit : function(component, event, helper) {
        var action = component.get("c.getMyCases");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.cases", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    goToDetail : function(component, event, helper) {
        event.preventDefault();
        var caseId = event.currentTarget.dataset.id;
        var navService = component.find("navService");

        // Utilisation de la PageReference standard (meilleure pour l'historique "Retour")
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        };
        navService.navigate(pageReference);
    },

    viewAll : function(component, event, helper) {
        var navService = component.find("navService");
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent' // Ou 'MyCases'
            }
        };
        navService.navigate(pageReference);
    }
})