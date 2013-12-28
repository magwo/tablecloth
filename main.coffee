
app = angular.module "tableTestApp", []


asSimpleListController = ($scope, $q, dataService, eventHandlers, itemsPerPage) ->

    # TODO: Fix/reconsider chained/simul operations
    startDeferred = $q.defer()
    $scope.currentOperation = startDeferred.promise
    startDeferred.resolve()

    $scope.currentItems = []
    $scope.selectedItem = null

    $scope.itemsPerPage = itemsPerPage
    $scope.itemCountTotal = 0
    $scope.pageCount = 0
    $scope.selectedPage = null

    $scope.isLoading = -> $scope.leftToLoad > 0

    $scope.selectItem = (item) ->
        # TODO: Support item select prevention with a function
        prevItem = $scope.selectedItem
        $scope.selectedItem = item
        eventHandlers.afterItemSelection($scope.selectedItem, prevItem)

    $scope.selectIndex = (i) ->
        $scope.selectItem($scope.currentItems[i])

    $scope.toggleSelect = (item) ->
        if item != $scope.selectedItem
            $scope.selectItem(item)
        else
            $scope.unselect()

    $scope.hasSelectedItem = ->
        return $scope.selectedItem != null

    $scope.isSelectedItem = (otherItem) ->
        return $scope.selectedItem is otherItem

    $scope.loadDetails = (item) ->
        return dataService.getDetails(item)

    $scope.unselect = ->
        $scope.selectItem(null)

    $scope.selectPage = (pageNum) ->
        safePageNum = Math.min($scope.pageCount - 1, Math.max(0, pageNum))
        if safePageNum != $scope.selectedPage
            $scope.selectedPage = pageNum
            $scope.getItemList()

    $scope.nextPage = ->
        $scope.selectPage($scope.selectedPage + 1)

    $scope.prevPage = ->
        $scope.selectPage($scope.selectedPage - 1)

    $scope.getItemList = ->
        # Respect previous operation by always using promise interface (or?)
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            $scope.currentOperation = dataService.getItemList($scope.itemsPerPage, $scope.itemsPerPage * $scope.selectedPage)
            $scope.currentOperation.then( (resp) ->
                $scope.unselect()
                eventHandlers.onListResponse(resp)
                $scope.currentItems = resp.items
                eventHandlers.onItemsChanged()
                $scope.leftToLoad = 0.0
            , eventHandlers.onError, eventHandlers.onLoadProgress)

    $scope.deleteItem = (item) ->
        # Respect previous operation by always using promise interface (or?)
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            if $scope.isSelectedItem(item)
                $scope.unselect()
            $scope.currentOperation = dataService.deleteItem(item)
            $scope.currentOperation.then(->
                $scope.currentItems.splice($scope.currentItems.indexOf(item), 1)
                eventHandlers.onItemsChanged()
                $scope.leftToLoad = 0.0
            , eventHandlers.onError, eventHandlers.onLoadProgress)

    $scope.saveItem = (item) ->
        # Respect previous operation by always using promise interface (or?)
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            $scope.currentOperation = dataService.saveItem(item)
            $scope.currentOperation.then(->
                eventHandlers.onItemSaved(item)
                $scope.leftToLoad = 0.0
            , eventHandlers.onError, eventHandlers.onLoadProgress)




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




app.controller "TableController", ($scope, $q, testDataService) ->
    window.$scope = $scope
    window.$q = $q

    eventHandlers = createTestEventHandlers($scope)

    asSimpleListController($scope, $q, testDataService, eventHandlers, 10)
    console.log($scope)
    $scope.selectPage(0)
