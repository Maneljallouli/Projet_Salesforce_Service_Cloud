({
    doInit : function(component, event, helper) {
        var action = component.get("c.getMyCases");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Pour debug : vérifiez la console F12 sur le site
                console.log("Données reçues : ", response.getReturnValue());
                component.set("v.cases", response.getReturnValue());
            } else {
                console.error("Erreur lors de la récupération des cases");
            }
        });
        $A.enqueueAction(action);
    },

    goToDetail : function(component, event, helper) {
        var caseId = event.currentTarget.dataset.id;
        var navService = component.find("navService");
        navService.navigate({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    },

    viewAll : function(component, event, helper) {
        var navService = component.find("navService");
        navService.navigate({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'list'
            },
            state: { filterName: 'Recent' }
        });
    }
})