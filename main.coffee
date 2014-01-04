
app = angular.module "exampleApp", []


createTestItem = (name) ->
    return {
        name: name
        someProperty: if Math.random() > 0.5 then true else false
        someOtherProperty: Math.random()
    }


app.factory "testDataService", ($q) ->
    service = {}
    items = (createTestItem("item #{it}") for it in [0..125])

    service.deleteItem = (item) ->
        d = $q.defer()

        setTimeout( ->
            #d.reject("nooo")
            items.splice(items.indexOf(item), 1)
            d.resolve()
        , 800)

        return d.promise

    service.saveItem = (item) ->
        d = $q.defer()
        setTimeout( ->
            d.resolve()
        , 400)
        return d.promise

    service.getItemList = (count, offset) ->
        d = $q.defer()

        setTimeout( ->
            actualCount = Math.min(count, items.length - offset)
            respItems = items.slice(offset, offset + actualCount)
            response = { items: respItems, totalCount: items.length }
            d.resolve(response)
        , 300)

        return d.promise

    return service


createTestEventHandlers = ($scope) ->
    obj = {}

    obj.onError = (e) ->
        console.log "Error", e

    obj.onLoadProgress = (value) ->
        console.log "Progress", value

    obj.onItemsChanged = ->
        console.log "Items changed yeah"

    obj.onItemSaved = (item) ->
        console.log "Saved", item
        $scope.unselect()

    obj.afterItemSelection = -> console.log "After item selection"

    obj.onListResponse = (response) ->
        console.log("")
        $scope.itemCountTotal = response.totalCount
        $scope.pageCount = Math.ceil(response.totalCount / $scope.itemsPerPage)
    return obj




app.controller "exampleController", ($scope, $q, testDataService) ->
    window.$scope = $scope

    eventHandlers = createTestEventHandlers($scope)

    tablecloth.asSimpleListController($scope, $q, testDataService, eventHandlers, 10)
    console.log($scope)
    $scope.selectPage(0)
