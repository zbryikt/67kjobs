angular.module \jobs, <[firebase]>
  ..filter \tok, -> (it) -> 
    if isNaN it => return it
    "#{parseInt(it / 1000 )}K"

  ..directive \delayBk, -> do
    restrict: \A
    link: (scope, e, attrs, ctrl) ->
      url = attrs["delayBk"]
      $ \<img/> .attr \src url .load ->
        $(@)remove!
        e.css "backgroundImage": "url(#url)"
        e.toggle-class \visible
  ..controller \index, ($scope, $timeout, $firebase) ->
    $scope.jobtypes = jobtypes
    $scope.needfix = false
    $scope.newjob = {}
    if false => $scope.newjob = do
      title: \碩士級以上研究助理
      jobtype: $scope.jobtypes.2
      jobname: $scope.jobtypes.2.jobs.3
      salary1: 67000
      salary2: 68000
      location: \台北市
      company: \中央研究院
      url: \http://www.sinica.edu.tw
      email: \hr@nowhere.no
      desc: \研究助理，協助研究員進行研究，處理文件，申請補助計劃，論文編撰。
    $scope.user = null
    $scope.jobtype = ""
    $scope.jobs = [] 

    update = (data) ->
      ret = []
      for item of data => if item.indexOf("$")!=0 => 
        ret.push [item, data[item]]
      ret

    $scope.$watch 'newjob.jobtype', (v) -> if $scope.newjob.jobtype =>
      $scope.jobs = $scope.newjob.jobtype.jobs
      console.log $scope.newjob.jobtype.jobs
    $scope.db-ref = {}
    $scope.datasrc = do
      get: ({id=0, name="all"})->
        if !@[name] => 
          if !$scope.db-ref[name] => $scope.db-ref[name] = new Firebase "https://joblist.firebaseio.com/cat#id"
          @[name] = $firebase $scope.db-ref[name]
        @[name].$on \loaded, (v) -> $scope.$apply ->
          #$scope.data[id] = update(v)
          $scope.data[id] = update(v)slice!reverse!
        @[name].$on \change, (v) ~> if v and $scope.data[id]!=undefined =>
          #$scope.$apply ~> $scope.data[id].push [v, @[name][v]]
          $scope.$apply ~> $scope.data[id] = [[v, @[name][v]]] ++ $scope.data[id]
        @[name]
    $scope.datasrc.get {id:0, name:"all"}
    $scope.data = {}

    $scope.auth = new FirebaseSimpleLogin $scope.db-ref.all, (e,u) -> $scope.$apply -> $scope.user = u
    $scope.login = -> $scope.auth.login('facebook')
    $scope.logout = -> $scope.auth.logout()
    $scope.$watch 'jobtab', -> if $scope.jobtab => 
      src = $scope.datasrc.get $scope.jobtab

    $scope.curjob = {}
    $scope.detail = (j) ->
      $scope.curjob = j
      setTimeout (->$(\#job-detail-modal).modal("show")), 0

    $scope.remove = (job) ->
      console.log "removing..."
      src = $scope.datasrc.get if $scope.jobtab => $scope.jobtab else {id: 0, name: "all"}
      src.$remove job.0 

    $scope.submit = ->
      check = <[jobname salary2 salary1 company email jobtype location title]>
      t1 = $scope.newjobform.salary1
      t2 = $scope.newjobform.salary2
      t1.$setValidity \salary1, (if $scope.newjob.salary1 < 67000 => false else true)
      t2.$setValidity \salary2, if isNaN($scope.newjob.salary2) or $scope.newjob.salary2 < $scope.newjob.salary1 => false else true
      if !$scope.user => return
      if check.map(-> $scope.newjobform[it].$invalid)filter(->it)length =>
        console.error "submit job failed"
        $scope.needfix = true
        return
      now = new Date!getTime!
      $scope.newjob.owner = {id: $scope.user.id, name: $scope.user.displayName}
      $scope.newjob.time = now
      ref1 = $scope.datasrc.all.$add $scope.newjob
      ref2 = $scope.datasrc.get($scope.newjob.jobtype).$add $scope.newjob
      $scope.newjob = {}
      $scope.needfix = false
      console.log "job added"
      $scope.waitreload = true
      $timeout (-> $scope.waitreload = false), 1000

    # message system
    $scope.msg = do
      db: do
        all: ref: {}, data: {}
        msg: ref: {}, data: {}
        mtd: ref: {}, data: {}
        mta: ref: {}, data: {}
      newmsg: 0
      getnewmsg: ->
        @newmsg = 0
        for k,v of @db.all.data => @newmsg += v.newmsg
      init: ->
        @db.all.ref = $firebase new Firebase "https://joblist.firebaseio.com/msgmeta/#{$scope.user.id}/"
        @db.all.ref.$on \loaded, (v) ~>
          @db.all.data = v or {}
          @getnewmsg!
        @db.all.ref.$on \change, (v) ~> 
          if v =>
            @db.all.data[v] = @db.all.ref[v]
            @getnewmsg!
      key: null
      get: (atk, def) ->
        [a,b] = if atk.id < def.id => [atk,def] else [def,atk]
        key = "#{a.id}+#{b.id}"
        @db.msg.ref[key] = $firebase new Firebase "https://joblist.firebaseio.com/msg/#{a.id}/#{b.id}/"
        @db.mtd.ref[key] = $firebase new Firebase "https://joblist.firebaseio.com/msgmeta/#{def.id}/#{atk.id}/"
        @db.mta.ref[key] = $firebase new Firebase "https://joblist.firebaseio.com/msgmeta/#{atk.id}/#{def.id}/"
        @db.mtd.ref[key].$on \loaded, (v) ~> @db.mtd.data[key] = v
        @db.mta.ref[key].$on \loaded, (v) ~> @db.mta.data[key] = v
        @db.msg.ref[key].$on \loaded, (v) ~> @db.msg.data[key] = update(v)slice!reverse!
        @db.msg.ref[key].$on \change, (v) ~> if !@db.msg.data[][key].filter(->it.0==v)length =>
          @db.msg.data[key] = [[v,@db.msg.ref[key][v]]] ++ @db.msg.data[key]
        key
      send: ->
        if !@content => return
        key = @get @atk, @def
        payload = {msg: @content, time: new Date!getTime!, author: @atk.id}
        @db.msg.ref[key].$add payload
        @db.mtd.ref[key].$update (@db.mtd.data[key] or {}) <<< do
          {newmsg: ((@db.mtd.data.{}[key].newmsg or 0) + 1), user: {displayName: @atk.displayName, id: @atk.id}}
        @db.mta.ref[key].$update (@db.mta.data[key] or {}) <<< do
          {newmsg: 0, user: {displayName: @def.displayName, id: @def.id}}
        @getnewmsg!
        @content = ""
        console.log "message sent."

      show: (atk, def) ->
        if !(atk and def) => return
        $scope.msg <<< {atk, def}
        @key = $scope.msg.get atk, def
        @db.mta.ref[@key].$update (@db.mta.data[@key] or {}) <<< do
          {newmsg: 0, user: {displayName: @def.displayName, id: @def.id}}
        @getnewmsg!
        setTimeout (-> $(\#msg-modal).modal("show")), 0
    $('#msg-modal').on 'hide.bs.modal', -> 
      m = $scope.msg
      if !(m.atk and m.def) => return
      key = m.get m.atk, m.def
      m.db.mta.ref[key].$update (m.db.mta.data[key] or {}) <<< do
        {newmsg: 0, user: {displayName: m.def.displayName, id: m.def.id}}
      m.getnewmsg!

    $scope.$watch 'user' -> if it => $scope.msg.init!
