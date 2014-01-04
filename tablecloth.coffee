module = if exports? then exports else (window.tablecloth = {})

module.asSimpleListController = ($scope, $q, dataService, eventHandlers, itemsPerPage) ->

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
        console.log "Attempting to select page #{pageNum}"
        safePageNum = Math.max(0, Math.min($scope.pageCount - 1, pageNum))
        if safePageNum != $scope.selectedPage
            console.log "Loading #{safePageNum}"
            $scope.selectedPage = safePageNum
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

    $scope.getPageNumList = (count) ->
        start = Math.max(0, $scope.selectedPage - Math.floor(count/2))
        end = Math.min($scope.pageCount, start + count)
        start = Math.max(0, end - count)
        return [start...end]

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




module.asSimpleListService = (serviceObj, $http, urlBuilder) ->

    serviceObj.deleteItem = (item) ->
        return $http.delete(urlBuilder.getDeleteUrl(item))

    serviceObj.saveItem = (item) ->
        return $http.put(urlBuilder.getSaveUrl(item), item)

    serviceObj.getItemList = (count, offset) ->
        return $http.get(urlBuilder.getListUrl(count, offset))

    return serviceObj
