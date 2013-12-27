
app = angular.module "tableTestApp", []


asSimpleTableController = ($scope, $q, dataService, itemsPerPage) ->

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

    $scope.afterItemSelection = -> console.log "TODO: Externalize this stuff"

    $scope.selectItem = (item) ->
        # TODO: Support item selection prevention with a function
        console.log "selecting", item
        prevItem = $scope.selectedItem
        $scope.selectedItem = item
        $scope.afterItemSelection($scope.selectedItem, prevItem)

    $scope.selectIndex = (i) ->
        $scope.selectItem($scope.currentItems[i])

    $scope.hasSelectedItem = ->
        return $scope.selectedItem != null

    $scope.isSelectedItem = (otherItem) ->
        return $scope.selectedItem is otherItem

    $scope.loadDetails = (item) ->
        return dataService.getDetails(item)

    $scope.unselect = ->
        $scope.selectItem(null)

    $scope.selectPage = (pageNum) ->
        console.log("Foooo")
        safePageNum = Math.min($scope.pageCount - 1, Math.max(0, pageNum))
        if safePageNum != $scope.selectedPage
            $scope.selectedPage = pageNum
            $scope.getItemList()

    $scope.nextPage = ->
        $scope.selectPage($scope.selectedPage + 1)

    $scope.prevPage = ->
        $scope.selectPage($scope.selectedPage - 1)

    ################
    # Externalize
    $scope.onError = (e) ->
        console.log "Error", e

    # Externalize
    $scope.onLoadProgress = (value) ->
        console.log "Progress", value

    # Externalize
    $scope.onItemsChanged = ->
        console.log "Items changed yeah"

    $scope.onItemSaved = (item) ->
        console.log "Saved", item
        $scope.unselect()

    # Externalize
    $scope.onListResponse = (response) ->
        $scope.itemCountTotal = response.totalCount
        $scope.pageCount = Math.ceil(response.totalCount / $scope.itemsPerPage)
    ###################

    $scope.getItemList = ->
        # Respect previous operation by always using promise interface (or?)
        console.log "Getting items..."
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            $scope.currentOperation = dataService.getItemList($scope.itemsPerPage, $scope.itemsPerPage * $scope.selectedPage)
            $scope.currentOperation.then( (resp) ->
                $scope.unselect()
                $scope.onListResponse(resp)
                $scope.currentItems = resp.items
                $scope.onItemsChanged()
                $scope.leftToLoad = 0.0
            , $scope.onError, $scope.onLoadProgress)

    $scope.deleteItem = (item) ->
        # Respect previous operation by always using promise interface (or?)
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            if $scope.isSelectedItem(item)
                $scope.unselect()
            $scope.currentOperation = dataService.deleteItem(item)
            $scope.currentOperation.then(->
                $scope.currentItems.splice($scope.currentItems.indexOf(item), 1)
                $scope.onItemsChanged()
                $scope.leftToLoad = 0.0
            , $scope.onError, $scope.onLoadProgress)

    $scope.saveItem = (item) ->
        # Respect previous operation by always using promise interface (or?)
        $scope.currentOperation['finally'] ->
            $scope.leftToLoad = 1.0
            $scope.currentOperation = dataService.saveItem(item)
            $scope.currentOperation.then(->
                $scope.onItemSaved(item)
                $scope.leftToLoad = 0.0
            , $scope.onError, $scope.onLoadProgress)

createTestItem = (name) ->
    return {
        name: name
        someProperty: if Math.random() > 0.5 then true else false
        someOtherProperty: Math.random()
    }

console.log(createTestItem("foo" + Math.round(Math.random() * 10)))

app.factory "testDataService", ($q) ->
    service = {}
    service.deleteItem = ->
        d = $q.defer()

        setTimeout( ->
            #d.reject("nooo")
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
        console.log "Pokpokpokp"
        d = $q.defer()

        setTimeout( ->
            actualCount = Math.min(count, 125 - offset)
            items = (createTestItem("item #{offset + it}") for it in [0..actualCount])
            response = { items: items, totalCount: 125 }
            d.resolve(response)
        , 300)

        return d.promise

    return service


app.controller "TableController", ($scope, $q, testDataService) ->
    window.$q = $q

    asSimpleTableController($scope, $q, testDataService, 10)
    console.log($scope)
    $scope.selectPage(0)
