angular.module \jobs, <[firebase]>
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
      title: \測試職稱
      jobtype: id: \test, name: \test
      jobname: id: \test, name: \test
      salary1: 67000
      salary2: 68000
      location: \台北市
      company: \市北台
      email: \blah@blah.io
    $scope.jobtype = ""
    $scope.jobs = [] 
    $scope.$watch 'newjob.jobtype', (v) -> if $scope.newjob.jobtype =>
      $scope.jobs = $scope.newjob.jobtype.jobs
      console.log $scope.newjob.jobtype.jobs
    $scope.db-ref = new Firebase \https://joblist.firebaseio.com/jobs
    $scope.listsrc = $firebase $scope.db-ref
    $scope.auth = new FirebaseSimpleLogin $scope.db-ref, (e,u) -> $scope.user = u
    $scope.joblist = []
    console.log $scope.listsrc
    update = ->
      $scope.joblist = []
      for item of $scope.listsrc => if item.indexOf("$")!=0 => 
        $scope.joblist.push $scope.listsrc[item]
    $scope.listsrc.$on \loaded, -> update!
    $scope.listsrc.$on \change, -> update!
    /*$scope.joblist = [
      {"company":"foundi.info","email":"hr@foundi.info","jobname":{"id":"0205","name":"裁石工、碎石工"},"jobtype":{"id":"02","jobs":[{"id":"0201","name":"冶金工程師"},{"id":"0202","name":"冶金技術員"},{"id":"0203","name":"採礦工程師"},{"id":"0204","name":"採礦技術員"},{"id":"0205","name":"裁石工、碎石工"},{"id":"0206","name":"裁石工及石雕工"},{"id":"0207","name":"熔爐操作工"},{"id":"0208","name":"爆破工"},{"id":"0209","name":"礦工、採石工"},{"id":"0210","name":"鑽井工"},{"id":"0211","name":"鑿岩工、採石工"}],"name":"採礦冶金職類"},"location":"台北市","salary":67000,"title":"軟體工程師"}
    ]*/
    $scope.submit = ->
      check = <[jobname salary2 salary1 company email jobtype location title]>
      t1 = $scope.newjobform.salary1
      t2 = $scope.newjobform.salary2
      t1.$setValidity \salary1, (if $scope.newjob.salary1 < 67000 => false else true)
      t2.$setValidity \salary2, if isNaN($scope.newjob.salary2) or $scope.newjob.salary2 < $scope.newjob.salary1 => false else true
      if check.map(-> $scope.newjobform[it].$invalid)filter(->it)length =>
        console.log "submit job failed"
        $scope.needfix = true
        return
      $scope.listsrc.$add $scope.newjob
      $scope.newjob = {}
      $scope.needfix = false
      console.log "job added"

