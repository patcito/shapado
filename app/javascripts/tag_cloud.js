function tagCloud() {
  var counts = db.eval(
    function(){
      var counts = {};
      db.questions.find().forEach(
        function(p){
          if ( p.tags ){
            for ( var i=0; i<p.tags.length; i++ ){
              var name = p.tags[i];
              counts[name] = 1 + ( counts[name] || 0 );
            }
          }
        }
      );
      return counts;
    }
  );

  // maybe sort to by nice
  var sorted = [];
  for ( var tag in counts ){
    sorted.push( { name : tag , count : counts[tag] } )
  }

  return sorted.sort(
    function(l,r){
      return r.count - l.count;
    }
  );
}
