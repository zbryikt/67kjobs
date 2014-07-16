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
    $scope.db-ref = do
      date: new Firebase \https://joblist.firebaseio.com/jobs
    $scope.datasrc = do
      date: $firebase $scope.db-ref.date
      get: ({id=0, name="date"})->
        if !@[name] => 
          if !$scope.db-ref[name] => $scope.db-ref[name] = new Firebase "https://joblist.firebaseio.com/cat#id"
          @[name] = $firebase $scope.db-ref[name]
        @[name].$on \loaded, -> $scope.data[id] = update it
        #@[name].$on \change, (it)-> $scope.data[id] = it
        @[name]
    $scope.data = {}

    $scope.auth = new FirebaseSimpleLogin $scope.db-ref.date, (e,u) -> $scope.$apply -> $scope.user = u
    $scope.login = -> $scope.auth.login('facebook')
    $scope.logout = -> $scope.auth.logout()
    #$scope.joblist = []
    $scope.datasrc.date.$on \loaded, -> $scope.data[0] = update it
    #$scope.datasrc.date.$on \change, -> update!
    $scope.$watch 'jobtab', -> if $scope.jobtab => 
      src = $scope.datasrc.get $scope.jobtab

    $scope.curjob = {}
    $scope.detail = (j) ->
      $scope.curjob = j
      setTimeout (->$(\#job-detail-modal).modal("show")), 0
    $scope.remove = (job) ->
      console.log "removing..."
      console.log $scope.jobtab
      src = $scope.datasrc.get if $scope.jobtab => $scope.jobtab else {id: 0, name: "date"}
      console.log src
      src.$remove job.0 

    $scope.submit = ->
      check = <[jobname salary2 salary1 company email jobtype location title]>
      t1 = $scope.newjobform.salary1
      t2 = $scope.newjobform.salary2
      t1.$setValidity \salary1, (if $scope.newjob.salary1 < 67000 => false else true)
      t2.$setValidity \salary2, if isNaN($scope.newjob.salary2) or $scope.newjob.salary2 < $scope.newjob.salary1 => false else true
      if !$scope.user => return
      if check.map(-> $scope.newjobform[it].$invalid)filter(->it)length =>
        console.log "submit job failed"
        $scope.needfix = true
        return
      now = new Date!getTime!
      $scope.newjob.owner = {id: $scope.user.id, name: $scope.user.displayName}
      $scope.newjob.time = now
      $scope.datasrc.date.$add $scope.newjob
      $scope.datasrc.get($scope.newjob.jobtype).$add $scope.newjob
      $scope.newjob = {}
      $scope.needfix = false
      console.log "job added"
      setTimeout (-> window.location.reload!), 1000
